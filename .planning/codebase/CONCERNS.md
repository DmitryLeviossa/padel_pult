# Codebase Concerns

**Analysis Date:** 2026-05-08

---

## Tech Debt

**No model validations anywhere:**
- Issue: None of the five domain models (`League`, `Tournament`, `Pair`, `LeagueUser`, `User`) define a single `validates` call (Devise covers only email format and password length on `User`). Required fields like `League#name`, `Tournament#name`, `Tournament#start_date`, `Tournament#end_date` are enforced only at the DB `NOT NULL` level, which raises an `ActiveRecord::NotNullViolation` exception instead of surfacing friendly form errors.
- Files: `app/models/league.rb`, `app/models/tournament.rb`, `app/models/pair.rb`, `app/models/league_user.rb`
- Impact: Invalid records crash rather than re-render with errors; business rules (e.g. `end_date >= start_date`, `max_participants >= 2`) are completely absent.
- Fix approach: Add `validates :name, presence: true` etc. to each model; add date-range cross-validation to `Tournament`.

**No RSpec — tests use Rails Minitest but are entirely empty stubs:**
- Issue: The `CLAUDE.md` convention requires RSpec (`bundle exec rspec`) and FactoryBot, but neither gem is in the Gemfile. Every test file (`test/models/*.rb`, `test/controllers/*.rb`) contains only a commented-out stub. Zero assertions exist.
- Files: `test/models/league_test.rb`, `test/models/tournament_test.rb`, `test/models/user_test.rb`, `test/models/league_user_test.rb`, `test/models/pair_test.rb`, `test/controllers/leagues_controller_test.rb`, `test/controllers/tournaments_controller_test.rb`, `Gemfile`
- Impact: CI passes with no coverage. Any regression goes undetected. Project convention (`CLAUDE.md`: "Write request specs for API endpoints", "Use FactoryBot") is not fulfilled.
- Fix approach: Add `rspec-rails` and `factory_bot_rails` to `Gemfile` test group; migrate test stubs to real RSpec specs; create factories for all models.

**Homegrown inline authorization instead of a policy library:**
- Issue: Authorization is implemented as ad-hoc `authorize_owner!` private methods duplicated in both `LeaguesController` and `TournamentsController`. Logic differs slightly (redirect paths, alert wording). No authorization library (Pundit, CanCanCan) is used.
- Files: `app/controllers/leagues_controller.rb:43-45`, `app/controllers/tournaments_controller.rb:37-39`
- Impact: Authorization logic will diverge further as more roles/contexts are added; easy to miss applying it to new actions.
- Fix approach: Extract to Pundit policies (`LeaguePolicy`, `TournamentPolicy`) and call `authorize @league` in a `before_action`.

**`League` and `Tournament` `destroy` actions are missing:**
- Issue: `resources :leagues` and `resources :tournaments` expose all seven RESTful routes, but neither controller defines a `destroy` action. Visiting `DELETE /leagues/:id` raises a `AbstractController::ActionNotFound` error.
- Files: `app/controllers/leagues_controller.rb`, `app/controllers/tournaments_controller.rb`, `config/routes.rb`
- Impact: No way to delete a league or tournament; unhandled routing crash if route is hit directly.
- Fix approach: Either add `destroy` actions with appropriate owner authorization, or scope routes with `only:` to exclude `:destroy` until it is implemented.

**`LeagueUser` duplicate-join not prevented at DB or model level:**
- Issue: The `league_users` table has no composite unique index on `(league_id, user_id)`, and the model has no `uniqueness` validation. A user can be added to the same league multiple times.
- Files: `app/models/league_user.rb`, `db/schema.rb:45-53`
- Impact: Score tallies, pair lookups, and UI listings break with duplicates.
- Fix approach: Add a migration `add_index :league_users, [:league_id, :user_id], unique: true` and `validates :user_id, uniqueness: { scope: :league_id }` to the model.

**`Pair` duplicate-pair not prevented:**
- Issue: The `pairs` table has no unique index on `(tournament_id, player1_id, player2_id)`. The same two players can be registered as a pair multiple times in the same tournament.
- Files: `app/models/pair.rb`, `db/schema.rb:64-73`
- Impact: Leaderboard scores double-count; UI shows duplicate rows.
- Fix approach: Add migration with a unique index on `(tournament_id, player1_id, player2_id)` and a model uniqueness validation.

**`Tournament#type` shadows ActiveRecord STI column — manually disabled:**
- Issue: The `type` column in `tournaments` is the Rails STI discriminator column. The model suppresses this with `self.inheritance_column = nil` to store a string value (`"olimpic"`, `"round_robin"`). This means the column name is a permanent footgun — any developer who removes that line breaks the app silently.
- Files: `app/models/tournament.rb:27`, `db/schema.rb:81`
- Impact: Easy to regress; also makes `type` values a bare string with no enum, scope, or validation.
- Fix approach: Rename the column to `tournament_type` (migration + form param update) and use an ActiveRecord `enum`.

**`Tournament#status` and `Tournament#type` are unvalidated bare strings:**
- Issue: Both columns have DB defaults (`"draft"` and `"olimpic"`) but accept any string. There is no `enum`, no `validates :status, inclusion:`, and no model-level enforcement.
- Files: `app/models/tournament.rb`
- Impact: Bad data can be persisted; views hardcode the allowed strings in badge hash lookups (`app/views/tournaments/show.html.slim:29`, `app/views/tournaments/index.html.slim:24`) with no fallback validation.
- Fix approach: Add `enum status: { draft: "draft", active: "active", completed: "completed", cancelled: "cancelled" }` (or integer enum) and `enum tournament_type: { olimpic: "olimpic", round_robin: "round_robin" }` after renaming the column.

**Hardcoded production mailer hostname:**
- Issue: `config/environments/production.rb:60` sets `host: "example.com"` and `config/initializers/devise.rb:27` still contains the Devise placeholder sender `please-change-me-at-config-initializers-devise@example.com`.
- Files: `config/environments/production.rb:60`, `config/initializers/devise.rb:27`
- Impact: Password reset and confirmation emails link to `example.com` in production; sender address is invalid.
- Fix approach: Replace both with environment-variable-driven values: `ENV.fetch("APP_HOST")` and `ENV.fetch("DEVISE_MAILER_FROM")`.

**Inline Ruby sorting in views (Ruby-side, not DB-side):**
- Issue: `app/views/tournaments/show.html.slim:46` sorts pairs with `@tournament.pairs.sort_by { |p| -p.score }` after the pairs are already loaded in memory. The `score` method itself calls `player1.score + player2.score`, but `player1` and `player2` are `LeagueUser` associations; their individual `score` attributes are already loaded via `includes`, so sorting is not an N+1 problem here, but it is a Ruby-side sort that should be replaced with a DB `ORDER BY`.
- Files: `app/views/tournaments/show.html.slim:46`
- Fix approach: Add a named scope or order clause at the controller level. Move sorting logic out of the view entirely.

---

## Security Considerations

**Content Security Policy is fully disabled:**
- Risk: The entire CSP initializer is commented out. No `default-src`, `script-src`, or `style-src` directives are enforced.
- Files: `config/initializers/content_security_policy.rb`
- Current mitigation: Rails CSRF protection and Devise authentication are in place.
- Recommendations: Enable and configure CSP. At minimum: `policy.default_src :self; policy.script_src :self; policy.style_src :self, :unsafe_inline`.

**No file-upload type or size validation:**
- Risk: `User#photo` and `League#logo` accept any file type and any file size. An attacker can upload multi-GB files or non-image content (SVG with embedded scripts, etc.).
- Files: `app/models/user.rb:27`, `app/models/league.rb:27`, Gemfile (image_processing gem is commented out)
- Current mitigation: None — no `validates :photo, content_type:` or `size:` check; the `image_processing` gem is commented out in Gemfile.
- Recommendations: Add Active Storage validations using `active_storage_validations` gem or manual content-type/size checks on `has_one_attached` blobs. Enable `image_processing` and use `.variant` to resize images on delivery.

**`Rails.application.config.hosts` is commented out in production:**
- Risk: DNS rebinding and `Host` header attacks are possible because host authorization is disabled.
- Files: `config/environments/production.rb:83-88`
- Current mitigation: SSL termination at reverse proxy.
- Recommendations: Uncomment and set `config.hosts` to the actual production domain.

---

## Performance Bottlenecks

**N+1 queries: `DashboardController` — `league.tournaments.count` per league:**
- Problem: The dashboard view calls `league.tournaments.count` for every league in `@my_leagues` (line 19 of `app/views/dashboard/index.html.slim`), generating one SQL COUNT query per league.
- Files: `app/controllers/dashboard_controller.rb:3`, `app/views/dashboard/index.html.slim:19`
- Cause: `@my_leagues = League.where(owner: current_user)` loads leagues without preloading tournament counts.
- Improvement path: Use `League.where(owner: current_user).includes(:tournaments)` or `left_joins(:tournaments).select("leagues.*, COUNT(tournaments.id) AS tournaments_count").group("leagues.id")`.

**N+1 queries: `DashboardController` — `tournament.league.name` per tournament:**
- Problem: `@my_tournaments` is loaded via `Tournament.joins(:league).where(...)` which performs a JOIN but does not `include` the `league` association. Each `tournament.league.name` call in the view (`app/views/dashboard/index.html.slim:35`) fires an additional SELECT.
- Files: `app/controllers/dashboard_controller.rb:4`, `app/views/dashboard/index.html.slim:35`
- Cause: `joins` does not populate the association cache; use `includes` (or `eager_load`).
- Improvement path: Change to `Tournament.includes(:league).joins(:league).where(leagues: { owner_id: current_user.id })`.

**N+1 queries: `DashboardController` — `league.owner.full_name` per recent league:**
- Problem: `@recent_leagues = League.order(created_at: :desc).limit(5)` does not preload `owner`. The view accesses `league.owner.full_name` for each recent league card (`app/views/dashboard/index.html.slim:52`), causing up to 5 extra queries.
- Files: `app/controllers/dashboard_controller.rb:5`, `app/views/dashboard/index.html.slim:52`
- Improvement path: Change to `League.includes(:owner).order(created_at: :desc).limit(5)`.

**N+1 queries: `LeaguesController#show` — `league_user.user.photo` per participant:**
- Problem: `League#show` renders `@league` with `league_users` iterated in the view. Each `league_user.user.photo.attached?` call traverses `league_user → user → active_storage_attachment`. The `user` association is not preloaded.
- Files: `app/controllers/leagues_controller.rb:7`, `app/views/leagues/show.html.slim:58-76`
- Improvement path: In the controller: `@league = League.includes(league_users: { user: :photo_attachment }).find(params[:id])`.

**Unscoped `League.all` and `Tournament.all` load full tables:**
- Problem: `LeaguesController#index` calls `League.all` and `TournamentsController#index` calls `Tournament.all` — both load every record in the table with no pagination.
- Files: `app/controllers/leagues_controller.rb:3`, `app/controllers/tournaments_controller.rb:7`
- Improvement path: Add `pagy` or `kaminari` gem and paginate. At minimum add `.order(:name).limit(50)`.

**`UsersController#index` loads all users with no pagination:**
- Problem: `@users = User.order(:last_name, :first_name, :email)` loads every user row.
- Files: `app/controllers/users_controller.rb:3`
- Improvement path: Paginate with `pagy` or `kaminari`.

**Full-size images served without variants:**
- Problem: User photos and league logos are served at their original uploaded resolution. Views constrain display to 40×40 px or 64×64 px via CSS, but full original files are downloaded to the browser.
- Files: `app/views/leagues/index.html.slim:15`, `app/views/leagues/show.html.slim:5,70`, `app/views/users/index.html.slim:23`, `app/views/tournaments/show.html.slim:51,59`, `app/views/devise/registrations/edit.html.slim:13`
- Improvement path: Uncomment `gem "image_processing", "~> 1.2"` in Gemfile and replace `image_tag record.photo` with `image_tag record.photo.variant(resize_to_fill: [80, 80])`.

---

## Fragile Areas

**`Pair#score` method — depends on `LeagueUser#score` staying an attribute:**
- Files: `app/models/pair.rb:29-31`
- Why fragile: `def score` sums `player1.score + player2.score` where `score` is the `league_users.score` integer column. If `score` is ever renamed, becomes a method, or `LeagueUser` gains a `score` method with different semantics, this silently changes pair ranking.
- Safe modification: Add a `Pair#score` test asserting the expected sum and document the dependency.
- Test coverage: Zero — `test/models/pair_test.rb` is an empty stub.

**`LeaguesController#edit` and `#update` call `authorize_owner!` but `@league` is set inline (not via `before_action`):**
- Files: `app/controllers/leagues_controller.rb:25-38`
- Why fragile: If a new action is added that calls `authorize_owner!` before `@league` is set, it raises a `NoMethodError` on `nil`. The pattern is inconsistent — `set_league` is not extracted as a `before_action` the way `TournamentsController` does it.
- Safe modification: Extract `before_action :set_league, only: [:show, :edit, :update, :destroy]`.

**`Tournament#type` column disabled STI — no guard against regression:**
- Files: `app/models/tournament.rb:27`
- Why fragile: The single line `self.inheritance_column = nil` is the only thing preventing Rails from trying to use `type` for STI class lookup. This is undocumented and could be removed during a refactor.
- Safe modification: Add a code comment explaining why it is present; consider the column rename fix described above.

**`Pair` cross-league validity not checked:**
- Files: `app/models/pair.rb`
- Why fragile: A `Pair` links two `LeagueUser` records and a `Tournament`. There is no validation ensuring that both `player1` and `player2` belong to the same league as the tournament. Pairs can be created with players from a different league.
- Safe modification: Add a custom validation: `validate :players_belong_to_tournament_league`.

---

## Test Coverage Gaps

**All controller and model tests are empty stubs:**
- What's not tested: Every controller action, every model association, every model method (`User#full_name`, `Pair#score`), authorization logic, and form parameter handling.
- Files: `test/controllers/leagues_controller_test.rb`, `test/controllers/tournaments_controller_test.rb`, `test/models/league_test.rb`, `test/models/tournament_test.rb`, `test/models/user_test.rb`, `test/models/league_user_test.rb`, `test/models/pair_test.rb`
- Risk: Any refactor can break existing behavior without detection; CI green light is meaningless.
- Priority: High

**No RSpec or FactoryBot despite being required by project convention:**
- What's not tested: The project `CLAUDE.md` specifies `bundle exec rspec` and FactoryBot, but neither is installed and no spec directory exists.
- Files: `Gemfile`, (missing) `spec/`
- Risk: Future developers will write Minitest tests while expecting RSpec patterns.
- Priority: High

**No test for authorization logic:**
- What's not tested: Unauthorized users editing leagues they don't own; unauthorized users creating tournaments in leagues they don't own.
- Risk: Authorization regressions go undetected.
- Priority: High

**No test for `Pair#score`:**
- What's not tested: The computed score method on `Pair`.
- Files: `app/models/pair.rb:29-31`, `test/models/pair_test.rb`
- Risk: Score bug undetected until noticed in UI.
- Priority: Medium

---

## Missing Critical Features

**No way to add or remove users from a league (UI/controller):**
- Problem: `LeagueUser` model and join table exist, but there is no controller or route to manage membership. Seeds populate it directly. The league show page renders members but provides no way to add or remove them.
- Blocks: Core padel league workflow — registering players before creating pairs.

**No tournament `edit`/`update` or `destroy` action:**
- Problem: `TournamentsController` only implements `index`, `show`, `new`, `create`. Once a tournament is created, name, dates, location, and status cannot be changed through the UI.
- Blocks: Tournament lifecycle management.

**No way to edit or destroy pairs:**
- Problem: No controller or routes exist for `Pair` CRUD. Pairs can only be created via seeds.
- Blocks: Tournament bracket management.

**No pagination on any list view:**
- Problem: All index actions load unbounded result sets.
- Blocks: Acceptable performance with real data.

---

*Concerns audit: 2026-05-08*

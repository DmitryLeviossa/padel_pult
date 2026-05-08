# Coding Conventions

**Analysis Date:** 2026-05-08

## Naming Patterns

**Files:**
- Controllers: `snake_case_controller.rb` — e.g., `leagues_controller.rb`, `dashboard_controller.rb`
- Models: `snake_case.rb` singular — e.g., `league.rb`, `league_user.rb`, `tournament.rb`
- Views: `action_name.html.slim` — e.g., `index.html.slim`, `show.html.slim`
- Migrations: timestamp prefix, descriptive verb — e.g., `20260506120601_create_leagues.rb`, `20260508164309_add_name_to_users.rb`

**Classes:**
- Models: `PascalCase` singular — `League`, `LeagueUser`, `Tournament`, `Pair`
- Controllers: `PascalCase` plural + `Controller` suffix — `LeaguesController`, `TournamentsController`
- Join model classes: compound name — `LeagueUser` (not `Membership`)

**Methods:**
- `snake_case` throughout — `full_name`, `authorize_owner!`, `configure_permitted_parameters`
- Bang suffix for methods that redirect/raise on failure — `authorize_owner!`
- Predicate methods use `?` suffix via Rails helpers — `.any?`, `.present?`, `.attached?`

**Variables:**
- Instance variables: `@snake_case` — `@league`, `@my_leagues`, `@recent_leagues`
- Local variables: `snake_case` — `league_user`, `badge_class`, `tournament`

**Database:**
- Table names: `snake_case` plural — `leagues`, `league_users`, `tournaments`, `pairs`
- Foreign keys: `{model}_id` — `owner_id`, `league_id`, `player1_id`, `player2_id`
- Non-conventional FK: aliased columns `player1_id`, `player2_id` both reference `league_users`

## Code Style

**Formatting:**
- Tool: RuboCop with `rubocop-rails-omakase` (Basecamp/Rails house style)
- Config: `.rubocop.yml` — inherits gem defaults with no local overrides active
- Two-space indentation (omakase default)
- Double-quoted strings for Ruby (omakase enforces)
- Trailing comma: omakase style

**Linting:**
- `rubocop-rails-omakase` gem — covers Layout, Style, Rails, Lint cops
- Run via: `bin/rubocop`
- Security scanning: `brakeman` gem (dev/test group)

## Import / Require Organization

**Pattern:**
- Model files begin with `# == Schema Information` annotaterb block, then blank line, then class definition
- No explicit `require` in app/ — Rails autoloading handles all models/controllers/helpers
- Test files: `require "test_helper"` as first non-comment line

## Controller Patterns

**Structure (skinny controllers):**
```ruby
class LeaguesController < ApplicationController
  before_action :set_league, only: [...]
  before_action :authorize_owner!, only: [...]

  def action
    # one assignment + redirect or render
  end

  private

  def set_league
    @league = League.find(params[:id])
  end

  def authorize_owner!
    redirect_to path, alert: "..." unless @record.owner == current_user
  end

  def resource_params
    params.require(:resource).permit(:attr1, :attr2)
  end
end
```

**before_action callbacks:**
- Used for record lookup: `set_league`, `set_tournament`
- Used for authorization: `authorize_owner!`
- Always scoped with `only:` array — never unscoped

**Strong parameters:**
- Private method named `{resource}_params` — `league_params`, `tournament_params`
- Defined at bottom of private section

**Authorization:**
- Inline owner check: `@league.owner == current_user`
- Implemented as private `authorize_owner!` bang method that redirects
- No external authorization gem (Pundit/CanCan) — manual pattern

**Flash messages:**
- `:notice` for success — English in some places (`"League created successfully."`), Russian in others (`"Лига обновлена."`)
- `:alert` for auth failure — Russian (`"Нет доступа."`, `"Not authorized."`)

## Model Patterns

**Associations:**
```ruby
belongs_to :owner, class_name: "User"      # aliased association
has_many :tournaments
has_many :league_users
has_many :users, through: :league_users    # through association
has_one_attached :photo                     # Active Storage
```

**Delegation:**
```ruby
delegate :full_name, to: :user             # used in LeagueUser
```

**Custom methods:**
- Business logic as instance methods on the model — `full_name`, `score`
- Fallback with `presence || default` pattern:
  ```ruby
  "#{first_name} #{last_name}".strip.presence || email
  ```

**STI opt-out:**
```ruby
self.inheritance_column = nil   # Tournament uses `type` column without STI
```

**Validations:**
- Not explicitly written in model files — relied on DB constraints and Devise validations for `User`
- `League` and `Tournament` have no explicit `validates` calls; presence enforced at DB level (`not null`)

## View Patterns

**Template engine:** Slim (`.html.slim`) — all application views
- Exception: Devise mailer templates are `.html.erb`

**CSS framework:** Bootstrap 5
- Utility classes chained with `.` in Slim — `.container.py-4`, `.d-flex.justify-content-between`
- No custom CSS utility layer

**Slim conventions:**
```slim
.container.py-4
  h1.mb-0 Title text
  = link_to "Label", path, class: "btn btn-primary"
  - if condition
    p.text-muted Conditional content
```

**Flash handling in views:**
```slim
- if flash[:notice]
  .alert.alert-success= flash[:notice]
- if flash[:alert]
  .alert.alert-danger= flash[:alert]
```

**Inline logic in views:**
- Status badge color mapping done inline in the view (`tournaments/show.html.slim`):
  ```slim
  - badge_class = { "draft" => "secondary", ... }.fetch(@tournament.status, "secondary")
  ```
- Sorting done inline: `@tournament.pairs.sort_by { |p| -p.score }` — this is a view concern that should move to the model/controller

**Presence checks:**
- `resource.attribute.presence || "—"` for optional fields
- `resource.attached?` for Active Storage

## Route Patterns

**RESTful resources:**
```ruby
resources :leagues do
  resources :tournaments, only: [:new, :create]   # nested for creation
end
resources :tournaments                             # standalone for show/index
```
- Shallow nesting: tournaments nested under leagues only for new/create; standalone resources used for show

## Error Handling

**Patterns:**
- Controller-level: redirect with flash `:alert` on authorization failure
- No rescue blocks in controllers for record lookup — `find` raises `ActiveRecord::RecordNotFound` (unhandled, relies on Rails default 404)
- No global error handler in `ApplicationController`
- Render `:new` or `:edit` with `status: :unprocessable_entity` on failed save

## Comments

**When to Comment:**
- annotaterb schema comments at top of every model and test file — auto-generated, always present
- Inline comments: minimal; only in initializers and generated config files
- No method-level documentation

## Authentication

**Devise integration:**
- `before_action :authenticate_user!` in `ApplicationController` — all actions require login
- Custom permitted params for `:sign_up` and `:account_update` configured in `ApplicationController`
- `current_user` helper used directly in controllers and views

---

*Convention analysis: 2026-05-08*

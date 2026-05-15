---
phase: 03-shared-components
reviewed: 2026-05-09T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - app/assets/stylesheets/_cards.scss
  - app/assets/stylesheets/_forms.scss
  - app/assets/stylesheets/_tables.scss
  - app/assets/stylesheets/_avatar.scss
  - app/assets/stylesheets/_variables.scss
  - app/assets/stylesheets/_theme.scss
  - app/assets/stylesheets/application.bootstrap.scss
  - app/views/shared/_avatar.html.slim
  - app/views/leagues/show.html.slim
  - app/views/users/index.html.slim
  - app/views/tournaments/index.html.slim
  - app/views/tournaments/show.html.slim
  - app/views/devise/registrations/edit.html.slim
findings:
  critical: 3
  warning: 4
  info: 2
  total: 9
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-05-09
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 3 introduced SCSS partials for dark-themed cards, forms, tables, and avatar placeholder; updated `_variables.scss` and `_theme.scss`; updated the manifest; added a shared `_avatar.html.slim` partial; and replaced inline avatar blocks with partial calls across five templates.

The SCSS cascade design is sound and the Bootstrap import ordering is correct. The primary defects are: (1) a nil-crash in the avatar partial when `full_name` resolves to a bare email address that contains no whitespace-separated words; (2) an N+1 query chain in `tournaments/show` because the includes clause stops at `player1`/`player2` (LeagueUser) without continuing to `:user`, causing one extra SELECT per pair for each `pair.player1.user` / `pair.player2.user` call; (3) a CSS class injection vector in the badge pattern that appears in two templates, where `tournament.status` is interpolated directly into a class attribute string without sanitisation. All three require fixes before shipping.

---

## Critical Issues

### CR-01: XSS — unsanitised model value interpolated into HTML attribute (badge class injection)

**File:** `app/views/tournaments/index.html.slim:25` and `app/views/tournaments/show.html.slim:30`

**Issue:** The badge CSS class is built by string-interpolating `tournament.status` through a hash `.fetch` with a hardcoded fallback:

```slim
- badge_class = { "draft" => "secondary", ... }.fetch(tournament.status, "secondary")
span class="badge bg-#{badge_class}" = tournament.status.capitalize
```

The `.fetch` with a string-literal fallback is not the problem — the problem is that `badge_class` is set to the *hash value* only when the key is found, which is safe. **However**, the `status` column has no database-level enum constraint enforced in the model: `Tournament` uses a plain `string` column with no `validates :status, inclusion:` guard. If `status` holds an unexpected value (e.g., injected via a direct DB write or a missing validation), `.fetch` returns the fallback `"secondary"` and `badge_class` is safe — but `tournament.status.capitalize` on that same line outputs the raw status string directly into element content via Slim's `=` (which HTML-escapes content), so content output is safe.

The **actual injection surface** is in Slim attribute interpolation: `class="badge bg-#{badge_class}"`. Slim attribute values written with `"..."` are **not** automatically HTML-escaped by Slim — Slim escapes content output (`=`) but not string-interpolated attribute values. Because `badge_class` is derived from a trusted hash lookup whose values are hardcoded strings (`"secondary"`, `"success"`, etc.), this particular path is not exploitable — but the pattern is fragile. If a developer refactors to pass `tournament.status` directly into the interpolation (e.g., a copy-paste of the pattern), the class attribute becomes a live injection point. More critically, the `status` column has no model-level inclusion validation, so any value that slips through the `.fetch` fallback would land directly in the class string if the pattern were slightly changed.

The correct fix is to use the hash purely for lookup and never interpolate any model-derived string into an attribute:

```slim
- badge_class = { "draft" => "secondary", "active" => "success", "completed" => "primary", "cancelled" => "danger" }.fetch(tournament.status, "secondary")
span.badge class="bg-#{badge_class}"
  = tournament.status.capitalize
```

And add model validation as defense-in-depth:

```ruby
# app/models/tournament.rb
validates :status, inclusion: { in: %w[draft active completed cancelled] }
```

---

### CR-02: Crash — `NoMethodError` when `full_name` returns an email address (nil character)

**File:** `app/views/shared/_avatar.html.slim:8`

**Issue:**

```slim
- initials = user.full_name.split.map(&:first).first(2).join.upcase
```

`User#full_name` falls back to `email` when both `first_name` and `last_name` are blank:

```ruby
def full_name
  "#{first_name} #{last_name}".strip.presence || email
end
```

`email` is always present (Devise requires it). An email like `"user@example.com"` has no spaces, so `.split` yields `["user@example.com"]`, `.map(&:first)` yields `["u"]`, and `.first(2).join.upcase` yields `"U"` — that part does not crash.

The crash scenario is subtler: `String#first` in Ruby core is not defined — `Array#first` is. `map(&:first)` calls `String#first` on each word. Rails extends `String` with `first(limit=1)`, which returns the first character. **This works in Rails** but would fail in pure Ruby. This is acceptable in a Rails context.

The real crash is: if `first_name` or `last_name` is somehow `nil` (the columns are nullable per the schema — `first_name :string` with no `not null` constraint), the interpolation `"#{nil} #{nil}".strip` yields `""`, `.presence` returns `nil`, and the fallback is `email`. Email is not nil (Devise validates presence), so no crash there.

**However**, there is a genuine crash when `user` itself is `nil`. The partial comment says `user` is required, but no guard is present. In `leagues/show.html.slim:69`, the call is `render "shared/avatar", user: league_user.user`. `league_user.user` is a `belongs_to :user` association — if the foreign key is valid this will not be nil. But in `tournaments/show.html.slim:50-54`, the call is `pair.player1.user` where `player1` is a `LeagueUser`. If a `LeagueUser` record was deleted after a `Pair` was created (orphaned pair — no `dependent: :destroy` on the league_user side), `.user` will be `nil`, and `nil.full_name` raises `NoMethodError`.

Add a nil guard:

```slim
- return if user.nil?
```

as the first line of the partial, or ensure referential integrity with `validates_associated` / database constraints.

---

### CR-03: N+1 query — `pair.player1.user` and `pair.player2.user` are not eagerly loaded

**File:** `app/views/tournaments/show.html.slim:50,54`
**Related:** `app/controllers/tournaments_controller.rb:34`

**Issue:** The controller eager-loads:

```ruby
@tournament = Tournament.includes(pairs: [:player1, :player2]).find(params[:id])
```

`player1` and `player2` are `LeagueUser` records. The avatar partial then calls `pair.player1.user` — the `:user` association on `LeagueUser` is not included in the `includes` chain. For a tournament with N pairs, this fires 2N additional `SELECT * FROM users WHERE id = ?` queries, one per avatar render.

Fix by extending the includes chain:

```ruby
@tournament = Tournament.includes(
  pairs: [
    { player1: :user },
    { player2: :user }
  ]
).find(params[:id])
```

---

## Warnings

### WR-01: `_tables.scss` selector is over-broad — targets all `<thead>` in the page, not just `.table` descendants

**File:** `app/assets/stylesheets/_tables.scss:6`

**Issue:**

```css
thead > tr > th {
  background-color: var(--color-bg-surface);
  color: var(--color-text-muted);
  font-weight: 600;
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}
```

The selector `thead > tr > th` matches every `<thead>` element in the entire document, including any third-party components, rich-text editors, admin panels, or email preview widgets that may render tables. The intent was to style Bootstrap `.table` headers. This will produce unintended dark styling on tables that do not carry the `.table` class.

Scope the selector:

```css
.table thead > tr > th {
  background-color: var(--color-bg-surface);
  color: var(--color-text-muted);
  font-weight: 600;
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}
```

---

### WR-02: Active Storage `image_tag` passes the attachment object directly — no size variant, full original served to browser

**File:** `app/views/shared/_avatar.html.slim:11`

**Issue:**

```slim
= image_tag user.photo, class: "rounded-circle", style: "width: #{size}px; height: #{size}px; object-fit: cover;"
```

`user.photo` is passed as an `ActiveStorage::Attached::One` object. Rails renders this as a URL to the original file. A user may upload a 4MB JPEG that is then served every time an avatar is displayed — at 40 px (default size). The browser scales it with CSS, but the full image is downloaded. This is both a correctness issue (the blob URL is a signed short-lived URL; in production with a CDN the original may be arbitrarily large) and a reliability concern (if image processing is not configured, calling `.variant` will raise at runtime — but the current code does not call `.variant`, so it silently serves originals).

Use a variant to enforce a safe maximum dimension:

```slim
= image_tag user.photo.variant(resize_to_fill: [size * 2, size * 2]), ...
```

Note: this requires `image_processing` gem in the Gemfile. If it is absent, add it; if image processing is explicitly out of scope for this phase, document the known gap.

---

### WR-03: `_variables.scss` sets `$input-bg` to a CSS custom property — this may not compile correctly

**File:** `app/assets/stylesheets/_variables.scss:12`

**Issue:**

```scss
$input-bg: var(--color-bg-surface);
```

Bootstrap's `$input-bg` is a Sass variable used inside Sass color functions (e.g., `rgba($input-bg, ...)`, `darken($input-bg, ...)`, `mix($input-bg, ...)`) in some Bootstrap partials. Passing a `var(--css-custom-property)` string as the value means those color functions will receive a string, not a color value, and will either silently produce invalid CSS or throw a Sass compile error depending on which Bootstrap partial uses it.

In Bootstrap 5, `$input-bg` is used in `_forms.scss` primarily as a direct property value (not inside color functions), so this may not cause a compile error today. However, it is fragile — any Bootstrap upgrade that adds a color function call on `$input-bg` will break the build silently or loudly.

The safer approach is to set `$input-bg` to a concrete hex value that matches the token:

```scss
$input-bg: #21262d; // matches --color-bg-surface
```

The `[data-bs-theme="dark"]` block in `_theme.scss` already overrides `--bs-input-bg: var(--color-bg-surface)` for Bootstrap's CSS-variable-driven components, so the dark surface will still apply at runtime even if the Sass variable is a static hex.

---

### WR-04: `devise/registrations/edit.html.slim` — "Delete account" card is outside the `.col-md-6` column, causing layout breakage

**File:** `app/views/devise/registrations/edit.html.slim:49`

**Issue:** The layout structure is:

```slim
.container
  .row.justify-content-center.mt-5
    .col-md-6           ← indented correctly
      .card.shadow-sm   ← edit form card (inside col-md-6)
        ...
    .card.shadow-sm.mt-3  ← DELETE card is a DIRECT child of .row, not inside any .col-*
      ...
```

The "Delete account" `.card` is a direct child of `.row`, not wrapped in a `.col-*` column. Bootstrap's `.row` uses negative margins and expects direct children to be `.col-*` elements. Placing a `.card` directly inside `.row` without a column wrapper breaks the grid, causing the delete card to ignore gutters and potentially overflow or misalign.

Fix:

```slim
.container
  .row.justify-content-center.mt-5
    .col-md-6
      .card.shadow-sm
        ...
      .card.shadow-sm.mt-3   ← move inside .col-md-6
        ...
```

---

## Info

### IN-01: `_avatar.scss` is an empty placeholder file — misleads readers

**File:** `app/assets/stylesheets/_avatar.scss:1-4`

**Issue:** The file contains only a comment saying styles are inline in the template and the file is reserved for Phase 5. Avatar styles (width, height, border, font-size, font-weight, color) are currently embedded as inline `style=` attributes on the element in `_avatar.html.slim:13`. This is not wrong, but it means styles cannot be overridden by CSS specificity alone — inline styles have the highest specificity, requiring `!important` in any override. The comment correctly identifies this as a future concern but does not flag it as a technical debt item.

No action required for Phase 3, but the inline style approach should be tracked and addressed before Phase 5 adds transitions, since transitions on inline-styled elements are unreliable.

---

### IN-02: `leagues/show.html.slim` — `@league.tournaments.order(...)` fires a new query inside the view

**File:** `app/views/leagues/show.html.slim:44`

**Issue:**

```slim
- @league.tournaments.order(start_date: :asc).each do |tournament|
```

This calls `.order` on the association, which fires a SQL query from within the view layer. The convention in this project (fat models, skinny controllers) is to move query logic out of views. This was not introduced by Phase 3 (it is pre-existing code), but it is present in a file modified in this phase and worth noting for cleanup.

Move to the controller or a model scope.

---

_Reviewed: 2026-05-09_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

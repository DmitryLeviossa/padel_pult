---
phase: 03-shared-components
fixed_at: 2026-05-09T00:00:00Z
review_path: .planning/phases/03-shared-components/03-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 3: Code Review Fix Report

**Fixed at:** 2026-05-09
**Source review:** `.planning/phases/03-shared-components/03-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (3 Critical, 4 Warning)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: XSS — unsanitised model value interpolated into HTML attribute (badge class injection)

**Files modified:** `app/views/tournaments/index.html.slim`, `app/views/tournaments/show.html.slim`, `app/models/tournament.rb`
**Commit:** 83837cc
**Applied fix:** Changed both badge span elements from `span class="badge bg-#{badge_class}"` with inline content to Slim shorthand `span.badge class="bg-#{badge_class}"` with `= tournament.status.capitalize` on a separate indented line. This separates the trusted hash-derived attribute interpolation from the HTML-escaped content output. Also added `validates :status, inclusion: { in: %w[draft active completed cancelled] }` to `Tournament` model as defense-in-depth.

---

### CR-02: Crash — `NoMethodError` when user is nil in avatar partial

**Files modified:** `app/views/shared/_avatar.html.slim`
**Commit:** dcd80f2
**Applied fix:** Added `- return if user.nil?` as the first executable line of the partial (after the comment header), before any method calls on `user`. This guards against orphaned `Pair` records where `pair.player1.user` or `pair.player2.user` is nil due to a deleted LeagueUser.

---

### CR-03: N+1 query — `pair.player1.user` and `pair.player2.user` are not eagerly loaded

**Files modified:** `app/controllers/tournaments_controller.rb`
**Commit:** 47577ae
**Applied fix:** Extended the `includes` chain in `set_tournament` from `includes(pairs: [:player1, :player2])` to `includes(pairs: [{ player1: :user }, { player2: :user }])`. This eagerly loads the `:user` association on both `LeagueUser` records for each pair, eliminating 2N additional SELECT queries per page load. Rubocop autocorrect was also applied to fix `SpaceInsideArrayLiteralBrackets` offenses introduced by the change.

---

### WR-01: `_tables.scss` selector is over-broad — targets all `<thead>` in the page

**Files modified:** `app/assets/stylesheets/_tables.scss`
**Commit:** 2228158
**Applied fix:** Changed `thead > tr > th` to `.table thead > tr > th` to scope the dark header styling exclusively to Bootstrap `.table` components, preventing unintended styling of third-party or non-Bootstrap tables.

---

### WR-02: Active Storage `image_tag` passes attachment object directly — full original served

**Files modified:** `app/views/shared/_avatar.html.slim`, `Gemfile`, `Gemfile.lock`
**Commit:** e80f497
**Applied fix:** Uncommented `gem "image_processing", "~> 1.2"` in Gemfile and ran `bundle install` to install the gem. Updated the `image_tag` call to use `user.photo.variant(resize_to_fill: [size * 2, size * 2])` — serving a 2x retina-resolution variant capped to the display size instead of the full original upload.

---

### WR-03: `_variables.scss` sets `$input-bg` to a CSS custom property

**Files modified:** `app/assets/stylesheets/_variables.scss`
**Commit:** 51ff247
**Applied fix:** Replaced `$input-bg: var(--color-bg-surface)` with `$input-bg: #21262d` — the concrete hex value that matches the `--color-bg-surface` token. This prevents potential Sass compile errors if Bootstrap upgrades use `$input-bg` inside color functions. The `_theme.scss` `--bs-input-bg` override continues to apply at runtime for CSS-variable-driven components.

---

### WR-04: `devise/registrations/edit.html.slim` — "Delete account" card outside `.col-md-6`

**Files modified:** `app/views/devise/registrations/edit.html.slim`
**Commit:** 4185dec
**Applied fix:** Re-indented the delete account `.card.shadow-sm.mt-3` block by two spaces so it becomes a sibling of the edit form `.card.shadow-sm` inside `.col-md-6`, rather than a direct child of `.row`. Both cards now sit correctly within the Bootstrap column, respecting grid gutters and alignment.

---

_Fixed: 2026-05-09_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

---
phase: 03-shared-components
plan: 01
subsystem: ui
tags: [bootstrap, scss, css-custom-properties, dark-theme, cards, forms, tables]

# Dependency graph
requires:
  - phase: 01-css-foundation
    provides: "_variables.scss SCSS overrides and _theme.scss CSS custom properties that new partials reference"
  - phase: 02-layout-shell
    provides: "application.bootstrap.scss manifest that new @imports are added to"
provides:
  - "_cards.scss: .card and .card-header/.card-footer dark surface + border overrides"
  - "_forms.scss: color-scheme: dark on date/time/datetime-local inputs"
  - "_tables.scss: thead > tr > th dark header using design tokens"
  - "_avatar.scss: reserved placeholder partial for Phase 5"
  - "_variables.scss: $input-bg override propagating dark surface to all Bootstrap form controls"
  - "_theme.scss: --bs-box-shadow-sm/box-shadow suppression + --bs-tertiary-bg for file-selector-button"
affects:
  - 03-02-avatar-template-cleanup
  - 04-dashboard
  - 05-league-pages

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Direct CSS property override pattern: new partials imported after Bootstrap resolve cascade-ineffective CSS variable approach"
    - "SCSS variable pre-definition pattern: $input-bg declared before Bootstrap compilation propagates to all form-control variants"
    - "Shadow suppression via CSS variable: --bs-box-shadow-sm: none neutralises Bootstrap !important shadow utility without specificity fight"

key-files:
  created:
    - app/assets/stylesheets/_cards.scss
    - app/assets/stylesheets/_forms.scss
    - app/assets/stylesheets/_tables.scss
    - app/assets/stylesheets/_avatar.scss
  modified:
    - app/assets/stylesheets/_variables.scss
    - app/assets/stylesheets/_theme.scss
    - app/assets/stylesheets/application.bootstrap.scss

key-decisions:
  - "Direct background-color property overrides in _cards.scss win over Bootstrap's cascade-ineffective --bs-card-bg CSS variable because they have equal specificity but later source order"
  - "Place $input-bg in _variables.scss (before Bootstrap compilation), not _theme.scss — SCSS variables in post-Bootstrap files cannot retroactively change already-compiled output"
  - "color-scheme: dark on date/time inputs forces browser-native chrome into dark mode, complementing the $input-bg approach"

patterns-established:
  - "Post-Bootstrap override partials: create _component.scss, import after @import 'flash' in manifest — equal specificity + later order wins"
  - "SCSS pre-variable pattern: declare $varname before @import 'bootstrap/scss/variables' to affect Bootstrap compilation output"
  - "CSS variable shadow suppression: --bs-box-shadow-sm: none inside [data-bs-theme='dark'] neutralises !important shadow utilities cleanly"

requirements-completed: [COMP-01, COMP-03, COMP-04]

# Metrics
duration: 10min
completed: 2026-05-09
---

# Phase 3 Plan 01: SCSS Component Foundation Summary

**Four new SCSS partials (cards, forms, tables, avatar) plus targeted variable overrides fix Bootstrap's cascade-ineffective CSS variable problem — cards, form inputs, and table headers now render on the correct dark surface (`#21262d`) via direct property overrides that win by source order.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-09T17:50:00Z
- **Completed:** 2026-05-09T18:00:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `$input-bg: var(--color-bg-surface)` to `_variables.scss`, causing Bootstrap to compile dark surface backgrounds directly into `.form-control`, `.form-select`, `.textarea`, and all input-group variants
- Created `_cards.scss` with direct `background-color`/`border-color` overrides that bypass Bootstrap's cascade-ineffective `--bs-card-bg` local declaration problem
- Created `_forms.scss` applying `color-scheme: dark` to date/time/datetime-local inputs to force browser-native picker chrome into dark mode
- Created `_tables.scss` with `thead > tr > th` dark header block using all three design tokens (surface, muted-text, border)
- Added `--bs-box-shadow-sm: none` and `--bs-box-shadow: none` to the dark theme block, neutralising Bootstrap's shadow utilities cleanly without specificity conflicts
- Added `--bs-tertiary-bg: var(--color-bg-navbar)` for file-selector-button background
- Wired all four new partials in manifest after `@import 'flash'` in correct order; SCSS builds without errors

## Task Commits

1. **Task 1: Modify _variables.scss and _theme.scss** - `293c1f3` (feat)
2. **Task 2: Create four new SCSS partials and update the manifest** - `a54fd34` (feat)

## Files Created/Modified

- `app/assets/stylesheets/_variables.scss` - Added `$input-bg: var(--color-bg-surface)` after `$dark` (line 12)
- `app/assets/stylesheets/_theme.scss` - Added `--bs-tertiary-bg`, `--bs-box-shadow-sm: none`, `--bs-box-shadow: none` to dark theme block
- `app/assets/stylesheets/_cards.scss` - New: `.card` background/border overrides, transparent card-header/footer with border token
- `app/assets/stylesheets/_forms.scss` - New: `color-scheme: dark` on date/time/datetime-local inputs
- `app/assets/stylesheets/_tables.scss` - New: `thead > tr > th` dark header with surface bg, muted text, 1px border
- `app/assets/stylesheets/_avatar.scss` - New: reserved placeholder for Phase 5 hover additions
- `app/assets/stylesheets/application.bootstrap.scss` - Added `@import 'cards'`, `@import 'forms'`, `@import 'tables'`, `@import 'avatar'` after `@import 'flash'`

## Decisions Made

- Direct `background-color` property overrides in `_cards.scss` rather than CSS variable approach — Bootstrap 5.3 compiles CSS custom properties as LOCAL declarations on `.card` elements which win over inherited values; equal specificity + later source order is the correct fix.
- `$input-bg` belongs in `_variables.scss` (pre-Bootstrap) not `_theme.scss` — SCSS variables compiled post-Bootstrap cannot retroactively change already-emitted CSS output.
- `--bs-box-shadow-sm: none` approach for shadow suppression — Bootstrap's `.shadow-sm` utility is `box-shadow: var(--bs-box-shadow-sm) !important`; setting the variable to `none` makes the `!important` value evaluate to `none` without any specificity fight.

## Deviations from Plan

None — plan executed exactly as written. The `assets:precompile` command failed due to a pre-existing Node engine incompatibility (`minimatch@10.2.5` requires Node 18/20/22+, current is v21.7.3) unrelated to SCSS. Compilation was verified successfully using the Dart Sass CLI directly with the main repo's `node_modules` as load path, confirming all new rules appear correctly in compiled output.

## Issues Encountered

`bin/rails assets:precompile` failed with a yarn engine incompatibility error — `minimatch@10.2.5` requires Node 18, 20, or >=22 but the system has Node 21.7.3. This is a pre-existing environment issue unrelated to the SCSS changes. SCSS compilation was verified using `sass` CLI directly (same binary used by `build:css:compile` yarn script), which produced correct output with all new CSS rules present.

## Self-Check: PASSED

- `app/assets/stylesheets/_cards.scss` - FOUND
- `app/assets/stylesheets/_forms.scss` - FOUND
- `app/assets/stylesheets/_tables.scss` - FOUND
- `app/assets/stylesheets/_avatar.scss` - FOUND
- `.planning/phases/03-shared-components/03-01-SUMMARY.md` - FOUND
- Commit `293c1f3` - FOUND
- Commit `a54fd34` - FOUND

## Next Phase Readiness

- SCSS foundation for shared components is complete — Phase 3 Plan 02 (avatar partial + template cleanup: remove `thead.table-dark` from view templates, wire avatar partial) can proceed immediately
- The four new partials follow the established override pattern and can be extended without conflict
- `_avatar.scss` is a reserved placeholder; Phase 5 can add `.avatar-circle` hover/transition rules directly

---
*Phase: 03-shared-components*
*Completed: 2026-05-09*

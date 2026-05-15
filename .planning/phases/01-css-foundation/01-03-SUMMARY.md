---
phase: 01-css-foundation
plan: "03"
subsystem: ui
tags: [scss, bootstrap5, sass, css-custom-properties, design-tokens, build-pipeline]

# Dependency graph
requires:
  - phase: 01-css-foundation/01-01
    provides: Dart Sass deprecation suppression and Bootstrap dark mode HTML attribute
  - phase: 01-css-foundation/01-02
    provides: Four SCSS partials (_variables, _theme, _spacing, _typography) containing design tokens
provides:
  - Selective Bootstrap SCSS import manifest wiring all four design token partials in correct order
  - Compiled application.css containing --color-bg-base, --color-accent, --space-1 through --space-16 tokens
  - Clean yarn build:css (exits 0, no deprecation warnings)
affects: [phase-2, phase-3, phase-4, phase-5]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Selective Bootstrap import pattern: import only needed partials to reduce compiled output size (12 unused partials omitted)"
    - "SCSS entry-point as pure import manifest: no CSS rules, only @import statements and comments"
    - "--silence-deprecation expanded to include if-function and global-builtin for Bootstrap 5.3 / Dart Sass 1.99+ compat"

key-files:
  created: []
  modified:
    - app/assets/stylesheets/application.bootstrap.scss
    - package.json

key-decisions:
  - "Selective Bootstrap import (not monolithic @import 'bootstrap'): reduces compiled output by omitting 12 unused partials (accordion, carousel, breadcrumb, pagination, list-group, close, toasts, tooltip, popover, offcanvas, placeholders, images)"
  - "Expanded --silence-deprecation to include if-function and global-builtin: Bootstrap 5.3 triggers these from _functions.scss and _variables.scss in addition to the import and color-functions types already silenced"
  - "application.bootstrap.scss is a pure import manifest — enforced by plan design: all CSS rules live in partials, not in the entry point"

patterns-established:
  - "Import ordering pattern: bootstrap/scss/functions → project _variables → bootstrap/scss/variables → bootstrap component chain → project _theme/_spacing/_typography → icon font"
  - "Build cleanliness pattern: all known Bootstrap 5.3 / Dart Sass 1.99 deprecation types silenced via --silence-deprecation flags"

requirements-completed: [CSST-02]

# Metrics
duration: 15min
completed: 2026-05-09
---

# Phase 01 Plan 03: Bootstrap Entry Point Rewrite Summary

**Selective Bootstrap SCSS import manifest wiring all four design token partials in correct cascade order, producing clean compiled CSS with --color-bg-base: #0d1117 and --space-1: 0.25rem**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-09T22:00:00Z
- **Completed:** 2026-05-09T22:07:50Z
- **Tasks:** 2
- **Files modified:** 2 (application.bootstrap.scss, package.json)

## Accomplishments

- Rewrote `application.bootstrap.scss` from 2-line monolithic import into 47-line selective import manifest
- `@import 'variables'` positioned at line 10 (after functions, before bootstrap/scss/variables) — Bootstrap !default override wins
- `@import 'theme'`, `@import 'spacing'`, `@import 'typography'` positioned after all Bootstrap component partials — cascade override wins
- 12 unused Bootstrap partials omitted to reduce compiled output size
- `yarn build:css` exits 0 with no deprecation warnings — clean build confirmed
- Compiled `application.css` contains all project color tokens and spacing tokens

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite application.bootstrap.scss with full selective import manifest** - `60585df` (feat)
2. **Task 2: Fix deprecation warnings + verify compiled output contains tokens** - `0d50c6d` (fix)

**Plan metadata:** (follows in separate commit)

## Files Created/Modified

- `app/assets/stylesheets/application.bootstrap.scss` - Replaced 2-line monolithic import with 47-line selective partial manifest; pure @import manifest with no CSS rules
- `package.json` - Extended --silence-deprecation to include if-function and global-builtin types (deviation fix)

## Decisions Made

- Selective Bootstrap import chosen over monolithic: 12 unused partials omitted (accordion, carousel, breadcrumb, pagination, list-group, close, toasts, tooltip, popover, offcanvas, placeholders, images). Reduces compiled CSS size while keeping all used components.
- Expanded silence-deprecation flags: Bootstrap 5.3 generates `if-function` and `global-builtin` deprecation warnings from _functions.scss and _variables.scss under Dart Sass 1.99+. These were added to the existing `import,color-functions` silencing.
- Pure import manifest enforced: no CSS rules in application.bootstrap.scss — all rules live in partials, making entry point easy to audit and diff.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Extended --silence-deprecation to cover all Bootstrap 5.3 Dart Sass warnings**
- **Found during:** Task 2 (Run yarn build:css and verify compiled output)
- **Issue:** Plan specified that build should exit 0 without deprecation flood, but `--silence-deprecation=import,color-functions` did not cover `if-function` and `global-builtin` types emitted by Bootstrap's `_functions.scss` and `_variables.scss`. Build showed "227 repetitive deprecation warnings omitted."
- **Fix:** Added `if-function,global-builtin` to the --silence-deprecation flag in `package.json` build:css:compile script. Build now exits 0 with no warnings.
- **Files modified:** package.json
- **Verification:** `yarn build:css 2>&1 | grep -i "deprecat"` returns only the command line itself (no warning lines)
- **Committed in:** 0d50c6d (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in deprecation suppression coverage)
**Impact on plan:** Essential fix for the must_have truth "no deprecation warning flood". No scope creep.

## Issues Encountered

Worktree has no `node_modules` — build scripts must resolve bootstrap partials from the main project's `node_modules`. Created a symlink from worktree `node_modules` to main project `node_modules` to enable `yarn build:css` to run from the worktree directory. This is a worktree-local runtime setup; it does not affect the committed files or the build when run from the main project after merge.

## User Setup Required

None — no external service configuration required.

## Known Stubs

None — `application.bootstrap.scss` is a complete, fully-wired import manifest. All four partials are imported and the compiled CSS contains all project tokens.

## Threat Flags

None — all @import paths are static string literals in a developer-authored file committed to git. No dynamic path construction. Consistent with T-03-01 accepted disposition in the plan's threat model.

## Next Phase Readiness

Phase 1 CSS Foundation is complete. All four ROADMAP success criteria are TRUE:
1. `--color-*` CSS custom properties resolve in the browser (--color-bg-base: #0d1117 in compiled CSS)
2. Bootstrap SCSS compiles dark with $variable overrides (yarn build:css exits 0, data-bs-theme="dark" on html element)
3. Body text, headings, links use Inter at correct weights ($font-family-sans-serif in _variables.scss, Inter link in layout)
4. `--space-*` tokens defined and available (--space-1: 0.25rem through --space-16 in compiled CSS)

Phase 2 can proceed with confidence that the CSS token layer is fully operational.

## Self-Check: PASSED

Files exist:
- app/assets/stylesheets/application.bootstrap.scss: FOUND — contains @import 'variables' (line 10) and @import 'theme'/'spacing'/'typography' (lines 42-44)
- package.json: FOUND — contains --silence-deprecation=import,color-functions,if-function,global-builtin
- .planning/phases/01-css-foundation/01-03-SUMMARY.md: FOUND

Commits exist:
- 60585df: FOUND (feat(01-03): rewrite application.bootstrap.scss as selective import manifest)
- 0d50c6d: FOUND (fix(01-03): silence if-function and global-builtin Dart Sass deprecation warnings)

Compiled CSS verified:
- --color-bg-base: FOUND (2 occurrences in application.css)
- --space-1:: FOUND (1 occurrence in application.css)

---
*Phase: 01-css-foundation*
*Completed: 2026-05-09*

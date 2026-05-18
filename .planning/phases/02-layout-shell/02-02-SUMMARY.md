---
phase: 02-layout-shell
plan: "02"
subsystem: ui
tags: [bootstrap, stimulus, flash, slim, scss, turbo]

requires:
  - phase: 02-01
    provides: "_navbar.html.slim, navbar_controller.js, _navbar.scss — navbar partial and Stimulus controller"
  - phase: 01-03
    provides: "Phase 1 CSS tokens (_theme.scss, _spacing.scss, _typography.scss)"
provides:
  - "_flash.html.slim — flash partial with auto-dismiss Stimulus wiring, data-turbo-temporary"
  - "flash_controller.js — Stimulus controller for flash auto-dismiss (5s) and manual close"
  - "_flash.scss — flush banner-style alert overrides"
  - "application.html.slim — wired layout: navbar + flash + main.py-4 wrapper"
  - "application.bootstrap.scss — updated manifest with @import navbar and @import flash"
affects:
  - "03-dashboard (dashboard view now sits inside full layout shell)"
  - "All page views — flash now rendered once in layout, not per-view"

tech-stack:
  added: []
  patterns:
    - "Flash rendered once in layout partial (_flash.html.slim), not per-view — prevents double rendering with Turbo"
    - "data-turbo-temporary on flash alerts — prevents Turbo Drive snapshot caching of flash DOM"
    - "Stimulus flash_controller with clearTimeout on disconnect — safe timer cleanup on Turbo navigation"
    - "Bootstrap .fade/.show transition with transitionend { once: true } — clean DOM removal without listener leaks"
    - "Flash type mapping via Ruby hash in partial (not conditional if/elsif chain)"

key-files:
  created:
    - app/views/layouts/_flash.html.slim
    - app/javascript/controllers/flash_controller.js
    - app/assets/stylesheets/_flash.scss
  modified:
    - app/views/layouts/application.html.slim
    - app/assets/stylesheets/application.bootstrap.scss
    - app/views/dashboard/index.html.slim
    - app/views/leagues/index.html.slim
    - app/views/users/index.html.slim
  deleted:
    - app/javascript/controllers/hello_controller.js

key-decisions:
  - "Use flash.each with type_map hash instead of per-key conditionals — handles arbitrary flash types, more extensible"
  - "data-turbo-temporary on flash div — prevents Turbo Drive caching flash element in DOM snapshot (reappear on back-nav)"
  - "main.py-4 without .container on <main> — individual views control horizontal constraint internally via .container.py-4"
  - "hello_controller.js deleted — unused scaffold placeholder, no page uses data-controller=hello"

patterns-established:
  - "Pattern: Layout renders flash once; page views must NOT contain inline flash blocks"
  - "Pattern: Stimulus timer cleared in disconnect() to prevent callbacks on removed elements"
  - "Pattern: transitionend with { once: true } to prevent memory leaks on repeated close actions"

requirements-completed: [LAY-02, LAY-03]

duration: 3min
completed: 2026-05-09
---

# Phase 2 Plan 02: Layout Shell Wiring — Flash, Manifest, and Integration Summary

**Full layout shell activated: flash partial with Stimulus auto-dismiss wired into application.html.slim alongside Plan 01 navbar, SCSS manifest updated, inline flash blocks removed from three page views.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-09T04:56:50Z
- **Completed:** 2026-05-09T04:59:43Z
- **Tasks:** 2
- **Files modified:** 9 (3 created, 5 modified, 1 deleted)

## Accomplishments

- Flash partial renders full-width banner alerts below navbar with Bootstrap .fade/.show transition, 5-second auto-dismiss via Stimulus, manual close button, and data-turbo-temporary guard
- application.html.slim body replaced: old flat inline nav removed, now renders navbar + flash partials and wraps yield in main.py-4
- application.bootstrap.scss manifest updated with @import 'navbar' and @import 'flash' before icon font (yarn build:css exits 0)
- Inline flash conditionals removed from dashboard/index, leagues/index, and users/index — flash now rendered exactly once per request from layout
- hello_controller.js (unused scaffold placeholder) deleted

## Task Commits

1. **Task 1: Create flash partial, flash_controller.js, and _flash.scss** — `cdaf36a` (feat)
2. **Task 2: Wire layout, update manifest, remove inline flash, delete hello_controller** — `fff8217` (feat)

## Files Created/Modified

- `app/views/layouts/_flash.html.slim` — Flash banner partial; iterates flash hash with type_map, = message (XSS-safe), data-turbo-temporary, Stimulus controller wiring
- `app/javascript/controllers/flash_controller.js` — Stimulus controller: static values delay, connect sets setTimeout, disconnect clears timer, close removes .show and handles transitionend
- `app/assets/stylesheets/_flash.scss` — Minimal overrides: border-radius 0, no side borders, margin-bottom 0 for flush banner style
- `app/views/layouts/application.html.slim` — Body block replaced: renders navbar + flash partials, main.py-4 wrapping yield
- `app/assets/stylesheets/application.bootstrap.scss` — Added @import 'navbar' and @import 'flash' after typography
- `app/views/dashboard/index.html.slim` — Removed 4 lines of inline flash conditionals (lines 4-7)
- `app/views/leagues/index.html.slim` — Removed 2 lines of inline flash conditionals (lines 6-7)
- `app/views/users/index.html.slim` — Removed 2 lines of inline flash conditionals (lines 4-5)
- `app/javascript/controllers/hello_controller.js` — Deleted (unused scaffold placeholder)

## Decisions Made

- Flash partial uses `flash.each` with a type_map hash (not per-key if/elsif) — handles arbitrary flash types and is more extensible
- `data-turbo-temporary` on each alert div — prevents Turbo Drive from including flash DOM in page snapshot (would cause flash to reappear on browser back)
- `main.py-4` without `.container` on `<main>` — individual page views all start with `.container.py-4` internally; adding container on main would double-nest containers
- `hello_controller.js` deleted — no page uses `data-controller="hello"`, scaffold placeholder not needed

## Deviations from Plan

None — plan executed exactly as written.

## Threat Coverage

All mitigations from the plan's threat model are implemented:

| Threat ID | Mitigation | Status |
|-----------|-----------|--------|
| T-02-07 | `= message` (Slim auto-escape) used throughout — `== message` (raw) never used | Implemented |
| T-02-08 | `data-turbo-temporary="true"` on each alert div — prevents Turbo snapshot caching | Implemented |
| T-02-09 | `disconnect()` calls `clearTimeout(this.timer)` + `{ once: true }` on transitionend | Implemented |
| T-02-10 | Flash is session-scoped — no cross-user disclosure possible | Accepted |
| T-02-11 | Navbar partial has `user_signed_in?` guards internally | Accepted |
| T-02-12 | @import paths are static literals authored by developer, no dynamic paths | Accepted |

## Issues Encountered

None.

## Known Stubs

None — all files have real implementations. No placeholder data or TODO markers.

## Threat Flags

None — no new threat surfaces introduced beyond those documented in the plan's threat model.

## Next Phase Readiness

- Full layout shell complete: dark navbar, flash messages, main content wrapper active on every page
- All four LAY requirements (LAY-01 through LAY-04) are live
- Phase 3 (Dashboard redesign) can begin — dashboard view renders inside the wired layout shell

---
*Phase: 02-layout-shell*
*Completed: 2026-05-09*

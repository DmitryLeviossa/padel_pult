---
phase: "02"
plan: "01"
subsystem: layout-shell
tags: [navbar, stimulus, bootstrap, scss, responsive]
dependency_graph:
  requires:
    - "01-03 (Phase 1 CSS tokens — _theme.scss, _spacing.scss)"
  provides:
    - "_navbar.html.slim — responsive Bootstrap navbar partial"
    - "navbar_controller.js — Stimulus controller wrapping Bootstrap Collapse API"
    - "_navbar.scss — navbar surface overrides using Phase 1 design tokens"
  affects:
    - "02-02 (Plan 02 wires these files into application.html.slim and application.bootstrap.scss)"
tech_stack:
  added: []
  patterns:
    - "Stimulus controller delegating to Bootstrap Collapse API (not reimplementing toggle)"
    - "Section-level active nav detection via request.path.start_with? (not current_page?)"
    - "Initials avatar rendered server-side from current_user.full_name"
    - "CSRF-safe logout via button_to with method: :delete (not link_to)"
    - "CSS custom property consumption from Phase 1 tokens (_theme.scss, _spacing.scss)"
key_files:
  created:
    - app/views/layouts/_navbar.html.slim
    - app/javascript/controllers/navbar_controller.js
    - app/assets/stylesheets/_navbar.scss
  modified: []
decisions:
  - "Use Stimulus controller wrapping Bootstrap Collapse API (not data-bs-toggle direct) — satisfies LAY-04; Stimulus owns trigger, Bootstrap owns animation state"
  - "Inline style for background-color on nav element — files not yet wired into manifest; SCSS override takes precedence once Plan 02 imports _navbar.scss"
  - "No .navbar-dark or .bg-dark classes — use var(--color-bg-navbar) directly to avoid mapping to $dark (#21262d card surface) instead of #161b22 navbar surface"
metrics:
  duration: "2 minutes"
  completed: "2026-05-09"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 0
---

# Phase 2 Plan 01: Navbar Partial, Controller, and SCSS Summary

Dark responsive navbar partial built with Bootstrap Collapse API delegated via Stimulus controller and Phase 1 CSS tokens — not yet wired into layout (Plan 02 does that).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create _navbar.html.slim partial | 508c6b3 | app/views/layouts/_navbar.html.slim |
| 2 | Create navbar_controller.js and _navbar.scss | b302711 | app/javascript/controllers/navbar_controller.js, app/assets/stylesheets/_navbar.scss |

## What Was Built

Three new files that implement LAY-01 and LAY-04, deliberately isolated from layout integration (handled by Plan 02):

**`_navbar.html.slim`** — Full Bootstrap `navbar-expand-lg` partial with:
- `data-controller="navbar"` on nav, `data-action="navbar#toggle"` on toggler (NO `data-bs-toggle="collapse"` — prevents double-fire)
- `data-navbar-target="menu"` on `#navbarCollapse` collapse div
- Section-level active states: `request.path.start_with?('/leagues')` pattern
- Initials avatar: `current_user.full_name.split.map(&:first).first(2).join.upcase`, 32x32px circle with `var(--color-bg-surface)` background
- Dropdown with "Редактировать аккаунт" link and `button_to "Выйти"` with `method: :delete` (CSRF-safe)
- Signed-out state: "Войти" nav-link and "Регистрация" primary button
- `var(--color-bg-navbar)` inline style — no `bg-dark` or `navbar-dark` classes

**`navbar_controller.js`** — Stimulus controller:
- Imports `{ Collapse }` from `"bootstrap"` (named import from importmap pin)
- `static targets = ["menu"]`
- `toggle()` calls `Collapse.getOrCreateInstance(this.menuTarget).toggle()`
- No `classList.toggle("show")` reimplementation

**`_navbar.scss`** — SCSS partial using Phase 1 tokens:
- `.navbar { background-color: var(--color-bg-navbar) !important; }`
- `.nav-link.active { color: var(--color-accent); font-weight: 600; }`
- `.navbar-toggler` focus ring: `rgba(47, 129, 247, 0.25)` (accent at 25% opacity)
- Hover backgrounds: `rgba(255, 255, 255, 0.05)` subtle ghost fill
- Transitions: `color 0.15s ease-in-out, background-color 0.15s ease-in-out`

## Deviations from Plan

None — plan executed exactly as written.

## Threat Coverage

All mitigations from the plan's threat model are implemented:

| Threat ID | Mitigation | Status |
|-----------|-----------|--------|
| T-02-02 | `button_to` with `method: :delete` generates CSRF-protected form | Implemented |
| T-02-06 | No `data-bs-toggle="collapse"` on hamburger — Stimulus only via `data-action="navbar#toggle"` | Implemented |

XSS (T-02-03): Slim `=` operator used throughout — auto-escapes `current_user.full_name` and all output. No `==` raw operator.

## Integration Note

These files are NOT yet wired into the application layout or SCSS manifest. Integration happens in Plan 02-02 (Wave 2):
- `application.html.slim` will render `"layouts/navbar"` and replace the inline flat navbar
- `application.bootstrap.scss` will add `@import 'navbar'`

## Self-Check: PASSED

- [x] `app/views/layouts/_navbar.html.slim` exists
- [x] `app/javascript/controllers/navbar_controller.js` exists
- [x] `app/assets/stylesheets/_navbar.scss` exists
- [x] Commit 508c6b3 exists (Task 1)
- [x] Commit b302711 exists (Task 2)
- [x] All automated verification checks passed
- [x] No stubs found
- [x] No new threat surfaces introduced

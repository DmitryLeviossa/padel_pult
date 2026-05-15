---
phase: 03-shared-components
plan: 02
subsystem: ui
tags: [slim, rails, bootstrap, dark-theme, avatar, partial, css-variables]

# Dependency graph
requires:
  - phase: 03-shared-components/03-01
    provides: _tables.scss overriding --bs-table-* variables and thead th design tokens (the reason thead.table-dark is safe to remove)
provides:
  - app/views/shared/_avatar.html.slim — reusable avatar partial with photo/initials fallback using dark surface tokens
  - All 5 inline bg-secondary avatar circles replaced with a single shared partial call
  - thead.table-dark removed from users/index and tournaments/index templates
affects: [04-content-pages, 05-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Avatar partial pattern: render 'shared/avatar', user: <User>, size: <int> — centralises photo/initials logic"
    - "size ||= 40 for Slim local-variable defaults (not local_assigns.fetch)"
    - "font_size = (size * 0.3).round(2) for proportional circle font-size in rem"
    - "Initials: user.full_name.split.map(&:first).first(2).join.upcase — replicates navbar pattern exactly"
    - "Pass league_user.user not league_user — LeagueUser delegates full_name but not .photo"

key-files:
  created:
    - app/views/shared/_avatar.html.slim
  modified:
    - app/views/leagues/show.html.slim
    - app/views/users/index.html.slim
    - app/views/tournaments/index.html.slim
    - app/views/tournaments/show.html.slim
    - app/views/devise/registrations/edit.html.slim

key-decisions:
  - "Use CSS design tokens (--color-bg-surface, --color-border, --color-text-muted) on initials circle instead of bg-secondary — bg-secondary maps to gray-800 (#343a40) not the design token #21262d"
  - "user.photo.attached? is sufficient — no need for && resource.photo.blob.persisted? which is redundant with Active Storage"
  - "No .mb-2 on avatar partial div — callers add spacing via wrapping elements to keep partial layout-agnostic"
  - "Slim = operator on initials auto-escapes HTML — XSS safe without sanitize helper"

patterns-established:
  - "Shared partial for avatar: all callers use render 'shared/avatar', user: <User object>"
  - "League context: always pass league_user.user not league_user"

requirements-completed: [COMP-02, COMP-04]

# Metrics
duration: 7min
completed: 2026-05-09
---

# Phase 3 Plan 02: Avatar Partial and Template Cleanup Summary

**Shared _avatar.html.slim partial with dark surface tokens replaces 5 inline bg-secondary avatar circles across leagues, users, tournaments, and devise templates; thead.table-dark removed from 2 table templates**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-09T14:45:00Z
- **Completed:** 2026-05-09T14:52:37Z
- **Tasks:** 2
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments
- Created `app/views/shared/_avatar.html.slim` with photo branch and initials fallback using `--color-bg-surface` / `--color-border` / `--color-text-muted` design tokens
- Replaced all 5 inline `bg-secondary` avatar circles across leagues/show (1), users/index (1), tournaments/show (2), and devise/registrations/edit (1) with `render "shared/avatar"` calls
- Removed `thead.table-dark` from users/index.html.slim and tournaments/index.html.slim — Bootstrap's hardcoded gray-900 (#212529) no longer overrides the design-token table styles from Plan 01

## Task Commits

Each task was committed atomically:

1. **Task 1: Create _avatar.html.slim partial** - `7c3a9ce` (feat)
2. **Task 2: Replace inline avatar blocks and remove thead.table-dark** - `f527c41` (feat)

**Plan metadata:** (committed with SUMMARY.md)

## Files Created/Modified
- `app/views/shared/_avatar.html.slim` - Reusable avatar partial: photo branch (Active Storage image_tag) or initials circle with dark design tokens; accepts `user` + optional `size` (default 40)
- `app/views/leagues/show.html.slim` - Inline 5-line avatar block replaced with `render "shared/avatar", user: league_user.user`
- `app/views/users/index.html.slim` - Inline avatar block replaced; `thead.table-dark` removed
- `app/views/tournaments/index.html.slim` - `thead.table-dark` removed
- `app/views/tournaments/show.html.slim` - Two inline avatar blocks replaced for player1 and player2
- `app/views/devise/registrations/edit.html.slim` - Inline avatar block replaced with `render "shared/avatar", user: resource, size: 100`

## Decisions Made
- Used `--color-bg-surface` (#21262d) for initials circle background — `bg-secondary` was mapping to Bootstrap's gray-800 (#343a40) which doesn't match the design token
- Dropped `&& resource.photo.blob.persisted?` from devise template — `attached?` is sufficient per Active Storage semantics
- Avatar partial is layout-agnostic (no `.mb-2`) — callers add spacing via wrapping elements

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Avatar partial available for all future page templates in Phase 4 (content pages) — import pattern established
- Both COMP-02 (avatar partial) and COMP-04 (table dark styles cleanup) satisfied
- Phase 3 Plan 01 (SCSS) + Plan 02 (templates) together complete the shared component foundation
- Phase 4 content pages can use `render "shared/avatar"` and rely on design-token table styles without any Bootstrap hardcoded overrides remaining

## Self-Check: PASSED

- FOUND: app/views/shared/_avatar.html.slim
- FOUND: commit 7c3a9ce (Task 1 — avatar partial)
- FOUND: commit f527c41 (Task 2 — template replacements)
- No stubs found in modified files
- bg-secondary count in 5 templates: 0 (PASS)
- thead.table-dark count across all views: 0 (PASS)
- Total render "shared/avatar" calls: 5 (PASS — leagues:1, users:1, tournaments:2, devise:1)

---
*Phase: 03-shared-components*
*Completed: 2026-05-09*

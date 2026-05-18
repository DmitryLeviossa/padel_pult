---
phase: 05-polish-pass
plan: 02
subsystem: stylesheets
tags: [scss, card, hover, lift, transition, table, typography, POLL-02, POLL-03]
dependency_graph:
  requires: []
  provides: [POLL-02 card transition + .card-hoverable utility, POLL-03 uppercase table headers]
  affects: [app/assets/stylesheets/_cards.scss, app/assets/stylesheets/_tables.scss]
tech_stack:
  added: []
  patterns: [SCSS CSS custom property cascade, transform-based hover lift, letter-spacing typography]
key_files:
  created: []
  modified:
    - app/assets/stylesheets/_cards.scss
    - app/assets/stylesheets/_tables.scss
decisions:
  - .card-hoverable selector (not a > .card) — user decision lock; stretched-link templates have .card as parent of <a>, reverse of a > .card
  - transition on base .card (not inside :hover) — enables smooth leave animation (mouseout fade)
  - transform: translateY(-1px) (not top/left) — zero layout shift on neighboring elements
  - var(--color-accent-hover) for brightened border — no hard-coded hex, per UI-SPEC
  - letter-spacing: 0.05em (not rem or px) — scales correctly with font-size
metrics:
  duration: ~5 min
  completed: 2026-05-10
---

# Phase 5 Plan 02: Card Lift + Table Header Typography (POLL-02 CSS / POLL-03) Summary

## One-liner

CSS transition + `.card-hoverable:hover` lift rule in `_cards.scss` (POLL-02 CSS half) and `text-transform: uppercase; letter-spacing: 0.05em` added to `.table thead > tr > th` in `_tables.scss` (POLL-03).

## What Was Built

**POLL-02 CSS (`_cards.scss`):** Added `transition: $transition-base` to the base `.card { }` block so hover enter and leave both animate. Added a new `.card-hoverable:hover` rule that lifts the card `transform: translateY(-1px)` and brightens the border to `var(--color-accent-hover)`. Uses transform (not `top`/`left`) for zero layout shift. The `.card-hoverable` utility class approach was chosen over `a > .card` per user decision lock — stretched-link templates have `.card` as the parent of `<a>`, making `a > .card` reversed/ineffective.

Visual verification of POLL-02 is deferred to Plan 05-03 where the `.card-hoverable` class is applied to league/dashboard card templates.

**POLL-03 (`_tables.scss`):** Added two property declarations to the existing `.table thead > tr > th` rule — `text-transform: uppercase;` and `letter-spacing: 0.05em;`. All five existing declarations (`background-color`, `color`, `font-weight`, `border-bottom`, `white-space`) preserved verbatim. No `font-size` added (inherits 15px body per UI-SPEC). Visible immediately on all pages using `.table` (leagues show, tournaments show, users index).

SCSS build confirmed clean — `sass` direct compilation with Bootstrap node_modules load-path completes with exit 0, no errors.

## Files Created

None.

## Files Modified

- `app/assets/stylesheets/_cards.scss` — +10 lines: updated comment block, added `transition: $transition-base` to base `.card`, added `.card-hoverable:hover` block with transform + border-color
- `app/assets/stylesheets/_tables.scss` — +3 lines: updated comment block, added `text-transform: uppercase;` and `letter-spacing: 0.05em;` to existing th rule

## Commits

| Task | Commit  | Description |
|------|---------|-------------|
| 1    | 404dbb0 | feat(05-02): add transition and .card-hoverable hover lift to _cards.scss (POLL-02 CSS) |
| 2    | bea62fa | feat(05-02): add uppercase + letter-spacing to table headers in _tables.scss (POLL-03) |
| 3    | (none)  | Verification-only task — SCSS build clean, no files committed |

## Deviations from Plan

None — plan executed exactly as written.

`bin/rails dartsass:build` did not exist in this Rails environment; used direct `sass` binary with `--load-path` pointing to main repo's `node_modules` per Task 3 fallback instructions. Build succeeded with exit 0, no SCSS errors.

## Success Criteria Verification

- POLL-02 CSS: `.card` has `transition: $transition-base` (enter + leave animation) — SATISFIED
- POLL-02 CSS: `.card-hoverable:hover` exists with `transform: translateY(-1px)` and `var(--color-accent-hover)` border — SATISFIED
- No layout-shifting properties (`top`, `margin-top`, `padding`) on hover — SATISFIED (grep confirms absent)
- User decision honored: `.card-hoverable` selector used (not `a > .card` or `.card-link > .card`) — SATISFIED
- POLL-03: All `.table thead > tr > th` headers now have `text-transform: uppercase; letter-spacing: 0.05em` — SATISFIED
- POLL-03: All 5 existing declarations preserved, no `font-size` added — SATISFIED
- SCSS build is clean — SATISFIED (exit 0, no errors)

## Known Stubs

`.card-hoverable` class is ready in CSS but not yet applied to any template. Cards do not lift on hover until Plan 05-03 adds the class to league/dashboard card templates. This is intentional — POLL-02 is split across two plans by design.

## Threat Flags

None. This plan adds only CSS rules with no network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

- `app/assets/stylesheets/_cards.scss` — FOUND (modified)
- `app/assets/stylesheets/_tables.scss` — FOUND (modified)
- Commit `404dbb0` — FOUND (`feat(05-02): add transition and .card-hoverable hover lift`)
- Commit `bea62fa` — FOUND (`feat(05-02): add uppercase + letter-spacing to table headers`)
- `transition: $transition-base` in `.card {}` block — VERIFIED (grep -c returns 1)
- `.card-hoverable:hover` selector — VERIFIED
- `transform: translateY(-1px)` — VERIFIED
- `border-color: var(--color-accent-hover)` — VERIFIED
- No `a > .card` selector — VERIFIED
- `text-transform: uppercase;` in _tables.scss — VERIFIED
- `letter-spacing: 0.05em;` in _tables.scss — VERIFIED
- No `font-size:` in _tables.scss (non-comment lines) — VERIFIED
- SCSS build exit 0, no errors — VERIFIED

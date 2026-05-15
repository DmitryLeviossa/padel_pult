---
phase: 05-polish-pass
plan: 03
subsystem: views
tags: [slim, card, hover, card-hoverable, POLL-02, template]
dependency_graph:
  requires: [05-02 .card-hoverable:hover CSS rule]
  provides: [POLL-02 hover lift on leagues/index and dashboard recent leagues]
  affects: [app/views/leagues/index.html.slim, app/views/dashboard/index.html.slim]
tech_stack:
  added: []
  patterns: [Slim class shorthand, CSS utility class application, stretched-link pattern]
key_files:
  created: []
  modified:
    - app/views/leagues/index.html.slim
    - app/views/dashboard/index.html.slim
decisions:
  - .card-hoverable applied ONLY to stretched-link cards (user decision lock)
  - Stat cards (lines 7, 13 in dashboard) NOT given .card-hoverable — display-only, not navigable
  - Wrapper cards "Мои лиги"/"Мои турниры" NOT given .card-hoverable — no stretched-link child
metrics:
  duration: ~5 min
  completed: 2026-05-15
---

# Phase 5 Plan 03: Apply .card-hoverable to Templates (POLL-02 Template Half) Summary

## One-liner

Added `.card-hoverable` to stretched-link cards on `/leagues` and dashboard "Последние лиги" — completes POLL-02 hover lift end-to-end; human-verified in browser.

## What Was Built

Applied the `.card-hoverable` CSS utility class (defined in Plan 05-02) to the two template locations that contain `stretched-link` children and should be interactive:

1. `app/views/leagues/index.html.slim` line 10: `.card.h-100` → `.card.card-hoverable.h-100`
2. `app/views/dashboard/index.html.slim` line 58: `.card.h-100` → `.card.card-hoverable.h-100` (inside `@recent_leagues.each`, under "Последние лиги" heading)

Per user decision (CONTEXT lock): `.card-hoverable` was applied ONLY to cards with a `stretched-link` child. Stat cards (icon + count, lines 7/13) and wrapper list cards ("Мои лиги"/"Мои турниры", lines 22/38) were intentionally left unchanged.

Human verification confirmed all three POLL requirements are working end-to-end in the browser.

## Files Modified

- `app/views/leagues/index.html.slim` — 1 line changed (`.card.h-100` → `.card.card-hoverable.h-100`)
- `app/views/dashboard/index.html.slim` — 1 line changed (`.card.h-100` → `.card.card-hoverable.h-100` on recent leagues card only)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1    | 5ac16bc | feat(05-03): add .card-hoverable to leagues index card grid (POLL-02) |
| 2    | b93e4d2 | feat(05-03): add .card-hoverable to dashboard recent leagues card (POLL-02) |
| 3    | —       | Human checkpoint — user approved after browser verification |

## Deviations from Plan

None. Plan executed exactly as written. Line numbers in plan (10 for leagues/index, 58 for dashboard) matched actual file state.

## Human Verification Results

User confirmed in browser:
- POLL-02: Hovering a card on /leagues → 1px upward lift + border brightens to #4d94f8, animates ~150ms; smooth reverse on mouseout ✓
- POLL-02: Dashboard "Последние лиги" cards → same lift + border-brighten ✓
- Stat cards and wrapper cards do NOT lift ✓
- POLL-03 cross-check: table headers uppercase with letter-spacing ✓
- POLL-01 cross-check: .btn-primary hover glow ✓

## Success Criteria Verification

- POLL-02 fully satisfied: "Hovering a clickable card animates a `translateY(-1px)` lift and brightens the border within 150ms, then reverses on mouse-out" — SATISFIED (human verified)
- Selective application honored: only stretched-link cards get `.card-hoverable` — SATISFIED
- All three Phase 5 POLL requirements are end-to-end visible to the user — SATISFIED

## Known Stubs

None.

## Threat Flags

None. Template-only change, no server-side logic or auth paths affected.

## Self-Check: PASSED

- `app/views/leagues/index.html.slim` contains `.card.card-hoverable.h-100` exactly once — VERIFIED
- `app/views/dashboard/index.html.slim` contains `.card.card-hoverable.h-100` exactly once — VERIFIED
- Dashboard still contains exactly 2 bare `.card.h-100` lines (wrapper cards) — VERIFIED
- Dashboard still contains exactly 2 bare `.card` lines (stat cards) — VERIFIED
- Human checkpoint approved — VERIFIED

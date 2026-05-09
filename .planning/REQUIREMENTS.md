# Requirements: Padel Pult — Dark UI Redesign

**Defined:** 2026-05-09
**Core Value:** Every screen feels premium and cohesive — a dark, modern sports management app users actually enjoy using.

## v1 Requirements

### CSS Foundation

- [x] **CSST-01**: Color token system implemented as CSS custom properties (`--color-*`) layered above Bootstrap's `--bs-*` variables — dark navy/slate palette + electric blue accent
- [x] **CSST-02**: Bootstrap SCSS entry point (`application.bootstrap.scss`) rewritten with selective partial imports and `$variable` overrides injected before `@import` to enable full color propagation
- [x] **CSST-03**: Typography system defined — font stack (Inter or system), heading weights/sizes, body text sizing for dark legibility
- [x] **CSST-04**: Spacing/layout tokens defined as CSS custom properties — consistent scale used across all components

### Layout

- [x] **LAY-01**: Application navbar redesigned — dark navy surface, brand, nav links with active states, user avatar/menu, fully responsive
- [x] **LAY-02**: Flash messages moved to `application.html.slim` and restyled for dark theme — dark-aware alert colors, auto-dismiss via Stimulus
- [x] **LAY-03**: Page body and background layers correct — dark base background, surface color distinct from navbar
- [x] **LAY-04**: Mobile hamburger menu implemented with Stimulus controller — responsive collapse on small screens

### Shared Components

- [ ] **COMP-01**: Card component dark-styled — elevated surface with `#21262d` background, 1px border-based depth (no invisible box-shadows), used consistently across all pages
- [ ] **COMP-02**: Avatar partial extracted as `_avatar.html.slim` — initials fallback uses dark-correct surface color (replaces broken `bg-secondary` in 4+ templates)
- [ ] **COMP-03**: Form controls dark-styled — `form-control`, `form-select`, `textarea`, file upload `::file-selector-button` all use dark surfaces with accent focus ring
- [ ] **COMP-04**: Tables dark-styled — Bootstrap `--bs-table-*` CSS variables overridden, `thead.table-dark` replaced, border and hover row colors correct

### Content Pages

- [ ] **PAGE-01**: Dashboard redesigned — stat cards with icons, user's leagues/tournaments in card grid, recent activity, dark empty states
- [ ] **PAGE-02**: All 7 auth pages redesigned — login, register, password reset (new/edit), account edit, email confirmation, unlock — centered card layout on dark background
- [ ] **PAGE-03**: League pages redesigned — index (card grid), show (tabs, members, tournaments), new (form), edit (form) — all 4 templates
- [ ] **PAGE-04**: Tournament pages redesigned — index (list/cards), show (pairs/leaderboard), new (form) — all 3 templates
- [ ] **PAGE-05**: Users index redesigned — dark table with avatar column, name, email, consistent with component library

### Polish

- [ ] **POLL-01**: Button hover glow — primary/accent buttons show subtle electric blue `box-shadow` on hover (`0 0 12px rgba(47,129,247,0.3)`)
- [ ] **POLL-02**: Card hover lift — clickable cards animate `translateY(-1px)` + border brightens on hover (150ms transition)
- [ ] **POLL-03**: Table header styling — `<th>` elements rendered uppercase with `letter-spacing: 0.05em` for premium table feel

## v2 Requirements

### Future Enhancements

- **ENH-01**: Skeleton loading states for async content
- **ENH-02**: Dark/light mode toggle (currently dark-only by design)
- **ENH-03**: Animated stat counters on dashboard
- **ENH-04**: Advanced mobile bottom navigation bar

## Out of Scope

| Feature | Reason |
|---------|--------|
| New features / data model changes | Pure UI pass — no backend changes |
| Dark/light mode toggle | Dark only for v1 — explicit decision |
| Custom font licensing | Use Inter (free) or system font stack |
| Bootstrap upgrade to v6 | Avoid during active redesign |
| New JavaScript frameworks | Stimulus is sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CSST-01 | Phase 1 | Complete (01-02) |
| CSST-02 | Phase 1 | Complete (01-03) |
| CSST-03 | Phase 1 | Complete (01-02) |
| CSST-04 | Phase 1 | Complete (01-02) |
| LAY-01 | Phase 2 | Complete (02-01) |
| LAY-02 | Phase 2 | Complete (02-02) |
| LAY-03 | Phase 2 | Complete (02-02) |
| LAY-04 | Phase 2 | Complete (02-01) |
| COMP-01 | Phase 3 | Pending |
| COMP-02 | Phase 3 | Pending |
| COMP-03 | Phase 3 | Pending |
| COMP-04 | Phase 3 | Pending |
| PAGE-01 | Phase 4 | Pending |
| PAGE-02 | Phase 4 | Pending |
| PAGE-03 | Phase 4 | Pending |
| PAGE-04 | Phase 4 | Pending |
| PAGE-05 | Phase 4 | Pending |
| POLL-01 | Phase 5 | Pending |
| POLL-02 | Phase 5 | Pending |
| POLL-03 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20 (roadmap complete)
- Unmapped: 0

---
*Requirements defined: 2026-05-09*
*Last updated: 2026-05-09 after roadmap creation*

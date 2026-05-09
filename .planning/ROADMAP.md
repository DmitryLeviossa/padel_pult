# Roadmap: Padel Pult — Dark UI Redesign

## Overview

Five phases transform Padel Pult from a default Bootstrap light app into a polished dark navy/slate sports management interface. Phase 1 builds the CSS foundation that every subsequent phase depends on. Phases 2 and 3 apply that foundation to the structural shell and shared components. Phase 4 redesigns all content pages. Phase 5 adds micro-interactions that elevate the overall feel to premium.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: CSS Foundation** - Color tokens, typography, spacing system, Bootstrap SCSS overrides *(Complete 2026-05-09)*
- [x] **Phase 2: Layout Shell** - Navbar, flash messages, backgrounds, mobile hamburger menu *(Complete 2026-05-09)*
- [ ] **Phase 3: Shared Components** - Cards, avatar partial, form controls, tables
- [ ] **Phase 4: Content Pages** - Dashboard, auth, leagues, tournaments, users index
- [ ] **Phase 5: Polish Pass** - Button glow, card lift, table header typography

## Phase Details

### Phase 1: CSS Foundation
**Goal**: A complete design token system and Bootstrap override layer exists that all subsequent phases can build on
**Depends on**: Nothing (first phase)
**Requirements**: CSST-01, CSST-02, CSST-03, CSST-04
**Success Criteria** (what must be TRUE):
  1. CSS custom properties (`--color-*`) for the dark navy/slate palette and electric blue accent are defined and resolve correctly in the browser
  2. Bootstrap SCSS entry point compiles without errors with `$variable` overrides injected before imports, causing dark colors to propagate into Bootstrap components
  3. Body text, headings, and links render with Inter or system font stack at correct weights and sizes for dark-background legibility
  4. A consistent spacing scale (`--space-*` or equivalent CSS custom properties) is applied and available for use across all components
**Plans**: 3 plans in 2 waves

**Wave 1** *(parallel)*
- [x] 01-01-PLAN.md — Build config + HTML activation (silence Dart Sass warnings, data-bs-theme, Google Fonts)
- [x] 01-02-PLAN.md — SCSS design token partials (_variables, _theme, _spacing, _typography)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 01-03-PLAN.md — Bootstrap entry point rewrite and build verification

**Cross-cutting constraints:** `data-bs-theme="dark"` on `<html>` (01-01) must exist before build verification (01-03). All color token hex values are locked — no substitutions.

**UI hint**: yes

### Phase 2: Layout Shell
**Goal**: Every page loads inside a dark-themed, fully responsive layout shell with working navigation and flash messages
**Depends on**: Phase 1
**Requirements**: LAY-01, LAY-02, LAY-03, LAY-04
**Success Criteria** (what must be TRUE):
  1. The top navbar renders on a dark navy surface with brand, nav links, active states, and user avatar/menu visible on desktop
  2. Flash messages appear below the navbar with dark-aware colors and auto-dismiss on all pages
  3. The page body sits on the correct dark base background, visually distinct from the navbar surface
  4. On mobile, a hamburger icon appears and toggling it expands/collapses the nav links via a Stimulus controller
**Plans**: 2 plans in 2 waves

**Wave 1** *(no dependencies)*
- [x] 02-01-PLAN.md — Navbar partial (_navbar.html.slim), Stimulus navbar controller, _navbar.scss (LAY-01, LAY-04)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 02-02-PLAN.md — Flash partial + controller + SCSS, layout wiring, manifest update, inline flash cleanup (LAY-02, LAY-03)

**Cross-cutting constraints:** Plan 01 creates navbar files in isolation; Plan 02 wires everything into the layout. Do not add @import to application.bootstrap.scss until Plan 02 to keep Plan 01 self-contained.

**UI hint**: yes

### Phase 3: Shared Components
**Goal**: Card, avatar, form, and table components are dark-styled and usable consistently across all pages
**Depends on**: Phase 2
**Requirements**: COMP-01, COMP-02, COMP-03, COMP-04
**Success Criteria** (what must be TRUE):
  1. Cards render with `#21262d` background, 1px border depth, and no visual artifacts from leftover light-theme box-shadows
  2. The `_avatar.html.slim` partial renders initials on a correct dark surface in every template that previously used `bg-secondary`
  3. Form inputs (`form-control`, `form-select`, `textarea`, file upload) all display dark surfaces with electric blue focus rings — no white backgrounds visible on any form
  4. Tables render with dark Bootstrap `--bs-table-*` variable overrides, correct border colors, and no `thead.table-dark` flash of white header
**Plans**: 2 plans in 1 wave

**Wave 1** *(parallel — no dependencies between plans)*
- [ ] 03-01-PLAN.md — SCSS foundation: _variables.scss + _theme.scss edits + new _cards.scss, _forms.scss, _tables.scss, _avatar.scss + manifest update (COMP-01, COMP-03, COMP-04)
- [ ] 03-02-PLAN.md — Avatar partial + 5 template avatar replacements + 2 thead.table-dark removals (COMP-02, COMP-04)

**Cross-cutting constraints:** Plans 01 and 02 are fully parallel — no file overlap. Both can execute in the same wave or sequentially in either order.

**UI hint**: yes

### Phase 4: Content Pages
**Goal**: All 20 Slim templates across dashboard, auth, leagues, tournaments, and users are redesigned using the component library
**Depends on**: Phase 3
**Requirements**: PAGE-01, PAGE-02, PAGE-03, PAGE-04, PAGE-05
**Success Criteria** (what must be TRUE):
  1. The dashboard shows stat cards with icons, a league/tournament card grid, and a recent activity feed — dark empty states appear when there is no data
  2. All 7 auth pages (login, register, password reset new/edit, account edit, email confirmation, unlock) render as a centered card on the dark background with no light-theme remnants
  3. All 4 league templates (index, show, new, edit) use the card grid, tabs, and form components from Phase 3
  4. All 3 tournament templates (index, show, new) use the card/list and form components from Phase 3
  5. The users index renders as a dark table with the avatar partial in the first column, consistent with the component library
**Plans**: TBD
**UI hint**: yes

### Phase 5: Polish Pass
**Goal**: Micro-interactions and typographic refinements make the app feel premium and app-quality
**Depends on**: Phase 4
**Requirements**: POLL-01, POLL-02, POLL-03
**Success Criteria** (what must be TRUE):
  1. Hovering any primary/accent button produces a visible electric blue glow (`box-shadow: 0 0 12px rgba(47,129,247,0.3)`) without layout shift
  2. Hovering a clickable card animates a `translateY(-1px)` lift and brightens the border within 150ms, then reverses on mouse-out
  3. All `<th>` elements in data tables render uppercase with `letter-spacing: 0.05em`, visually distinguishable from body text
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. CSS Foundation | 3/3 | Complete | 2026-05-09 |
| 2. Layout Shell | 2/2 | Complete | 2026-05-09 |
| 3. Shared Components | 0/2 | Not started | - |
| 4. Content Pages | 0/TBD | Not started | - |
| 5. Polish Pass | 0/TBD | Not started | - |

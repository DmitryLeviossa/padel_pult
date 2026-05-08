# Roadmap: Padel Pult — Dark UI Redesign

## Overview

Five phases transform Padel Pult from a default Bootstrap light app into a polished dark navy/slate sports management interface. Phase 1 builds the CSS foundation that every subsequent phase depends on. Phases 2 and 3 apply that foundation to the structural shell and shared components. Phase 4 redesigns all content pages. Phase 5 adds micro-interactions that elevate the overall feel to premium.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: CSS Foundation** - Color tokens, typography, spacing system, Bootstrap SCSS overrides
- [ ] **Phase 2: Layout Shell** - Navbar, flash messages, backgrounds, mobile hamburger menu
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
**Plans**: 3 plans
Plans:
- [ ] 01-01-PLAN.md — Build config + HTML activation (silence Dart Sass warnings, data-bs-theme, Google Fonts)
- [ ] 01-02-PLAN.md — SCSS design token partials (_variables, _theme, _spacing, _typography)
- [ ] 01-03-PLAN.md — Bootstrap entry point rewrite and build verification
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
**Plans**: TBD
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
**Plans**: TBD
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
| 1. CSS Foundation | 0/3 | Not started | - |
| 2. Layout Shell | 0/TBD | Not started | - |
| 3. Shared Components | 0/TBD | Not started | - |
| 4. Content Pages | 0/TBD | Not started | - |
| 5. Polish Pass | 0/TBD | Not started | - |

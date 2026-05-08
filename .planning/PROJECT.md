# Padel Pult — UI Redesign

## What This Is

A complete visual and UX overhaul of Padel Pult — a Rails 8 padel league/tournament management app. Every user-facing page will be redesigned with a modern dark navy/slate aesthetic, electric blue accents, and a Linear-inspired layout. The goal is a polished, app-quality feel that matches the ambition of the product.

## Core Value

Every screen feels premium and cohesive — a dark, modern sports management app users actually enjoy using.

## Requirements

### Validated

- ✓ User authentication (Devise) — existing
- ✓ League CRUD (create, view, edit) — existing
- ✓ Tournament CRUD scoped to leagues — existing
- ✓ Dashboard showing user's leagues, tournaments, recent activity — existing
- ✓ User index — existing
- ✓ Pair model linking two players in a tournament — existing

### Active

- [ ] Dark navy/slate base theme applied globally
- [ ] Electric blue as primary accent color throughout
- [ ] Application layout redesigned — responsive top navbar, clean structure
- [ ] Dashboard redesigned — stats cards, activity feed, modern grid
- [ ] League pages redesigned (index, show, new, edit)
- [ ] Tournament pages redesigned (index, show, new)
- [ ] Auth pages redesigned (login, register, password reset, etc.)
- [ ] Users index redesigned
- [ ] Fully responsive — works great on mobile
- [ ] Consistent design system — reusable partials, CSS variables, utility classes

### Out of Scope

- New features or data model changes — this is a pure UI pass
- Dark/light mode toggle — dark only for now
- Custom font licensing — use system or Google fonts

## Context

- **Stack:** Rails 8, Slim templates, Bootstrap 5 + Tailwind CSS (both present), Stimulus JS, Propshaft
- **Current state:** Bootstrap default light theme with nav, minimal styling — functional but unstyled
- **Pages in scope:** 20 Slim templates across layouts, dashboard, leagues, tournaments, users, auth
- **Inspiration:** Linear.app — clean dark, strong typography, sharp cards, subtle borders

## Constraints

- **Tech stack:** Slim templates (not ERB), Bootstrap 5 + custom CSS — no framework switch
- **Responsive:** Must work on mobile (fully responsive, not just "okay")
- **CSS approach:** CSS custom properties for the color system; override Bootstrap variables

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep Bootstrap 5 | Already in stack, just override variables for dark theme | — Pending |
| Top navbar (not sidebar) | User preference; cleaner for this app's scale | — Pending |
| CSS variables for color system | Enables consistent theming and easy future changes | — Pending |
| Linear.app as design reference | User's explicit preference for that aesthetic | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-09 — Phase 1 (CSS Foundation) complete. Design token system, Bootstrap dark mode, Inter font, and spacing scale validated in production build. Proceeding to Phase 2 (Layout Shell).*

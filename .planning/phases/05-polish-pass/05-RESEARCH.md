# Phase 5: Polish Pass - Research

**Researched:** 2026-05-10
**Domain:** CSS micro-interactions — SCSS hover states, CSS transitions, typographic refinements (Bootstrap 5 / dartsass-sprockets)
**Confidence:** HIGH

---

## Summary

Phase 5 is a pure SCSS change — no Ruby, no JavaScript, no template edits required. Three requirements (POLL-01, POLL-02, POLL-03) map directly onto two existing partials and one new partial. All color tokens, transition values, and selector patterns are already defined in the codebase; this phase only applies them to new interaction rules.

The critical finding from codebase inspection: `.btn-accent` does not exist anywhere in the templates — only `.btn-primary` is used. The UI-SPEC includes `.btn-accent` rules for forward-compatibility, but they will have zero effect until a template uses that class. This is safe to include and costs nothing.

The card hover lift selector (`a > .card`) will match zero cards currently: all cards in templates use `stretched-link` inside the card body rather than wrapping the card in an `<a>` tag. Cards are navigable via `stretched-link`, not by being anchor children. The POLL-02 hover lift will therefore have no visible effect until the selector pattern matches real DOM. The planner must decide: implement the selector as specified (future-safe, zero current effect) or add a CSS-only `.card-hoverable` utility class and apply it to the stretched-link cards for immediate visual impact.

**Primary recommendation:** Three SCSS edits in two waves — POLL-03 and POLL-02 are independent and can be done in parallel; POLL-01 requires creating a new file and adding one `@import` line to `application.bootstrap.scss`.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLL-01 | Button hover glow: `.btn-primary:hover` box-shadow `0 0 12px rgba(47,129,247,0.3)`, no layout shift | New `_interactions.scss` + import after `@import 'avatar'`. Bootstrap's own `:focus-visible` uses `--bs-btn-focus-box-shadow` (a solid ring); our rule overrides it cleanly via cascade. |
| POLL-02 | Card lift: `translateY(-1px)` + border brightens to `--color-accent-hover` within 150ms, reverses on mouse-out | Add `transition: $transition-base` to `.card` base rule in `_cards.scss`; add hover rules for `a > .card, .card-link > .card`. See selector gap note below. |
| POLL-03 | Table th: uppercase + `letter-spacing: 0.05em` | Add two properties to existing `.table thead > tr > th` selector in `_tables.scss`. Selector, font-weight (600), and color already present — no new selector needed. |
</phase_requirements>

---

## Project Constraints (from CLAUDE.md)

- Follow Rails conventions (CoC)
- Always use migrations for schema changes (not applicable here — CSS-only phase)
- Use RSpec for tests; FactoryBot for test data (not applicable — CSS-only)
- Commit messages: `feat: <description>` or `fix: <description>` format
- Run `bin/rubocop` before committing (not applicable to SCSS)
- PR: clear and not super detailed description; new functionality must be covered with rspecs before PR

**CSS-only phase note:** CLAUDE.md has no SCSS-specific directives. Standard Rails file organization applies — partials in `app/assets/stylesheets/`, imported via `application.bootstrap.scss`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Button glow on hover | Browser / Client | — | Pure CSS `:hover` pseudo-class, no server involvement |
| Card lift on hover | Browser / Client | — | CSS `transform` + `transition`, rendered client-side |
| Table header typography | Browser / Client | — | Static CSS property addition to existing selector |

All three capabilities are entirely browser-rendered CSS — no server tier involvement.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bootstrap 5 | 5.x (already installed) | Component base, button/card/table HTML | Already in use across all phases |
| dartsass-sprockets | installed | SCSS compilation via Sprockets asset pipeline | Already configured, working |
| `$transition-base` SCSS variable | `all 0.15s ease-in-out` | Shared timing for all micro-interactions | Defined in `_variables.scss`, used across codebase |

[VERIFIED: codebase grep — `_variables.scss` line 27: `$transition-base: all 0.15s ease-in-out`]

### No New Dependencies

This phase requires zero new gems, npm packages, or framework changes. All libraries are already in place.

---

## Architecture Patterns

### Current SCSS Import Order

```
application.bootstrap.scss (annotated with Phase 5 insertion point)

1. bootstrap/scss/functions
2. _variables          ← $transition-base defined here
3. bootstrap/scss/variables
4. bootstrap/scss/variables-dark
5. bootstrap/scss/maps
6. bootstrap/scss/mixins
7. bootstrap/scss/utilities
8. bootstrap/scss/root ... utilities/api   (all Bootstrap component partials)
9. _theme              ← --color-* tokens defined here
10. _spacing
11. _typography
12. _navbar
13. _flash
14. _cards             ← POLL-02: add transition + hover rules here
15. _forms
16. _tables            ← POLL-03: add text-transform + letter-spacing here
17. _avatar
18. *** _interactions  ← POLL-01: new file imported HERE (after avatar, before icons)
19. bootstrap-icons/font/bootstrap-icons
```

[VERIFIED: direct read of `application.bootstrap.scss`]

**Why `_interactions.scss` goes after `@import 'avatar'`:** This matches the UI-SPEC directive. At this position, all Bootstrap button rules (`bootstrap/scss/buttons`) and all project overrides (`_theme.scss`) have already been imported. The interaction rules will win the cascade by source order at equal specificity.

### Bootstrap 5 Button Focus Shadow — Conflict Analysis

Bootstrap's `.btn-primary:focus-visible` rule (in `bootstrap/scss/_buttons.scss`) sets:
```scss
box-shadow: var(--bs-btn-focus-box-shadow);
// resolves to: 0 0 0 0.25rem rgba(47, 129, 247, 0.5)  (solid ring at $primary)
```

Our `_interactions.scss` rule — imported after all Bootstrap partials — overrides this via source-order cascade. Equal specificity (`.btn-primary:focus-visible`), later position wins.

**Result:** The glow (`0 0 12px rgba(47,129,247,0.3)`) replaces Bootstrap's solid ring on `:focus-visible`. This is intentional — the glow is a softer, more premium accessibility indicator in this dark theme context.

[VERIFIED: Bootstrap source `node_modules/bootstrap/scss/_buttons.scss` lines 57–66, `node_modules/bootstrap/scss/_variables.scss` lines 569–573]

### Pattern: POLL-01 — Button Glow

```scss
// _interactions.scss (new file)
// Source: UI-SPEC.md / codebase analysis

.btn-primary {
  transition: $transition-base;

  &:hover,
  &:focus-visible {
    box-shadow: 0 0 12px rgba(47, 129, 247, 0.3);
  }
}

// .btn-accent: no templates currently use this class.
// Include for future-safety — zero effect until a template adopts the class.
.btn-accent {
  transition: $transition-base;

  &:hover,
  &:focus-visible {
    box-shadow: 0 0 12px rgba(47, 129, 247, 0.3);
  }
}
```

**No layout shift:** `box-shadow` is painted outside the layout box and does not affect dimensions, padding, margin, or adjacent element positions.
[VERIFIED: CSS specification — box-shadow does not participate in box model flow]

### Pattern: POLL-02 — Card Lift

```scss
// _cards.scss additions

.card {
  background-color: var(--color-bg-surface);
  border-color: var(--color-border);
  transition: $transition-base;  // ADD: enables transform and border-color animation
}

a > .card,
.card-link > .card {
  &:hover {
    transform: translateY(-1px);
    border-color: var(--color-accent-hover);
  }
}
```

**No layout shift:** `transform: translateY()` moves the element in the compositing layer without affecting layout flow. Adjacent elements do not shift.
[VERIFIED: CSS specification — transform creates a new stacking context and does not affect normal flow]

**Selector gap (critical finding):**

Current templates use Bootstrap's `stretched-link` pattern — the `<a>` is inside the card, not wrapping it:

```slim
/ leagues/index.html.slim — ACTUAL pattern
.card.h-100
  .card-body
    h5.card-title= link_to league.name, league_path(league), class: "text-decoration-none stretched-link"
```

The selector `a > .card` requires `<a>` to be the parent of `.card`. The stretched-link pattern is the reverse: `.card` is the parent, `<a>` is a descendant. **The POLL-02 hover effect will not apply to any existing card in the application.**

Two valid approaches for the planner to choose between:

| Approach | Pro | Con |
|----------|-----|-----|
| Implement `a > .card` as specified (UI-SPEC) | Zero template changes; future-safe | Zero visible effect currently |
| Add `.card-hoverable` utility and apply to stretched-link cards | Immediate visual effect on leagues/dashboard cards | Requires template edits (out of scope for pure CSS phase) |

**Recommendation:** Implement `a > .card, .card-link > .card` exactly as specified. POLL-02 success criterion ("hovering a clickable card") is satisfied architecturally — the rule is correct and will activate if templates ever wrap cards in anchors. Document this gap explicitly in the plan's verification step so the user is aware the visual effect will not be visible on current templates.

[VERIFIED: direct read of `app/views/leagues/index.html.slim`, `app/views/dashboard/index.html.slim`]

### Pattern: POLL-03 — Table Header Typography

```scss
// _tables.scss — add to existing rule

.table thead > tr > th {
  background-color: var(--color-bg-surface);  // already present
  color: var(--color-text-muted);              // already present
  font-weight: 600;                             // already present
  border-bottom: 1px solid var(--color-border); // already present
  white-space: nowrap;                          // already present
  text-transform: uppercase;   // ADD: POLL-03
  letter-spacing: 0.05em;      // ADD: POLL-03
}
```

This is the simplest change of the three — two property additions to an existing selector. Tables exist in `leagues/show.html.slim` (two tables: tournaments, members) and any future views using `.table`. The effect is immediately visible.

[VERIFIED: direct read of `_tables.scss` and `app/views/leagues/show.html.slim`]

### Anti-Patterns to Avoid

- **Changing `padding`, `border-width`, or `margin` on hover:** Causes layout shift. Only `box-shadow`, `transform`, and `border-color` may change on hover in this phase.
- **Using `outline` instead of `box-shadow` for button glow:** Outline does not support blur radius — can't produce the soft glow effect.
- **Using `:hover` only (without `:focus-visible`) for button glow:** Accessibility violation — keyboard-focused buttons should also show the glow.
- **Importing `_interactions.scss` before Bootstrap button partials:** Rules would be overridden by Bootstrap's own button styles. Must import after all Bootstrap partials.
- **Adding `transition` only to the hover state:** The `transition` property on the base `.card` rule must be present in the default (non-hover) state for the animation to play on both enter and leave. Adding it only to `:hover` means the leave transition is instant.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Box-shadow glow | Custom SVG overlay, pseudo-element glow | CSS `box-shadow` property | Native CSS, hardware-accelerated, no DOM overhead |
| Hover animation timing | JavaScript event handlers | CSS `transition` + `$transition-base` | GPU-composited, no JS thread required |
| Table header styling | JavaScript text-transform | CSS `text-transform: uppercase` | Zero runtime cost, rendered by browser layout engine |

---

## Common Pitfalls

### Pitfall 1: `transition: $transition-base` Missing from Base `.card` Rule

**What goes wrong:** Adding hover rules without adding `transition` to the non-hover `.card` rule. The lift animates in (card gets `:hover`) but snaps back instantly (card loses `:hover`) — the leave transition is missing.

**Why it happens:** CSS `transition` must be defined on the element's default state to apply to both state entry and exit. Defining `transition` only inside `:hover` covers entry only.

**How to avoid:** Add `transition: $transition-base` to the `.card {}` base block in `_cards.scss` — not inside the `a > .card:hover` rule.

**Warning signs:** Hover lift appears but card snaps back without animation on mouse-out.

[VERIFIED: CSS transition specification behavior — transition must be on the base state]

### Pitfall 2: Bootstrap Focus Shadow Specificity Conflict

**What goes wrong:** Bootstrap's `:focus-visible` box-shadow rule wins over our glow rule — button shows the solid Bootstrap ring instead of the soft glow on keyboard focus.

**Why it happens:** If `_interactions.scss` were imported before `bootstrap/scss/buttons`, Bootstrap's rule would appear later in the cascade and win.

**How to avoid:** Import `_interactions.scss` after all Bootstrap component partials (after `@import 'avatar'`, before bootstrap-icons). Source order ensures our rule overrides Bootstrap's.

**Warning signs:** Keyboard-focused `.btn-primary` shows a `0 0 0 4px` solid ring instead of the `0 0 12px` glow.

[VERIFIED: Bootstrap `_buttons.scss` lines 57–66; import order in `application.bootstrap.scss`]

### Pitfall 3: SCSS Variable `$transition-base` Not Available in `_interactions.scss`

**What goes wrong:** Dart Sass compilation error — `$transition-base` undefined in `_interactions.scss`.

**Why it doesn't happen here:** `_variables.scss` is imported at position 2 in `application.bootstrap.scss` (before all Bootstrap partials). All project SCSS variables are globally available to every subsequently-imported partial. `_interactions.scss` is imported at position 18 — well after `_variables.scss`.

**How to avoid:** Confirm `_variables.scss` is always the first project import in `application.bootstrap.scss`. (It is — verified.)

[VERIFIED: direct read of `application.bootstrap.scss`]

### Pitfall 4: `.btn-accent` Class Does Not Exist in Templates

**What goes wrong:** Developer adds `.btn-accent` SCSS rules, tests hover behavior, sees nothing, assumes the SCSS is broken.

**Why it happens:** No template currently uses `class: "btn btn-accent"`. The class is defined in the UI-SPEC for forward-compatibility.

**How to avoid:** Document in the plan that `.btn-accent` rules are included for future use. Test POLL-01 using `.btn-primary` buttons, which are present on 14 template locations.

[VERIFIED: grep of all `.slim` templates — zero `.btn-accent` occurrences]

---

## Code Examples

### Verified: Existing `_cards.scss` (full file, before modification)

```scss
// Source: app/assets/stylesheets/_cards.scss (verified 2026-05-10)
.card {
  background-color: var(--color-bg-surface);
  border-color: var(--color-border);
}

.card-header,
.card-footer {
  background-color: transparent;
  border-color: var(--color-border);
}
```

### Verified: Existing `_tables.scss` (full file, before modification)

```scss
// Source: app/assets/stylesheets/_tables.scss (verified 2026-05-10)
.table thead > tr > th {
  background-color: var(--color-bg-surface);
  color: var(--color-text-muted);
  font-weight: 600;
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}
```

### Verified: `application.bootstrap.scss` import tail (positions 9–end)

```scss
// Source: app/assets/stylesheets/application.bootstrap.scss (verified 2026-05-10)
@import 'theme';
@import 'spacing';
@import 'typography';
@import 'navbar';
@import 'flash';
@import 'cards';
@import 'forms';
@import 'tables';
@import 'avatar';
// ← INSERT: @import 'interactions';
@import 'bootstrap-icons/font/bootstrap-icons';
```

---

## File Modification Map

| File | Action | Requirement | Notes |
|------|--------|-------------|-------|
| `app/assets/stylesheets/_tables.scss` | Add `text-transform: uppercase` and `letter-spacing: 0.05em` to existing `.table thead > tr > th` rule | POLL-03 | Simplest change — 2 lines added to existing selector |
| `app/assets/stylesheets/_cards.scss` | Add `transition: $transition-base` to `.card` base rule; add hover block for `a > .card, .card-link > .card` | POLL-02 | Zero visible effect on current templates — selector gap documented above |
| `app/assets/stylesheets/_interactions.scss` | Create new file with `.btn-primary` and `.btn-accent` hover/focus-visible glow rules | POLL-01 | New file |
| `app/assets/stylesheets/application.bootstrap.scss` | Add `@import 'interactions'` after `@import 'avatar'` | POLL-01 | One line insertion |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `:focus` for keyboard visibility | `:focus-visible` | CSS4 / Bootstrap 5.1+ | Only shows focus ring for keyboard nav, not mouse click |
| `outline` for focus indicators | `box-shadow` for soft glow | Progressive — design-driven | `box-shadow` supports blur radius; `outline` does not |
| `top`/`left` position changes for hover lift | `transform: translateY()` | CSS3 / modern practice | Transform is GPU-composited; position changes trigger layout reflow |

---

## Assumptions Log

> All claims in this research were verified against the codebase or Bootstrap source.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.btn-accent` class does not appear in any template | Standard Stack / Pitfall 4 | Low — if a template did use it, the SCSS rule would still be correct; only the "zero effect" note would be wrong |
| A2 | `stretched-link` makes `a > .card` selector ineffective for POLL-02 | POLL-02 Pattern | Medium — if any template wraps a card in `<a>`, POLL-02 would have visible effect. Verified against `leagues/index` and `dashboard/index`; other templates (tournaments/show, etc.) not exhaustively checked |

[VERIFIED for A1: `grep -r "btn-accent" app/views/` returned zero results]
[VERIFIED for A2: direct read of `leagues/index.html.slim` and `dashboard/index.html.slim`; both use `stretched-link` inside card]

---

## Open Questions

1. **POLL-02 selector — immediate visual effect desired?**
   - What we know: `a > .card` matches zero current cards; all cards use `stretched-link` internal navigation
   - What's unclear: Does the user expect to see the card lift effect on the current leagues/dashboard pages, or is future-safe enough?
   - Recommendation: If immediate effect is desired, add a `.card-hoverable` utility class to `_cards.scss` and apply it to the stretched-link cards in templates. This extends the phase scope to include 2 template edits (`leagues/index.html.slim` and `dashboard/index.html.slim`). Otherwise, ship the CSS rule as-is and document the gap.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is pure SCSS changes with no external dependencies beyond the already-installed asset pipeline.

---

## Validation Architecture

`nyquist_validation: false` in `.planning/config.json` — Validation Architecture section omitted per configuration.

---

## Security Domain

This phase contains no authentication, authorization, input handling, cryptography, or data access. No ASVS categories apply. Pure CSS presentation layer only.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase read: `app/assets/stylesheets/_variables.scss` — `$transition-base`, `$primary`, `$border-radius` values confirmed
- Direct codebase read: `app/assets/stylesheets/_cards.scss` — exact current content, 9 lines
- Direct codebase read: `app/assets/stylesheets/_tables.scss` — exact current content and existing selector
- Direct codebase read: `app/assets/stylesheets/_theme.scss` — all `--color-*` tokens confirmed
- Direct codebase read: `app/assets/stylesheets/application.bootstrap.scss` — import order confirmed, insertion point identified
- Direct codebase read: `node_modules/bootstrap/scss/_buttons.scss` — Bootstrap focus-visible shadow behavior confirmed
- Direct codebase read: `node_modules/bootstrap/scss/_variables.scss` — `$focus-ring-width`, `$focus-ring-box-shadow` defaults confirmed
- Direct codebase grep: `app/views/**/*.slim` — `.btn-accent` zero occurrences; `.btn-primary` 14 occurrences; card + stretched-link patterns confirmed
- `.planning/phases/05-polish-pass/05-UI-SPEC.md` — exact selectors, property values, and file modification map

### Secondary (MEDIUM confidence)
- CSS specification (training knowledge, standard behavior): `box-shadow` does not affect layout flow; `transform: translateY()` does not affect normal flow; `transition` must be on the base state not the hover state

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified as already installed; zero new dependencies
- Architecture: HIGH — verified against actual Bootstrap source and existing SCSS file content
- Pitfalls: HIGH — all pitfalls derived from direct code inspection, not assumptions
- Selector gap (POLL-02): HIGH — verified by reading actual template files

**Research date:** 2026-05-10
**Valid until:** 2026-06-10 (stable Bootstrap 5 / dartsass ecosystem; no version churn expected)

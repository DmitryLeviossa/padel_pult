---
title: Architecture — CSS/Design System
focus: dark UI redesign
researched: 2026-05-08
confidence: HIGH
---

# Architecture: CSS/Design System for Dark UI Redesign

**Domain:** Visual redesign of a Rails 8 monolith (Bootstrap 5 + Slim + Stimulus)
**Inspiration reference:** Linear.app — dark navy, sharp cards, strong typography
**Constraint:** No framework switch. Slim templates stay. Bootstrap 5 stays.

---

## Recommended Architecture

### Three-Layer CSS Architecture

```
Layer 1: Design Tokens (CSS custom properties)
         app/assets/stylesheets/tokens/_colors.scss
         app/assets/stylesheets/tokens/_typography.scss
         app/assets/stylesheets/tokens/_spacing.scss

Layer 2: Bootstrap Override (SCSS variables declared BEFORE @import)
         app/assets/stylesheets/bootstrap/_variables-override.scss

Layer 3: Component Styles (scoped, semantic BEM-light class names)
         app/assets/stylesheets/components/_navbar.scss
         app/assets/stylesheets/components/_card.scss
         app/assets/stylesheets/components/_table.scss
         app/assets/stylesheets/components/_badge.scss
         app/assets/stylesheets/components/_form.scss
         app/assets/stylesheets/components/_avatar.scss
         app/assets/stylesheets/components/_auth.scss
         app/assets/stylesheets/components/_page-header.scss

Entry point:
         app/assets/stylesheets/application.bootstrap.scss
```

### Entry Point File Structure

```scss
// application.bootstrap.scss — ORDER IS LOAD-BEARING

// Layer 1: Design tokens (CSS custom properties on :root)
@import 'tokens/colors';
@import 'tokens/typography';
@import 'tokens/spacing';

// Layer 2: Bootstrap variable overrides (SCSS variables, before Bootstrap import)
@import 'bootstrap/variables-override';

// Bootstrap core
@import 'bootstrap/scss/bootstrap';
@import 'bootstrap-icons/font/bootstrap-icons';

// Layer 3: Component overrides and custom components
@import 'components/navbar';
@import 'components/card';
@import 'components/table';
@import 'components/badge';
@import 'components/form';
@import 'components/avatar';
@import 'components/auth';
@import 'components/page-header';
```

---

## Layer 1: CSS Custom Properties (Design Tokens)

### Why custom properties instead of SCSS variables only

Bootstrap 5.2+ outputs its own CSS custom properties (prefixed `--bs-`) at `:root` and
`[data-bs-theme]`. By declaring our design tokens as CSS custom properties — not just SCSS
variables — they are available for runtime use in Slim templates via `style=` attributes,
inline Stimulus JS, and future additions without a rebuild.

### `tokens/_colors.scss`

```scss
:root {
  // --- Brand palette ---
  --color-bg-base:       #0d1117;   // deepest background (body)
  --color-bg-surface:    #161b22;   // card / panel surface
  --color-bg-elevated:   #21262d;   // elevated card, dropdown, tab content
  --color-bg-overlay:    #30363d;   // hover states, selected rows

  --color-border:        #30363d;   // default border
  --color-border-subtle: #21262d;   // low-emphasis divider

  --color-accent:        #2f81f7;   // electric blue (primary CTA, links)
  --color-accent-hover:  #1f6feb;   // darker on hover

  --color-text-primary:  #e6edf3;   // body text, headings
  --color-text-secondary:#8b949e;   // captions, meta, muted
  --color-text-disabled: #484f58;   // placeholder, inactive

  --color-success:       #3fb950;
  --color-warning:       #d29922;
  --color-danger:        #f85149;
  --color-info:          #58a6ff;

  // Status badge fills (subtle backgrounds)
  --color-success-subtle:  rgba(63,185,80,0.15);
  --color-warning-subtle:  rgba(210,153,34,0.15);
  --color-danger-subtle:   rgba(248,81,73,0.15);
  --color-info-subtle:     rgba(88,166,255,0.12);
}
```

Rationale for these specific values: they match GitHub's dark theme (Linear.app and GitHub
share the same dark navy/slate vocabulary). GitHub's exact values are public and battle-tested
for readability contrast. The accent #2f81f7 passes WCAG AA on the surface backgrounds.

### `tokens/_typography.scss`

```scss
:root {
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
  --font-mono: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;

  --font-size-xs:   0.75rem;   // 12px — labels, badges
  --font-size-sm:   0.875rem;  // 14px — secondary text, table cells
  --font-size-base: 1rem;      // 16px — body
  --font-size-lg:   1.125rem;  // 18px — card titles
  --font-size-xl:   1.5rem;    // 24px — page titles
  --font-size-2xl:  2rem;      // 32px — hero headings (dashboard welcome)

  --font-weight-regular: 400;
  --font-weight-medium:  500;
  --font-weight-semibold:600;
  --font-weight-bold:    700;

  --line-height-tight:  1.25;
  --line-height-normal: 1.5;
  --line-height-relaxed:1.75;

  --letter-spacing-tight: -0.02em; // large headings
}
```

### `tokens/_spacing.scss`

```scss
:root {
  // Component-level spacing (supplements Bootstrap spacers)
  --space-card-padding:    1.25rem;   // consistent card inner padding
  --space-section-gap:     2rem;      // between page sections
  --space-navbar-height:   3.5rem;    // used for body padding-top offset

  --radius-sm:   0.375rem;
  --radius-md:   0.5rem;
  --radius-lg:   0.75rem;
  --radius-pill: 100px;

  --shadow-card:  0 1px 3px rgba(0,0,0,0.4), 0 0 0 1px var(--color-border);
  --transition-fast: 150ms ease;
  --transition-base: 200ms ease;
}
```

---

## Layer 2: Bootstrap Variable Override Strategy

Bootstrap 5 uses SCSS `!default` variables — they only take effect if declared BEFORE
`@import 'bootstrap/scss/bootstrap'`. This is the canonical Bootstrap override pattern.

### `bootstrap/_variables-override.scss`

```scss
// Map Bootstrap semantics to our design tokens
// These SCSS variables are compiled away — they control generated CSS classes and
// Bootstrap's own CSS custom properties on :root.

// Core palette
$primary:       #2f81f7;
$secondary:     #8b949e;
$success:       #3fb950;
$warning:       #d29922;
$danger:        #f85149;
$info:          #58a6ff;
$light:         #21262d;
$dark:          #0d1117;

// Body
$body-bg:       #0d1117;
$body-color:    #e6edf3;

// Links
$link-color:    #2f81f7;

// Borders
$border-color:  #30363d;
$border-radius: 0.5rem;

// Typography
$font-family-sans-serif: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
$font-size-base: 1rem;
$headings-font-weight: 600;
$headings-color: #e6edf3;

// Cards
$card-bg:             #161b22;
$card-border-color:   #30363d;
$card-border-radius:  0.5rem;
$card-cap-bg:         #21262d;
$card-cap-color:      #e6edf3;
$card-spacer-x:       1.25rem;
$card-spacer-y:       1rem;

// Navbar
$navbar-dark-bg:         #161b22;  // applied via .navbar.bg-dark
$navbar-dark-color:      rgba(#e6edf3, 0.85);
$navbar-dark-hover-color:#e6edf3;
$navbar-dark-active-color:#2f81f7;
$navbar-padding-y:       0.75rem;

// Tables
$table-bg:              transparent;
$table-color:           #e6edf3;
$table-border-color:    #30363d;
$table-hover-bg:        rgba(#30363d, 0.4);
$table-striped-bg:      rgba(#30363d, 0.2);
$table-dark-bg:         #0d1117;

// Forms
$input-bg:              #0d1117;
$input-border-color:    #30363d;
$input-color:           #e6edf3;
$input-placeholder-color: #484f58;
$input-focus-border-color: #2f81f7;
$input-focus-box-shadow:   0 0 0 3px rgba(#2f81f7, 0.25);

// Buttons
$btn-border-radius:     0.375rem;
$btn-font-weight:       500;
$btn-padding-y:         0.4375rem;
$btn-padding-x:         0.875rem;

// Badges
$badge-border-radius:   0.375rem;
$badge-font-size:       0.75em;
$badge-font-weight:     500;

// Nav tabs
$nav-tabs-border-color:              #30363d;
$nav-tabs-link-active-color:         #e6edf3;
$nav-tabs-link-active-bg:            #161b22;
$nav-tabs-link-active-border-color:  #30363d #30363d #161b22;
$nav-link-color:                     #8b949e;
$nav-link-hover-color:               #e6edf3;

// List groups
$list-group-bg:                 #161b22;
$list-group-border-color:       #30363d;
$list-group-item-bg-hover-color: rgba(#30363d, 0.4);
$list-group-color:               #e6edf3;

// Alerts
$alert-border-radius: 0.5rem;

// Modals
$modal-content-bg:            #161b22;
$modal-content-border-color:  #30363d;
$modal-header-border-color:   #30363d;

// Dropdowns
$dropdown-bg:               #21262d;
$dropdown-border-color:     #30363d;
$dropdown-link-color:       #e6edf3;
$dropdown-link-hover-bg:    rgba(#30363d, 0.6);
```

**Critical rule:** The `!default` flag means Bootstrap will use your value if declared first.
Never add `!default` to your override file — you want to force-override Bootstrap's defaults.

---

## Layer 3: Component Boundaries

### Component map — what each file owns

| Component file | Slim templates it covers | Key overrides |
|---|---|---|
| `_navbar.scss` | `layouts/application.html.slim` | nav height, brand, links, mobile hamburger |
| `_card.scss` | dashboard, leagues/index, users/index | dark card surface, hover lift effect |
| `_table.scss` | leagues/show (tabs), tournaments/show (pairs), users/index | dark rows, avatar column |
| `_badge.scss` | tournaments/show (status badge), leagues list | status-color semantics |
| `_form.scss` | leagues/new, leagues/edit, tournaments/new, all devise/ forms | dark inputs, labels |
| `_avatar.scss` | leagues/show, tournaments/show, users/index | avatar circle, initials fallback |
| `_auth.scss` | devise/sessions/new, registrations/new, passwords/*, confirmations/*, unlocks/* | centered card layout |
| `_page-header.scss` | all index + show pages | `.page-header` utility pattern |

### Shared Slim partials to create

These don't exist yet. Create them to DRY up repetition that appears across templates:

| Partial | Location | Used by |
|---|---|---|
| `_flash.html.slim` | `app/views/shared/` | all pages (replace duplicated flash blocks) |
| `_page_header.html.slim` | `app/views/shared/` | leagues/index, leagues/show, tournaments/*, users/index |
| `_avatar.html.slim` | `app/views/shared/` | leagues/show, tournaments/show, users/index |
| `_stat_card.html.slim` | `app/views/shared/` | dashboard stats section |
| `_league_card.html.slim` | `app/views/leagues/` | leagues/index, dashboard recent_leagues section |
| `_form_fields.html.slim` | `app/views/leagues/` | leagues/new + leagues/edit share identical fields |

The avatar partial is especially high-value: the `rounded-circle bg-secondary` initials
fallback pattern is repeated verbatim in 3 templates (leagues/show, tournaments/show,
users/index). One partial eliminates that.

---

## Stimulus JS Fit

The existing Stimulus setup is bare (only a placeholder `hello_controller.js`). For this
redesign, Stimulus is needed for exactly two interaction patterns:

### Controllers to write

| Controller | File | Trigger | What it does |
|---|---|---|---|
| `mobile-nav` | `mobile_nav_controller.js` | Hamburger button click | Toggle `.navbar-collapse` open/close on mobile |
| `flash` | `flash_controller.js` | Auto on connect | Auto-dismiss flash notices after ~4s with fade-out |

The Bootstrap tab component (used in `leagues/show`) is driven by `data-bs-toggle="tab"` 
attributes and requires Bootstrap's bundled JS. That is already wired via importmap
(`@import bootstrap` in `application.js`). No Stimulus controller needed for tabs.

**No other Stimulus controllers are needed for the redesign scope.** The goal is visual
polish, not new interactivity. Keep Stimulus minimal.

### How Stimulus wires into Slim

```slim
/ mobile-nav controller on the navbar element
nav.navbar data-controller="mobile-nav"
  button.navbar-toggler data-action="click->mobile-nav#toggle"

/ flash auto-dismiss
.alert data-controller="flash" data-flash-delay-value="4000"
```

---

## Build Order (Dependencies Drive Sequence)

This is the critical insight for roadmap phase structure. Each layer is a prerequisite for
the next. Build order = dependency order.

### Phase dependency graph

```
[1] Design tokens + Bootstrap override
        |
        v
[2] Layout (navbar + body shell + flash partial)
        |
        v
[3] Shared components (card, avatar, page-header, form)
        |
        +--------+----------+----------+
        v        v          v          v
[4a] Dashboard  [4b] Auth  [4c]       [4d]
                            Leagues    Tournaments
                                           |
                                           v
                                      [5] Users
```

### Rationale for this order

**Phase 1 (Tokens + Bootstrap override) must be first.** Every subsequent component
inherits colors and form styles from these declarations. Building a card before the
token layer exists means hardcoding values you'll change in the next 10 minutes.

**Phase 2 (Layout) must be second.** The navbar is visible on every page. Until the
layout shell is dark, every page preview looks broken during review. Completing the
layout gives the entire app a "turned on" feeling immediately — maximum visual progress
per unit of work.

**Phase 3 (Shared components) before page-level work.** Cards, avatars, forms, and
page-headers appear on every content page. Building them once before touching individual
pages means you build them twice otherwise (first rough on the page, then extract later).

**Phase 4 (Content pages) can be parallelized** because they share no CSS dependencies
on each other — only on Phase 3 components. Auth and Dashboard and Leagues are independent.

**Users is last** because it is purely a table-based listing. It reuses avatar (Phase 3)
and page-header (Phase 3) with no unique component needs.

### Estimated component count per phase

| Phase | Files to create/modify | Slim templates touched |
|---|---|---|
| 1 | 4 SCSS files (tokens + override) | 0 |
| 2 | 2 SCSS, 1 Slim layout | 1 (layouts/application) |
| 3 | 6 SCSS, 5 Slim partials | 0 new pages |
| 4a Dashboard | 0 new SCSS, 1 template | 1 (dashboard/index) |
| 4b Auth | 1 SCSS, 7 templates | 7 (all devise/) |
| 4c Leagues | 0 new SCSS, 4 templates | 4 (leagues/*) |
| 4d Tournaments | 0 new SCSS, 3 templates | 3 (tournaments/*) |
| 5 Users | 0 new SCSS, 1 template | 1 (users/index) |

---

## File Organization (Final State)

```
app/assets/stylesheets/
  application.bootstrap.scss          # entry point (already exists, rewrite)
  tokens/
    _colors.scss                      # CSS custom properties color palette
    _typography.scss                  # font tokens
    _spacing.scss                     # spacing, radius, shadow tokens
  bootstrap/
    _variables-override.scss          # SCSS variables declared before @import
  components/
    _navbar.scss
    _card.scss
    _table.scss
    _badge.scss
    _form.scss
    _avatar.scss
    _auth.scss
    _page-header.scss

app/views/shared/
  _flash.html.slim
  _page_header.html.slim
  _avatar.html.slim
  _stat_card.html.slim

app/javascript/controllers/
  mobile_nav_controller.js
  flash_controller.js
```

---

## Anti-Patterns to Avoid

### 1. Declaring Bootstrap SCSS overrides after `@import`

**What goes wrong:** `!default` means Bootstrap's value wins if declared first. Your
override has zero effect. Symptoms are confusing (your variable exists, nothing changes).

**Prevention:** The `_variables-override.scss` file is always imported before
`@import 'bootstrap/scss/bootstrap'`. Never reorder this.

### 2. Mixing `data-bs-theme="dark"` with SCSS overrides

**What goes wrong:** Bootstrap 5.3+ supports `data-bs-theme="dark"` on the `<html>` tag
which loads `_variables-dark.scss`. If you set this attribute AND override variables via
SCSS, you get conflicts where some components read the SCSS-compiled values and others
read the runtime CSS custom properties from Bootstrap's dark theme block.

**Prevention:** For this app — dark only, no toggle — do NOT set `data-bs-theme="dark"`.
Instead, compile a fully dark stylesheet via SCSS overrides. Bootstrap's built-in dark
mode is for toggle scenarios. Since we are dark-only, we want a compiled dark theme.

### 3. Inline `style=` attributes hardcoding colors in Slim templates

**What goes wrong:** The current codebase has multiple `style="width: 40px; height: 40px;
object-fit: cover;"` inline styles and avatar circles hardcoded with `bg-secondary`. Once
you have CSS tokens, these become stale and undermine the design system.

**Prevention:** Extract avatar display into the `_avatar.html.slim` partial with a CSS
class (`.avatar-circle`, `.avatar-img`). Sizing and colors live in `_avatar.scss`.

### 4. Building page templates before tokens exist

**What goes wrong:** You hardcode `background: #161b22` in a card on the dashboard. Then
you define `--color-bg-surface: #161b22` in tokens. Now you have two sources of truth for
the same value. Future color tweaks miss the hardcoded one.

**Prevention:** Build Phase 1 (tokens) and Phase 2 (layout) before touching any content
template. The first visible page built should be the dashboard, which can use tokens
throughout.

### 5. Separate stylesheet per page

**What goes wrong:** `leagues.scss`, `tournaments.scss` etc. lead to duplicated component
definitions, specificity wars, and a maintenance nightmare.

**Prevention:** Styles are organized by component, not by page. `_card.scss` covers cards
everywhere. A "league card" is just a card with standard slots — no separate file needed.

---

## Scalability Considerations

| Concern | Now (~20 templates) | If 50+ templates added |
|---|---|---|
| Token drift | Not a risk at this scale | Add a design token linting step |
| CSS bundle size | Single compiled file via Sass; fine | Consider PurgeCSS via PostCSS |
| Partial proliferation | 4-5 shared partials is manageable | Namespace under `shared/` strictly |
| Stimulus controllers | 2 controllers is very lean | Add per-feature, never globally |

---

## Sources

- Bootstrap 5 variable system: `node_modules/bootstrap/scss/_variables.scss` (confirmed in codebase)
- Bootstrap 5 dark mode variables: `node_modules/bootstrap/scss/_variables-dark.scss` (confirmed in codebase)
- Bootstrap 5 CSS custom property output: `node_modules/bootstrap/scss/_root.scss` (confirmed in codebase)
- Build pipeline: `package.json` — sass compile → postcss autoprefixer → Propshaft (confirmed)
- Existing view templates: confirmed by reading all 20 Slim files in `app/views/`
- Current stylesheet: `app/assets/stylesheets/application.bootstrap.scss` — single file, no overrides yet (confirmed)
- Stimulus setup: `app/javascript/controllers/` — only scaffold hello_controller present (confirmed)
- Linear.app design reference: per PROJECT.md explicit requirement

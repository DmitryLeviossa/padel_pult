# Technology Stack — Dark Theme Implementation

**Project:** Padel Pult UI Redesign (dark navy/slate + electric blue)
**Researched:** 2026-05-08
**Overall confidence:** HIGH (sourced from Bootstrap 5.3 official docs + direct codebase inspection)

---

## Recommended Approach

### Strategy: Bootstrap `data-bs-theme="dark"` + SCSS variable overrides + CSS custom property layer

The project already has everything needed. No new packages required. The approach is:

1. Override Bootstrap SCSS variables (before `@import`) to set custom primary color and dark palette.
2. Add `data-bs-theme="dark"` to the `<html>` element in the Slim layout.
3. Override the dark-mode CSS custom properties (inside `[data-bs-theme="dark"]`) for the navy/slate palette.
4. Define a project-level CSS variable layer (e.g., `--pp-*`) for design tokens above Bootstrap's layer.

This is the authoritative Bootstrap 5.3 pattern. It is not a workaround — it is the documented design.

---

## The Color System

### Palette (recommended values)

```scss
// Padel Pult design tokens — set these as CSS custom properties
// and map them into Bootstrap's variable system

// Background layers (navy/slate, darkest to lightest surface)
--pp-bg-base:       #0d1117;   // deepest background (page body)
--pp-bg-surface:    #161b22;   // cards, panels
--pp-bg-elevated:   #1c2433;   // dropdowns, modals, hover states
--pp-bg-subtle:     #21293a;   // table rows, list items

// Borders
--pp-border:        #30363d;   // default border
--pp-border-subtle: #21293a;   // subtle / hairline

// Text
--pp-text-primary:  #e6edf3;   // body text
--pp-text-secondary:#8b949e;   // muted / labels
--pp-text-tertiary: #484f58;   // placeholder / disabled

// Electric blue accent
--pp-accent:        #3b82f6;   // primary action (btn, link, active)
--pp-accent-hover:  #60a5fa;   // hover state
--pp-accent-subtle: #1e3a5f;   // subtle accent background

// Semantic
--pp-success:       #3fb950;
--pp-warning:       #d29922;
--pp-danger:        #f85149;
```

These token names (`--pp-*`) are project-owned and sit above Bootstrap's `--bs-*` layer. Components reference `--pp-*` directly or through Bootstrap mappings.

---

## SCSS File Structure

### Recommended layout for `app/assets/stylesheets/`

```
app/assets/stylesheets/
├── application.bootstrap.scss     # entry point — keep slim, just imports
├── _variables.scss                # Bootstrap SCSS variable overrides (step 1)
├── _theme.scss                    # --pp-* token definitions + [data-bs-theme="dark"] overrides
├── _typography.scss               # font stack, heading styles
├── _components.scss               # custom component styles (cards, badges, etc.)
└── _utilities.scss                # project utility classes
```

### Entry point (`application.bootstrap.scss`)

```scss
// Step 1: Bootstrap functions (required before any color manipulation)
@import 'bootstrap/scss/functions';

// Step 2: Project variable overrides (must come before bootstrap/scss/variables)
@import 'variables';

// Step 3: Bootstrap core
@import 'bootstrap/scss/variables';
@import 'bootstrap/scss/variables-dark';
@import 'bootstrap/scss/maps';
@import 'bootstrap/scss/mixins';
@import 'bootstrap/scss/root';

// Step 4: Bootstrap components
@import 'bootstrap/scss/utilities';
@import 'bootstrap/scss/reboot';
@import 'bootstrap/scss/type';
@import 'bootstrap/scss/containers';
@import 'bootstrap/scss/grid';
@import 'bootstrap/scss/helpers';
@import 'bootstrap/scss/utilities/api';
@import 'bootstrap/scss/buttons';
@import 'bootstrap/scss/nav';
@import 'bootstrap/scss/navbar';
@import 'bootstrap/scss/card';
@import 'bootstrap/scss/forms';
@import 'bootstrap/scss/modal';
@import 'bootstrap/scss/dropdown';
@import 'bootstrap/scss/badge';
@import 'bootstrap/scss/alert';
@import 'bootstrap/scss/tables';
@import 'bootstrap/scss/transitions';
@import 'bootstrap/scss/spinners';

// Step 5: Project theme layer (tokens + dark overrides)
@import 'theme';

// Step 6: Project components and utilities
@import 'typography';
@import 'components';
@import 'utilities';

// Step 7: Bootstrap Icons
@import 'bootstrap-icons/font/bootstrap-icons';
```

This replaces the current two-line `@import 'bootstrap/scss/bootstrap'`. The selective import is worth it: it lets the project-owned partial imports land in the right cascade position, and shaves ~15-20% of unused Bootstrap CSS (carousels, offcanvas, etc. can be omitted).

### `_variables.scss` — Bootstrap SCSS overrides

```scss
// Override Bootstrap's SCSS variables BEFORE bootstrap imports them.
// These affect compiled values, not just runtime CSS properties.

// Remap $primary to electric blue (affects btn-primary, focus rings, etc.)
$primary: #3b82f6;

// Remap $dark to the app's deepest background
$dark: #0d1117;

// Body defaults (overridden again at runtime by [data-bs-theme="dark"],
// but setting these ensures compiled fallbacks are correct)
$body-bg:    #0d1117;
$body-color: #e6edf3;

// Border radius — sharper, more Linear-like
$border-radius:    0.375rem;
$border-radius-sm: 0.25rem;
$border-radius-lg: 0.5rem;

// Typography — system font stack (no licensing required)
$font-family-sans-serif: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
$font-size-base: 0.9375rem;  // 15px, slightly tighter than Bootstrap's 16px
$headings-font-weight: 600;

// Transitions — snappier
$transition-base: all 0.15s ease-in-out;
```

### `_theme.scss` — CSS custom property layer + dark mode overrides

```scss
// Project design tokens — available everywhere as --pp-* variables
:root {
  --pp-bg-base:        #0d1117;
  --pp-bg-surface:     #161b22;
  --pp-bg-elevated:    #1c2433;
  --pp-bg-subtle:      #21293a;
  --pp-border:         #30363d;
  --pp-border-subtle:  #21293a;
  --pp-text-primary:   #e6edf3;
  --pp-text-secondary: #8b949e;
  --pp-text-tertiary:  #484f58;
  --pp-accent:         #3b82f6;
  --pp-accent-hover:   #60a5fa;
  --pp-accent-subtle:  #1e3a5f;
  --pp-success:        #3fb950;
  --pp-warning:        #d29922;
  --pp-danger:         #f85149;
}

// Override Bootstrap's dark mode CSS custom properties to use the navy/slate palette.
// Bootstrap's default dark mode uses gray-900 (#212529) — we replace with deeper navy.
[data-bs-theme="dark"] {
  color-scheme: dark;

  // Body
  --bs-body-bg:              var(--pp-bg-base);
  --bs-body-color:           var(--pp-text-primary);
  --bs-secondary-bg:         var(--pp-bg-surface);
  --bs-tertiary-bg:          var(--pp-bg-elevated);
  --bs-secondary-color:      var(--pp-text-secondary);
  --bs-tertiary-color:       var(--pp-text-tertiary);
  --bs-emphasis-color:       #ffffff;

  // Primary / accent
  --bs-primary:              var(--pp-accent);
  --bs-primary-rgb:          59, 130, 246;
  --bs-link-color:           var(--pp-accent);
  --bs-link-hover-color:     var(--pp-accent-hover);
  --bs-primary-bg-subtle:    var(--pp-accent-subtle);
  --bs-primary-border-subtle: #1d4ed8;
  --bs-primary-text-emphasis: var(--pp-accent-hover);

  // Borders
  --bs-border-color:         var(--pp-border);
  --bs-border-color-translucent: rgba(255, 255, 255, 0.08);

  // Component variables that components inherit
  --bs-card-bg:              var(--pp-bg-surface);
  --bs-card-border-color:    var(--pp-border);
  --bs-dropdown-bg:          var(--pp-bg-elevated);
  --bs-dropdown-border-color: var(--pp-border);
  --bs-modal-bg:             var(--pp-bg-surface);
  --bs-table-bg:             transparent;
  --bs-table-striped-bg:     rgba(255, 255, 255, 0.03);
  --bs-input-bg:             var(--pp-bg-surface);
  --bs-input-border-color:   var(--pp-border);
  --bs-input-color:          var(--pp-text-primary);
  --bs-input-placeholder-color: var(--pp-text-tertiary);
}
```

---

## Layout Change Required

The `<html>` tag in `app/views/layouts/application.html.slim` needs `data-bs-theme="dark"`. Without this, Bootstrap's dark mode CSS variable overrides never activate:

```slim
html data-bs-theme="dark"
  head
    ...
```

This is the single most important structural change. Everything else builds on it.

---

## Alternatives Considered and Why Not

### Option A: CSS-only override (no SCSS layer)
Only override `[data-bs-theme="dark"]` CSS variables, no SCSS variable changes. Works for colors, but `$primary` still compiles to Bootstrap's blue `#0d6efd` — meaning `.btn-primary` background, focus ring box shadows, and utility classes like `.bg-primary` are all the wrong color unless also overridden in CSS. The SCSS layer is simpler and more complete.

**Verdict: Do not use CSS-only. Use SCSS variable overrides + CSS layer together.**

### Option B: Force dark with `$color-mode-type: media-query`
Bootstrap can use `@media (prefers-color-scheme: dark)` instead of `data-bs-theme`. This would automatically match the system theme.

**Verdict: Do not use.** The PROJECT.md explicitly states "dark only for now" and "no dark/light mode toggle". Using `data-bs-theme` on `<html>` is simpler, more predictable, and eliminates the media query dependency. If a toggle is added later, it is trivial to implement with JS on the `data-bs-theme` attribute.

### Option C: Keep `@import 'bootstrap/scss/bootstrap'` monolith + add overrides after
The current single-import approach works but forces all overrides to be CSS-only (cannot inject SCSS variable overrides mid-file). This is the path of most resistance.

**Verdict: Replace with selective imports as shown above.**

### Option D: Add a gem (bootstrap-dark-5 or similar)
No gems exist that add meaningful value here. Bootstrap 5.3 has native dark mode support. A gem would add a dependency for functionality that is natively supported.

**Verdict: No additional gems needed.**

---

## Build Pipeline — No Changes Required

The existing build pipeline is correct for this approach:

```
Sass compiler (Node, yarn build:css)
  → reads app/assets/stylesheets/application.bootstrap.scss
  → resolves @imports from node_modules/ via --load-path=node_modules
  → outputs app/assets/builds/application.css
PostCSS + Autoprefixer
  → processes app/assets/builds/application.css
  → outputs app/assets/builds/application.css
Propshaft
  → fingerprints app/assets/builds/application.css
  → serves as application-[digest].css
```

Propshaft serves pre-built CSS from `app/assets/builds/` — it does not process SCSS itself. The Sass step happens in Node (yarn). This means:
- SCSS `@import` paths are resolved by Node's Sass, not Propshaft.
- `--load-path=node_modules` in the build script handles Bootstrap's `node_modules/bootstrap/scss/` imports.
- No `url()` path rewriting issues with Propshaft because Bootstrap Icons fonts are served from Propshaft's load path (configured in `config/initializers/assets.rb`).

**No changes to `package.json`, `Procfile.dev`, or `config/initializers/assets.rb` are required.**

---

## Typography

No font licensing is needed. The system font stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif`) is the Linear.app approach — it renders Inter on macOS/iOS and Segoe UI on Windows. This is the correct choice given the "no custom font licensing" constraint.

If Inter is desired explicitly (closer to Linear), Google Fonts `Inter` can be added via a `<link>` tag in the layout head — no licensing cost. Set `$font-family-sans-serif: 'Inter', system-ui, sans-serif` in `_variables.scss`.

---

## Confidence Assessment

| Decision | Confidence | Source |
|----------|------------|--------|
| `data-bs-theme="dark"` on `<html>` is correct approach | HIGH | Bootstrap 5.3 official docs |
| SCSS variable overrides before `@import` required for compiled values | HIGH | Bootstrap 5.3 official docs |
| Selective SCSS import order is safe | HIGH | Bootstrap 5.3 official docs |
| No new gems or packages needed | HIGH | Codebase inspection + Bootstrap docs |
| Propshaft serves pre-built CSS, no pipeline changes needed | HIGH | Codebase inspection (package.json, Procfile.dev, assets.rb) |
| Navy/slate color values for Linear-like aesthetic | MEDIUM | Design analysis; exact values should be validated visually |
| System font stack matches Linear.app | MEDIUM | Common knowledge; exact Linear font is Inter |

---

## What NOT to Do

- Do not add `data-bs-theme` to the `<body>` — put it on `<html>` so `color-scheme: dark` applies to browser chrome (scrollbars, inputs) as well.
- Do not override Bootstrap colors only in CSS without touching SCSS variables — compiled utility classes (`.bg-primary`, `.btn-primary`, focus rings) will still use Bootstrap's default `#0d6efd` blue.
- Do not use `.navbar-dark` class — it is deprecated in Bootstrap 5.3. Use `data-bs-theme="dark"` on the navbar element instead.
- Do not define colors as raw hex values in component classes — always go through `--pp-*` tokens so a future palette change is a one-file edit.
- Do not put custom styles in `application.bootstrap.scss` directly — keep it as a pure import manifest. Put custom rules in their own partials.
- Do not use `!important` to override Bootstrap — if you find yourself needing `!important`, the import order or specificity is wrong.

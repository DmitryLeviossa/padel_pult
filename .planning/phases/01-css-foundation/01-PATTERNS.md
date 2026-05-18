# Phase 1: CSS Foundation - Pattern Map

**Mapped:** 2026-05-09
**Files analyzed:** 7
**Analogs found:** 2 / 7 (5 new files with no in-project analog — patterns sourced from verified Bootstrap source and RESEARCH.md)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `app/assets/stylesheets/application.bootstrap.scss` | config / entry-point | transform (build pipeline) | `node_modules/bootstrap/scss/bootstrap.scss` | structural-match (import manifest pattern) |
| `app/assets/stylesheets/_variables.scss` | config | transform (compile-time injection) | `node_modules/bootstrap/scss/_variables.scss` | structural-match (variable definitions with `!default`) |
| `app/assets/stylesheets/_theme.scss` | config | transform (CSS custom properties) | `node_modules/bootstrap/scss/_root.scss` | structural-match (`:root` + `[data-bs-theme]` blocks) |
| `app/assets/stylesheets/_spacing.scss` | config | transform (CSS custom properties) | none — no existing token file | no analog |
| `app/assets/stylesheets/_typography.scss` | config | transform (CSS cascade override) | none — no existing typography partial | no analog |
| `app/views/layouts/application.html.slim` | view / layout | request-response | `app/views/layouts/application.html.slim` (self — modify) | exact (single attribute addition) |
| `package.json` | config | build pipeline | `package.json` (self — modify) | exact (single flag addition) |

---

## Pattern Assignments

### `app/assets/stylesheets/application.bootstrap.scss` (config, entry-point)

**Operation:** Rewrite (currently 2 lines — full replacement)

**Current state** (`app/assets/stylesheets/application.bootstrap.scss`, lines 1–2):
```scss
@import 'bootstrap/scss/bootstrap';
@import 'bootstrap-icons/font/bootstrap-icons';
```

**Analog:** `node_modules/bootstrap/scss/bootstrap.scss` — shows the canonical partial import order. The project entry point replicates this order with our `_variables.scss` injected after `functions` and before `variables`.

**Core pattern — full import manifest** (verified against Bootstrap 5.3.8, documented in RESEARCH.md Pattern 3):
```scss
// application.bootstrap.scss
// Pure import manifest — no CSS rules in this file.

// 1. Bootstrap infrastructure (must precede all variable and mixin use)
@import 'bootstrap/scss/functions';

// 2. Project SCSS variable overrides (MUST come before bootstrap/scss/variables
//    because Bootstrap uses !default — pre-defined values win)
@import 'variables';

// 3. Bootstrap configuration chain (order is mandatory — each depends on prior)
@import 'bootstrap/scss/variables';
@import 'bootstrap/scss/variables-dark';
@import 'bootstrap/scss/maps';
@import 'bootstrap/scss/mixins';
@import 'bootstrap/scss/utilities';

// 4. Bootstrap layout and component partials (selective — omitting unused ones)
@import 'bootstrap/scss/root';
@import 'bootstrap/scss/reboot';
@import 'bootstrap/scss/type';
@import 'bootstrap/scss/containers';
@import 'bootstrap/scss/grid';
@import 'bootstrap/scss/tables';
@import 'bootstrap/scss/forms';
@import 'bootstrap/scss/buttons';
@import 'bootstrap/scss/transitions';
@import 'bootstrap/scss/dropdown';
@import 'bootstrap/scss/nav';
@import 'bootstrap/scss/navbar';
@import 'bootstrap/scss/card';
@import 'bootstrap/scss/badge';
@import 'bootstrap/scss/alert';
@import 'bootstrap/scss/modal';
@import 'bootstrap/scss/spinners';
@import 'bootstrap/scss/helpers';
@import 'bootstrap/scss/utilities/api';

// 5. Project design tokens (MUST come after Bootstrap — our vars override --bs-* cascade)
@import 'theme';
@import 'spacing';
@import 'typography';

// 6. Icon font (always last)
@import 'bootstrap-icons/font/bootstrap-icons';
```

**Critical ordering rule:** `@import 'variables'` MUST appear after `bootstrap/scss/functions` and BEFORE `bootstrap/scss/variables`. If reversed, Bootstrap's `!default` variables are already set and project overrides are silently ignored. Verified in Bootstrap 5.3.8 `_variables.scss` source.

---

### `app/assets/stylesheets/_variables.scss` (config, compile-time injection)

**Operation:** New file

**Analog:** `node_modules/bootstrap/scss/_variables.scss` — all Bootstrap variables use `!default`, meaning any value pre-defined in this file takes precedence. Our file defines variables without `!default` so they are unconditional.

**Core pattern** (sourced from RESEARCH.md Pattern 1 + UI-SPEC.md Bootstrap Variable Mapping table):
```scss
// _variables.scss
// Bootstrap SCSS variable overrides.
// Imported after bootstrap/scss/functions, before bootstrap/scss/variables.
// No !default — these are unconditional project values.

// Color palette
$primary:          #2f81f7;
$body-bg:          #0d1117;
$body-color:       #e6edf3;
$border-color:     #30363d;
$dark:             #21262d;

// Shape
$border-radius:    0.375rem;
$border-radius-sm: 0.25rem;
$border-radius-lg: 0.5rem;

// Typography
$font-family-sans-serif: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
$font-size-base:   0.9375rem;
$headings-font-weight: 600;
$small-font-size:  0.875em;
$link-decoration:  none;

// Motion
$transition-base:  all 0.15s ease-in-out;
```

**Font propagation note:** Bootstrap's `_root.scss` sets `--bs-body-font-family: #{inspect($font-family-sans-serif)}`. This means overriding `$font-family-sans-serif` here automatically propagates Inter into Bootstrap's CSS custom property, which `_reboot.scss` applies to `<body>`. No additional CSS needed in `_typography.scss` for the font-family itself.

---

### `app/assets/stylesheets/_theme.scss` (config, CSS custom properties)

**Operation:** New file

**Analog:** `node_modules/bootstrap/scss/_root.scss` — defines `:root { --bs-* }` and `[data-bs-theme="dark"] { --bs-* }`. Our `_theme.scss` follows the same two-block structure but defines our semantic `--color-*` tokens in `:root` and then overrides Bootstrap's `--bs-*` variables inside `[data-bs-theme="dark"]`.

**Critical cascade rule:** `_theme.scss` MUST be imported after all Bootstrap component partials. Bootstrap's `_root.scss` emits its own `[data-bs-theme="dark"]` block; our block must come later in the cascade to win.

**Core pattern** (sourced from RESEARCH.md Pattern 2 + UI-SPEC.md Color Tokens + Bootstrap Dark Mode tables):
```scss
// _theme.scss
// Imported after all Bootstrap partials, before spacing and typography.
// Block 1: Project semantic color tokens on :root
// Block 2: Bootstrap dark mode variable overrides inside [data-bs-theme="dark"]

:root {
  // Locked decisions D-01 through D-07
  --color-bg-base:          #0d1117;
  --color-bg-navbar:        #161b22;
  --color-bg-surface:       #21262d;
  --color-text-primary:     #e6edf3;
  --color-text-muted:       #8b949e;
  --color-border:           #30363d;
  --color-accent:           #2f81f7;

  // Extended semantic tokens (Bootstrap dark mode mapping + Phase 3+ components)
  --color-text-placeholder: #484f58;
  --color-accent-hover:     #4d94f8;
  --color-accent-subtle:    #0d2340;
  --color-success:          #3fb950;
  --color-warning:          #d29922;
  --color-danger:           #f85149;
}

[data-bs-theme="dark"] {
  --bs-body-bg:                  var(--color-bg-base);
  --bs-body-color:               var(--color-text-primary);
  --bs-secondary-bg:             var(--color-bg-surface);
  --bs-secondary-color:          var(--color-text-muted);
  --bs-emphasis-color:           #ffffff;
  --bs-primary:                  var(--color-accent);
  --bs-primary-rgb:              47, 129, 247;
  --bs-link-color:               var(--color-accent);
  --bs-link-hover-color:         var(--color-accent-hover);
  --bs-border-color:             var(--color-border);
  --bs-card-bg:                  var(--color-bg-surface);
  --bs-card-border-color:        var(--color-border);
  --bs-dropdown-bg:              var(--color-bg-surface);
  --bs-modal-bg:                 var(--color-bg-surface);
  --bs-input-bg:                 var(--color-bg-surface);
  --bs-input-border-color:       var(--color-border);
  --bs-input-color:              var(--color-text-primary);
  --bs-input-placeholder-color:  var(--color-text-placeholder);
}
```

---

### `app/assets/stylesheets/_spacing.scss` (config, CSS custom properties)

**Operation:** New file

**Analog:** None in project. Pattern sourced from UI-SPEC.md Spacing Scale table and RESEARCH.md code example (verified against Bootstrap's spacing scale base unit).

**Core pattern** (sourced from UI-SPEC.md Spacing Scale + RESEARCH.md spacing token example):
```scss
// _spacing.scss
// Spacing tokens as CSS custom properties.
// Follows a 0.25rem (4px) base unit — matches Bootstrap's $spacer scale.
// Available globally for all phases.

:root {
  --space-1:  0.25rem;   // 4px  — icon gaps, inline micro-padding
  --space-2:  0.5rem;    // 8px  — compact element spacing, badge padding
  --space-3:  0.75rem;   // 12px — tight list item padding
  --space-4:  1rem;      // 16px — default element spacing (base unit)
  --space-5:  1.25rem;   // 20px — form field spacing
  --space-6:  1.5rem;    // 24px — section padding, card body
  --space-7:  1.75rem;   // 28px — large card padding
  --space-8:  2rem;      // 32px — layout gaps, major section breaks

  // Extended page-level tokens
  --space-12: 3rem;      // 48px — major section breaks
  --space-16: 4rem;      // 64px — page-level vertical rhythm
}
```

---

### `app/assets/stylesheets/_typography.scss` (config, CSS cascade override)

**Operation:** New file

**Analog:** None in project. Pattern sourced from RESEARCH.md Typography override example and UI-SPEC.md Typography table.

**Scope note:** Font family, heading weights, and font sizes are handled at compile time via `$font-family-sans-serif`, `$headings-font-weight`, and `$font-size-base` in `_variables.scss`. The `_typography.scss` partial handles only what cannot be expressed as Bootstrap SCSS variables: link decoration behavior and any direct element overrides.

**Core pattern** (sourced from RESEARCH.md code example + UI-SPEC.md Typography — Link color section):
```scss
// _typography.scss
// Handles link behavior and any element overrides not covered by Bootstrap $variables.
// Font family and heading weights flow through _variables.scss (compile-time).

// Link decoration override for dark surfaces
// Bootstrap default is underline; dark surfaces use color alone as the affordance.
a {
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
}
```

---

### `app/views/layouts/application.html.slim` (view/layout, request-response)

**Operation:** Modify — add `data-bs-theme="dark"` to `html` element; add Google Fonts `<link>` tags to `<head>`.

**Current state** (`app/views/layouts/application.html.slim`, lines 1–3):
```slim
doctype html
html
  head
```

**Analog:** `app/views/layouts/application.html.slim` itself (self-modification). Pattern for `<link>` tags follows the existing icon link pattern at lines 16–18.

**Existing `<link>` tag pattern** (lines 16–18 — copy this Slim syntax):
```slim
link rel="icon" href="/icon.png" type="image/png"
link rel="icon" href="/icon.svg" type="image/svg+xml"
link rel="apple-touch-icon" href="/icon.png"
```

**Changes required:**

Change 1 — `html` line (line 2): add `data-bs-theme="dark"` attribute:
```slim
html data-bs-theme="dark"
```

Change 2 — Insert Google Fonts preconnect and stylesheet links inside `head`, before `stylesheet_link_tag` (line 21). Insert after `csp_meta_tag` block and before `yield :head`:
```slim
    link rel="preconnect" href="https://fonts.googleapis.com"
    link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"
    link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"
```

**Turbo compatibility note:** Turbo Drive preserves `<head>` content across navigations. The font loads once and persists. Verified: `stylesheet_link_tag` already uses `data-turbo-track: "reload"` (line 21).

---

### `package.json` (config, build pipeline)

**Operation:** Modify — add `--silence-deprecation=import,color-functions` flag to `build:css:compile` script.

**Current state** (`package.json`, line 5):
```json
"build:css:compile": "sass ./app/assets/stylesheets/application.bootstrap.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules",
```

**Target state** (add flag at end, before closing quote):
```json
"build:css:compile": "sass ./app/assets/stylesheets/application.bootstrap.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules --silence-deprecation=import,color-functions",
```

**Rationale:** Bootstrap 5.3.8 uses `@import` and legacy color functions. Dart Sass 1.99.0 emits 312+ deprecation warnings per build, obscuring real errors. This flag suppresses known-safe deprecations without changing compilation behavior. Verified: `sass --help` confirms `--silence-deprecation` exists in 1.99.0.

---

## Shared Patterns

### CSS Custom Property Declaration Block
**Apply to:** `_theme.scss`, `_spacing.scss`
**Pattern:** All project tokens are declared on `:root {}` as a flat list with inline comments. One token per line. Group related tokens with a blank line between groups.

```scss
:root {
  --token-name: value;  // px equivalent — semantic description
}
```

### Slim Attribute Syntax
**Source:** `app/views/layouts/application.html.slim`, line 2 (html element), lines 16–18 (link tags)
**Apply to:** `application.html.slim` modifications
**Pattern:** HTML attributes in Slim follow `element attr="value"` inline syntax. Multiple attributes on same line separated by spaces. Boolean attributes use `attribute="value"` not shorthand.

```slim
html data-bs-theme="dark"
link rel="preconnect" href="https://fonts.googleapis.com"
```

### No Rules in Entry Point
**Apply to:** `application.bootstrap.scss`
**Pattern:** The entry point file contains only `@import` statements and comments. Zero CSS rules. All rules live in partials. This is the Bootstrap convention verified in `node_modules/bootstrap/scss/bootstrap.scss`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `app/assets/stylesheets/_spacing.scss` | config | transform | No CSS token files exist in this project yet; pattern from UI-SPEC.md + RESEARCH.md |
| `app/assets/stylesheets/_typography.scss` | config | transform | No typography partials exist; pattern from RESEARCH.md code example |
| `app/assets/stylesheets/_variables.scss` | config | build transform | No SCSS override files exist; pattern from Bootstrap `!default` variable system |
| `app/assets/stylesheets/_theme.scss` | config | transform | No CSS custom property files exist; pattern from Bootstrap `_root.scss` structure |
| `app/assets/stylesheets/application.bootstrap.scss` | config | build transform | Existing 2-line file is replaced wholesale; import order pattern from `node_modules/bootstrap/scss/bootstrap.scss` |

---

## Metadata

**Analog search scope:** `app/assets/stylesheets/`, `app/views/layouts/`, `node_modules/bootstrap/scss/`
**Files scanned:** 7 project files + Bootstrap source (functions, variables, variables-dark, maps, mixins, root, bootstrap.scss)
**Pattern extraction date:** 2026-05-09
**Bootstrap version verified:** 5.3.8 (node_modules/bootstrap/package.json)
**Sass version verified:** 1.99.0

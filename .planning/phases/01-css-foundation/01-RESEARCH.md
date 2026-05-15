# Phase 1: CSS Foundation - Research

**Researched:** 2026-05-09
**Domain:** Bootstrap 5 SCSS override pipeline, CSS custom properties, typography (Google Fonts), Dart Sass 1.99
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `--color-bg-base: #0d1117`
- **D-02:** `--color-bg-navbar: #161b22`
- **D-03:** `--color-bg-surface: #21262d`
- **D-04:** `--color-text-primary: #e6edf3`
- **D-05:** `--color-text-muted: #8b949e`
- **D-06:** `--color-border: #30363d`
- **D-07:** `--color-accent: #2f81f7`
- Bootstrap SCSS variables must be overridden before `@import 'bootstrap/scss/...'`
- Variable mapping: `$body-bg → #0d1117`, `$body-color → #e6edf3`, `$border-color → #30363d`, `$primary → #2f81f7`, `$dark → #21262d`

### Claude's Discretion
- Font loading: Inter via Google Fonts or system font stack
- Spacing scale values (`--space-1` through `--space-8`)
- SCSS file structure (single file vs. partials)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CSST-01 | Color token system as CSS custom properties (`--color-*`) over Bootstrap's `--bs-*` variables | Color token patterns documented; `[data-bs-theme="dark"]` override approach verified in Bootstrap source |
| CSST-02 | Bootstrap SCSS entry point rewritten with selective partial imports and `$variable` overrides before `@import` | Import order confirmed from Bootstrap 5.3.8 source; selective partial list verified against installed files |
| CSST-03 | Typography system — font stack, heading weights/sizes, body text sizing for dark legibility | Google Fonts `<link>` approach, Bootstrap font variables, and no-underline link override documented |
| CSST-04 | Spacing/layout tokens as CSS custom properties — consistent scale | `--space-{1..8}` scale at `0.25rem` base documented; extended tokens documented |
</phase_requirements>

---

## Summary

Phase 1 is a pure CSS pipeline task: rewrite `application.bootstrap.scss` from 2 lines into a proper SCSS architecture with variable overrides, selective imports, and design token partials. All decisions are already locked in CONTEXT.md and the approved UI-SPEC.md — research reveals no ambiguities that require user input.

The installed Bootstrap version is **5.3.8** (not 5.3.3 as referenced in context — yarn resolved to latest patch). Bootstrap 5.3.8 still uses `@import` throughout its SCSS, but the installed Dart Sass version (1.99.0) emits 312+ deprecation warnings when compiling Bootstrap. The build currently succeeds but is noisy. The plan must address silencing these warnings in `package.json`'s build script via `--silence-deprecation=import,color-functions` flags.

Bootstrap's dark mode works by setting `data-bs-theme="dark"` on `<html>`, which triggers CSS variable overrides in `_root.scss` via the `color-mode(dark, true)` mixin. Our custom `_theme.scss` partial — placed **after** Bootstrap imports — overrides those `--bs-*` variables again with our exact palette tokens. This layering approach is correct and verified in the Bootstrap source. No CSP is active in this app, so Google Fonts loads without any configuration changes.

**Primary recommendation:** Follow the 4-partial SCSS structure from UI-SPEC.md verbatim (`_variables.scss`, `_theme.scss`, `_spacing.scss`, `_typography.scss`). Add `--silence-deprecation=import,color-functions` to the sass compile command in `package.json`. Add `data-bs-theme="dark"` to the `<html>` tag in `application.html.slim`. That is the complete Phase 1 scope.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS custom property tokens (`--color-*`, `--space-*`) | Static CSS | — | Plain CSS variables, no server logic needed |
| Bootstrap SCSS `$variable` overrides | Build pipeline (Sass CLI) | — | Compile-time injection before Bootstrap's own variables |
| Bootstrap dark mode activation (`data-bs-theme="dark"`) | Frontend Server (SSR) | — | Set on `<html>` in `application.html.slim`; propagates to all rendered pages |
| Inter font loading | Browser / Client | Frontend Server | `<link>` preconnect + stylesheet in `<head>` of layout; browser fetches from Google CDN |
| CSS build pipeline | Build tooling (yarn/sass/postcss) | — | `yarn build:css` compiles SCSS → CSS → autoprefixer; no Rails involvement |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bootstrap SCSS | 5.3.8 [VERIFIED: node_modules/bootstrap/package.json] | Component styles and utility generation | Already installed; phase overrides it, does not replace it |
| Dart Sass CLI | 1.99.0 [VERIFIED: node_modules/.bin/sass --version] | SCSS compilation | Already in package.json devDependencies; runs as `yarn build:css:compile` |
| PostCSS + autoprefixer | 8.4.38 / 10.4.19 [VERIFIED: package.json] | Vendor prefix injection | Already in build pipeline |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bootstrap Icons | 1.11.3 [VERIFIED: package.json] | Icon font | Already imported at end of scss entry point; keep as last import |
| Google Fonts (Inter) | CDN [ASSUMED] | Inter 400/600 weights | Loaded via `<link>` in layout `<head>` — not an npm package |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Google Fonts `<link>` | Self-hosted Inter via npm/fontsource | Self-hosting eliminates external dependency and privacy concern; Google Fonts is simpler and works here since CSP is inactive |
| `--silence-deprecation` flag | Downgrade to Sass 1.76 | Downgrade creates more risk; silencing is the correct short-term approach until Bootstrap 6 migrates to `@use` |

**Installation:** No new packages required. Phase 1 uses only what is already installed.

---

## Architecture Patterns

### System Architecture Diagram

```
yarn build:css
    │
    ▼
sass CLI (1.99.0)
    │  --load-path=node_modules
    │  --silence-deprecation=import,color-functions
    │
    ▼
application.bootstrap.scss (entry point — import manifest only)
    │
    ├── @import 'bootstrap/scss/functions'
    ├── @import 'variables'              ← _variables.scss (our $overrides BEFORE Bootstrap)
    ├── @import 'bootstrap/scss/variables'
    ├── @import 'bootstrap/scss/variables-dark'
    ├── @import 'bootstrap/scss/maps'
    ├── @import 'bootstrap/scss/mixins'
    ├── @import 'bootstrap/scss/utilities'
    ├── @import 'bootstrap/scss/root'    ← emits :root { --bs-* } and [data-bs-theme="dark"] { --bs-* }
    ├── [selective Bootstrap component imports]
    ├── @import 'theme'                  ← _theme.scss overrides --bs-* vars with our --color-* values
    ├── @import 'spacing'               ← _spacing.scss defines --space-* tokens
    ├── @import 'typography'            ← _typography.scss font-family, heading, link overrides
    └── @import 'bootstrap-icons/font/bootstrap-icons'
    │
    ▼
app/assets/builds/application.css (compiled output)
    │
    ▼
PostCSS autoprefixer (adds vendor prefixes)
    │
    ▼
app/assets/builds/application.css (final — Propshaft serves this)


Browser rendering:
    <html data-bs-theme="dark">   ← set in application.html.slim (activates Bootstrap dark vars)
        <head>
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
            <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
            <link rel="stylesheet" href="/assets/application.css">   ← Propshaft-served
```

### Recommended Project Structure

```
app/assets/stylesheets/
├── application.bootstrap.scss   # Pure import manifest — no CSS rules
├── _variables.scss              # Bootstrap $variable overrides (before bootstrap imports)
├── _theme.scss                  # :root { --color-* } + [data-bs-theme="dark"] { --bs-* overrides }
├── _spacing.scss                # :root { --space-* } spacing tokens
└── _typography.scss             # font-family on body, heading weight/size, link styles
```

### Pattern 1: Bootstrap SCSS Variable Override (Compile-Time Injection)

**What:** Set project SCSS variables before Bootstrap's own `_variables.scss` runs. Bootstrap uses `!default` on every variable, meaning any variable already defined takes precedence.

**When to use:** When you need Bootstrap's generated classes (`.btn-primary`, `.bg-dark`, `.border`) to use project colors automatically — no extra CSS needed.

**Example:**
```scss
// Source: Bootstrap 5.3.8 _variables.scss — all vars use !default
// _variables.scss (our file, imported BEFORE bootstrap/scss/variables)

$primary:          #2f81f7;
$body-bg:          #0d1117;
$body-color:       #e6edf3;
$border-color:     #30363d;
$dark:             #21262d;
$border-radius:    0.375rem;
$border-radius-sm: 0.25rem;
$border-radius-lg: 0.5rem;
$headings-font-weight: 600;
$font-size-base:   0.9375rem;
$transition-base:  all 0.15s ease-in-out;
$font-family-sans-serif: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
$link-decoration:  none;  // no underline on dark surfaces
```

### Pattern 2: CSS Custom Property Token Layer + Bootstrap Dark Mode

**What:** Define project `--color-*` tokens in `:root`, then override Bootstrap's `--bs-*` runtime variables inside `[data-bs-theme="dark"]` to point at the project tokens. This creates a two-layer token system: our semantic tokens are the source of truth; Bootstrap's vars reference ours.

**When to use:** After all Bootstrap imports, so our overrides win the cascade.

**How Bootstrap's dark mode works (verified in source):**
Bootstrap's `_root.scss` emits `[data-bs-theme="dark"]` via `@include color-mode(dark, true)`. This block resets `--bs-body-color`, `--bs-body-bg`, `--bs-border-color`, etc. to Bootstrap's dark palette defaults. Our `_theme.scss` then overrides these again with our exact token values. Because `_theme.scss` is imported after all Bootstrap partials, our values win.

**Example:**
```scss
// Source: Derived from Bootstrap 5.3.8 _root.scss dark mode pattern
// _theme.scss

:root {
  --color-bg-base:         #0d1117;
  --color-bg-navbar:       #161b22;
  --color-bg-surface:      #21262d;
  --color-text-primary:    #e6edf3;
  --color-text-muted:      #8b949e;
  --color-border:          #30363d;
  --color-accent:          #2f81f7;
  --color-text-placeholder: #484f58;
  --color-accent-hover:    #4d94f8;
  --color-accent-subtle:   #0d2340;
  --color-success:         #3fb950;
  --color-warning:         #d29922;
  --color-danger:          #f85149;
}

[data-bs-theme="dark"] {
  --bs-body-bg:              var(--color-bg-base);
  --bs-body-color:           var(--color-text-primary);
  --bs-secondary-bg:         var(--color-bg-surface);
  --bs-secondary-color:      var(--color-text-muted);
  --bs-emphasis-color:       #ffffff;
  --bs-primary:              var(--color-accent);
  --bs-primary-rgb:          47, 129, 247;
  --bs-link-color:           var(--color-accent);
  --bs-link-hover-color:     var(--color-accent-hover);
  --bs-border-color:         var(--color-border);
  --bs-card-bg:              var(--color-bg-surface);
  --bs-card-border-color:    var(--color-border);
  --bs-dropdown-bg:          var(--color-bg-surface);
  --bs-modal-bg:             var(--color-bg-surface);
  --bs-input-bg:             var(--color-bg-surface);
  --bs-input-border-color:   var(--color-border);
  --bs-input-color:          var(--color-text-primary);
  --bs-input-placeholder-color: var(--color-text-placeholder);
}
```

### Pattern 3: Selective Bootstrap Partial Imports

**What:** Import only the Bootstrap partials the app uses, skipping unused ones (accordion, carousel, breadcrumb, pagination, list-group, close, toasts, tooltip, popover, offcanvas, placeholders, images). This reduces compiled CSS output size.

**Critical import order** (verified against Bootstrap 5.3.8 `bootstrap.scss`):
```scss
// application.bootstrap.scss

// 1. Bootstrap infrastructure (must precede everything)
@import 'bootstrap/scss/functions';

// 2. Our variable overrides (before Bootstrap reads its variables)
@import 'variables';

// 3. Bootstrap configuration chain (order is mandatory)
@import 'bootstrap/scss/variables';
@import 'bootstrap/scss/variables-dark';
@import 'bootstrap/scss/maps';
@import 'bootstrap/scss/mixins';
@import 'bootstrap/scss/utilities';

// 4. Bootstrap layout and components
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

// 5. Project design tokens (after Bootstrap — our vars override Bootstrap's)
@import 'theme';
@import 'spacing';
@import 'typography';

// 6. Icon font (last)
@import 'bootstrap-icons/font/bootstrap-icons';
```

### Pattern 4: Google Fonts Preconnect + Preload in Slim Layout

**What:** Load Inter 400/600 weights via Google Fonts CDN with `rel="preconnect"` to reduce latency. Font goes in the `<head>` of `application.html.slim`, before the stylesheet link.

**Example:**
```slim
/ application.html.slim — inside <head>, before stylesheet_link_tag
link rel="preconnect" href="https://fonts.googleapis.com"
link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"
link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"
```

Note: Turbo Drive preserves `<head>` content across page navigations, so the font loads once and persists throughout the session. [VERIFIED: application.html.slim uses `data-turbo-track: "reload"` on stylesheet — Turbo correctly handles this]

### Pattern 5: Silence Dart Sass Deprecation Warnings

**What:** Bootstrap 5.3.8 still uses `@import` and legacy color functions. Dart Sass 1.77+ emits deprecation warnings for these; 1.99 emits 312+ warnings per build, making the output unreadable.

**Fix:** Add `--silence-deprecation=import,color-functions` to the sass compile command in `package.json`.

**Example:**
```json
"build:css:compile": "sass ./app/assets/stylesheets/application.bootstrap.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules --silence-deprecation=import,color-functions"
```

This is safe: it does not change compilation behavior, only suppresses expected warnings until Bootstrap 6 migrates to the `@use` module system. [VERIFIED: `sass --help` confirms `--silence-deprecation` flag exists in 1.99.0]

### Anti-Patterns to Avoid

- **Importing `bootstrap/scss/bootstrap` as a monolith:** Prevents variable injection. Bootstrap's `bootstrap.scss` defines functions + variables + maps + mixins + all partials in a single chain — you cannot inject your `_variables.scss` into the middle of it. Must use selective imports.
- **Placing `@import 'variables'` after `@import 'bootstrap/scss/variables'`:** All Bootstrap variables use `!default`, so if Bootstrap reads its variables first, your overrides are silently ignored. Order is critical.
- **Placing `_theme.scss` before Bootstrap imports:** The `--bs-*` variable overrides in `[data-bs-theme="dark"]` must come after Bootstrap's `_root.scss` generates its dark block, or the specificity cascade will be wrong.
- **Omitting `data-bs-theme="dark"` from `<html>`:** Without this attribute, Bootstrap's dark mode CSS block never activates regardless of `_theme.scss` overrides. The `_root.scss` source confirms the attribute is required.
- **Using `@use` instead of `@import` for Bootstrap partials:** Bootstrap 5.x SCSS is not structured for the `@use` module system. Using `@use` would break variable forwarding across partials. Stay on `@import` until Bootstrap 6.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark mode variable switching | Custom JavaScript toggle logic | `data-bs-theme="dark"` on `<html>` | Bootstrap's `color-mode()` mixin already handles all `--bs-*` variable switching; zero JS needed for dark-only design |
| Utility class generation | Custom `@each` loops over color maps | Bootstrap's `utilities/api` import | Bootstrap already generates `.text-*`, `.bg-*`, `.border-*` utilities from the theme color maps |
| Focus ring styles | Custom `:focus` CSS | Bootstrap's `$focus-ring-*` variables | `$focus-ring-color` defaults to `rgba($primary, 0.25)` — overriding `$primary` automatically gives accent-colored focus rings |
| Vendor prefixes | Manual `-webkit-`, `-moz-` properties | autoprefixer (already in pipeline) | Already in the PostCSS pipeline; just write standard CSS |

**Key insight:** This phase is almost entirely configuration of existing tools. The only hand-written CSS is the token definitions — everything else flows from Bootstrap's variable system.

---

## Common Pitfalls

### Pitfall 1: Variable Override Order

**What goes wrong:** Custom `$variable` overrides are silently ignored — Bootstrap uses default values.
**Why it happens:** Bootstrap variables use `!default`, meaning they are only set if not already defined. If `_variables.scss` is imported after `bootstrap/scss/variables`, Bootstrap has already set everything.
**How to avoid:** Import `_variables.scss` before `bootstrap/scss/variables`, and after `bootstrap/scss/functions` (functions must come first so color manipulation works).
**Warning signs:** `$primary` colors showing Bootstrap's default blue (`#0d6efd`) instead of `#2f81f7` in compiled output.

### Pitfall 2: Dart Sass 1.99 Deprecation Warnings Obscuring Real Errors

**What goes wrong:** 312+ deprecation warnings flood the build output; a real SCSS syntax error is hidden in the noise.
**Why it happens:** Bootstrap 5.3.8 uses `@import` and legacy `red()`/`green()`/`blue()` color functions — both deprecated in Dart Sass 1.77+. The current build emits these warnings even with a valid build. [VERIFIED: `yarn build:css` tested and confirmed 312 warnings]
**How to avoid:** Add `--silence-deprecation=import,color-functions` to `build:css:compile` in `package.json`.
**Warning signs:** Output shows "312 repetitive deprecation warnings omitted" after every build.

### Pitfall 3: `[data-bs-theme="dark"]` Not Activating

**What goes wrong:** Page renders with light Bootstrap defaults despite all SCSS work.
**Why it happens:** Bootstrap's dark mode in 5.3+ requires `data-bs-theme="dark"` on an ancestor element (typically `<html>`). Without it, Bootstrap's dark variable block in `_root.scss` never activates.
**How to avoid:** Set `html data-bs-theme="dark"` in `application.html.slim`. This is a Slim template change, not a CSS file change.
**Warning signs:** Background shows Bootstrap's default `#212529` (gray-900) instead of `#0d1117`; body text is dark-on-light.

### Pitfall 4: `--bs-*` Variable Overrides Not Applied to Components

**What goes wrong:** Components like cards, modals, or dropdowns still show Bootstrap's default dark colors (grays), not our palette.
**Why it happens:** Bootstrap's `[data-bs-theme="dark"]` block in `_root.scss` sets `--bs-body-bg`, `--bs-body-color`, etc. to Bootstrap defaults. Our `_theme.scss` must override these with our palette values. If `_theme.scss` is placed before Bootstrap imports, the cascade is wrong — Bootstrap's dark block overrides ours.
**How to avoid:** Import `theme`, `spacing`, and `typography` after ALL Bootstrap component imports.
**Warning signs:** Cards showing `#212529` instead of `#21262d`; links showing `#6ea8fe` (Bootstrap's tinted primary) instead of `#2f81f7`.

### Pitfall 5: Google Fonts `@import` Inside SCSS

**What goes wrong:** Putting a Google Fonts `@import` statement inside a `.scss` file works but is slower (browser must first download, parse, and then find the `@import`).
**Why it happens:** Developers put font imports in CSS for simplicity.
**How to avoid:** Use `<link rel="stylesheet">` tags directly in `application.html.slim` `<head>`. This allows the browser to preload the font in parallel with the stylesheet. Add `rel="preconnect"` tags for `fonts.googleapis.com` and `fonts.gstatic.com` to eliminate DNS/TLS handshake latency.
**Warning signs:** Inter font not appearing on first page load; brief flash of system font on load.

### Pitfall 6: `$font-family-sans-serif` Override Not Propagating to `--bs-body-font-family`

**What goes wrong:** Inter is set in `$font-family-sans-serif` in `_variables.scss` but rendered pages still show the system font.
**Why it happens:** Bootstrap's `_root.scss` sets `--bs-body-font-family: #{inspect($font-family-sans-serif)}` and `<body>` in `_reboot.scss` uses `font-family: var(--bs-body-font-family)`. If the variable override precedes Bootstrap's variable compilation correctly, the CSS custom property will include Inter. But `inspect()` wraps the value in quotes — the output will be: `--bs-body-font-family: 'Inter', -apple-system, ...` which is correct.
**How to avoid:** Verify via DevTools that `--bs-body-font-family` on `:root` starts with `'Inter'`.
**Warning signs:** DevTools shows `--bs-body-font-family` starting with `system-ui` or `-apple-system`.

---

## Code Examples

### Verified import order test (compiles successfully)

```scss
// Source: Verified by running yarn build:css against actual Bootstrap 5.3.8

// This is the minimum correct ordering:
@import 'bootstrap/scss/functions';  // MUST be first — provides shade-color(), tint-color(), etc.
@import 'variables';                  // Our overrides — BEFORE bootstrap's variables
@import 'bootstrap/scss/variables';   // Bootstrap reads our overrides as already-set
@import 'bootstrap/scss/variables-dark';
@import 'bootstrap/scss/maps';
@import 'bootstrap/scss/mixins';
// ... rest of imports
```

### Spacing token definition

```scss
// Source: UI-SPEC.md approved 2026-05-09
// _spacing.scss

:root {
  --space-1:  0.25rem;   // 4px
  --space-2:  0.5rem;    // 8px
  --space-3:  0.75rem;   // 12px
  --space-4:  1rem;      // 16px
  --space-5:  1.25rem;   // 20px
  --space-6:  1.5rem;    // 24px
  --space-7:  1.75rem;   // 28px
  --space-8:  2rem;      // 32px
  --space-12: 3rem;      // 48px
  --space-16: 4rem;      // 64px
}
```

### Typography override

```scss
// Source: UI-SPEC.md approved 2026-05-09
// _typography.scss

// Font family applied to body via Bootstrap's CSS variable (already set via $font-family-sans-serif in _variables.scss)
// Override link decoration for dark surfaces
a {
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
}
```

Note: Heading weights and font sizes flow through Bootstrap's `$headings-font-weight` and `$font-size-base` variable overrides in `_variables.scss`. No additional CSS needed for those in `_typography.scss`.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@import 'bootstrap'` monolith | Selective `@import 'bootstrap/scss/partial'` | Bootstrap 4 → 5 | Allows variable injection between functions and variables imports |
| `prefers-color-scheme` media query | `[data-bs-theme="dark"]` attribute | Bootstrap 5.3.0 | Explicit dark mode: no OS preference dependency |
| CSS class-based dark mode (`.dark-mode` on body) | CSS custom property overrides on `[data-bs-theme="dark"]` | Bootstrap 5.3.0 | Single attribute activates all component variable overrides |
| Sass `@import` | Sass `@use` / `@forward` module system | Dart Sass 1.77 deprecated `@import` | Bootstrap 5.x still uses `@import`; migration to `@use` expected in Bootstrap 6 |

**Deprecated/outdated:**
- `navbar-dark bg-dark` classes on navbar: These will still render on the existing navbar. They do not conflict with Phase 1 token definitions but will be replaced in Phase 2.
- `@import 'bootstrap/scss/bootstrap'` (monolithic): Replaced by selective imports in CSST-02.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Google Fonts delivers Inter reliably in this app's deployment environment | Standard Stack / Pitfalls | If deployed in a network-restricted environment, Inter may not load — system font stack fallback ensures legibility but not pixel-perfect Inter rendering |

**All other claims were verified against installed source files or direct test compilation.**

---

## Open Questions

1. **Dart Sass 2.0 migration timeline**
   - What we know: Sass 1.99 supports `@import` with warnings; Sass 2.0 will remove it
   - What's unclear: Bootstrap 6 release timeline (will migrate to `@use`); could affect build when Sass is updated
   - Recommendation: Use `--silence-deprecation` now; this is a known, documented Bootstrap limitation. No action needed in Phase 1 beyond the flag.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Dart Sass CLI | CSST-02 build | ✓ | 1.99.0 | — |
| PostCSS + autoprefixer | CSST-02 build | ✓ | 8.4.38 / 10.4.19 | — |
| Bootstrap 5 SCSS | CSST-01, CSST-02 | ✓ | 5.3.8 | — |
| Bootstrap Icons | CSST-02 (icon font) | ✓ | 1.11.3 | — |
| Google Fonts CDN (Inter) | CSST-03 | ✓ [ASSUMED] | CDN | System font stack already in $font-family-sans-serif fallback |
| nodemon (watch) | dev workflow | ✓ | 3.1.3 | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Google Fonts CDN (assumed available; system font stack is the built-in fallback).

---

## Security Domain

> `security_enforcement` not explicitly set to false — including this section.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | CSS/SCSS only — no user input processed |
| V6 Cryptography | no | — |

### Known Threat Patterns for CSS/Font Pipeline

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Google Fonts CDN subresource integrity | Tampering | No SRI possible for Google Fonts (URL is dynamic); CSP is currently disabled — not a concern for v1 |
| Malicious SCSS injection via `@import` path | Tampering | All SCSS is developer-controlled files in git; no dynamic path construction |

No active security concerns for this phase. CSP is entirely commented out in `config/initializers/content_security_policy.rb` — Google Fonts loads without restriction.

---

## Sources

### Primary (HIGH confidence)
- `node_modules/bootstrap/scss/bootstrap.scss` — authoritative import order for Bootstrap 5.3.8
- `node_modules/bootstrap/scss/_root.scss` — confirms `[data-bs-theme="dark"]` activation mechanism via `color-mode(dark, true)` mixin
- `node_modules/bootstrap/scss/_variables.scss` — confirms `!default` on all variables; verified `$color-mode-type: data` (not `media-query`)
- `node_modules/bootstrap/scss/_variables-dark.scss` — confirms dark mode variable names
- `node_modules/bootstrap/scss/mixins/_color-mode.scss` — confirms `data-bs-theme` attribute mechanism
- `node_modules/bootstrap/package.json` — version 5.3.8 [VERIFIED]
- `app/assets/stylesheets/application.bootstrap.scss` — current 2-line entry point [VERIFIED]
- `package.json` — build scripts, dependency versions [VERIFIED]
- `app/views/layouts/application.html.slim` — current layout; no `data-bs-theme` set; no font links [VERIFIED]
- `config/initializers/content_security_policy.rb` — CSP entirely commented out [VERIFIED]
- `yarn build:css` test run — confirmed 312 deprecation warnings, successful compile [VERIFIED]
- `sass --version` — 1.99.0, `--silence-deprecation` flag confirmed available [VERIFIED]

### Secondary (MEDIUM confidence)
- `.planning/phases/01-css-foundation/01-UI-SPEC.md` — approved design contract; token values, file structure, import order [CITED]
- `.planning/phases/01-css-foundation/01-CONTEXT.md` — locked user decisions D-01 through D-07 [CITED]

### Tertiary (LOW confidence)
- None — all claims verified from installed source or direct execution.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in node_modules and package.json
- Architecture / import order: HIGH — verified against actual Bootstrap 5.3.8 SCSS source files
- Sass deprecation behavior: HIGH — confirmed by running `yarn build:css` in the actual project
- Google Fonts availability: ASSUMED (A1) — external CDN dependency; system font fallback mitigates risk
- Pitfalls: HIGH — root cause of each verified in Bootstrap source

**Research date:** 2026-05-09
**Valid until:** 2026-11-09 (stable stack; Bootstrap 5.x and Sass 1.x behavior is stable for 6 months)

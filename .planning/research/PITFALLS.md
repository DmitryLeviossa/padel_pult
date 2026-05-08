# Dark Theme UI Redesign — Pitfalls

**Domain:** Bootstrap 5 dark theme redesign, Rails 8 / Slim / Propshaft
**Researched:** 2026-05-08
**Confidence:** HIGH (Bootstrap docs confirmed), MEDIUM (Rails-specific patterns from codebase analysis)

---

## Critical Pitfalls

Mistakes that cause visual breakage, failed redesigns, or rewrites.

---

### Pitfall 1: Incomplete SCSS Import Order Breaks Custom Variable Overrides

**What goes wrong:** Bootstrap's Sass variables must be overridden *after* `functions` is imported but *before* `variables` and `variables-dark` are imported. The current `application.bootstrap.scss` is a single `@import 'bootstrap/scss/bootstrap'` — adding custom variables above or below this import has zero effect. Dark theme color overrides are silently ignored and Bootstrap renders its defaults.

**Why it happens:** Bootstrap uses `!default` flags. A variable already defined (by the full `bootstrap` import) cannot be overridden. Custom dark palette variables injected after the full import become dead code.

**Consequences:** You think you are customizing the dark palette, but Bootstrap still renders its grey-on-dark-grey default. The electric blue `$primary` override does not propagate to buttons, links, focus rings, or validation states.

**Prevention:** Split the single import into the structured Bootstrap partial sequence:
```scss
// 1. Functions (required first)
@import 'bootstrap/scss/functions';

// 2. Your variable overrides HERE — before Bootstrap reads them
$primary: #2563eb;        // electric blue
$body-bg: #0d1117;        // dark navy
$body-color: #e2e8f0;     // slate text
// etc.

// 3. Bootstrap variables + dark map
@import 'bootstrap/scss/variables';
@import 'bootstrap/scss/variables-dark';

// 4. Maps (after variables, before mixins)
@import 'bootstrap/scss/maps';
@import 'bootstrap/scss/mixins';
@import 'bootstrap/scss/root';

// 5. Remaining Bootstrap
@import 'bootstrap/scss/utilities';
// ...all other partials
```
If you want to stay with the single `@import 'bootstrap/scss/bootstrap'`, you must override via CSS custom properties at the `[data-bs-theme="dark"]` selector level instead — a different, valid strategy, but all color changes happen at CSS variable level, not Sass level.

**Warning signs:** Changing `$primary` has no effect on rendered buttons. Custom colors defined before `@import 'bootstrap/scss/bootstrap'` do nothing.

**Phase:** Phase 1 (CSS foundation setup — before any component work).

---

### Pitfall 2: `data-bs-theme="dark"` Must Be on `<html>`, Not `<body>`

**What goes wrong:** Placing `data-bs-theme="dark"` on `<body>` instead of `<html>` causes Bootstrap's root-level CSS variable declarations (set on `:root`) to remain in light mode. Components that inherit from `:root` — not from `body` — still render light.

**Why it happens:** Bootstrap scopes its dark-mode CSS variable overrides to both `[data-bs-theme=dark]` and inheriting selectors, but the `:root` block that sets global defaults is always light unless `<html>` itself carries the attribute.

**Consequences:** Some components flip dark, others stay light, producing an inconsistent mix that is hard to debug.

**Prevention:** Always set the attribute on the `<html>` element in `layouts/application.html.slim`:
```slim
html data-bs-theme="dark"
```

**Warning signs:** Cards go dark but page background stays white; or form controls are dark but alerts stay light.

**Phase:** Phase 1 (layout template).

---

### Pitfall 3: Bootstrap Table Variants Do Not Adapt to Dark Mode (Bootstrap 5 Limitation)

**What goes wrong:** `table-hover`, `table-striped`, and especially named color variants (`table-primary`, `table-dark`) do **not** automatically adapt to `data-bs-theme="dark"`. Bootstrap's own docs state: *"table variants most likely won't see color mode adaptive styling until v6."*

**Specific instance:** `users/index.html.slim` uses `table.table.table-striped.table-hover` with `thead.table-dark`. In dark mode, `thead.table-dark` renders as near-black-on-dark, colliding with the dark body background and producing invisible or unreadable headers.

**Why it happens:** Table variant colors are compiled from Sass into static hex values, not CSS variables. They do not read from `--bs-body-bg`.

**Consequences:** Tables look broken — striped rows become invisible or produce hard glare, `thead.table-dark` clashes with the dark body.

**Prevention:**
- Remove `thead.table-dark` from all tables — it's counterproductive in a global dark theme.
- Use CSS custom property overrides on the table component directly:
  ```scss
  [data-bs-theme="dark"] .table {
    --bs-table-bg: transparent;
    --bs-table-striped-bg: rgba(255, 255, 255, 0.04);
    --bs-table-hover-bg: rgba(255, 255, 255, 0.07);
    --bs-table-border-color: rgba(255, 255, 255, 0.1);
    color: var(--bs-body-color);
  }
  ```
- Audit every `table.*` usage across the four templates that use tables: `leagues/show`, `tournaments/show`, `users/index`.

**Warning signs:** Table headers disappear into the background; striped rows produce strong contrast lines that look like horizontal rules.

**Phase:** Phase 2 (component overrides — tables are a dedicated sub-task).

---

### Pitfall 4: `text-muted`, `bg-light`, `bg-white`, `bg-secondary` Are Not Theme-Aware

**What goes wrong:** Bootstrap 5.3 deprecated `.text-muted` (maps to `--bs-secondary-color` now, but the *class name* is removed in v6). More critically, `.bg-light`, `.bg-white`, `.bg-secondary` do **not** respond to color modes — they remain their original light values in dark mode. `.text-primary`, `.text-secondary`, `.text-danger` (without the `-emphasis` suffix) are also **not** theme-aware.

**Specific instances in codebase:**
- `dashboard/index.html.slim`: multiple `p.text-muted`, `span.badge.bg-secondary`, `card-footer.text-muted`
- `leagues/index.html.slim`: `p.card-text.text-muted`, `card-footer.text-muted.small`
- `leagues/show.html.slim`: `p.text-muted`, `p.text-muted.small`
- `tournaments/show.html.slim`: `p.text-muted`, avatar fallback uses `bg-secondary`
- `users/index.html.slim`: avatar fallback uses `.rounded-circle.bg-secondary`
- `devise/registrations/edit.html.slim`: `text-danger` for delete section header, `bg-secondary` avatar

**Why it happens:** These utilities use the original `$theme-colors` Sass map compiled to static hex values, not the theme-aware CSS variable variants.

**Consequences:** `bg-secondary` avatar fallbacks render as medium-grey circles against a dark background — visually muddy and low contrast. `text-muted` on dark is marginally acceptable but semantically wrong (it was designed for light backgrounds). `bg-light` in cards becomes an unpleasant white box.

**Prevention:**
- Replace `.text-muted` with `.text-secondary` (uses `--bs-secondary-color`) or a custom CSS variable.
- Replace `.bg-secondary` avatar fallbacks with a custom CSS variable: `background: var(--bs-primary)` or a dedicated `--avatar-bg`.
- Replace `.bg-light` with `var(--bs-secondary-bg)`.
- Audit: search all `.slim` files for `bg-secondary`, `bg-light`, `bg-white`, `text-muted`.

**Warning signs:** Avatar circles look muddy; "muted" text is barely distinguishable from body text.

**Phase:** Phase 1 (global audit), then Phase 2 per component.

---

### Pitfall 5: Box Shadows Become Invisible on Dark Backgrounds

**What goes wrong:** Bootstrap's shadow utilities (`shadow-sm`, `shadow`) use `rgba(0, 0, 0, 0.15)` — black with low opacity. On dark backgrounds (near-black body), a dark shadow has no visible effect and depth cues disappear entirely. Cards in `leagues/index.html.slim` use `card.shadow-sm`; they will look flat on dark navy.

**Why it happens:** Shadows are designed for light UIs where dark shadows create depth against white. In dark UIs, the same shadows are invisible or actually make things look flatter.

**Consequences:** Card hierarchy collapses. The "clean sharp cards" Linear aesthetic is impossible if shadows aren't replaced with appropriate depth cues for dark UIs.

**Prevention:** Override `--bs-box-shadow-sm` and `--bs-box-shadow` under `[data-bs-theme="dark"]` to use either:
- Elevated background (`--bs-tertiary-bg` for card background vs `--bs-secondary-bg` for page) — this is the Linear approach
- Subtle inset glow: `box-shadow: 0 0 0 1px rgba(255,255,255,0.08)`
- Upward glow: `box-shadow: 0 -1px 0 rgba(255,255,255,0.05), 0 4px 16px rgba(0,0,0,0.4)`

**Warning signs:** All cards look identical depth-wise; the UI looks flat despite `shadow-sm` being present.

**Phase:** Phase 1 (design tokens / CSS variable setup).

---

## Moderate Pitfalls

Issues that cause visible incorrectness but don't require structural rewrites.

---

### Pitfall 6: Rails Flash Messages Use Raw `alert-success` / `alert-danger` Without Container Styling

**What goes wrong:** Flash messages are rendered inline in specific views (`dashboard/index.html.slim`, `leagues/index.html.slim`, `users/index.html.slim`) with raw Bootstrap alert classes. Two problems in dark mode:
1. The alert classes (`alert-success`, `alert-danger`) use `*-bg-subtle` and `*-border-subtle` CSS variables which *do* adapt to dark mode — but at Bootstrap's default dark values, which are muted pastel tones that may have poor contrast against a custom dark navy background.
2. Flash messages are not in the layout — they are per-view. Any newly added page that forgets to render them will silently drop notifications.

**Prevention:**
- Move flash rendering into `layouts/application.html.slim` (above `yield`) so it is universal.
- Add a custom override for alert colors in dark mode that matches the dark navy palette:
  ```scss
  [data-bs-theme="dark"] .alert-success {
    --bs-alert-bg: rgba(34, 197, 94, 0.12);
    --bs-alert-border-color: rgba(34, 197, 94, 0.3);
    --bs-alert-color: #86efac;
  }
  ```
- Test contrast: success green and danger red on dark navy must both pass 4.5:1.

**Warning signs:** Flash messages appear and disappear between pages as you navigate. Success messages look the same as danger messages at a glance.

**Phase:** Phase 1 (layout), with color tuning in Phase 2.

---

### Pitfall 7: Form File Input (`form-control` for File Uploads) Has Light Background in Browsers

**What goes wrong:** The browser-native file picker button inside `<input type="file" class="form-control">` is rendered by the OS/browser, not by Bootstrap CSS. Even with a fully dark `form-control` background, the file picker button will render in the browser's default theme (light grey on most systems) unless the user has OS-level dark mode enabled. This affects the logo upload on `leagues/new`, `leagues/edit`, and the photo upload on `devise/registrations/edit`.

**Prevention:**
- Style the `::file-selector-button` pseudo-element:
  ```scss
  [data-bs-theme="dark"] .form-control::file-selector-button {
    background-color: var(--bs-secondary-bg);
    color: var(--bs-body-color);
    border-color: var(--bs-border-color);
  }
  ```
- Bootstrap 5.3 already includes some `::file-selector-button` styles but they may not override OS chrome in all browsers.

**Warning signs:** File upload fields look broken — light button inset in a dark control.

**Phase:** Phase 2 (form components).

---

### Pitfall 8: Active Storage Images Have No Dark-Background Treatment

**What goes wrong:** User photos and league logos from Active Storage are rendered as `<img>` tags with `object-fit: cover` and rounded corners. Three issues in dark context:
1. Images with transparent backgrounds (PNG logos) will show the image transparency as transparent, not as the dark background, if `background-color` is not set on the containing element.
2. League card header images (`card-img-top`) on `leagues/index.html.slim` have no fallback placeholder for loading state — a brief white flash appears before the image loads.
3. No handling for broken/unavailable images — the browser default broken image icon is a light-background element.

**Prevention:**
- Add `background-color: var(--bs-secondary-bg)` to all `image_tag` containers.
- Add CSS `img { background-color: var(--bs-secondary-bg); }` globally to catch transparent PNGs and loading states.
- For league logo `card-img-top`, add a minimum height and background color so the card does not collapse while loading.
- Do NOT add dark overlays on top of images — this kills the image vibrancy that makes cards interesting.

**Warning signs:** White rectangles flash during page load where images should be; transparent-background logos show jagged transparent edges.

**Phase:** Phase 2 (cards and image components).

---

### Pitfall 9: Avatar Fallback (`bg-secondary`) Is a Hardcoded Sass Color in Multiple Places

**What goes wrong:** Every user avatar fallback in the codebase uses:
```slim
.rounded-circle.bg-secondary.d-inline-flex...
  span.text-white.small
```
`.bg-secondary` is not theme-aware (see Pitfall 4). More critically, the initial letter inside uses `.text-white` which is hardcoded. This exact pattern appears in: `leagues/show.html.slim` (league participants table), `tournaments/show.html.slim` (pairs table, appears twice), `devise/registrations/edit.html.slim` (profile avatar), and `users/index.html.slim`.

**Prevention:** Replace with a CSS custom property approach:
```slim
.rounded-circle.d-inline-flex... style="background: var(--bs-primary); color: white;"
```
Or better, create a `_avatar.html.slim` partial that enforces consistent styling. The electric blue primary color as avatar background creates strong brand cohesion on dark backgrounds.

**Warning signs:** Avatar fallback circles look grey and washed-out against dark navy.

**Phase:** Phase 2 (create shared `_avatar` partial — this is used in 4+ views).

---

### Pitfall 10: Nav Tabs Active State Border Clashes With Dark Background

**What goes wrong:** `leagues/show.html.slim` uses Bootstrap nav-tabs (`ul.nav.nav-tabs`). In light mode, the active tab has a white background (`--bs-body-bg`) that creates the visual "lifted" tab effect against a light page background. In dark mode with `data-bs-theme="dark"`, the active tab background changes to `--bs-body-bg` (dark), but the surrounding inactive tab area also uses the dark body background — the visual distinction between active and inactive collapses.

**Prevention:** Override the active tab appearance for dark mode:
```scss
[data-bs-theme="dark"] .nav-tabs .nav-link.active {
  background-color: var(--bs-secondary-bg);
  border-bottom-color: var(--bs-secondary-bg);
}
```
Or switch to `nav-pills` for tab navigation — pills use a filled background for active state which is more legible in dark contexts.

**Warning signs:** It is impossible to tell which tab is selected.

**Phase:** Phase 2 (league show page).

---

### Pitfall 11: Dynamic Badge Colors via Inline Slim Logic Are Not Dark-Aware

**What goes wrong:** `tournaments/show.html.slim` generates badge classes dynamically:
```slim
- badge_class = { "draft" => "secondary", "active" => "success", "completed" => "primary", "cancelled" => "danger" }.fetch(@tournament.status, "secondary")
span class="badge bg-#{badge_class}"
```
`bg-secondary`, `bg-success`, `bg-primary`, `bg-danger` as utility classes are **not** theme-aware (they are Sass-compiled static values). In dark mode, `bg-success` (green) and `bg-primary` (blue) will render at their full-saturation light-theme values — potentially garish against dark navy, and possibly failing contrast requirements for text inside.

**Prevention:** Use `text-bg-{color}` instead of `bg-{color}` for badges — this applies Bootstrap's Sass `color-contrast()` function to guarantee readable text. Or override badge colors under `[data-bs-theme="dark"]` with semantic CSS variable values.

**Warning signs:** Status badges look neon/oversaturated against the dark background; white text on `bg-success` may fail contrast on dark.

**Phase:** Phase 2 (tournament show page).

---

### Pitfall 12: Deprecated `navbar-dark` Class Requires Migration

**What goes wrong:** `layouts/application.html.slim` uses `nav.navbar.navbar-dark.bg-dark`. In Bootstrap 5.3, `.navbar-dark` is deprecated — the recommended approach is `data-bs-theme="dark"` on the navbar. The deprecated class still works in 5.3 but will be removed in 6.0. More importantly, `.bg-dark` hardcodes a Sass-compiled dark grey, which will clash with the custom dark navy `--bs-body-bg`.

**Prevention:**
```slim
nav.navbar.navbar-expand-lg data-bs-theme="dark" style="background-color: var(--bs-body-bg);"
```
Or define a custom `--navbar-bg` CSS variable tied to the dark navy palette.

**Warning signs:** Navbar background does not match the page body background.

**Phase:** Phase 1 (layout redesign).

---

## Minor Pitfalls

Issues that cause cosmetic problems but are quick to fix.

---

### Pitfall 13: `shadow-sm` on Cards Adds No Visual Value on Dark Backgrounds

**What goes wrong:** `card.shadow-sm.h-100` in `dashboard/index.html.slim` and `leagues/index.html.slim` uses `box-shadow: 0 .125rem .25rem rgba(0,0,0,.075)`. On a dark navy background, this is invisible (black shadow on near-black surface). It wastes CSS and provides no depth cue.

**Prevention:** Remove `shadow-sm` from all cards and replace with either border-based elevation (`border: 1px solid var(--bs-border-color)`) or background elevation (card bg slightly lighter than page bg). This is the Linear.app approach.

**Phase:** Phase 1 (CSS token setup).

---

### Pitfall 14: Turbo Drive Flash Message Persistence

**What goes wrong:** Turbo Drive replaces the `<body>` content on navigation, so flash messages in the current `<body>` are cleared. The `_error_messages.html.slim` partial already uses `data-turbo-temporary=true` — but the inline flash messages in `dashboard/index.html.slim`, `leagues/index.html.slim`, and `users/index.html.slim` do not. Moving flash to the layout (Pitfall 6's fix) resolves this, but only if the layout's flash container is outside Turbo permanent zones.

**Prevention:** Place the flash partial inside a `data-turbo-temporary` container or rely on Turbo's default sweep behavior. The key is that flash messages rendered server-side are transient by nature and Turbo Drive already handles this correctly for layout-rendered flashes when using `data-turbo-permanent` is not set.

**Phase:** Phase 1 (layout) — resolved as part of Pitfall 6 fix.

---

### Pitfall 15: CSS Specificity Bloat from Override-on-Override Pattern

**What goes wrong:** A common dark theme implementation mistake is adding long chains of overrides under `[data-bs-theme="dark"]` for each component, each with increasing specificity. After 200+ lines, component-specific rules conflict with later rules, requiring `!important` hacks, which then cascade into further override debt.

**Prevention:**
- Define the entire dark palette as CSS custom properties at the design token level first (`--color-navy-900`, `--color-slate-200`, `--color-electric-blue`, etc.).
- Override Bootstrap's own CSS variables (not components directly) at the `[data-bs-theme="dark"]` root level.
- Only add component-specific rules for the known exceptions (tables, specific badges, shadows).
- Keep the custom SCSS below 400 lines total — if it exceeds this, you are patching Bootstrap rather than overriding it cleanly.

**Warning signs:** Multiple `!important` appearing in SCSS; opening DevTools shows 5+ competing rules for a single property.

**Phase:** Phase 1 (architecture decision before writing CSS).

---

### Pitfall 16: Typography Contrast on Dark — Inter/System Font vs Line-Height

**What goes wrong:** The Linear.app aesthetic relies on Inter or a similar geometric sans-serif at precise weights (400 body, 500 medium, 600 semibold). Bootstrap's default `--bs-font-sans-serif` is a system font stack that renders differently across OS. On macOS, the system font (SF Pro) renders crisply dark-on-dark. On Windows, Segoe UI at small sizes on dark backgrounds can appear blurry or faint due to ClearType rendering on dark surfaces.

**Prevention:**
- Load Inter from Google Fonts (free, no licensing issue) as specified in PROJECT.md constraints.
- Set `--bs-body-font-family: 'Inter', var(--bs-font-sans-serif)` after the font import.
- Use `font-optical-sizing: auto` and `text-rendering: optimizeLegibility` on `body`.
- Bump body font to at least `15px` — dark themes need slightly larger type to maintain apparent legibility.

**Warning signs:** Text looks "thin" or "blurry" on Windows clients; headings look like body text in weight.

**Phase:** Phase 1 (typography tokens).

---

## Phase-Specific Warnings Summary

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| SCSS foundation setup | Wrong import order silences variable overrides (P1) | Split `@import 'bootstrap/scss/bootstrap'` into partials |
| Layout template | `data-bs-theme="dark"` on wrong element (P2); deprecated `navbar-dark` (P12) | Set on `<html>`; migrate to data attribute |
| CSS design tokens | Shadow invisibility (P5, P13); specificity bloat (P15) | Define elevation via background color layers, not shadows |
| Flash / alert system | Per-view flash not in layout (P6); dark-aware colors needed | Move to layout, override alert CSS variables |
| Form components | File input native button stays light (P7); validation states need testing | Override `::file-selector-button` |
| Cards and tables | Table variants not theme-aware (P3); shadow-sm invisible (P13) | Override table CSS variables; replace shadows with borders |
| Avatar / image components | `bg-secondary` fallback not theme-aware (P4, P9); transparent PNG flash (P8) | Create `_avatar` partial; set `background-color` on image containers |
| Badge / status indicators | Dynamic `bg-{color}` classes not dark-aware (P11) | Use `text-bg-{color}` or override under dark selector |
| Nav tabs | Active state visually collapses on dark (P10) | Override active tab border-bottom color |
| Typography | System font rendering issues on Windows (P16) | Load Inter, set `text-rendering: optimizeLegibility` |

---

## Sources

- Bootstrap 5.3 Color Modes documentation: https://getbootstrap.com/docs/5.3/customize/color-modes/
- Bootstrap 5.3 Sass customization order: https://getbootstrap.com/docs/5.3/customize/sass/
- Bootstrap 5.3 Tables documentation (v6 note re: color mode): https://getbootstrap.com/docs/5.3/content/tables/
- Bootstrap 5.3 Color utilities (`.text-muted` deprecation, theme-aware variants): https://getbootstrap.com/docs/5.3/utilities/colors/
- Bootstrap 5.3 Form validation dark mode variables: https://getbootstrap.com/docs/5.3/forms/validation/
- Bootstrap 5.3 CSS Variables reference: https://getbootstrap.com/docs/5.3/customize/css-variables/
- Bootstrap 5.3 Accessibility / WCAG 4.5:1 requirement: https://getbootstrap.com/docs/5.3/getting-started/accessibility/
- Bootstrap 5.3 `text-bg-*` helpers: https://getbootstrap.com/docs/5.3/helpers/color-background/
- Codebase analysis: all `.slim` templates in `app/views/` (2026-05-08)

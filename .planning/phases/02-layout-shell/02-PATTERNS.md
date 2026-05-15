# Phase 2: Layout Shell - Pattern Map

**Mapped:** 2026-05-09
**Files analyzed:** 10 (new/modified)
**Analogs found:** 9 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `app/views/layouts/application.html.slim` | layout | request-response | `app/views/layouts/application.html.slim` (self — modify) | exact |
| `app/views/layouts/_navbar.html.slim` | layout partial | request-response | `app/views/layouts/application.html.slim` lines 29-43 (existing navbar) | role-match |
| `app/views/layouts/_flash.html.slim` | layout partial | request-response | `app/views/dashboard/index.html.slim` lines 3-7 (inline flash blocks) | role-match |
| `app/javascript/controllers/navbar_controller.js` | Stimulus controller | event-driven | `app/javascript/controllers/hello_controller.js` (structure only) | structure-match |
| `app/javascript/controllers/flash_controller.js` | Stimulus controller | event-driven | `app/javascript/controllers/hello_controller.js` (structure only) | structure-match |
| `app/assets/stylesheets/_navbar.scss` | stylesheet partial | transform | `app/assets/stylesheets/_theme.scss` (partial authoring pattern) | role-match |
| `app/assets/stylesheets/_flash.scss` | stylesheet partial | transform | `app/assets/stylesheets/_typography.scss` (partial authoring pattern) | role-match |
| `app/assets/stylesheets/application.bootstrap.scss` | stylesheet manifest | transform | `app/assets/stylesheets/application.bootstrap.scss` (self — modify) | exact |
| `app/views/dashboard/index.html.slim` | view | request-response | `app/views/leagues/index.html.slim` (same flash removal pattern) | exact |
| `app/views/leagues/index.html.slim` | view | request-response | `app/views/users/index.html.slim` (same flash removal pattern) | exact |

---

## Pattern Assignments

### `app/views/layouts/application.html.slim` (layout, request-response)

**Analog:** self — current file, lines 1-43

**Existing head pattern** (lines 1-26) — keep verbatim, no changes needed:
```slim
doctype html
html data-bs-theme="dark"
  head
    title= content_for(:title) || "Padel Pult"
    meta name="viewport" content="width=device-width,initial-scale=1"
    meta name="apple-mobile-web-app-capable" content="yes"
    meta name="mobile-web-app-capable" content="yes"
    = csrf_meta_tags
    = csp_meta_tag
    = yield :head
    link rel="preconnect" href="https://fonts.googleapis.com"
    link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"
    link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"
    link rel="icon" href="/icon.png" type="image/png"
    link rel="icon" href="/icon.svg" type="image/svg+xml"
    link rel="apple-touch-icon" href="/icon.png"
    = stylesheet_link_tag "application", "data-turbo-track": "reload"
    = javascript_importmap_tags
```

**Body pattern — what to replace** (lines 28-43, the flat `<body>` block):

Replace the current body block entirely. The new body:
```slim
  body
    = render "layouts/navbar"
    = render "layouts/flash"
    main.py-4
      = yield
```

Key constraints:
- `render "layouts/navbar"` renders `_navbar.html.slim`
- `render "layouts/flash"` renders `_flash.html.slim`
- `main.py-4` wraps yield — no `.container` here; each page view provides its own `.container.py-4` internally
- Remove lines 29-43 (the `nav.navbar...` block and bare `= yield`)

---

### `app/views/layouts/_navbar.html.slim` (layout partial, request-response)

**Analog:** `app/views/layouts/application.html.slim` lines 29-43 (existing flat navbar)

**Existing navbar pattern to replace** (lines 29-43 of `application.html.slim`):
```slim
nav.navbar.navbar-expand-lg.navbar-dark.bg-dark
  .container-fluid
    = link_to "Padel Pult", root_path, class: "navbar-brand"
    .d-flex.align-items-center.gap-3
      - if user_signed_in?
        = link_to "Лиги", leagues_path, class: "text-light text-decoration-none small"
        = link_to "Турниры", tournaments_path, class: "text-light text-decoration-none small"
        = link_to "Игроки", users_path, class: "text-light text-decoration-none small"
        span.text-light.small= current_user.email
        = link_to "Редактировать аккаунт", edit_user_registration_path, class: "text-light text-decoration-none small"
        = button_to "Выйти", destroy_user_session_path, method: :delete, class: "btn btn-outline-light btn-sm"
      - else
        = link_to "Войти", new_user_session_path, class: "text-light text-decoration-none small"
        = link_to "Регистрация", new_user_registration_path, class: "btn btn-outline-light btn-sm"
```

**Conditional auth guard pattern** (lines 33 and 40 — copy this `user_signed_in?` pattern):
```slim
- if user_signed_in?
  / authenticated links here
- else
  / guest links here
```

**Active link state pattern** — adapt from RESEARCH.md with `request.path.start_with?`:
```slim
= link_to "Лиги", leagues_path, class: "nav-link #{request.path.start_with?('/leagues') ? 'active' : ''}", aria: { current: (request.path.start_with?('/leagues') ? 'page' : nil) }
```

**User initials avatar pattern** — from `app/views/users/index.html.slim` lines 25-26 (initials fallback):
```slim
.rounded-circle.bg-secondary.d-inline-flex.align-items-center.justify-content-center style="width: 40px; height: 40px;"
  span.text-white.small = user.full_name.first.upcase
```
Adapt to use `current_user.full_name.split.map(&:first).first(2).join.upcase` for two initials and `var(--color-bg-surface)` background.

**Logout button pattern** (line 39 — keep `button_to` with `method: :delete` for CSRF correctness):
```slim
= button_to "Выйти", destroy_user_session_path, method: :delete, class: "dropdown-item text-danger border-0 bg-transparent w-100 text-start"
```

**Stimulus wiring attributes for the new partial:**
- `data-controller="navbar"` on `<nav>`
- `data-action="navbar#toggle"` on the toggler button (do NOT also add `data-bs-toggle="collapse"` — would double-fire)
- `data-navbar-target="menu"` on the collapse div

---

### `app/views/layouts/_flash.html.slim` (layout partial, request-response)

**Analog:** `app/views/dashboard/index.html.slim` lines 3-7 (existing inline flash blocks)

**Existing inline flash pattern** (dashboard, lines 3-7):
```slim
- if flash[:notice]
  .alert.alert-success= flash[:notice]
- if flash[:alert]
  .alert.alert-danger= flash[:alert]
```

**Existing inline flash pattern** (leagues/index.html.slim, lines 6-7):
```slim
- if flash[:notice]
  .alert.alert-success= flash[:notice]
```

**Existing inline flash pattern** (users/index.html.slim, lines 4-5):
```slim
- if flash[:notice]
  .alert.alert-success= flash[:notice]
```

**Generalized type-map pattern** — iterate `flash` hash instead of per-key conditionals:
```slim
- type_map = { "notice" => "alert-success", "alert" => "alert-danger", "warning" => "alert-warning", "info" => "alert-info" }
- flash.each do |type, message|
  .alert.alert-dismissible.fade.show role="alert" class=type_map.fetch(type, "alert-secondary") data-controller="flash" data-turbo-temporary="true"
    = message
    button.btn-close type="button" data-bs-dismiss="alert" data-action="flash#close" aria-label="Close"
```

Key constraints:
- Use `= message` (not `== message`) — Slim auto-escapes, preventing XSS
- `data-turbo-temporary="true"` prevents Turbo snapshot caching (Pitfall 6 from RESEARCH.md)
- Both `data-bs-dismiss="alert"` (Bootstrap manual dismiss) and `data-action="flash#close"` are present — Bootstrap handles the click, Stimulus handles the auto-dismiss timer

---

### `app/javascript/controllers/navbar_controller.js` (Stimulus controller, event-driven)

**Analog:** `app/javascript/controllers/hello_controller.js` (structural pattern only)

**Existing controller structure** (`hello_controller.js`, lines 1-7):
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.textContent = "Hello World!"
  }
}
```

**Import pattern to copy** (line 1):
```javascript
import { Controller } from "@hotwired/stimulus"
```

**New controller pattern** — adds Bootstrap Collapse import and `targets`:
```javascript
import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    const collapse = Collapse.getOrCreateInstance(this.menuTarget)
    collapse.toggle()
  }
}
```

Naming convention: file name `navbar_controller.js` → Stimulus identifier `navbar` (underscore-to-dash convention handled by `eagerLoadControllersFrom` in `index.js`).

---

### `app/javascript/controllers/flash_controller.js` (Stimulus controller, event-driven)

**Analog:** `app/javascript/controllers/hello_controller.js` (structural pattern only)

**Import pattern to copy** (line 1 of `hello_controller.js`):
```javascript
import { Controller } from "@hotwired/stimulus"
```

**New controller pattern** — adds `values` and lifecycle hooks:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => this.close(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  close() {
    this.element.classList.remove("show")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
```

`disconnect()` clears the timer — required to avoid acting on a removed element when navigating away before auto-dismiss fires.

---

### `app/assets/stylesheets/_navbar.scss` (stylesheet partial, transform)

**Analog:** `app/assets/stylesheets/_theme.scss` and `app/assets/stylesheets/_typography.scss` (partial authoring conventions)

**File header comment pattern** (from `_theme.scss` lines 1-3, and `_spacing.scss` lines 1-4):
```scss
// _navbar.scss
// Imported in application.bootstrap.scss after project theme partials.
// Navbar surface and link overrides — uses Phase 1 tokens from _theme.scss and _spacing.scss.
```

**CSS custom property consumption pattern** (from `_theme.scss` — how tokens are used):
```scss
// Available tokens to reference:
// --color-bg-navbar: #161b22  (navbar surface — NOT same as $dark/#21262d)
// --color-bg-surface: #21262d
// --color-text-primary: #e6edf3
// --color-text-muted: #8b949e
// --color-border: #30363d
// --color-accent: #2f81f7
// --space-2: 0.5rem
// --space-3: 0.75rem
```

**Transition variable to reuse** (from `_variables.scss` line 26):
```scss
// Project transition: all 0.15s ease-in-out (matches $transition-base)
transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out;
```

**Anti-pattern to avoid:** Do NOT use `.bg-dark` or `.navbar-dark` — `$dark: #21262d` maps to surface color, not navbar surface. Use `background-color: var(--color-bg-navbar)` explicitly.

---

### `app/assets/stylesheets/_flash.scss` (stylesheet partial, transform)

**Analog:** `app/assets/stylesheets/_typography.scss` (minimal targeted override pattern)

**Pattern to copy** — minimal targeted CSS with BEM-light selectors (from `_typography.scss` lines 9-15):
```scss
a:not(.btn):not(.nav-link):not(.navbar-brand) {
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
}
```

Bootstrap `.alert-success/danger/warning/info` variants already support `data-bs-theme="dark"` through CSS variable inheritance — no dark mode overrides needed for standard alert colors. `_flash.scss` should only contain positional or spacing adjustments if needed (e.g., adding margin below the flash zone). May be near-empty for Phase 2.

---

### `app/assets/stylesheets/application.bootstrap.scss` (stylesheet manifest, transform)

**Analog:** self — current file, lines 1-48

**Existing @import pattern** (lines 41-47 — project partials block):
```scss
// 5. Project design tokens — AFTER all Bootstrap partials.
//    _theme.scss overrides Bootstrap's [data-bs-theme="dark"] block via cascade.
@import 'theme';
@import 'spacing';
@import 'typography';

// 6. Icon font — always last
@import 'bootstrap-icons/font/bootstrap-icons';
```

**What to add** — insert new imports after `@import 'typography'` and before the icon font line:
```scss
@import 'navbar';
@import 'flash';
```

Result block:
```scss
@import 'theme';
@import 'spacing';
@import 'typography';
@import 'navbar';
@import 'flash';

// 6. Icon font — always last
@import 'bootstrap-icons/font/bootstrap-icons';
```

**Constraint:** Never add CSS rules directly to `application.bootstrap.scss` — it is a pure import manifest (enforced by line 2 comment: "Pure import manifest — no CSS rules in this file.").

---

### `app/views/dashboard/index.html.slim` (view, request-response — modify only)

**Analog:** self — current file, lines 3-7

**Lines to remove** (lines 3-7 — inline flash blocks that will be served by layout):
```slim
  - if flash[:notice]
    .alert.alert-success= flash[:notice]
  - if flash[:alert]
    .alert.alert-danger= flash[:alert]
```

After removal, line 2 (`h1.mb-4 Добро пожаловать...`) immediately follows line 1 (`.container.py-4`). No other changes to this file.

**Pitfall:** If `render "layouts/flash"` is added to `application.html.slim` before removing these inline blocks, flash messages will appear twice (Pitfall 3 in RESEARCH.md).

---

### `app/views/leagues/index.html.slim` (view, request-response — modify only)

**Analog:** `app/views/users/index.html.slim` lines 4-5 (same inline flash pattern being removed)

**Lines to remove** (lines 6-7 of `leagues/index.html.slim`):
```slim
  - if flash[:notice]
    .alert.alert-success= flash[:notice]
```

After removal, the `- if @leagues.any?` block (currently line 9) moves up to become line 7. No other changes.

**Note:** `app/views/users/index.html.slim` lines 4-5 also contain an identical inline flash block — remove it there as well (same pattern, same fix). This is not in the Phase 2 scope list but is an identical change required to avoid double-rendering.

---

## Shared Patterns

### Slim Partial Rendering
**Source:** `app/views/layouts/application.html.slim` (existing pattern of `= yield :head`)
**Apply to:** All partial renders in `application.html.slim`
```slim
= render "layouts/navbar"
= render "layouts/flash"
```
The `"layouts/partial_name"` path convention resolves to `app/views/layouts/_partial_name.html.slim`.

### CSS Token Consumption
**Source:** `app/assets/stylesheets/_theme.scss` lines 6-23
**Apply to:** `_navbar.scss`, `_flash.scss`

Available tokens relevant to Phase 2:
```scss
--color-bg-navbar:    #161b22;   // navbar surface
--color-bg-surface:   #21262d;   // cards and dropdowns
--color-text-primary: #e6edf3;
--color-text-muted:   #8b949e;
--color-border:       #30363d;
--color-accent:       #2f81f7;
```
And spacing tokens from `_spacing.scss`: `--space-1` through `--space-8`.

### Stimulus Controller File Naming
**Source:** `app/javascript/controllers/index.js` line 3 (`eagerLoadControllersFrom`)
**Apply to:** `navbar_controller.js`, `flash_controller.js`

`eagerLoadControllersFrom` auto-registers any file matching `*_controller.js` in `app/javascript/controllers/`. No manual registration needed. Stimulus converts `navbar_controller.js` → identifier `navbar`, `flash_controller.js` → identifier `flash`.

### Bootstrap Import Line
**Source:** `app/javascript/controllers/hello_controller.js` line 1
**Apply to:** `navbar_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"
```
For `navbar_controller.js` only, also add:
```javascript
import { Collapse } from "bootstrap"
```
Bootstrap is pinned in `config/importmap.rb` and served via `node_modules/bootstrap/dist/js`. Named import `{ Collapse }` works with the bundle.

### Inline Flash Block Removal
**Source:** `app/views/dashboard/index.html.slim` lines 3-7 and `app/views/leagues/index.html.slim` lines 6-7
**Apply to:** Any view that has an inline `- if flash[:*]` block after layout consolidation

Pattern being removed (identical across all three view files):
```slim
- if flash[:notice]
  .alert.alert-success= flash[:notice]
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `app/javascript/controllers/navbar_controller.js` | Stimulus controller | event-driven | No existing Stimulus controllers with targets or Bootstrap API delegation — `hello_controller.js` provides only file structure |
| `app/javascript/controllers/flash_controller.js` | Stimulus controller | event-driven | No existing Stimulus controllers with `values`, `connect`/`disconnect` lifecycle — `hello_controller.js` provides only file structure |

Both controllers have full reference implementations in RESEARCH.md (Pattern 2 and Pattern 3 / Code Examples section) and should be copied verbatim from there, not inferred.

---

## Metadata

**Analog search scope:** `app/views/`, `app/assets/stylesheets/`, `app/javascript/controllers/`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-09

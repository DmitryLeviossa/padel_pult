# Phase 2: Layout Shell - Research

**Researched:** 2026-05-09
**Domain:** Rails Slim layout, Bootstrap 5 navbar, Stimulus.js, flash messages
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAY-01 | Application navbar redesigned — dark navy surface, brand, nav links with active states, user avatar/menu, fully responsive | Bootstrap 5 navbar HTML structure verified; active state via `current_page?` helper; custom CSS for `--color-bg-navbar` surface; User model has `full_name` and `photo` attachment |
| LAY-02 | Flash messages moved to `application.html.slim` and restyled for dark theme — dark-aware alert colors, auto-dismiss via Stimulus | Bootstrap `.alert-dismissible` with `data-bs-dismiss` documented; Stimulus auto-dismiss pattern researched; currently flash lives in individual page views — must consolidate |
| LAY-03 | Page body and background layers correct — dark base background, surface color distinct from navbar | `--color-bg-base: #0d1117` (body) vs `--color-bg-navbar: #161b22` (navbar) already defined in `_theme.scss`; body background flows from `$body-bg` Bootstrap override |
| LAY-04 | Mobile hamburger menu implemented with Stimulus controller — responsive collapse on small screens | Bootstrap Collapse plugin available (bundle confirmed); Stimulus toggle pattern researched; both Bootstrap-native and Stimulus approaches documented |
</phase_requirements>

---

## Summary

Phase 2 builds directly on Phase 1's CSS token system. The current `application.html.slim` is a minimal 44-line file with a flat navbar — no partials, no flash messages, no responsive collapse, and no active link states. All four requirements are changes to this single layout file plus new SCSS and Stimulus controller additions.

The color tokens needed are already defined: `--color-bg-navbar: #161b22` for the navbar surface, `--color-bg-base: #0d1117` for the page body, and `--color-accent: #2f81f7` for the active link indicator. No new color decisions are needed. The primary work is structural: converting the flat inline navbar into a proper Bootstrap `navbar-expand-lg` with collapse, extracting it to a partial, adding flash message rendering to the layout, and writing a `navbar_controller.js` Stimulus controller.

Bootstrap's Collapse plugin is already available via `import * as bootstrap from "bootstrap"` in `application.js`. The `data-bs-toggle="collapse"` approach therefore works natively. LAY-04 requires a Stimulus controller explicitly — the correct implementation is a Stimulus controller that calls Bootstrap's `Collapse` API directly (not reimplementing toggle logic), keeping Bootstrap JS as the single source of truth for animation state.

**Primary recommendation:** Extract the navbar to `app/views/layouts/_navbar.html.slim`, add flash messages to `application.html.slim` via a `_flash.html.slim` partial, write `navbar_controller.js` that wraps Bootstrap's Collapse API, and add a `_navbar.scss` partial to `application.bootstrap.scss`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Navbar HTML structure | Frontend Server (SSR) | — | Slim partial rendered by Rails; user auth state evaluated server-side |
| Active link state (`aria-current`, `.active`) | Frontend Server (SSR) | — | `current_page?` Rails helper resolves server-side per request |
| User avatar/menu | Frontend Server (SSR) | — | `current_user` is a server-side Devise helper |
| Flash message rendering | Frontend Server (SSR) | — | `flash` hash available in layout render cycle |
| Flash auto-dismiss | Browser / Client | — | Stimulus controller: setTimeout to remove element after delay |
| Flash manual dismiss | Browser / Client | — | Bootstrap `data-bs-dismiss="alert"` or Stimulus `close` action |
| Mobile hamburger collapse | Browser / Client | — | Stimulus controller wrapping Bootstrap's Collapse API |
| Navbar background color | Static CSS | — | `--color-bg-navbar` custom property from `_theme.scss` |
| Page body background | Static CSS | — | `--color-bg-base` via Bootstrap `$body-bg` override — already active |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bootstrap 5 (SCSS) | 5.3.8 [VERIFIED: package.json] | Navbar component CSS, collapse animations, alert styles | Already installed; navbar/alert/collapse partials already imported in `application.bootstrap.scss` |
| Bootstrap 5 (JS bundle) | 5.3.x [VERIFIED: node_modules/bootstrap/dist/js/bootstrap.bundle.min.js] | Collapse plugin for navbar animation | Already served via Propshaft from `node_modules/bootstrap/dist/js`; pinned in `importmap.rb` |
| Stimulus | ^3.x [VERIFIED: `@hotwired/stimulus` in importmap.rb] | `navbar_controller.js` and `flash_controller.js` | Already installed with `stimulus-rails` gem; `eagerLoadControllersFrom` auto-loads any new `*_controller.js` |
| Slim | [VERIFIED: all views are `.html.slim`] | Layout and partial templates | Project's established template language |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bootstrap Icons | 1.11.3 [VERIFIED: package.json] | Hamburger icon (`bi-list`), close icon (`bi-x`) | Already imported last in `application.bootstrap.scss` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Stimulus wrapping Bootstrap Collapse | Pure `data-bs-toggle="collapse"` on button | Bootstrap-native requires no JS — but LAY-04 explicitly requires a Stimulus controller. Use Stimulus that delegates to Bootstrap's API |
| Bootstrap `.alert-dismissible` + `data-bs-dismiss` | Custom Stimulus remove | Bootstrap's built-in dismiss is sufficient for manual close; Stimulus adds only the auto-dismiss timeout |
| `current_page?` Rails helper | Stimulus-based active detection | `current_page?` is accurate server-side per request; no client-side detection needed for SSR app |

**Installation:** No new packages required. Phase 2 uses only what is already installed.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser request → Rails router → ApplicationController
                                        │
                                        ▼
                              application.html.slim (layout)
                                        │
                              ┌─────────┼──────────────┐
                              ▼         ▼               ▼
                        <head>     _navbar.slim    _flash.slim
                        (Phase 1)       │               │
                                   navbar CSS      flash CSS
                                   (dark surface)  (alert variants)
                                        │               │
                                        ▼               ▼
                              navbar_controller.js  flash_controller.js
                              (Stimulus)            (Stimulus)
                                   │                    │
                              Bootstrap               setTimeout
                              Collapse API            → element.remove()
                              (toggle show/collapse)
                                        │
                                        ▼
                               yield (page content)
                               sits on --color-bg-base
```

### Recommended Project Structure

```
app/
├── assets/stylesheets/
│   ├── application.bootstrap.scss   # add: @import 'navbar'; @import 'flash'
│   ├── _navbar.scss                 # navbar surface, active link, avatar styles
│   └── _flash.scss                  # flash message positioning and overrides
├── javascript/controllers/
│   ├── navbar_controller.js         # hamburger toggle via Bootstrap Collapse API
│   └── flash_controller.js          # auto-dismiss with setTimeout
└── views/
    └── layouts/
        ├── application.html.slim    # add: render _navbar, render _flash
        ├── _navbar.html.slim        # extracted navbar partial
        └── _flash.html.slim         # flash messages partial
```

### Pattern 1: Bootstrap Navbar Structure (Slim)

**What:** Convert the current flat navbar to Bootstrap's responsive `navbar-expand-lg` structure with a toggler button and collapsible content area.

**When to use:** Required for LAY-01 and LAY-04 — the collapse div is what Bootstrap's Collapse plugin (and our Stimulus controller) toggle.

**Example:**
```slim
/ app/views/layouts/_navbar.html.slim
/ Source: Bootstrap 5.3 navbar docs [CITED: getbootstrap.com/docs/5.3/components/navbar/]

nav.navbar.navbar-expand-lg data-controller="navbar" style="background-color: var(--color-bg-navbar); border-bottom: 1px solid var(--color-border);"
  .container-fluid
    = link_to "Padel Pult", root_path, class: "navbar-brand fw-semibold"

    button.navbar-toggler type="button" data-action="navbar#toggle" aria-controls="navbarCollapse" aria-expanded="false" aria-label="Toggle navigation"
      span.navbar-toggler-icon

    #navbarCollapse.collapse.navbar-collapse data-navbar-target="menu"
      ul.navbar-nav.me-auto.mb-2.mb-lg-0
        - if user_signed_in?
          li.nav-item
            = link_to "Лиги", leagues_path, class: "nav-link #{current_page?(leagues_path) || request.path.start_with?('/leagues') ? 'active' : ''}", aria: { current: (current_page?(leagues_path) ? 'page' : nil) }
          li.nav-item
            = link_to "Турниры", tournaments_path, class: "nav-link #{current_page?(tournaments_path) || request.path.start_with?('/tournaments') ? 'active' : ''}", aria: { current: (current_page?(tournaments_path) ? 'page' : nil) }
          li.nav-item
            = link_to "Игроки", users_path, class: "nav-link #{current_page?(users_path) ? 'active' : ''}", aria: { current: (current_page?(users_path) ? 'page' : nil) }

      - if user_signed_in?
        ul.navbar-nav.ms-auto.align-items-center.gap-2
          li.nav-item.dropdown
            a.nav-link.dropdown-toggle href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false"
              .d-inline-flex.align-items-center.justify-content-center.rounded-circle style="width:32px;height:32px;background:var(--color-bg-surface);border:1px solid var(--color-border);font-size:0.75rem;font-weight:600;"
                = current_user.full_name.split.map(&:first).first(2).join.upcase
            ul.dropdown-menu.dropdown-menu-end
              li
                = link_to "Редактировать аккаунт", edit_user_registration_path, class: "dropdown-item"
              li
                hr.dropdown-divider
              li
                = button_to "Выйти", destroy_user_session_path, method: :delete, class: "dropdown-item text-danger border-0 bg-transparent w-100 text-start"
      - else
        ul.navbar-nav.ms-auto
          li.nav-item
            = link_to "Войти", new_user_session_path, class: "nav-link"
          li.nav-item
            = link_to "Регистрация", new_user_registration_path, class: "btn btn-primary btn-sm ms-2"
```

**Note on active states:** Rails' `current_page?` takes an exact path. For section-level active states (e.g., leagues show/edit should also highlight Лиги), use `request.path.start_with?('/leagues')`. [VERIFIED: `request.path` is available in view context via ActionDispatch]

### Pattern 2: Stimulus Navbar Controller (Bootstrap Collapse Delegation)

**What:** A Stimulus controller that uses Bootstrap's `Collapse` API to toggle the navbar collapse. Delegates to Bootstrap for animation; Stimulus handles only the trigger wiring.

**When to use:** LAY-04 requires a Stimulus controller. This approach avoids reimplementing Bootstrap's toggle logic.

**Why delegate to Bootstrap:** The `data-bs-toggle="collapse"` attribute would work without Stimulus. Adding Stimulus means the controller owns the trigger but delegates collapse behavior to Bootstrap's existing plugin — single source of truth for animation state.

**Example:**
```javascript
// Source: Bootstrap 5 Collapse API [CITED: getbootstrap.com/docs/5.3/components/collapse/]
// app/javascript/controllers/navbar_controller.js

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

**HTML wiring** (in `_navbar.html.slim`):
- `data-controller="navbar"` on the `<nav>`
- `data-action="navbar#toggle"` on the toggler button
- `data-navbar-target="menu"` on the `#navbarCollapse` div

**Alternative — pure Stimulus class toggle (no Bootstrap API):**
```javascript
// Simpler but loses Bootstrap's height animation
toggle() {
  this.menuTarget.classList.toggle("show")
  this.menuTarget.classList.toggle("collapse")
}
```

The Bootstrap API approach is preferred because it preserves the CSS transition animation. [ASSUMED — preference for Bootstrap API over class toggle]

### Pattern 3: Flash Messages in Layout (Stimulus Auto-Dismiss)

**What:** Flash messages rendered once in the layout file, styled as Bootstrap dismissible alerts, with a Stimulus controller that auto-dismisses after 5 seconds.

**When to use:** LAY-02 requires flash messages in `application.html.slim`. Currently they are duplicated in individual page views — this consolidates them.

**Current state:** Flash rendering exists in `dashboard/index.html.slim` and `leagues/index.html.slim` as inline Bootstrap alert divs. These must be removed from individual pages once the layout partial handles them.

**Flash partial example:**
```slim
/ app/views/layouts/_flash.html.slim
- flash.each do |type, message|
  - alert_class = { "notice" => "alert-success", "alert" => "alert-danger", "warning" => "alert-warning", "info" => "alert-info" }.fetch(type, "alert-secondary")
  .alert.alert-dismissible.fade.show role="alert" class=alert_class data-controller="flash" data-flash-delay-value="5000"
    = message
    button.btn-close type="button" data-bs-dismiss="alert" data-action="flash#close" aria-label="Close"
```

**Stimulus flash controller:**
```javascript
// Source: Pattern from [CITED: gist.github.com/secretpray/f5a56475d7abd06b9ebf7f7c72040f1e]
// app/javascript/controllers/flash_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 }
  }

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

**Layout integration** — in `application.html.slim` after the navbar render:
```slim
= render "layouts/flash"
```

### Pattern 4: Navbar SCSS Partial

**What:** A dedicated `_navbar.scss` for navbar-specific overrides — background, active link indicator, avatar circle, toggler border.

**When to use:** Keep all navbar CSS isolated; Phase 1's `_theme.scss` provides the token values.

**Example:**
```scss
// app/assets/stylesheets/_navbar.scss
// Navbar surface and link overrides — uses Phase 1 tokens

.navbar {
  background-color: var(--color-bg-navbar) !important;
  border-bottom: 1px solid var(--color-border);

  .navbar-brand {
    color: var(--color-text-primary);
    font-weight: 600;

    &:hover {
      color: var(--color-accent);
    }
  }

  .nav-link {
    color: var(--color-text-muted);
    padding: var(--space-2) var(--space-3);
    border-radius: var(--bs-border-radius-sm);
    transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out;

    &:hover {
      color: var(--color-text-primary);
      background-color: rgba(255, 255, 255, 0.05);
    }

    &.active {
      color: var(--color-accent);
      font-weight: 600;
    }
  }

  // Hamburger toggler — remove default border on dark surface
  .navbar-toggler {
    border-color: var(--color-border);
    color: var(--color-text-muted);

    &:focus {
      box-shadow: 0 0 0 0.25rem rgba(47, 129, 247, 0.25);
    }
  }
}
```

### Pattern 5: Application Layout Integration

**What:** Updated `application.html.slim` that renders navbar and flash partials, and adds a main content wrapper with correct background.

**Example:**
```slim
/ app/views/layouts/application.html.slim (updated)
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
    = stylesheet_link_tag "application", "data-turbo-track": "reload"
    = javascript_importmap_tags
  body
    = render "layouts/navbar"
    = render "layouts/flash"
    main.py-4
      = yield
```

**Note:** The `<main>` wrapper with `py-4` replaces each page's `.container.py-4` — check whether individual page views also have `.container` wrappers before removing. Most views already have `.container` internally, so `<main>` should not add a `.container` here.

### Anti-Patterns to Avoid

- **Keeping `navbar-dark bg-dark` classes:** These legacy classes still work with `data-bs-theme="dark"` on `<html>`, but they set Bootstrap's `--bs-navbar-color` based on Bootstrap's own dark palette rather than our tokens. Remove them and use explicit CSS via `_navbar.scss`.
- **Putting flash in individual page views:** Flash should only render in the layout. After adding the layout partial, scan and remove the inline flash blocks from `dashboard/index.html.slim`, `leagues/index.html.slim`, and any others.
- **Using `data-bs-toggle="collapse"` AND a Stimulus `navbar#toggle` on the same button:** These would double-fire. If using Stimulus, remove `data-bs-toggle` from the button and let Stimulus call the Bootstrap API.
- **Hardcoding navbar background with `bg-dark`:** `bg-dark` maps to `$dark: #21262d` (card surface) — not the navbar surface `#161b22`. Must use inline `style` or `_navbar.scss` override.
- **Using `button_to` for logout inside dropdown on mobile:** `button_to` generates a `<form>` which gets correct DELETE method handling but can have styling issues inside `.dropdown-menu`. Test on mobile.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Navbar collapse animation | Custom CSS height transition | Bootstrap's Collapse plugin | Bootstrap handles `height: 0 → auto` transition with correct overflow; reimplementing this has edge cases |
| Flash dismiss | Custom JS DOM removal | Bootstrap `data-bs-dismiss="alert"` + Stimulus timeout | Bootstrap's `.fade.show` transition already in the CSS; just clear the class and remove |
| Alert color mapping | Custom CSS per flash type | Bootstrap `.alert-success/danger/warning/info` | These variants already respect `data-bs-theme="dark"` — no additional dark mode CSS needed |
| Active nav detection | JavaScript URL comparison | Rails `current_page?` helper | Server-side helper is accurate and requires zero JavaScript |
| User initials fallback | Custom image proxy or upload requirement | Inline initials avatar with CSS | `current_user.full_name` already returns name or email; extract first letters in view |

**Key insight:** Bootstrap's alert and collapse components in v5 already support dark theme through CSS variable inheritance — no custom dark overrides needed for the standard variants.

---

## Current State Audit (What Exists Now)

### `application.html.slim` (44 lines, verified)

**What's there:**
- `html data-bs-theme="dark"` — Phase 1 complete [VERIFIED]
- Google Fonts Inter links — Phase 1 complete [VERIFIED]
- `nav.navbar.navbar-expand-lg.navbar-dark.bg-dark` — flat navbar, no hamburger toggler, no collapse wrapper [VERIFIED]
- Nav links as `link_to` with `text-light text-decoration-none small` classes — not using Bootstrap `.nav-link` class [VERIFIED]
- `= yield` with no wrapping `<main>` element [VERIFIED]
- **No flash messages in layout** — flash lives in individual page views [VERIFIED]

**What's missing for Phase 2:**
- Hamburger toggler button with `data-bs-toggle` or Stimulus action
- `.collapse.navbar-collapse` wrapper div
- `.nav-item` / `.nav-link` structure for Bootstrap nav
- Active link state logic
- User avatar/dropdown (currently just `span.text-light.small= current_user.email`)
- Flash partial render
- `<main>` wrapper

### Flash Messages (current)

Inline in `dashboard/index.html.slim` (lines 4-7): `flash[:notice]` → `.alert.alert-success`, `flash[:alert]` → `.alert.alert-danger` [VERIFIED]
Inline in `leagues/index.html.slim` (lines 6-7): `flash[:notice]` → `.alert.alert-success` [VERIFIED]
Not present in: tournaments views, users index, devise views [VERIFIED by grep]

### Stimulus Controllers (current)

- `application.js` — standard setup, `debug: false` [VERIFIED]
- `index.js` — `eagerLoadControllersFrom("controllers", application)` [VERIFIED]
- `hello_controller.js` — placeholder, can be deleted or kept [VERIFIED]

**No existing navbar or flash controllers.** Both must be created in Phase 2.

### SCSS Partials (Phase 1 output, current)

- `_variables.scss` — Bootstrap `$variable` overrides [VERIFIED]
- `_theme.scss` — `:root { --color-* }` + `[data-bs-theme="dark"]` overrides [VERIFIED]
- `_spacing.scss` — `--space-1` through `--space-16` [VERIFIED]
- `_typography.scss` — link decoration override [VERIFIED]
- `application.bootstrap.scss` — includes all four partials, `bootstrap/scss/navbar` and `bootstrap/scss/alert` already imported [VERIFIED]

Phase 2 must add `_navbar.scss` and `_flash.scss` and import them in `application.bootstrap.scss`.

---

## Common Pitfalls

### Pitfall 1: Bootstrap's `data-bs-toggle` and Stimulus Both Firing

**What goes wrong:** Hamburger click triggers Bootstrap's built-in collapse AND Stimulus toggle, causing double-fire — menu opens and immediately closes.
**Why it happens:** `data-bs-toggle="collapse"` is handled by Bootstrap's JavaScript at the DOM level. If the same button also has `data-action="navbar#toggle"`, both handlers fire.
**How to avoid:** Choose one mechanism. For Stimulus-owned toggle: omit `data-bs-toggle` from the button; let the Stimulus controller call `Collapse.getOrCreateInstance(target).toggle()`. For Bootstrap-native: omit `data-controller` and `data-action` entirely.
**Warning signs:** Menu flashes open and closes immediately on button click.

### Pitfall 2: `bg-dark` Maps to Card Surface, Not Navbar Surface

**What goes wrong:** Using `bg-dark` class on navbar gives `background-color: #21262d` (card surface `--color-bg-surface`) instead of `#161b22` (navbar surface `--color-bg-navbar`).
**Why it happens:** `$dark: #21262d` is the Bootstrap variable override from Phase 1 `_variables.scss`. Bootstrap's `.bg-dark` utility maps to `$dark`. The navbar surface is a different, lighter shade intentionally.
**How to avoid:** Do not use `.bg-dark` on the navbar. Use `style="background-color: var(--color-bg-navbar)"` inline or via `_navbar.scss`.
**Warning signs:** Navbar and card surfaces look identical — no visual depth layering.

### Pitfall 3: Flash Rendering Twice After Moving to Layout

**What goes wrong:** Flash messages appear twice — once from the layout partial and once from the old inline blocks still in `dashboard/index.html.slim` and `leagues/index.html.slim`.
**Why it happens:** Flash is a hash that persists until read. Reading it twice in the same request renders it twice.
**How to avoid:** After adding `render "layouts/flash"` to `application.html.slim`, delete the flash blocks from all individual view files. The grep confirmed they exist in at least `dashboard/index.html.slim` and `leagues/index.html.slim`.
**Warning signs:** Two identical flash alerts appear stacked on dashboard or leagues pages.

### Pitfall 4: `current_page?` Returns False for Section Sub-Pages

**What goes wrong:** Nav link for "Лиги" is not highlighted when viewing `leagues/show`, `leagues/new`, or `leagues/edit`.
**Why it happens:** `current_page?(leagues_path)` matches only the index URL `/leagues` exactly.
**How to avoid:** Use `request.path.start_with?('/leagues')` for section-level active detection. Similarly `/tournaments` and `/users` for those sections.
**Warning signs:** Nav link is unhighlighted when on a league detail page.

### Pitfall 5: `navbar-toggler-icon` Not Visible in Dark Theme

**What goes wrong:** The hamburger icon (three lines) is invisible against the dark navbar background.
**Why it happens:** `.navbar-toggler-icon` uses a background-image SVG that is light-colored only when `.navbar-dark` is applied or `data-bs-theme="dark"` is on the navbar element or an ancestor.
**How to avoid:** Since `<html data-bs-theme="dark">` is already set in Phase 1, Bootstrap automatically uses the dark-aware toggler icon SVG. Verify this renders correctly. If not, add `data-bs-theme="dark"` directly to the `<nav>` as well.
**Warning signs:** Hamburger button appears as an empty outline square with no visible lines.

### Pitfall 6: Turbo Drive Caching Flash Messages

**What goes wrong:** Flash messages reappear on browser back navigation because Turbo caches the DOM snapshot with the flash element present.
**Why it happens:** Turbo Drive saves a DOM snapshot before navigation. If the flash element is still in the DOM when navigation occurs, it reappears when the user goes back.
**How to avoid:** In the Stimulus flash controller's `connect()`, always clear the auto-dismiss timer on `disconnect()`. Additionally, mark the flash container with `data-turbo-temporary` to exclude it from Turbo's snapshot cache.
**Warning signs:** Flash messages reappear after pressing the browser back button.

---

## Code Examples

### Active Link Helper (Rails, no gem needed)

```slim
/ Source: Rails API current_page? [ASSUMED — standard Rails view helper]
/ In _navbar.html.slim
= link_to "Лиги", leagues_path, class: "nav-link #{'active' if request.path.start_with?('/leagues')}", "aria-current": (request.path.start_with?('/leagues') ? "page" : nil)
```

### Flash Partial with Bootstrap Dismissible Alerts

```slim
/ Source: Bootstrap 5.3 alerts docs [CITED: getbootstrap.com/docs/5.3/components/alerts/]
/ app/views/layouts/_flash.html.slim
- type_map = { "notice" => "alert-success", "alert" => "alert-danger", "warning" => "alert-warning", "info" => "alert-info" }
- flash.each do |type, message|
  .alert.alert-dismissible.fade.show role="alert" class=type_map.fetch(type, "alert-secondary") data-controller="flash"
    = message
    button.btn-close type="button" data-bs-dismiss="alert" data-action="flash#close" aria-label="Close"
```

### Navbar Controller (Bootstrap Collapse API)

```javascript
// Source: Bootstrap 5.3 Collapse API [CITED: getbootstrap.com/docs/5.3/javascript/collapse/]
// app/javascript/controllers/navbar_controller.js
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

### Flash Controller (Auto-Dismiss)

```javascript
// Source: Stimulus values API [CITED: stimulus.hotwired.dev/reference/values]
// app/javascript/controllers/flash_controller.js
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

### Import new SCSS partials in application.bootstrap.scss

```scss
// Add after existing @import 'typography'; line:
@import 'navbar';
@import 'flash';
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `navbar-dark bg-dark` classes | Custom CSS with `--color-bg-navbar` token | Bootstrap 5.3.0 | Color token approach gives precise control over exact surface color |
| Flash in individual page views | Flash in application layout | — | Single point of truth; no duplication across templates |
| Bootstrap `data-bs-toggle` for collapse | Stimulus controller wrapping Bootstrap Collapse API | — | Explicit LAY-04 requirement; Stimulus controller makes behavior testable and extensible |
| `dropdown-menu-dark` class | Inherits from `data-bs-theme="dark"` on `<html>` | Bootstrap 5.3.0 | `[data-bs-theme="dark"]` on `<html>` covers all dropdowns globally; `dropdown-menu-dark` is redundant |

**Deprecated/outdated:**
- `.navbar-dark` class: Still works but is the legacy approach. Bootstrap 5.3+ prefers `data-bs-theme="dark"` on the element. Since `<html data-bs-theme="dark">` is already set, `.navbar-dark` is redundant — remove it.
- `dropdown-menu-dark` class: Legacy approach replaced by inherited `data-bs-theme`. [CITED: getbootstrap.com/docs/5.3/components/navbar/]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Bootstrap Collapse API (`Collapse.getOrCreateInstance`) is importable as `import { Collapse } from "bootstrap"` via the importmap pin | Code Examples / Pattern 2 | If named import doesn't work, fall back to `import * as bootstrap from "bootstrap"; bootstrap.Collapse.getOrCreateInstance(...)` — both should work with the bundle |
| A2 | `request.path.start_with?('/leagues')` is available in Slim view context | Pattern 1 / Pitfall 4 | Standard Rails — `request` is available in views via `ActionDispatch::Request`; standard practice |
| A3 | The Stimulus flash controller's `close()` using `transitionend` event correctly handles Bootstrap's `.fade` transition | Code Examples | If Bootstrap's fade transition fires differently, the element may not remove cleanly — fallback is `setTimeout(() => this.element.remove(), 150)` |
| A4 | `data-turbo-temporary` attribute prevents Turbo from caching flash elements in snapshots | Pitfall 6 | This is a Turbo feature; if it doesn't work, flash reappears on back navigation — acceptable UX issue, not critical |

---

## Open Questions

1. **Should `<main>` wrapper include `.container` or not?**
   - What we know: Individual page views (`dashboard/index`, `leagues/index`, etc.) all start with `.container.py-4` internally
   - What's unclear: Whether to add `<main class="py-4">` (no container — pages provide their own) or `<main class="container py-4">` (container in layout)
   - Recommendation: Use `<main class="py-4">` without `.container` — let each page control its own horizontal constraint. This is more flexible for full-width pages later.

2. **User photo vs initials fallback for avatar**
   - What we know: `User` model has `has_one_attached :photo` (Active Storage). Dashboard view does not use it. Current navbar shows `current_user.email`.
   - What's unclear: LAY-01 says "user avatar/menu" — should it attempt to render the photo attachment?
   - Recommendation: Use initials-only avatar for Phase 2 (simpler, no image processing). Phase 3's COMP-02 extracts a proper `_avatar.html.slim` partial. Phase 2 just needs the dropdown menu.

3. **Remove `hello_controller.js` or keep it?**
   - What we know: It's a Rails scaffold placeholder that sets `textContent = "Hello World!"` on connect.
   - What's unclear: Whether any page uses `data-controller="hello"`.
   - Recommendation: Delete it in Phase 2 cleanup — it serves no purpose and would overwrite element content if accidentally applied.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bootstrap SCSS (navbar, alert partials) | LAY-01, LAY-02 | ✓ | 5.3.8 | — |
| Bootstrap JS bundle (Collapse plugin) | LAY-04 | ✓ | 5.3.x [VERIFIED: node_modules/bootstrap/dist/js/bootstrap.bundle.min.js] | — |
| Stimulus | LAY-02, LAY-04 | ✓ | ^3.x [VERIFIED: importmap.rb + gem] | — |
| Dart Sass (build) | SCSS partials | ✓ | 1.99.0 [VERIFIED: package.json] | — |

**Missing dependencies with no fallback:** None.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (partial) | `user_signed_in?` Devise helper gates nav links; no new routes introduced |
| V5 Input Validation | no | Flash messages originate from Rails server-side flash hash — not user input rendered without escaping |
| V6 Cryptography | no | — |

### Known Threat Patterns for Layout/Flash

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Flash XSS — rendering flash content unescaped | Tampering | Slim's `= message` auto-escapes HTML — safe. Do not use `== message` (raw) in flash partial. |
| Clickjacking via navbar links | Spoofing | Not relevant — links go to app's own routes; no external redirects in navbar |
| CSRF on logout button | Tampering | `button_to destroy_user_session_path, method: :delete` generates a form with Rails CSRF token — correct |

**No active security concerns for this phase beyond the above.** Flash message rendering is safe with Slim's default escaping.

---

## Sources

### Primary (HIGH confidence)
- `app/views/layouts/application.html.slim` — current state of layout [VERIFIED: read in session]
- `app/assets/stylesheets/application.bootstrap.scss` — SCSS import manifest [VERIFIED: read in session]
- `app/assets/stylesheets/_theme.scss` — confirmed color tokens available [VERIFIED: read in session]
- `app/assets/stylesheets/_variables.scss` — confirmed Bootstrap variable overrides [VERIFIED: read in session]
- `app/javascript/controllers/` — confirmed Stimulus setup, no existing navbar/flash controllers [VERIFIED: read in session]
- `config/importmap.rb` — confirmed `bootstrap`, `@hotwired/stimulus`, `stimulus-loading` pinned [VERIFIED: read in session]
- `config/initializers/assets.rb` — confirmed `node_modules/bootstrap/dist/js` in asset path [VERIFIED: read in session]
- `node_modules/bootstrap/dist/js/bootstrap.bundle.min.js` — confirmed Collapse class present [VERIFIED: grep in session]
- `app/models/user.rb` — confirmed `full_name` method and `has_one_attached :photo` [VERIFIED: read in session]
- `getbootstrap.com/docs/5.3/components/navbar/` — navbar structure, toggler attributes, dark theme [CITED]
- `getbootstrap.com/docs/5.3/components/alerts/` — dismissible alert structure, dark theme variants [CITED]
- `stimulus.hotwired.dev/reference/actions` — `data-action` syntax [CITED]
- `stimulus.hotwired.dev/reference/controllers` — controller patterns [CITED]

### Secondary (MEDIUM confidence)
- `gist.github.com/secretpray/f5a56475d7abd06b9ebf7f7c72040f1e` — Rails 7 Stimulus flash controller pattern [CITED]
- `railsdesigner.com/stimulus-toggle-class/` — Stimulus toggle class pattern [CITED]

### Tertiary (LOW confidence)
- None — all major claims verified from installed files or official docs.

---

## Project Constraints (from CLAUDE.md)

- Follow Rails conventions (CoC) — partials in `app/views/layouts/` prefixed with `_`
- Fat models, skinny controllers — no logic in controllers for this phase
- Use migrations for schema changes — Phase 2 has no schema changes
- Write request specs for API endpoints — Phase 2 has no new endpoints
- Write model specs for validations — Phase 2 has no new models
- Commit messages start with `feat:` or `fix:` — e.g., `feat: redesign application navbar with dark theme and mobile collapse`
- Run `bin/rubocop` before PR — no Ruby changes in Phase 2 beyond view helpers; applies to any `.rb` changes

---

## Metadata

**Confidence breakdown:**
- Current state of codebase: HIGH — all source files read directly
- Bootstrap 5 navbar patterns: HIGH — official docs verified
- Stimulus controller patterns: HIGH — official docs + verified working pattern
- Flash auto-dismiss: HIGH — pattern verified from multiple sources
- Active link detection: MEDIUM — `request.path.start_with?` is standard but not verified against this app's exact route structure
- Bootstrap Collapse named import: ASSUMED (A1) — fallback documented

**Research date:** 2026-05-09
**Valid until:** 2026-11-09 (stable stack — Bootstrap 5.x and Stimulus 3.x are stable)

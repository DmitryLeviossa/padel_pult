---
phase: 02-layout-shell
reviewed: 2026-05-09T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - app/views/layouts/_navbar.html.slim
  - app/javascript/controllers/navbar_controller.js
  - app/assets/stylesheets/_navbar.scss
  - app/views/layouts/_flash.html.slim
  - app/javascript/controllers/flash_controller.js
  - app/assets/stylesheets/_flash.scss
  - app/views/layouts/application.html.slim
  - app/assets/stylesheets/application.bootstrap.scss
  - app/views/dashboard/index.html.slim
  - app/views/leagues/index.html.slim
  - app/views/users/index.html.slim
findings:
  critical: 2
  warning: 4
  info: 4
  total: 10
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-05-09
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed the layout shell implementation: application layout, navbar, flash messages, and three index views. The overall structure is sound — Bootstrap integration is correct, Turbo/Stimulus wiring follows conventions, and all template output is properly escaped (no XSS risk). However two blockers were found: the users index exposes all registered users' email addresses to any authenticated user with no authorization gate, and the flash `close()` method silently fails to remove the DOM element in browsers/environments where CSS transitions are disabled (prefers-reduced-motion), causing invisible but permanent DOM pollution. Four warnings cover the navbar's broken aria-expanded accessibility state, a duplicate/dead inline style on the navbar element, the missing `<meta charset>` tag, and the double-close handler race on flash dismissal. Four info items cover inline styles, missing RSpec coverage, and a minor avatar initials edge case.

---

## Critical Issues

### CR-01: All Authenticated Users Can Read Every Other User's Email Address

**File:** `app/views/users/index.html.slim:14` / `app/controllers/users_controller.rb:3`

**Issue:** `UsersController#index` returns `User.all` with no authorization scope. The view then renders `user.email` in a table column. Every authenticated user — regardless of role — can visit `/users` and harvest the full email address list of every registered account. The navbar also links directly to this page for all signed-in users (`_navbar.html.slim:16`). There is no admin guard, no role column in the schema, and no `before_action` restriction in the controller. This is a privacy/data-exposure violation: personal email addresses are PII.

**Fix:** Either restrict the endpoint to admins (requires adding a role system) or remove the Email column from the public view and scope the list appropriately. Minimum safe patch with no role system:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  # Temporary: hide the endpoint entirely until authorization is designed
  before_action :require_admin!

  def index
    @users = User.order(:last_name, :first_name, :email)
  end

  private

  def require_admin!
    redirect_to root_path, alert: "Нет доступа." unless current_user.admin?
  end
end
```

Or, at minimum, remove the Email column from the view until an authorization model is in place.

---

### CR-02: Flash Element Not Removed from DOM When CSS Transitions Are Disabled

**File:** `app/javascript/controllers/flash_controller.js:15-16`

**Issue:** The `close()` method removes the `show` class and then relies on the `transitionend` event to remove the element from the DOM:

```js
close() {
  this.element.classList.remove("show")
  this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
}
```

`transitionend` only fires when a CSS transition actually completes. When the OS `prefers-reduced-motion: reduce` setting is active, browsers (including Chrome, Firefox, Safari) disable CSS transitions — Bootstrap respects this via its `@media (prefers-reduced-motion: reduce)` block. In those environments, `transitionend` never fires. The result is that the flash element becomes invisible (`opacity: 0` from `.fade` without `.show`) but is never removed from the DOM. It remains in the layout, occupying space, accumulating on every page action, and can shift layout content downward.

**Fix:** Guard with a direct removal fallback:

```js
close() {
  this.element.classList.remove("show")

  const onTransitionEnd = () => this.element.remove()
  this.element.addEventListener("transitionend", onTransitionEnd, { once: true })

  // Fallback: if no transition fires within 200ms, remove directly
  setTimeout(() => {
    this.element.removeEventListener("transitionend", onTransitionEnd)
    if (this.element.isConnected) this.element.remove()
  }, 200)
}
```

---

## Warnings

### WR-01: Navbar Toggle Button aria-expanded Is Never Updated (Accessibility Regression)

**File:** `app/views/layouts/_navbar.html.slim:5` / `app/javascript/controllers/navbar_controller.js:7-9`

**Issue:** The toggler button has `aria-expanded="false"` hardcoded:

```slim
button.navbar-toggler type="button" data-action="navbar#toggle" aria-expanded="false" ...
```

Bootstrap's `Collapse` programmatic API (`Collapse.getOrCreateInstance(el).toggle()`) fires collapse events on the collapsible element itself, but only updates `aria-expanded` on buttons that carry the `data-bs-toggle="collapse"` and `data-bs-target="#navbarCollapse"` attributes. Because our button uses `data-action="navbar#toggle"` without those Bootstrap data attributes, Bootstrap never touches its `aria-expanded` attribute. Screen readers will always announce the button as "collapsed" even when the menu is open.

**Fix — Option A (keep Stimulus controller, update aria manually):**

```js
// navbar_controller.js
toggle() {
  const collapse = Collapse.getOrCreateInstance(this.menuTarget)
  collapse.toggle()

  const isExpanded = this.menuTarget.classList.contains("show")
  // After toggle, the class state reflects the *previous* state; use BS events instead:
  this.menuTarget.addEventListener("shown.bs.collapse", () => {
    this.element.querySelector(".navbar-toggler").setAttribute("aria-expanded", "true")
  }, { once: true })
  this.menuTarget.addEventListener("hidden.bs.collapse", () => {
    this.element.querySelector(".navbar-toggler").setAttribute("aria-expanded", "false")
  }, { once: true })
}
```

**Fix — Option B (drop Stimulus controller, use Bootstrap's native toggle):**

```slim
button.navbar-toggler type="button" data-bs-toggle="collapse" data-bs-target="#navbarCollapse" aria-controls="navbarCollapse" aria-expanded="false" aria-label="Toggle navigation"
  span.navbar-toggler-icon
```

Option B removes the need for `navbar_controller.js` entirely.

---

### WR-02: Inline Style on `<nav>` Is Dead Code (Overridden by SCSS `!important`)

**File:** `app/views/layouts/_navbar.html.slim:1` and `app/assets/stylesheets/_navbar.scss:6-7`

**Issue:** The `<nav>` element carries an inline `style` attribute setting `background-color` and `border-bottom`:

```slim
nav.navbar... style="background-color: var(--color-bg-navbar); border-bottom: 1px solid var(--color-border);"
```

`_navbar.scss` sets the same two properties — and uses `!important` on `background-color`:

```scss
.navbar {
  background-color: var(--color-bg-navbar) !important;
  border-bottom: 1px solid var(--color-border);
}
```

`!important` declarations beat inline styles in the CSS cascade. The inline `background-color` is overridden and has no effect. The inline `border-bottom` is also redundant (same value, same selector). The inline style is entirely dead code and creates a false impression that two sources of truth exist.

**Fix:** Remove the `style` attribute from the `<nav>` tag entirely:

```slim
nav.navbar.navbar-expand-lg data-controller="navbar"
```

---

### WR-03: Missing `<meta charset="utf-8">` in Application Layout

**File:** `app/views/layouts/application.html.slim:1-9`

**Issue:** The layout contains no `<meta charset>` declaration. HTML5 requires the charset to be declared within the first 1024 bytes of the document. Without it, browsers use heuristic encoding detection. The views contain Cyrillic text in both template literals and user-generated content. If the server's `Content-Type` header does not include `; charset=utf-8` (which Rails sets by default, but can be stripped by proxies), the browser may misinterpret the encoding, corrupting Cyrillic characters. This is also a violation of the HTML5 specification requirement.

**Fix:** Add the charset meta tag as the first element inside `<head>`:

```slim
head
  meta charset="utf-8"
  title= content_for(:title) || "Padel Pult"
  ...
```

---

### WR-04: Double-Close Race Condition on Flash Button Click

**File:** `app/views/layouts/_flash.html.slim:5` / `app/javascript/controllers/flash_controller.js:14-16`

**Issue:** The close button carries both `data-bs-dismiss="alert"` (Bootstrap's own dismiss handler) and `data-action="flash#close"` (our Stimulus handler). On click, both fire concurrently. Bootstrap starts its own fade-and-remove sequence using an internal `transitionend` listener. Our `close()` method also attaches a `transitionend` listener. If Bootstrap's listener fires first and removes the element from the DOM, Stimulus's `disconnect()` lifecycle hook fires, clearing the timer — but our `transitionend` listener is already attached to the now-detached element. It will never fire and is not cleaned up. While this does not cause a visible bug in practice, it is an unintended interaction that will complicate future changes.

**Fix:** Remove `data-action="flash#close"` from the button and let Bootstrap's native dismiss handle manual close. The Stimulus controller only needs to handle the auto-timer:

```slim
button.btn-close type="button" data-bs-dismiss="alert" aria-label="Close"
```

The `flash_controller.js` `close()` method and `disconnect()` already handle timer cleanup correctly via the controller lifecycle.

---

## Info

### IN-01: No RSpec Tests for Layout Shell Functionality

**Files:** `app/javascript/controllers/navbar_controller.js`, `app/javascript/controllers/flash_controller.js`, `app/views/layouts/application.html.slim`

**Issue:** The project's `CLAUDE.md` requires that new functionality be covered with RSpecs before a PR is created. The `test/` directory contains minitest files for model and controller tests, but no specs exist for the layout shell, dashboard page, flash behaviour, or navbar rendering. The flash auto-dismiss logic (timer, transitionend) and the navbar's authentication-conditional rendering are non-trivial and warrant at minimum a request spec asserting the layout renders correctly for signed-in vs signed-out users.

**Fix:** Add request specs covering:
- Layout renders navbar and flash partial
- Flash messages appear and have correct CSS classes
- Authenticated user sees nav links; unauthenticated user sees login/register links

---

### IN-02: Multiple Inline Styles Should Use CSS Classes

**Files:** `app/views/leagues/index.html.slim:12`, `app/views/users/index.html.slim:20,22`, `app/views/layouts/_navbar.html.slim:22`

**Issue:** Several elements carry hardcoded inline `style` attributes for sizing and layout (e.g., `style="height: 140px; object-fit: cover;"`, `style="width: 40px; height: 40px;"`, avatar circle sizing inline). These are not overridable via CSS, conflict with design token usage established in Phase 1, and will cause duplication as similar components are added.

**Fix:** Extract to utility classes or SCSS rules. Example:

```scss
// _components.scss
.img-league-thumb { height: 140px; object-fit: cover; }
.avatar-sm { width: 40px; height: 40px; }
```

---

### IN-03: Avatar Initials Fallback Silently Empty for Users With No Name and No Email

**File:** `app/views/layouts/_navbar.html.slim:23`

**Issue:** The avatar initials are generated as:

```ruby
current_user.full_name.split.map(&:first).first(2).join.upcase
```

`User#full_name` returns `"#{first_name} #{last_name}".strip.presence || email`. If both name fields are blank AND email is an empty string (the DB default is `""`), `full_name` returns `""`, `split` returns `[]`, and `join` returns `""`. The avatar circle renders with no text — blank and undetectable. While Devise's validation normally prevents an empty email, this silently degrades rather than using a sensible default glyph.

**Fix:** Add a safe fallback:

```ruby
current_user.full_name.split.map(&:first).first(2).join.upcase.presence || "?"
```

---

### IN-04: `href="#"` on Dropdown Toggle Anchor Can Cause Scroll Jump

**File:** `app/views/layouts/_navbar.html.slim:21`

**Issue:** The user dropdown uses an `<a>` tag with `href="#"`:

```slim
a.nav-link.dropdown-toggle href="#" role="button" data-bs-toggle="dropdown"
```

On some mobile browsers and older Bootstrap versions, clicking an anchor with `href="#"` scrolls the page to the top before the dropdown opens. Bootstrap's JavaScript prevents default on `click` in its dropdown handler, so this is usually suppressed — but the behaviour is fragile across browser versions and introduces unnecessary scroll event noise.

**Fix:** Use a `<button>` element instead of an anchor for non-navigation triggers:

```slim
button.nav-link.dropdown-toggle type="button" data-bs-toggle="dropdown" aria-expanded="false"
```

---

_Reviewed: 2026-05-09_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

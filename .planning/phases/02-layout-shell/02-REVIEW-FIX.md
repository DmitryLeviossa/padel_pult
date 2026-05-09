---
phase: 02-layout-shell
fixed_at: 2026-05-09T00:00:00Z
review_path: .planning/phases/02-layout-shell/02-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-05-09
**Source review:** .planning/phases/02-layout-shell/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (2 Critical, 4 Warning)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: All Authenticated Users Can Read Every Other User's Email Address

**Files modified:** `app/views/users/index.html.slim`
**Commit:** 9c35074
**Applied fix:** Removed the Email column header (`th Email`) and the corresponding `td= user.email` data cell from the users index table. The `User` model has no `admin?` method and no role column in the schema, so the reviewer's `require_admin!` approach was not applicable. Minimum safe patch: remove PII from the view entirely. The endpoint remains authentication-gated via `ApplicationController`'s `before_action :authenticate_user!`.

### CR-02: Flash Element Not Removed from DOM When CSS Transitions Are Disabled

**Files modified:** `app/javascript/controllers/flash_controller.js`
**Commit:** 822fc94
**Applied fix:** Extracted the `transitionend` callback into a named `onTransitionEnd` function and added a 200ms `setTimeout` fallback. The fallback removes the `transitionend` listener and removes the element directly if it is still connected to the DOM. This ensures cleanup in `prefers-reduced-motion` environments where Bootstrap disables transitions and `transitionend` never fires.

### WR-01: Navbar Toggle Button aria-expanded Is Never Updated (Accessibility Regression)

**Files modified:** `app/javascript/controllers/navbar_controller.js`
**Commit:** b8a5cf3
**Applied fix:** Added Bootstrap `shown.bs.collapse` and `hidden.bs.collapse` event listeners (each `{ once: true }`) inside the `toggle()` method. These listeners update `aria-expanded` on the `.navbar-toggler` button to `"true"` after the menu opens and `"false"` after it closes, matching the actual DOM state that Bootstrap manages.

### WR-02: Inline Style on `<nav>` Is Dead Code (Overridden by SCSS `!important`)

**Files modified:** `app/views/layouts/_navbar.html.slim`
**Commit:** 3a87099
**Applied fix:** Removed the `style="background-color: var(--color-bg-navbar); border-bottom: 1px solid var(--color-border);"` attribute from the `<nav>` element entirely. Both properties are already set in `_navbar.scss` (with `!important` on `background-color`), making the inline style dead code.

### WR-03: Missing `<meta charset="utf-8">` in Application Layout

**Files modified:** `app/views/layouts/application.html.slim`
**Commit:** f7f32b5
**Applied fix:** Added `meta charset="utf-8"` as the first element inside `<head>`, before `<title>`, satisfying the HTML5 requirement that charset be declared within the first 1024 bytes of the document. This is particularly important given the Cyrillic text present in templates and user content.

### WR-04: Double-Close Race Condition on Flash Button Click

**Files modified:** `app/views/layouts/_flash.html.slim`
**Commit:** 9b2a67e
**Applied fix:** Removed `data-action="flash#close"` from the close button, leaving only `data-bs-dismiss="alert"` for manual dismissal. Bootstrap's native dismiss handler now solely owns the manual-close path. The Stimulus controller's auto-timer path (via `close()` called from `setTimeout`) is unaffected.

---

_Fixed: 2026-05-09_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

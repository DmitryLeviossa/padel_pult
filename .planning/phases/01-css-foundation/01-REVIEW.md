---
phase: 01-css-foundation
reviewed: 2026-05-09T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - package.json
  - app/views/layouts/application.html.slim
  - app/assets/stylesheets/_variables.scss
  - app/assets/stylesheets/_theme.scss
  - app/assets/stylesheets/_spacing.scss
  - app/assets/stylesheets/_typography.scss
  - app/assets/stylesheets/application.bootstrap.scss
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-05-09
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Reviewed the CSS Foundation phase: Bootstrap 5.3 dark mode integration, custom SCSS tokens, Inter font loading, spacing scale, and the application layout. The selective Bootstrap import approach is structurally sound and the variable override ordering is correct. However, two blockers were found: a missing `_close.scss` partial that leaves modal and alert dismiss buttons completely unstyled, and an `a:hover` rule in `_typography.scss` that will apply underline decoration to button elements rendered as `<a>` tags. Four warnings cover a dead design token (the navbar background color token is defined but never applied), a misleading variable comment, an incomplete spacing scale, and a `package.json` type error. Three info items address the deprecated `@import` syntax, use of deprecated `navbar-dark` class, and a gap in font-weight loading.

---

## Critical Issues

### CR-01: Missing `_close.scss` import — dismiss buttons are completely unstyled

**File:** `app/assets/stylesheets/application.bootstrap.scss:34-37`

**Issue:** `_modal.scss` and `_alert.scss` are imported and both reference `.btn-close` in their compiled output (lines 4445 and 4624 of the compiled CSS). However, `_close.scss` — the only file that defines `.btn-close` — is absent from the import manifest. As a result, dismissible alerts and modal close buttons have no dimensions, no X icon background, and no opacity styling. The class is referenced but never defined.

Verified: `grep "^\.btn-close {" app/assets/builds/application.css` returns no results.

**Fix:** Add `_close.scss` to the import manifest between `buttons` and `transitions`, which is where Bootstrap's own `bootstrap.scss` places it:

```scss
@import 'bootstrap/scss/buttons';
@import 'bootstrap/scss/close';       // ADD — required for .btn-close used by modal and alert
@import 'bootstrap/scss/transitions';
```

---

### CR-02: `a:hover { text-decoration: underline }` applies to `<a>`-rendered buttons

**File:** `app/assets/stylesheets/_typography.scss:12-14`

**Issue:** The `a:hover` rule added in `_typography.scss` is appended after all Bootstrap partials in the cascade (compiled output line ~10100). Bootstrap's `.btn` styles do not declare `text-decoration` when `$link-decoration` is `none` — the compiled `.btn` and `.btn:hover` blocks contain no `text-decoration` property. This means the lower-specificity `a:hover { text-decoration: underline }` rule bleeds through and underlines every button rendered as an anchor element (e.g., `link_to ... class: "btn btn-outline-light btn-sm"`).

Confirmed: The layout's "Выйти" (sign-out) and "Регистрация" buttons use this pattern.

**Fix:** Scope the hover underline to exclude button and nav link roles:

```scss
a:not(.btn):not(.nav-link):not(.navbar-brand):hover {
  text-decoration: underline;
}
```

Or alternatively, add an explicit `text-decoration: none` to `.btn:hover` by extending the Bootstrap override in `_theme.scss`:

```scss
// Prevent typography a:hover from underlining button anchors
.btn:hover {
  text-decoration: none;
}
```

---

## Warnings

### WR-01: `--color-bg-navbar` token is defined but never applied to the navbar

**File:** `app/assets/stylesheets/_theme.scss:9` and `app/views/layouts/application.html.slim:29`

**Issue:** The design token `--color-bg-navbar: #161b22` is declared in `_theme.scss` as a core palette decision (D-02 per the comment). The navbar in the layout uses `.bg-dark` instead. `.bg-dark` resolves to `rgba(var(--bs-dark-rgb), 1)` where `--bs-dark-rgb` is `33, 38, 45` (i.e., `#21262d` — the `$dark` override). The intended navbar color `#161b22` is never rendered. The design token exists solely in the `:root` block and has no consumers.

**Fix:** Replace `.bg-dark` on the navbar with an inline style or a dedicated utility class:

```slim
/ In application.html.slim line 29 — replace bg-dark with the token
nav.navbar.navbar-expand-lg style="background-color: var(--color-bg-navbar);"
```

Or create a utility in `_theme.scss`:

```scss
.bg-navbar {
  background-color: var(--color-bg-navbar) !important;
}
```

Then use `nav.navbar.navbar-expand-lg.bg-navbar` in the layout.

---

### WR-02: `$border-radius` comment claims "sharp corners" but value is Bootstrap's default

**File:** `app/assets/stylesheets/_variables.scss:13-16`

**Issue:** The comment reads `// Shape — Linear-inspired sharp corners`. However, `$border-radius: 0.375rem` is identical to Bootstrap's own default (`$border-radius: .375rem !default` in Bootstrap's `_variables.scss`). This variable override has no effect and the comment is misleading — 6px border radius is not "sharp corners" (that would be 0–2px). Any developer reading this file will incorrectly believe a design decision was made here.

**Fix:** Either implement the stated intent or correct the comment:

```scss
// Shape — using Bootstrap defaults (no override needed; remove if no change intended)
// $border-radius:    0.375rem;
// $border-radius-sm: 0.25rem;
// $border-radius-lg: 0.5rem;
```

Or, if sharp corners are genuinely intended:

```scss
// Shape — Linear-inspired sharp corners
$border-radius:    0.125rem;   // 2px
$border-radius-sm: 0;
$border-radius-lg: 0.25rem;    // 4px
```

---

### WR-03: Spacing scale has a gap — tokens 9, 10, 11 are missing

**File:** `app/assets/stylesheets/_spacing.scss:7-18`

**Issue:** The scale jumps from `--space-8: 2rem` (32px) directly to `--space-12: 3rem` (48px), omitting the 36px, 40px, and 44px steps. When components in later phases need spacing between 32px and 48px, there will be no token for it, which will force either magic numbers or skipping to `--space-12`. This contradicts the stated goal of the scale ("Available globally for all phases").

**Fix:** Add the missing tokens to close the gap:

```scss
--space-9:  2.25rem;   // 36px — intermediate gap
--space-10: 2.5rem;    // 40px — intermediate gap
--space-11: 2.75rem;   // 44px — intermediate gap
--space-12: 3rem;      // 48px — major section breaks
```

---

### WR-04: `package.json` — `"private"` field is a string instead of a boolean

**File:** `package.json:3`

**Issue:** `"private": "true"` is a string. The npm and yarn specifications require this field to be a boolean (`true`). A string value is treated as truthy by some tools but may cause unexpected behavior or warnings in others. The `npm publish` guard may not function correctly with a string value in some npm versions.

**Fix:**

```json
"private": true,
```

---

## Info

### IN-01: Sass `@import` is deprecated — `--silence-deprecation=import` masks the warning

**File:** `package.json:5`

**Issue:** The build command includes `--silence-deprecation=import`, confirming that all SCSS files use the deprecated `@import` syntax. Sass 1.99 (installed) still supports it, but it is scheduled for removal in Dart Sass 2.0. Bootstrap 5.x itself ships `@import`-based partials, so full migration to `@use`/`@forward` requires waiting for Bootstrap 6 or using a SASS wrapper. The silencing is the correct short-term fix, but this is a known future migration debt.

**Fix:** No action required now. Track as migration debt when Bootstrap 6 (with `@use`) is released. Document the reason for `--silence-deprecation=import` with a comment in `package.json`:

```json
"build:css:compile": "sass ./app/assets/stylesheets/application.bootstrap.scss:./app/assets/builds/application.css --no-source-map --load-path=node_modules --silence-deprecation=import,color-functions,if-function,global-builtin"
// NOTE: @import silenced because Bootstrap 5.x uses @import; migrate when Bootstrap 6 ships
```

---

### IN-02: `navbar-dark` class is deprecated in Bootstrap 5.3 in favour of `data-bs-theme`

**File:** `app/views/layouts/application.html.slim:29`

**Issue:** The navbar uses `.navbar-dark`, which Bootstrap 5.3 soft-deprecated in favour of the `data-bs-theme="dark"` attribute. Since the `<html>` element already carries `data-bs-theme="dark"`, the navbar inherits dark mode automatically. The `.navbar-dark` class is redundant and is on the Bootstrap deprecation path.

**Fix:** Remove `.navbar-dark` from the navbar class chain:

```slim
nav.navbar.navbar-expand-lg.bg-dark
```

The dark mode navbar colours will be inherited from `[data-bs-theme="dark"]` on `<html>`.

---

### IN-03: Inter font loaded at weights 400 and 600 only — browser will synthesise weight 700 if needed

**File:** `app/views/layouts/application.html.slim:18`

**Issue:** The Google Fonts URL loads `Inter:wght@400;600`. The `$headings-font-weight: 600` override in `_variables.scss` ensures Bootstrap headings use weight 600 rather than the default 700. However, if any component in a later phase uses `font-weight: bold` or `font-weight: 700` explicitly (common in third-party widgets or user-agent styles), the browser will apply synthetic bold to Inter, which renders worse than a real 700 weight.

**Fix:** Either add weight 700 to the font URL as a safety net:

```slim
link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap"
```

Or add a project-wide CSS rule to prevent synthesis:

```scss
// In _typography.scss
* {
  font-synthesis: none;
}
```

---

_Reviewed: 2026-05-09_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

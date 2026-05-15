# Phase 3: Shared Components - Pattern Map

**Mapped:** 2026-05-09
**Files analyzed:** 13 (5 new, 3 modified SCSS, 5 modified templates)
**Analogs found:** 13 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `app/views/shared/_avatar.html.slim` | partial | request-response | `app/views/layouts/_navbar.html.slim` (lines 21-23) + `app/views/layouts/_flash.html.slim` (parameterized partial) | exact |
| `app/assets/stylesheets/_cards.scss` | style | transform | `app/assets/stylesheets/_navbar.scss` | role-match |
| `app/assets/stylesheets/_forms.scss` | style | transform | `app/assets/stylesheets/_flash.scss` | role-match |
| `app/assets/stylesheets/_tables.scss` | style | transform | `app/assets/stylesheets/_navbar.scss` | role-match |
| `app/assets/stylesheets/_avatar.scss` | style | transform | `app/assets/stylesheets/_flash.scss` | role-match |
| `app/assets/stylesheets/_variables.scss` | config | transform | self (modification) | exact |
| `app/assets/stylesheets/_theme.scss` | config | transform | self (modification) | exact |
| `app/assets/stylesheets/application.bootstrap.scss` | config | transform | self (modification) | exact |
| `app/views/leagues/show.html.slim` | template | request-response | self (modification — lines 69-73) | exact |
| `app/views/users/index.html.slim` | template | request-response | self (modification — lines 7, 18-22) | exact |
| `app/views/tournaments/index.html.slim` | template | request-response | self (modification — line 6) | exact |
| `app/views/tournaments/show.html.slim` | template | request-response | self (modification — lines 50-54, 58-62) | exact |
| `app/views/devise/registrations/edit.html.slim` | template | request-response | self (modification — lines 12-16) | exact |

---

## Pattern Assignments

### `app/views/shared/_avatar.html.slim` (partial, request-response)

**Analog:** `app/views/layouts/_navbar.html.slim` lines 21-23 (initials circle inline pattern) and `app/views/layouts/_flash.html.slim` (local-variable parameterized partial pattern)

**Parameterized partial pattern** — `_flash.html.slim` (entire file, 5 lines):
```slim
- type_map = { "notice" => "alert-success", "alert" => "alert-danger", "warning" => "alert-warning", "info" => "alert-info" }
- flash.each do |type, message|
  .alert.alert-dismissible.fade.show role="alert" class=type_map.fetch(type, "alert-secondary") data-controller="flash" data-flash-delay-value="5000" data-turbo-temporary="true"
    = message
    button.btn-close type="button" data-bs-dismiss="alert" aria-label="Close"
```
Key pattern: local variables are set with `- var ||= default` at the top; the partial is stateless and driven by parameters passed via `render`.

**Initials extraction pattern** — `_navbar.html.slim` lines 21-23:
```slim
.d-inline-flex.align-items-center.justify-content-center.rounded-circle style="width:32px;height:32px;background:var(--color-bg-surface);border:1px solid var(--color-border);font-size:0.75rem;font-weight:600;color:var(--color-text-muted);"
  = current_user.full_name.split.map(&:first).first(2).join.upcase
```
Key patterns:
- Initials formula: `.full_name.split.map(&:first).first(2).join.upcase` — produces 2-letter uppercase initials
- Circle styling is 100% inline — `background:var(--color-bg-surface); border:1px solid var(--color-border);` — no CSS class dependency
- `d-inline-flex.align-items-center.justify-content-center.rounded-circle` is the Bootstrap utility stack for centering content in a circle

**Photo branch pattern** — `app/views/leagues/show.html.slim` lines 69-70:
```slim
- if league_user.user.photo.attached?
  = image_tag league_user.user.photo, class: "rounded-circle", style: "width: 40px; height: 40px; object-fit: cover;"
```
Key pattern: Active Storage check is `user.photo.attached?`; `image_tag` with `object-fit: cover` keeps aspect ratio in the circle.

**Complete partial to create** (synthesized from the two analogs above):
```slim
/ app/views/shared/_avatar.html.slim
/ Parameters:
/   user: (required) User ActiveRecord object — must respond to .full_name and .photo
/   size: (optional) Integer px size, default 40
- size ||= 40
- font_size = (size * 0.3).round(2)
- initials = user.full_name.split.map(&:first).first(2).join.upcase

- if user.photo.attached?
  = image_tag user.photo, class: "rounded-circle", style: "width: #{size}px; height: #{size}px; object-fit: cover;"
- else
  .rounded-circle.d-inline-flex.align-items-center.justify-content-center style="width: #{size}px; height: #{size}px; background: var(--color-bg-surface); border: 1px solid var(--color-border); font-size: #{font_size}rem; font-weight: 600; color: var(--color-text-muted);"
    = initials
```

---

### `app/assets/stylesheets/_cards.scss` (style, transform)

**Analog:** `app/assets/stylesheets/_navbar.scss` (entire file, 43 lines)

**File header comment pattern** — `_navbar.scss` lines 1-4:
```scss
// _navbar.scss
// Imported in application.bootstrap.scss after project theme partials (Plan 02).
// Navbar surface and link overrides — uses Phase 1 tokens from _theme.scss and _spacing.scss.
```
Key pattern: First line is filename comment; second line states import position; third line states purpose and token sources.

**CSS custom property usage pattern** — `_navbar.scss` lines 5-8:
```scss
.navbar {
  background-color: var(--color-bg-navbar) !important;
  border-bottom: 1px solid var(--color-border);
```
Key pattern: Use `var(--color-*)` semantic tokens from `_theme.scss`. Direct `background-color` and `border-*` properties (not Bootstrap custom property overrides). `!important` only when Bootstrap uses it too (Bootstrap navbar uses `bg-*` classes with `!important`).

**Nested selector pattern** — `_navbar.scss` lines 9-33:
```scss
  .navbar-brand {
    color: var(--color-text-primary);
    font-weight: 600;

    &:hover {
      color: var(--color-accent-hover);
    }
  }
```
Key pattern: Shallow SCSS nesting for sub-components; `&:hover` for state variants.

**Complete `_cards.scss` to create:**
```scss
// _cards.scss
// Imported in application.bootstrap.scss after @import 'flash' (Plan 03).
// Card dark surface + border overrides — bypasses Bootstrap's cascade-ineffective --bs-card-bg.
// Direct property overrides win by source order (equal specificity, imported after Bootstrap).

.card {
  background-color: var(--color-bg-surface);
  border-color: var(--color-border);
}

.card-header,
.card-footer {
  background-color: transparent;
  border-color: var(--color-border);
}
```

---

### `app/assets/stylesheets/_forms.scss` (style, transform)

**Analog:** `app/assets/stylesheets/_flash.scss` (entire file, 11 lines)

**Minimal targeted override pattern** — `_flash.scss` lines 1-11:
```scss
// _flash.scss
// Flash message positional overrides.
// Bootstrap .alert-success/danger/warning/info dark variants are automatic via
// data-bs-theme="dark" on <html> — no custom dark color overrides needed here.

.alert {
  margin-bottom: 0;
  border-radius: 0;
  border-left: none;
  border-right: none;
}
```
Key patterns:
- Header comment explains what Bootstrap handles automatically and what this file adds
- Minimal rule surface: only the properties Bootstrap does NOT handle correctly on its own
- No nesting needed for simple element selectors

**Complete `_forms.scss` to create:**
```scss
// _forms.scss
// Imported in application.bootstrap.scss after @import 'cards' (Plan 03).
// Supplemental form dark styles — $input-bg override in _variables.scss handles background.
// This file covers browser-native chrome (date pickers) not controlled by Bootstrap.

// Native date/time pickers — force browser chrome into dark mode
input[type="date"],
input[type="time"],
input[type="datetime-local"] {
  color-scheme: dark;
}
```

---

### `app/assets/stylesheets/_tables.scss` (style, transform)

**Analog:** `app/assets/stylesheets/_navbar.scss` (structure) and `app/assets/stylesheets/_flash.scss` (minimal override philosophy)

**Token usage pattern** — copy from `_navbar.scss` lines 19-21:
```scss
    color: var(--color-text-muted);
    padding: var(--space-2) var(--space-3);
    border-radius: var(--bs-border-radius-sm);
```
Key pattern: Use `var(--color-text-muted)` for de-emphasised header text; use design token vars throughout.

**Complete `_tables.scss` to create:**
```scss
// _tables.scss
// Imported in application.bootstrap.scss after @import 'forms' (Plan 03).
// Table thead dark header — after removing thead.table-dark from templates.
// Bootstrap .table uses CSS vars for borders/text/hover that already follow _theme.scss tokens.

thead > tr > th {
  background-color: var(--color-bg-surface);
  color: var(--color-text-muted);
  font-weight: 600;
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;
}
```

---

### `app/assets/stylesheets/_avatar.scss` (style, transform)

**Analog:** `app/assets/stylesheets/_flash.scss` (minimal / potentially empty partial)

Per RESEARCH.md Open Question 1: the navbar avatar uses 100% inline styles and works correctly. If all avatar styles stay inline in the Slim partial, `_avatar.scss` may be an empty placeholder or omitted. If created, follow `_flash.scss`'s minimal-override structure.

**Decision for planner:** Create `_avatar.scss` as an empty placeholder with the header comment only, to keep the `application.bootstrap.scss` manifest consistent. If Phase 5 adds hover effects, styles go here.

```scss
// _avatar.scss
// Imported in application.bootstrap.scss after @import 'tables' (Plan 03).
// Avatar component styles — currently all styles are inline in _avatar.html.slim.
// Reserved for Phase 5 hover/transition additions (.avatar-circle class).
```

---

### `app/assets/stylesheets/_variables.scss` (config, modification)

**Analog:** self — add one line following the existing variable declaration pattern.

**Existing pattern** — `_variables.scss` lines 1-27 (entire file):
```scss
// _variables.scss
// Bootstrap SCSS variable overrides.
// Imported after bootstrap/scss/functions, BEFORE bootstrap/scss/variables.
// No !default — these are unconditional project values.

// Color palette (per D-01 through D-07 and Bootstrap variable mapping from UI-SPEC.md)
$primary:          #2f81f7;
$body-bg:          #0d1117;
$body-color:       #e6edf3;
$border-color:     #30363d;
$dark:             #21262d;
...
```
Key patterns:
- No `!default` — these are unconditional overrides, Bootstrap's `!default` values never win
- Grouped by concern with blank lines between groups
- Inline comments reference the Bootstrap variable name being overridden

**Change: add after line 11** (after `$dark` in the color palette group):
```scss
$input-bg:         var(--color-bg-surface); // COMP-03: dark input surface; propagates to form-control, form-select, textarea
```

---

### `app/assets/stylesheets/_theme.scss` (config, modification)

**Analog:** self — add two lines inside the existing `[data-bs-theme="dark"]` block.

**Existing dark block** — `_theme.scss` lines 25-44:
```scss
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
Key pattern: Each variable on its own line, aligned with spaces; grouped logically; follows `--bs-*` naming.

**Changes: add at end of the `[data-bs-theme="dark"]` block** (after line 43, before the closing `}`):
```scss
  --bs-tertiary-bg:              var(--color-bg-navbar);    // COMP-03: file-selector-button bg (#161b22)
  --bs-box-shadow-sm:            none;                       // COMP-01: suppress invisible light-theme shadows
  --bs-box-shadow:               none;                       // COMP-01: suppress box-shadow utility
```

---

### `app/assets/stylesheets/application.bootstrap.scss` (config, modification)

**Analog:** self — add four `@import` lines following the existing pattern.

**Existing import section 5** — `application.bootstrap.scss` lines 41-47:
```scss
// 5. Project design tokens — AFTER all Bootstrap partials.
//    _theme.scss overrides Bootstrap's [data-bs-theme="dark"] block via cascade.
@import 'theme';
@import 'spacing';
@import 'typography';
@import 'navbar';
@import 'flash';

// 6. Icon font — always last
@import 'bootstrap-icons/font/bootstrap-icons';
```
Key pattern: One `@import` per line, no quotes around filename, alphabetically within a logical group is NOT the rule — order follows dependency and cascade requirement.

**Change: add after `@import 'flash';` (line 47), before the icon font comment:**
```scss
@import 'cards';
@import 'forms';
@import 'tables';
@import 'avatar';
```

---

### Template modifications — avatar replacement (5 files)

**Pattern: replace the inline `if/else` photo/initials block with `render "shared/avatar"`**

**From `app/views/leagues/show.html.slim` lines 69-73** (existing pattern to remove):
```slim
                - if league_user.user.photo.attached?
                  = image_tag league_user.user.photo, class: "rounded-circle", style: "width: 40px; height: 40px; object-fit: cover;"
                - else
                  .rounded-circle.bg-secondary.d-inline-flex.align-items-center.justify-content-center style="width: 40px; height: 40px;"
                    span.text-white.small = league_user.full_name.first.upcase
```
Replacement (1 line):
```slim
                = render "shared/avatar", user: league_user.user
```

**From `app/views/users/index.html.slim` lines 18-22** (existing pattern to remove):
```slim
                - if user.photo.attached?
                  = image_tag user.photo, class: "rounded-circle", style: "width: 40px; height: 40px; object-fit: cover;"
                - else
                  .rounded-circle.bg-secondary.d-inline-flex.align-items-center.justify-content-center style="width: 40px; height: 40px;"
                    span.text-white.small = user.full_name.first.upcase
```
Replacement (1 line):
```slim
                = render "shared/avatar", user: user
```

**From `app/views/tournaments/show.html.slim` lines 50-54** (player1):
```slim
              - if pair.player1.user.photo.attached?
                = image_tag pair.player1.user.photo, class: "rounded-circle", style: "width: 40px; height: 40px; object-fit: cover;"
              - else
                .rounded-circle.bg-secondary.d-inline-flex.align-items-center.justify-content-center style="width: 40px; height: 40px;"
                  span.text-white.small = pair.player1.full_name.first.upcase
```
Replacement (1 line):
```slim
              = render "shared/avatar", user: pair.player1.user
```

**From `app/views/tournaments/show.html.slim` lines 58-62** (player2):
```slim
              - if pair.player2.user.photo.attached?
                = image_tag pair.player2.user.photo, class: "rounded-circle", style: "width: 40px; height: 40px; object-fit: cover;"
              - else
                .rounded-circle.bg-secondary.d-inline-flex.align-items-center.justify-content-center style="width: 40px; height: 40px;"
                  span.text-white.small = pair.player2.full_name.first.upcase
```
Replacement (1 line):
```slim
              = render "shared/avatar", user: pair.player2.user
```

**From `app/views/devise/registrations/edit.html.slim` lines 12-16**:
```slim
              - if resource.photo.attached? && resource.photo.blob.persisted?
                = image_tag resource.photo, class: "rounded-circle mb-2", style: "width: 100px; height: 100px; object-fit: cover;"
              - else
                .rounded-circle.bg-secondary.d-inline-flex.align-items-center.justify-content-center.mb-2 style="width: 100px; height: 100px;"
                  span.text-white.fs-2 = resource.full_name.first.upcase
```
Replacement (1 line):
```slim
              = render "shared/avatar", user: resource, size: 100
```
Note: The existing pattern has `resource.photo.attached? && resource.photo.blob.persisted?` — the avatar partial uses the simpler `user.photo.attached?`. This is correct: `attached?` already implies the blob is persisted for Active Storage.

---

### Template modifications — `thead.table-dark` removal (2 files)

**From `app/views/users/index.html.slim` line 7**:
```slim
        thead.table-dark
```
Change to:
```slim
        thead
```

**From `app/views/tournaments/index.html.slim` line 6**:
```slim
      thead.table-dark
```
Change to:
```slim
      thead
```

Note: `app/views/leagues/show.html.slim` line 35 and `app/views/tournaments/show.html.slim` line 36 already use plain `thead` (no `.table-dark`). No change needed there.

---

## Shared Patterns

### Design token CSS variables (apply to ALL new SCSS partials)
**Source:** `app/assets/stylesheets/_theme.scss` lines 7-23 (`:root` block)
```scss
:root {
  --color-bg-base:          #0d1117;
  --color-bg-navbar:        #161b22;
  --color-bg-surface:       #21262d;
  --color-text-primary:     #e6edf3;
  --color-text-muted:       #8b949e;
  --color-border:           #30363d;
  --color-accent:           #2f81f7;
}
```
Apply to: every `var()` call in `_cards.scss`, `_forms.scss`, `_tables.scss`, `_avatar.scss`.

### SCSS partial file header comment (apply to ALL new SCSS partials)
**Source:** `app/assets/stylesheets/_navbar.scss` lines 1-4
```scss
// _filename.scss
// Imported in application.bootstrap.scss after [anchor import] (Plan XX).
// Purpose description — references Phase tokens or Bootstrap behavior.
```
Apply to: `_cards.scss`, `_forms.scss`, `_tables.scss`, `_avatar.scss`.

### Slim partial local-variable defaults (apply to `_avatar.html.slim`)
**Source:** `app/views/layouts/_flash.html.slim` line 1 (variable setup before iteration)
Pattern: set computed/default locals at the top of the partial before any HTML output:
```slim
- size ||= 40
- font_size = (size * 0.3).round(2)
- initials = user.full_name.split.map(&:first).first(2).join.upcase
```

### Initials extraction formula (apply to `_avatar.html.slim`)
**Source:** `app/views/layouts/_navbar.html.slim` line 23
```slim
= current_user.full_name.split.map(&:first).first(2).join.upcase
```
Replace `current_user` with the `user` local variable. This produces 2-letter uppercase initials (e.g., "John Doe" → "JD").

### Avatar circle Bootstrap utility class stack (apply to `_avatar.html.slim`)
**Source:** `app/views/layouts/_navbar.html.slim` line 22
```slim
.d-inline-flex.align-items-center.justify-content-center.rounded-circle
```
Exact utility class stack for centering initials text inside a circular container.

### `render "shared/partial_name"` calling convention
**Source:** Rails CoC — Rails resolves `"shared/avatar"` to `app/views/shared/_avatar.html.slim` automatically.
Pass locals as keyword arguments: `render "shared/avatar", user: user, size: 40`.
The `size:` parameter is optional — the partial defaults to 40 via `- size ||= 40`.

---

## No Analog Found

All files have analogs. No files require fallback to RESEARCH.md patterns only.

---

## Metadata

**Analog search scope:** `app/assets/stylesheets/`, `app/views/layouts/`, `app/views/leagues/`, `app/views/users/`, `app/views/tournaments/`, `app/views/devise/`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-09

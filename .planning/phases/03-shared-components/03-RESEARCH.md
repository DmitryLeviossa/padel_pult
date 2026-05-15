# Phase 3: Shared Components - Research

**Researched:** 2026-05-09
**Domain:** Bootstrap 5.3 CSS custom property cascade, SCSS variable overrides, Rails Slim partials
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-01 | Card component dark-styled — elevated surface with `#21262d` background, 1px border-based depth (no invisible box-shadows), used consistently across all pages | Bootstrap's compiled `.card { --bs-card-bg: var(--bs-body-bg) }` means `_theme.scss`'s `--bs-card-bg` override is CASCADE-INEFFECTIVE (card element's own declaration wins over inherited html-level value). Requires explicit `_cards.scss` with `background-color: var(--color-bg-surface)` and `border-color: var(--color-border)`. `.shadow-sm` produces invisible black shadow on dark backgrounds — must suppress via `--bs-box-shadow-sm: none` in `_theme.scss`. |
| COMP-02 | Avatar partial extracted as `_avatar.html.slim` — initials fallback uses dark-correct surface color (replaces broken `bg-secondary` in 4+ templates) | 5 avatar `bg-secondary` instances located by grep (leagues/show:72, users/index:21, tournaments/show:53+61, devise/registrations/edit:15). Interface: `render "shared/avatar", user: [User], size: 40`. Initials: `user.full_name.split.map(&:first).first(2).join.upcase` (same pattern as navbar — verified in `_navbar.html.slim`). LeagueUser delegates `full_name` to `user` but NOT `photo` — callers must pass `.user` explicitly. |
| COMP-03 | Form controls dark-styled — `form-control`, `form-select`, `textarea`, file upload `::file-selector-button` all use dark surfaces with accent focus ring | Bootstrap compiles `$input-bg = var(--bs-body-bg)` meaning inputs default to `#0d1117` (page base), not `#21262d` (surface). Fix: add `$input-bg: var(--color-bg-surface)` to `_variables.scss` BEFORE Bootstrap compiles. Focus ring already correct: `$primary = #2f81f7` gives `rgba(47,129,247,.25)` focus ring from Phase 1. `::file-selector-button` uses `--bs-tertiary-bg` (not covered by current `_theme.scss`) — set to `var(--color-bg-navbar)`. |
| COMP-04 | Tables dark-styled — Bootstrap `--bs-table-*` CSS variables overridden, `thead.table-dark` replaced, border and hover row colors correct | `.table` already uses CSS vars that follow our theme (borders → `--bs-border-color` = `#30363d`, text → `--bs-emphasis-color` = `#fff`, hover = white at 7.5%). `thead.table-dark` hardcodes `--bs-table-bg: #212529` (Bootstrap gray-900) — must be removed from 2 templates. After removal, thead inherits `.table`'s dark theme correctly. Add `_tables.scss` for thead `<th>` visual polish. |
</phase_requirements>

---

## Summary

Phase 3 applies the Phase 1 design token system to four shared UI components: cards, avatars, form controls, and tables. The core challenge is that Bootstrap 5.3 compiles many CSS custom properties as LOCAL declarations on component elements (`.card { --bs-card-bg: ... }`), which WIN over inherited values from `[data-bs-theme="dark"]` on `<html>`. This makes several of `_theme.scss`'s existing `--bs-*` overrides cascade-ineffective for their intended targets.

The Phase 1 token system is complete and correct. What's missing is the custom CSS layer that bridges the gap between inherited tokens and component-level defaults. For cards and tables, this means adding SCSS partials that directly set `background-color` and `border-color` (not just custom property overrides). For form inputs, the cleanest solution is overriding `$input-bg` in `_variables.scss` before Bootstrap compiles — this propagates to `form-control`, `form-select`, `textarea`, and all input-group variants in a single line. The avatar partial is a pure Rails partial extraction with no CSS complexity.

The `thead.table-dark` class is the only template-level table problem — it hardcodes Bootstrap's `#212529` gray. Removing it (2 templates) and adding optional `_tables.scss` polish for `<th>` elements completes COMP-04. Five templates need the avatar circle replacement with `render "shared/avatar"`.

**Primary recommendation:** 4 new SCSS partials (`_cards.scss`, `_forms.scss`, `_tables.scss`, `_avatar.scss`), 1 new view partial (`app/views/shared/_avatar.html.slim`), plus targeted changes to `_variables.scss` and `_theme.scss` — no template changes needed except avatar substitutions (5 files) and `thead.table-dark` removal (2 files).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Card dark background + border | Static CSS (`_cards.scss`) | — | Pure CSS override; no JS or server logic involved |
| Card shadow suppression | Static CSS (`_theme.scss` token) | — | `--bs-box-shadow-sm: none` in dark theme block suppresses via CSS var |
| Avatar initials extraction | Frontend Server (SSR) | — | `user.full_name.split...` evaluated at render time in Slim partial |
| Avatar photo rendering | Frontend Server (SSR) | — | `user.photo.attached?` is an Active Storage check at render time |
| Form input dark surface | Static CSS (`_variables.scss` + `_forms.scss`) | — | `$input-bg` override propagates at SCSS compile time; `::file-selector-button` needs CSS var override |
| Focus ring color | Static CSS (`_variables.scss`) | — | `$primary = #2f81f7` already in Phase 1 — no new work |
| Table `thead` dark header | Static CSS (`_tables.scss`) | Template change | Remove `thead.table-dark` class; style with CSS vars |
| `--bs-table-*` variable overrides | Static CSS | — | CSS custom properties on `:root` or via theme block |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bootstrap 5 (SCSS) | 5.3.8 [VERIFIED: node_modules/bootstrap/package.json] | Card, form, table component base styles | Already installed; Phase 1-2 built on it |
| Dart Sass | 1.99.0 [VERIFIED: package.json from Phase 2 research] | Compiles `application.bootstrap.scss` with all partials | Project's SCSS build tool |
| Slim | [VERIFIED: all views are `.html.slim`] | `_avatar.html.slim` partial template | Project's established template language |
| Rails Partials (`render`) | Rails 8 [VERIFIED: project] | `render "shared/avatar"` for avatar reuse | Standard Rails CoC pattern for shared view fragments |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Active Storage | Rails 8 built-in [VERIFIED: user.rb has `has_one_attached :photo`] | `user.photo.attached?` check in avatar partial | Every avatar render — determines photo vs initials branch |
| Bootstrap Icons | 1.11.3 [VERIFIED: Phase 2 research] | Optional icon use in empty states | Only if needed for table/card empty states |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `$input-bg: var(--color-bg-surface)` in `_variables.scss` | Custom CSS `.form-control { background-color: ... }` in `_forms.scss` | SCSS variable override is cleaner — propagates to form-select, textarea, input-group-addon automatically; CSS rule override is more explicit but requires listing all selectors |
| 4 separate SCSS partials | Single `_components.scss` | Separate partials match Phase 2 pattern (_navbar.scss, _flash.scss) and make Phase 5 polish additions cleaner; choose 4 separate files |
| Passing `user:` (User object) to avatar partial | Accepting any duck-typed object | Always passing the User object keeps the partial simple — callers with LeagueUser explicitly pass `.user`; avoids conditional `respond_to?` logic in partial |

**Installation:** No new packages required. Phase 3 uses only what is already installed.

---

## CSS Cascade Analysis (Critical for Planning)

### Why `_theme.scss`'s Existing Overrides Are Insufficient

Bootstrap 5.3 compiles CSS custom property declarations as LOCAL values on component elements:

```css
/* Bootstrap compiled output */
.card { --bs-card-bg: var(--bs-body-bg); }   /* local to .card element */
.table { --bs-table-bg: var(--bs-body-bg); } /* local to .table element */
```

Our `_theme.scss` sets:
```css
[data-bs-theme="dark"] { --bs-card-bg: var(--color-bg-surface); } /* on <html> */
```

CSS cascade rule: A property declared on an element's OWN rule wins over an inherited value from an ancestor. The `.card` element has its own `--bs-card-bg` declaration, so the `<html>`-level value (from `[data-bs-theme="dark"]`) is never applied to `.card` elements. [VERIFIED: Bootstrap 5.3.8 compiled dist/css/bootstrap.css; CSS spec inheritance rules]

**Consequence**: `--bs-card-bg`, `--bs-card-border-color`, `--bs-input-bg`, and `--bs-table-bg` in `_theme.scss`'s dark block are cascade-ineffective for their intended targets. They affect `<html>` and any element that INHERITS these variables but has no own declaration — which excludes all Bootstrap component elements.

**The fix**: Use direct property overrides in component SCSS partials imported AFTER Bootstrap, with equal specificity but later source order:

```scss
// _cards.scss — comes after @import 'bootstrap/scss/card' in application.bootstrap.scss
.card {
  background-color: var(--color-bg-surface); // overrides Bootstrap's background-color: var(--bs-card-bg)
  border-color: var(--color-border);          // overrides Bootstrap's var(--bs-card-border-color)
}
```

This works because `.card` selector has specificity `0,1,0` = same as Bootstrap's `.card`, but our file is imported later — source order wins.

### What ALREADY Works via Cascade

| Property | Reason | Status |
|----------|--------|--------|
| Body background | `--bs-body-bg` set on `:root`; no component overrides it | ✓ Works |
| Table borders | `.table { --bs-table-border-color: var(--bs-border-color) }` — follows `--bs-border-color` which `_theme.scss` overrides | ✓ Works |
| Table hover/stripe | Uses `rgba(--bs-emphasis-color-rgb, ...)` — inherits emphasis-color | ✓ Works |
| Table text color | `--bs-table-color: var(--bs-emphasis-color)` — follows `--bs-emphasis-color` = `#fff` in dark | ✓ Works |
| Focus ring (accent blue) | `$primary = #2f81f7` in `_variables.scss` → `$focus-ring-color = rgba($primary, 0.25)` compiled | ✓ Works |
| Form-select dark arrow | Bootstrap 5.3 auto-handles via `@include color-mode(dark)` inside `_form-select.scss` | ✓ Works |
| Dropdown backgrounds | `--bs-dropdown-bg: var(--color-bg-surface)` in `_theme.scss` — dropdowns DO inherit this (no own decl) | ✓ Works |

---

## Architecture Patterns

### System Architecture Diagram

```
SCSS build (Dart Sass):
  application.bootstrap.scss
    ├── bootstrap/scss/functions
    ├── _variables.scss      ← ADD: $input-bg: var(--color-bg-surface)
    ├── bootstrap/scss/...   (compiles with overridden $input-bg)
    ├── _theme.scss          ← ADD: --bs-box-shadow-sm: none; --bs-tertiary-bg in dark block
    ├── _spacing.scss
    ├── _typography.scss
    ├── _navbar.scss
    ├── _flash.scss
    ├── _cards.scss          ← NEW: .card bg + border overrides
    ├── _forms.scss          ← NEW: ::file-selector-button, textarea overrides
    ├── _tables.scss         ← NEW: thead th dark header styles
    ├── _avatar.scss         ← NEW: .avatar-circle component styles
    └── bootstrap-icons/...

Rails request → View template
  ├── leagues/index.html.slim   (COMP-01: .card.shadow-sm → styled by _cards.scss)
  ├── leagues/show.html.slim    (COMP-02: avatar partial; COMP-04: remove thead.table-dark)
  ├── users/index.html.slim     (COMP-02: avatar partial; COMP-04: remove thead.table-dark)
  ├── tournaments/show.html.slim (COMP-02: 2 avatar partials)
  ├── devise/registrations/edit.html.slim (COMP-02: avatar partial, 100px)
  ├── leagues/new.html.slim     (COMP-03: form-control → styled by _forms.scss + $input-bg)
  ├── leagues/edit.html.slim    (COMP-03: form-control + file_field)
  └── tournaments/new.html.slim (COMP-03: form-control + form-select)
                                        ↓
                               app/views/shared/_avatar.html.slim
                               (NEW: accepts user:, size: — renders photo or initials circle)
```

### Recommended Project Structure

```
app/
├── assets/stylesheets/
│   ├── application.bootstrap.scss   # add: @import 'cards', 'forms', 'tables', 'avatar'
│   ├── _variables.scss              # add: $input-bg: var(--color-bg-surface)
│   ├── _theme.scss                  # add: --bs-box-shadow-sm: none; --bs-tertiary-bg override
│   ├── _cards.scss                  # NEW: card bg, border, shadow-sm suppression
│   ├── _forms.scss                  # NEW: ::file-selector-button, form-control border-color
│   ├── _tables.scss                 # NEW: thead th header styles
│   └── _avatar.scss                 # NEW: .avatar-circle base styles
└── views/
    └── shared/
        └── _avatar.html.slim        # NEW: avatar partial (create shared/ dir)
```

### Pattern 1: Card Dark Styling (COMP-01)

**What:** Direct `background-color` and `border-color` override on `.card` to bypass Bootstrap's cascade-ineffective `--bs-card-bg` local declaration.

**When to use:** Any `.card` element in the app.

**Example:**
```scss
// app/assets/stylesheets/_cards.scss
// Source: Bootstrap 5.3 card SCSS analysis [VERIFIED: node_modules/bootstrap/scss/_card.scss]
// Direct property override wins by source order (imported after Bootstrap).

.card {
  background-color: var(--color-bg-surface); // #21262d — COMP-01 requirement
  border-color: var(--color-border);          // #30363d — replaces translucent default
}

.card-header,
.card-footer {
  background-color: transparent;             // don't let cap-bg add unexpected tint
  border-color: var(--color-border);
}
```

**Shadow suppression** — add to `_theme.scss` inside `[data-bs-theme="dark"]` block:
```scss
// Suppress light-theme shadows — invisible on dark backgrounds
// Source: Bootstrap shadow utility uses var(--bs-box-shadow-sm) !important
--bs-box-shadow-sm: none;
--bs-box-shadow:    none;
```

**Why not `!important` on `.card`:** Using direct property override (later source order) avoids `!important` specificity wars and remains composable.

### Pattern 2: Avatar Partial (COMP-02)

**What:** A Rails partial at `app/views/shared/_avatar.html.slim` that renders a user's photo if attached, or a dark-surfaced initials circle if not.

**Interface:**
```slim
/= render "shared/avatar", user: user, size: 40
```

- `user` — a `User` ActiveRecord object (NOT `LeagueUser` — caller passes `.user` explicitly)
- `size` — integer pixel size, default 40
- Initials: `user.full_name.split.map(&:first).first(2).join.upcase` (2-letter initials matching navbar pattern)

**Example:**
```slim
/ app/views/shared/_avatar.html.slim
/ Source: navbar pattern from _navbar.html.slim [VERIFIED: app/views/layouts/_navbar.html.slim:22-23]
- size ||= 40
- font_size = (size * 0.3).round(2)
- initials = user.full_name.split.map(&:first).first(2).join.upcase

- if user.photo.attached?
  = image_tag user.photo, class: "rounded-circle", style: "width: #{size}px; height: #{size}px; object-fit: cover;"
- else
  .rounded-circle.d-inline-flex.align-items-center.justify-content-center style="width: #{size}px; height: #{size}px; background: var(--color-bg-surface); border: 1px solid var(--color-border); font-size: #{font_size}rem; font-weight: 600; color: var(--color-text-muted);"
    = initials
```

**Template replacement sites (5 locations):**
```
1. app/views/leagues/show.html.slim:69-73       league_user.user → render "shared/avatar", user: league_user.user
2. app/views/users/index.html.slim:18-22        user → render "shared/avatar", user: user
3. app/views/tournaments/show.html.slim:50-54   pair.player1.user → render "shared/avatar", user: pair.player1.user
4. app/views/tournaments/show.html.slim:58-62   pair.player2.user → render "shared/avatar", user: pair.player2.user
5. app/views/devise/registrations/edit.html.slim:12-16  resource → render "shared/avatar", user: resource, size: 100
```

**Why not use the existing navbar inline pattern for the partial:** The navbar avatar is a special case (32px, inside a dropdown toggle) and deliberately stays inline. The 5 replacement sites all use 40px circles (or 100px for profile) — these are the extraction targets.

### Pattern 3: Form Controls Dark Surface (COMP-03)

**What:** Override Bootstrap's `$input-bg` SCSS variable to `var(--color-bg-surface)` before Bootstrap compiles. This propagates to `form-control`, `form-select`, `textarea`, `input-group-addon`, and `input-focus-bg` in one declaration.

**When to use:** Always — all Bootstrap form inputs project-wide.

**Change in `_variables.scss`:**
```scss
// Add after existing variable overrides
// Source: Bootstrap _variables.scss:900 [$input-bg !default = var(--bs-body-bg)]
// [VERIFIED: node_modules/bootstrap/scss/_variables.scss:900]
$input-bg: var(--color-bg-surface);
```

This causes Bootstrap to compile `.form-control { background-color: var(--color-bg-surface); }` directly — no custom property inheritance issues.

**File upload `::file-selector-button`** — add to `_theme.scss` dark block:
```scss
// File selector button bg uses --bs-tertiary-bg (not covered by existing overrides)
// Source: Bootstrap _variables.scss:1066 [$form-file-button-bg = var(--bs-tertiary-bg)]
// [VERIFIED: node_modules/bootstrap/scss/_variables.scss:1066]
--bs-tertiary-bg: var(--color-bg-navbar); // #161b22 — darker than input surface, clear visual separation
```

**Border color consistency** — add to `_forms.scss`:
```scss
// _forms.scss
// Border color uses --bs-border-color via inheritance — already correct from _theme.scss.
// Additional: ensure consistent styling for textarea (no extra overrides needed beyond $input-bg).

// date/time inputs have a calendar icon that needs override in some browsers
input[type="date"],
input[type="time"],
input[type="datetime-local"] {
  color-scheme: dark; // Renders browser native date picker in dark mode
}
```

**Focus ring** — already correct. `$primary = #2f81f7` in `_variables.scss` produces `$focus-ring-color = rgba(47, 129, 247, 0.25)` which is the electric blue focus ring. [VERIFIED: Bootstrap _variables.scss:571]

### Pattern 4: Table Dark Header (COMP-04)

**What:** Remove `thead.table-dark` class from 2 templates. Add `_tables.scss` to style `thead th` with design-system tokens.

**Template changes (2 files):**
```slim
/ BEFORE:
thead.table-dark
  tr ...

/ AFTER:
thead
  tr ...
```

**Files to change:**
- `app/views/users/index.html.slim:7` — `thead.table-dark` → `thead`
- `app/views/tournaments/index.html.slim:6` — `thead.table-dark` → `thead`

**Table SCSS:**
```scss
// app/assets/stylesheets/_tables.scss
// Bootstrap .table already uses CSS vars for borders, text, hover — they follow our dark theme.
// Only thead requires explicit dark header treatment after removing .table-dark class.

.table {
  // Ensure table bg is explicitly surface (not body-bg) if we want elevated table rows
  // Leave at var(--bs-body-bg) = transparent/page bg — tables blend with dark page ✓
}

thead > tr > th {
  background-color: var(--color-bg-surface); // Subtle elevation vs transparent tbody rows
  color: var(--color-text-muted);
  font-weight: 600;
  border-bottom: 1px solid var(--color-border);
  white-space: nowrap;                       // prevents header text wrapping
}
```

**Why not override `--bs-table-bg` at root level:** `.table` declares `--bs-table-bg: var(--bs-body-bg)` locally. Like `.card`, a root-level override would be cascade-ineffective. Direct `background-color` on `thead th` is targeted and correct.

### Anti-Patterns to Avoid

- **Setting `--bs-card-bg` in `[data-bs-theme="dark"]` and expecting it to override `.card`:** The `.card` element has its own declaration that wins. Use direct `background-color` override in component SCSS instead.
- **Using `bg-secondary` for avatar circles:** `--bs-secondary` in Bootstrap's dark mode maps to gray-800 (#343a40) from Bootstrap's own dark variables. Our `_theme.scss` does override `--bs-secondary-bg` to `--color-bg-surface`, but `.bg-secondary` applies background-color differently. Use explicit `var(--color-bg-surface)` inline or via avatar partial.
- **Keeping `thead.table-dark`:** This hardcodes `--bs-table-bg: #212529` which doesn't match our design tokens and causes a visual inconsistency.
- **Adding `!important` to every card rule:** Not needed. Source-order wins when specificity is equal. Save `!important` for `.shadow-sm` suppression (which Bootstrap itself uses `!important`).
- **Passing `LeagueUser` to avatar partial:** `LeagueUser` delegates `full_name` but NOT `photo`. Passing `league_user.user` ensures both `.full_name` and `.photo.attached?` work on the User object.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Avatar initials fallback | Custom image-generation service or placeholder API | Inline CSS circle with initials in Slim partial | Pure CSS+HTML, zero external dependencies, already proven in navbar |
| Dark form inputs | Reinvent form styling from scratch | Override `$input-bg` in `_variables.scss` before Bootstrap | One-line SCSS change propagates to all input types; Bootstrap handles rest |
| Focus ring | Custom `:focus` CSS on every input | Bootstrap's `$focus-ring-color` already uses our `$primary` | Phase 1 already configured this correctly |
| Table row striping/hover | Custom alternating row JS | Bootstrap `.table-striped` + `.table-hover` — CSS vars follow dark theme | Already working via `--bs-emphasis-color-rgb` inheritance |
| Avatar file-path routing | Custom resize/crop pipeline | Active Storage `image_tag user.photo` | Active Storage is already configured |

**Key insight:** Bootstrap 5.3's CSS variable architecture handles most dark-mode work automatically — the exceptions are where Bootstrap compiles local custom property declarations (`.card`, `.table`) rather than inheriting from `:root`. Those 3-4 targeted overrides are the entire complexity of this phase.

---

## Common Pitfalls

### Pitfall 1: `_theme.scss` Override Not Reaching Card Elements

**What goes wrong:** Setting `--bs-card-bg: var(--color-bg-surface)` in `[data-bs-theme="dark"]` block, verifying it in browser DevTools on `<html>`, then wondering why `.card` elements still show `#0d1117`.

**Why it happens:** `.card { --bs-card-bg: var(--bs-body-bg) }` is Bootstrap's compiled local declaration on card elements. An element's own CSS custom property declaration wins over an inherited ancestor value, regardless of source order.

**How to avoid:** Write `_cards.scss` with `.card { background-color: var(--color-bg-surface); }` as a direct property override (not custom property). This comes after Bootstrap by source order and wins.

**Warning signs:** Cards are not visually distinct from the `#0d1117` page background.

### Pitfall 2: `$input-bg` Override Not Working Because of Import Order

**What goes wrong:** Adding `$input-bg: var(--color-bg-surface)` in `_variables.scss` but the change has no effect.

**Why it happens:** Bootstrap's `$input-bg` uses `!default` — the override must appear BEFORE `@import 'bootstrap/scss/variables'`. Since `_variables.scss` is imported between `bootstrap/scss/functions` and `bootstrap/scss/variables` in `application.bootstrap.scss`, any variable added to `_variables.scss` takes precedence correctly.

**How to avoid:** Add `$input-bg` to `_variables.scss` (already imported in the correct position). Do NOT add it to `_theme.scss` (imported after Bootstrap — SCSS variables from there cannot retroactively change compiled Bootstrap output).

**Warning signs:** Form inputs show `#0d1117` (page base color) instead of `#21262d` (surface).

### Pitfall 3: Avatar Partial Receiving LeagueUser Instead of User

**What goes wrong:** `render "shared/avatar", user: league_user` fails when the partial calls `user.photo.attached?`.

**Why it happens:** `LeagueUser` delegates `full_name` to `:user` but NOT `photo`. So `league_user.photo` raises `NoMethodError`.

**How to avoid:** Always pass the `User` object to the partial. In league/tournament contexts: pass `league_user.user` or `pair.player1.user`. In devise/users contexts: `user` or `resource` are already User objects.

**Warning signs:** `undefined method 'photo'` error on `LeagueUser` instances.

### Pitfall 4: `shadow-sm` Suppression Requires `!important`

**What goes wrong:** Adding `.shadow-sm { box-shadow: none; }` in `_cards.scss` without `!important` has no effect.

**Why it happens:** Bootstrap's `.shadow-sm` utility is defined as `box-shadow: var(--bs-box-shadow-sm) !important;`. Without `!important` on our override, Bootstrap's `!important` wins.

**How to avoid:** Use `--bs-box-shadow-sm: none` in `_theme.scss`'s `[data-bs-theme="dark"]` block. Since `.shadow-sm` uses `var(--bs-box-shadow-sm)`, setting the variable to `none` makes the `!important` value evaluate to `none` — no specificity fight needed.

**Warning signs:** Cards still show a faint shadow on hover or page load.

### Pitfall 5: `color-scheme: dark` Missing on Date/Time Inputs

**What goes wrong:** Date and time inputs (`type="date"`, `type="time"`) show the browser's native light-mode calendar picker regardless of our dark styling.

**Why it happens:** Browser native date pickers respect `color-scheme` CSS property, not `background-color` overrides.

**How to avoid:** Add to `_forms.scss`:
```scss
input[type="date"], input[type="time"], input[type="datetime-local"] { color-scheme: dark; }
```
The tournament form uses `f.date_field` which renders `type="date"`. [VERIFIED: app/views/tournaments/new.html.slim:19,23]

**Warning signs:** Date picker popup appears white/light even on dark inputs.

### Pitfall 6: `thead.table-dark` Removal Causes Row Border Misalignment

**What goes wrong:** After removing `.table-dark` from `thead`, the first row no longer has a bottom border separating header from body.

**Why it happens:** `.table-dark` was providing its own border styling. After removal, the header relies on Bootstrap's default `thead > tr > th` border.

**How to avoid:** The `_tables.scss` `thead th` rule explicitly sets `border-bottom: 1px solid var(--color-border)`. This re-establishes the visual separator.

**Warning signs:** Header cells have no bottom border; hard to distinguish header row from data rows.

---

## Code Examples

### Card SCSS Partial (Complete)

```scss
// app/assets/stylesheets/_cards.scss
// Source: Bootstrap cascade analysis [VERIFIED: node_modules/bootstrap/dist/css/bootstrap.css]
// Direct property overrides — source order wins over Bootstrap's equal-specificity rules.

.card {
  background-color: var(--color-bg-surface); // #21262d — elevated surface per COMP-01
  border-color: var(--color-border);          // #30363d — replaces rgba(white,.15) default
}

.card-header,
.card-footer {
  background-color: transparent;             // inherit from .card, no extra tint
  border-color: var(--color-border);
}
```

### Form SCSS Additions

In `_variables.scss` (before all Bootstrap imports):
```scss
// COMP-03: Dark form input surface — propagates to form-control, form-select, textarea, etc.
// Source: Bootstrap _variables.scss:900 — $input-bg !default = var(--bs-body-bg)
// [VERIFIED: node_modules/bootstrap/scss/_variables.scss:900]
$input-bg: var(--color-bg-surface);
```

In `_theme.scss` `[data-bs-theme="dark"]` block:
```scss
// File upload button bg (uses --bs-tertiary-bg, not covered by existing overrides)
--bs-tertiary-bg:  var(--color-bg-navbar);    // #161b22 — darker than input, clear separation

// Suppress light-theme box-shadows (invisible on dark backgrounds)
--bs-box-shadow-sm: none;
--bs-box-shadow:    none;
```

New `_forms.scss`:
```scss
// app/assets/stylesheets/_forms.scss
// Source: MDN color-scheme [CITED: developer.mozilla.org/en-US/docs/Web/CSS/color-scheme]

// Native date/time pickers — force dark mode for browser chrome
input[type="date"],
input[type="time"],
input[type="datetime-local"] {
  color-scheme: dark;
}
```

### Avatar Partial (Complete)

```slim
/ app/views/shared/_avatar.html.slim
/ Source: navbar initials pattern [VERIFIED: app/views/layouts/_navbar.html.slim:22-23]
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

### Template Changes — Avatar Replacement Pattern

```slim
/ BEFORE (leagues/show.html.slim:69-73):
- if league_user.user.photo.attached?
  = image_tag league_user.user.photo, class: "rounded-circle", style: "width: 40px; height: 40px; object-fit: cover;"
- else
  .rounded-circle.bg-secondary.d-inline-flex.align-items-center.justify-content-center style="width: 40px; height: 40px;"
    span.text-white.small = league_user.full_name.first.upcase

/ AFTER:
= render "shared/avatar", user: league_user.user
```

### Template Changes — Table Header Replacement

```slim
/ BEFORE (users/index.html.slim:7, tournaments/index.html.slim:6):
thead.table-dark

/ AFTER:
thead
```

### Tables SCSS

```scss
// app/assets/stylesheets/_tables.scss

thead > tr > th {
  background-color: var(--color-bg-surface); // Elevates header above transparent tbody rows
  color: var(--color-text-muted);
  font-weight: 600;
  border-bottom: 1px solid var(--color-border);
}
```

### application.bootstrap.scss — New @import Lines

```scss
// Add after @import 'flash'; line:
@import 'cards';
@import 'forms';
@import 'tables';
@import 'avatar';
```

---

## Complete Change Inventory

### SCSS File Changes

| File | Change Type | What |
|------|-------------|------|
| `_variables.scss` | Add 1 line | `$input-bg: var(--color-bg-surface);` |
| `_theme.scss` | Add to dark block | `--bs-tertiary-bg`, `--bs-box-shadow-sm: none`, `--bs-box-shadow: none` |
| `application.bootstrap.scss` | Add 4 lines | `@import 'cards', 'forms', 'tables', 'avatar';` |
| `_cards.scss` | NEW | `.card` background + border overrides, `.card-header/footer` |
| `_forms.scss` | NEW | `color-scheme: dark` on date/time inputs |
| `_tables.scss` | NEW | `thead th` dark header styles |
| `_avatar.scss` | NEW | `.avatar-circle` base styles (if any extracted from partial) |

### Template Changes

| File | Change | Lines |
|------|--------|-------|
| `app/views/leagues/show.html.slim` | Replace `bg-secondary` avatar with `render "shared/avatar"` | 69-73 |
| `app/views/users/index.html.slim` | Replace `bg-secondary` avatar + remove `thead.table-dark` | 7, 18-22 |
| `app/views/tournaments/index.html.slim` | Remove `thead.table-dark` | 6 |
| `app/views/tournaments/show.html.slim` | Replace 2 `bg-secondary` avatars with `render "shared/avatar"` | 50-54, 58-62 |
| `app/views/devise/registrations/edit.html.slim` | Replace `bg-secondary` avatar with `render "shared/avatar", size: 100` | 12-16 |

### New Files

| File | Purpose |
|------|---------|
| `app/views/shared/_avatar.html.slim` | Avatar partial — photo or initials circle |
| `app/assets/stylesheets/_cards.scss` | Card dark surface + border styles |
| `app/assets/stylesheets/_forms.scss` | Form input supplemental dark styles |
| `app/assets/stylesheets/_tables.scss` | Table header dark styles |
| `app/assets/stylesheets/_avatar.scss` | Avatar component SCSS (if any base styles extracted) |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `bg-secondary` for avatar circles | CSS custom property inline style or partial | Bootstrap 5.3 dark mode | `bg-secondary` maps to Bootstrap gray-800 (#343a40) in dark mode — doesn't match design system |
| `thead.table-dark` | Remove class; CSS-override via `_tables.scss` | — | `table-dark` hardcodes Bootstrap gray-900 (#212529); CSS var approach follows design tokens |
| Shadows for card depth | 1px border for depth | Bootstrap 5.3 dark mode best practice | Black `rgba` shadows are invisible on dark backgrounds; borders create visible depth |
| `$input-bg` at Bootstrap default (`var(--bs-body-bg)`) | Override to `var(--color-bg-surface)` | — | Default causes inputs to show page base color (#0d1117), not surface |

**Deprecated/outdated:**
- `.table-dark` on `thead`: Creates hardcoded Bootstrap gray header; CSS variable approach is correct for dark theme
- `.bg-secondary` for avatar fallbacks: Maps to wrong Bootstrap dark palette value; use explicit `var(--color-bg-surface)`
- `.shadow-sm` on cards: Invisible on dark backgrounds; use border depth instead

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CSS custom property declared on `.card { --bs-card-bg: X }` wins over inherited value from `[data-bs-theme="dark"] { --bs-card-bg: Y }` on ancestor — meaning `_theme.scss`'s existing `--bs-card-bg` override does nothing to actual card backgrounds | CSS Cascade Analysis | If wrong (cascade works differently), cards may already be styled correctly, and our explicit `.card { background-color }` override would still be correct (just redundant) — no harm either way |
| A2 | `$input-bg: var(--color-bg-surface)` in `_variables.scss` is processed by Sass as a CSS var string, not evaluated at compile time — resulting in compiled output `background-color: var(--color-bg-surface)` | Standard Stack / Pattern 3 | Sass does pass CSS `var()` strings through as literal values in property values — this pattern is confirmed by Bootstrap itself using `var(--bs-body-bg)` in `$input-bg` |
| A3 | `color-scheme: dark` on date inputs makes Chrome/Firefox/Safari render native date pickers with dark chrome | Pattern 3 / Pitfall 5 | Cross-browser support: `color-scheme` is supported in Chrome 81+, Firefox 96+, Safari 13+ — covers modern browsers; may not work in older browsers |
| A4 | `app/views/shared/` directory does not need to be registered anywhere — Rails automatically renders partials from any subdirectory under `app/views/` | Pattern 2 | Standard Rails convention — `render "shared/avatar"` resolves to `app/views/shared/_avatar.html.slim` automatically |
| A5 | The `_avatar.scss` partial may have no content if all avatar styles are inline in the Slim partial | Project Structure | If inline styles are sufficient (as they are in the navbar pattern), `_avatar.scss` may be empty or omitted; the planner should decide whether to create it |

---

## Open Questions

1. **Does `_avatar.scss` need any content, or are inline styles on the avatar circle sufficient?**
   - What we know: The navbar uses 100% inline styles for its avatar circle (`style="width:32px;..."`)
   - What's unclear: Should the avatar partial use a CSS class (`.avatar-circle`) with styles in `_avatar.scss`, or inline styles?
   - Recommendation: Use inline styles in the Slim partial for Phase 3 (matches navbar pattern, simpler). Add `.avatar-circle` CSS class in Phase 5 polish if hover effects are needed. If `_avatar.scss` is created but empty, that's fine — or skip it entirely.

2. **Should the navbar avatar also use the new `_avatar.html.slim` partial?**
   - What we know: Navbar uses 32px, `current_user` — a special case with dropdown context
   - What's unclear: Whether to unify or keep the navbar avatar inline
   - Recommendation: Keep navbar avatar inline for Phase 3. The COMP-02 requirement covers 5 explicit `bg-secondary` replacement sites. The navbar already uses `var(--color-bg-surface)` inline — it is not broken.

3. **Should `thead th` get `background-color: var(--color-bg-surface)` or `transparent`?**
   - What we know: After removing `.table-dark`, thead renders on the table background (transparent = page bg #0d1117)
   - What's unclear: Whether a slightly elevated header (surface color) looks better than a fully transparent one
   - Recommendation: Use `var(--color-bg-surface)` for headers to create visible separation between header and data rows. This is the Linear.app pattern — dark surface header, transparent data rows.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bootstrap 5 SCSS | All 4 COMP requirements | ✓ | 5.3.8 [VERIFIED] | — |
| Dart Sass | SCSS compilation | ✓ | 1.99.0 [VERIFIED: Phase 2 research] | — |
| Active Storage | Avatar photo check | ✓ | Rails 8 built-in [VERIFIED: user.rb] | Initials-only avatar (already the fallback) |
| Rails partials (`shared/`) | COMP-02 avatar partial | ✓ | Rails 8 [VERIFIED: project] | — |

**Missing dependencies with no fallback:** None.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | Phase 3 is CSS/partial-only; no new routes, controllers, or authorization logic |
| V5 Input Validation | yes (partial) | Avatar partial renders `user.full_name` via Slim's `= initials` — auto-escaped; `image_tag` generates safe URLs |
| V6 Cryptography | no | — |

### Known Threat Patterns for {stack}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via avatar initials | Tampering | Slim's `= initials` auto-escapes HTML; `user.full_name` from DB via ActiveRecord is safe |
| Path traversal via `image_tag user.photo` | Tampering | Active Storage generates signed URLs via `rails_blob_path` — not arbitrary file paths |

**No active security concerns for Phase 3.** CSS and partial changes with auto-escaping in Slim templates are safe.

---

## Project Constraints (from CLAUDE.md)

- Follow Rails conventions (CoC) — shared partials in `app/views/shared/` prefixed with `_`
- Fat models, skinny controllers — avatar partial uses model method (`full_name`) and Active Storage check; no controller logic
- No schema changes — Phase 3 is purely CSS + view partials
- Commit messages start with `feat:` or `fix:` — e.g., `feat: dark-style cards, avatars, forms, and tables`
- Run `bin/rubocop` before PR — no Ruby `.rb` files changed in Phase 3; applies if helpers are modified
- Write request specs for new API endpoints — Phase 3 has no new endpoints
- Write model specs for validations — Phase 3 has no new models

---

## Sources

### Primary (HIGH confidence)
- `app/assets/stylesheets/_variables.scss` — confirmed `$dark: #21262d`, `$primary: #2f81f7`, `$border-color: #30363d` [VERIFIED: read in session]
- `app/assets/stylesheets/_theme.scss` — confirmed existing overrides and their scope [VERIFIED: read in session]
- `app/assets/stylesheets/application.bootstrap.scss` — confirmed import order; `_navbar.scss` and `_flash.scss` already imported [VERIFIED: read in session]
- `node_modules/bootstrap/dist/css/bootstrap.css` — compiled `.card`, `.table`, `.form-select`, `.shadow-sm` definitions [VERIFIED: grep in session]
- `node_modules/bootstrap/scss/_variables.scss` — `$input-bg`, `$card-bg`, `$table-bg`, `$form-file-button-bg` [VERIFIED: read in session]
- `node_modules/bootstrap/scss/_card.scss` — confirmed `.card { --bs-card-bg: #{$card-bg} }` [VERIFIED: read in session]
- `node_modules/bootstrap/scss/_tables.scss` — confirmed `--bs-table-*` local declarations [VERIFIED: read in session]
- `node_modules/bootstrap/scss/forms/_form-select.scss` — confirmed dark indicator auto-handling [VERIFIED: read in session]
- `node_modules/bootstrap/scss/_root.scss` — confirmed Bootstrap dark root overrides (does NOT include card-bg, input-bg) [VERIFIED: read in session]
- `node_modules/bootstrap/package.json` — version 5.3.8 [VERIFIED]
- `app/views/layouts/_navbar.html.slim` — avatar inline style pattern + initials extraction [VERIFIED: read in session]
- `app/views/leagues/show.html.slim` — confirmed `bg-secondary` at line 72, `table.table-hover` [VERIFIED: read in session]
- `app/views/users/index.html.slim` — confirmed `bg-secondary` at line 21, `thead.table-dark` at line 7 [VERIFIED: read in session]
- `app/views/tournaments/index.html.slim` — confirmed `thead.table-dark` at line 6 [VERIFIED: read in session]
- `app/views/tournaments/show.html.slim` — confirmed `bg-secondary` at lines 53 + 61 [VERIFIED: read in session]
- `app/views/devise/registrations/edit.html.slim` — confirmed `bg-secondary` at line 15, 100px size [VERIFIED: read in session]
- `app/models/league_user.rb` — confirmed `delegate :full_name, to: :user` (NOT photo) [VERIFIED: read in session]
- `app/models/user.rb` — confirmed `full_name` method implementation [VERIFIED: read in session]
- `.planning/config.json` — confirmed `nyquist_validation: false` [VERIFIED: read in session]

### Secondary (MEDIUM confidence)
- Bootstrap 5.3 CSS custom property cascade behavior — CSS spec; verified via compiled output inspection
- `color-scheme: dark` for native date pickers — standard CSS property, widely supported

### Tertiary (LOW confidence)
- None — all claims verified from codebase files or Bootstrap compiled output.

---

## Metadata

**Confidence breakdown:**
- CSS cascade analysis (cards/forms/tables): HIGH — verified via Bootstrap compiled dist CSS and SCSS source
- Avatar interface design: HIGH — verified via model analysis and all 5 usage sites
- Template change locations: HIGH — verified via grep, line numbers confirmed by read
- `$input-bg` SCSS override propagation: HIGH — Bootstrap uses this pattern itself for all its own vars
- `color-scheme: dark` browser support: MEDIUM — standard CSS but not verified in this specific browser environment

**Research date:** 2026-05-09
**Valid until:** 2026-11-09 (Bootstrap 5.3 is stable; no breaking changes expected)

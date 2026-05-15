---
phase: 05-polish-pass
reviewed: 2026-05-15T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - app/assets/stylesheets/_cards.scss
  - app/assets/stylesheets/_interactions.scss
  - app/assets/stylesheets/_tables.scss
  - app/assets/stylesheets/application.bootstrap.scss
  - app/views/dashboard/index.html.slim
  - app/views/leagues/index.html.slim
findings:
  critical: 2
  warning: 4
  info: 1
  total: 7
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-05-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Six files were reviewed covering the Phase 5 polish pass: three SCSS partials (`_cards.scss`, `_interactions.scss`, `_tables.scss`), the main stylesheet manifest, and two Slim templates. The SCSS variable references are all valid and the import order in `application.bootstrap.scss` is correct. However, two correctness bugs were found that will produce broken behavior in production: a `transform` on `.card-hoverable:hover` that silently breaks `stretched-link`, and a missing `.present?` guard that will render a blank `<p>` element for leagues without a description. Four warnings cover a duplicate CSS block, a focus-indicator accessibility issue, an N+1 query, and a cascade concern with `$transition-base: all`.

---

## Critical Issues

### CR-01: `transform` on `.card-hoverable:hover` breaks `stretched-link`

**File:** `app/assets/stylesheets/_cards.scss:22-25`

**Issue:** Bootstrap's `.stretched-link` works by placing a pseudo-element (`::after`) with `position: absolute` inside the nearest ancestor that has `position: relative` and no other stacking context. Applying `transform: translateY(-1px)` on the `.card-hoverable:hover` rule **creates a new stacking context** on the card element itself. Once a stacking context exists, the `::after` pseudo-element is clipped to it, and the click target collapses — the card appears to lift but the link is no longer clickable across the full card face. This is a confirmed broken behavior with Bootstrap's stretched-link + transform combination; it is not a potential issue.

Both `dashboard/index.html.slim:58-60` and `leagues/index.html.slim:10-14` use `.card.card-hoverable` together with a `stretched-link` child, so both pages are affected.

**Fix:** Replace `transform` with a `box-shadow` lift. This achieves the same visual "elevation" effect without creating a stacking context:

```scss
// _cards.scss

.card-hoverable:hover {
  // transform: translateY(-1px);  <-- REMOVE: creates stacking context, breaks stretched-link
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
  border-color: var(--color-accent-hover);
}
```

Alternatively, keep the transform but remove `stretched-link` from the templates and replace the link with an explicit card wrapper `<a>` element.

---

### CR-02: `league.description` rendered without nil/blank guard in dashboard template

**File:** `app/views/dashboard/index.html.slim:61`

**Issue:** `league.description` is a nullable `text` column (no `NOT NULL` constraint in the schema, no `validates :description, presence: true` in the model). The dashboard template renders it unconditionally:

```slim
p.card-text.text-muted.small= league.description
```

When `description` is `nil` or an empty string, this emits `<p class="card-text text-muted small"></p>` — an empty paragraph that adds unwanted vertical space inside the card. The leagues index template (`leagues/index.html.slim:15-16`) already has the correct `.present?` guard; the dashboard is inconsistent and incorrect.

**Fix:**

```slim
- if league.description.present?
  p.card-text.text-muted.small= league.description
```

---

## Warnings

### WR-01: `.btn-primary:focus-visible` box-shadow is too dim to meet WCAG 2.4.11 (non-text contrast 3:1)

**File:** `app/assets/stylesheets/_interactions.scss:11-13`

**Issue:** The focus indicator for `.btn-primary` is `box-shadow: 0 0 12px rgba(47, 129, 247, 0.3)`. A diffuse outer glow at 30% opacity on a `#21262d` background does not provide a 3:1 contrast ratio between the focused and unfocused states as required by WCAG 2.1 SC 1.4.11 and the emerging 2.4.11. The glow has no hard edge and its effective perimeter luminance at 30% opacity is well below the threshold. Additionally, Bootstrap sets `outline: 0` on `.btn:focus-visible`, so the browser's native outline is suppressed — making this the sole focus indicator.

**Fix:** Add a solid focus ring in addition to the ambient glow:

```scss
.btn-primary {
  transition: $transition-base;

  &:hover,
  &:focus-visible {
    box-shadow: 0 0 12px rgba(47, 129, 247, 0.3);
  }

  &:focus-visible {
    outline: 2px solid var(--color-accent);
    outline-offset: 2px;
  }
}
```

The same applies to `.btn-accent` in the same file (lines 19-24).

---

### WR-02: `.btn-accent` block is a duplicate of `.btn-primary` with no differentiation

**File:** `app/assets/stylesheets/_interactions.scss:17-25`

**Issue:** `.btn-accent` declares the same `transition` and the exact same `box-shadow` values as `.btn-primary`. The comment acknowledges no template currently uses this class. Shipping unused dead code that is byte-for-byte identical to another rule is a maintainability burden: if the glow color needs to change, it must be changed in two places, and the duplication will be silently forgotten.

**Fix:** If `.btn-accent` is genuinely forward-compatibility scaffolding, use a shared placeholder or extract the value to a variable:

```scss
$glow-focus: 0 0 12px rgba(47, 129, 247, 0.3);

.btn-primary,
.btn-accent {
  transition: $transition-base;

  &:hover,
  &:focus-visible {
    box-shadow: $glow-focus;
  }
}
```

If `.btn-accent` is not needed yet, remove it and add it when a template actually adopts it.

---

### WR-03: `$transition-base: all` animates `border-color` and `box-shadow` but also `background-color` — may cause visual jank during active state

**File:** `app/assets/stylesheets/_cards.scss:10` and `app/assets/stylesheets/_interactions.scss:8, 19`

**Issue:** `$transition-base` is defined as `all 0.15s ease-in-out` (see `_variables.scss:27`). Applying `all` on `.card` means every animatable CSS property transitions, including `background-color`, `color`, `border-radius`, `width`, `height`, etc. While harmless in most cases today, it means any future change to card sizing or padding (e.g., a JS class toggle) will animate when it should snap, and it can cause subtle paint-layer thrashing in browsers that cannot promote `all`-transitioned elements to GPU layers.

For `.btn-primary`, Bootstrap's active state changes `background-color` and `border-color` rapidly; transitioning `all` means the active press flash will also animate instead of being instantaneous, which reduces the perceived responsiveness of click actions.

**Fix:** Scope transitions to the specific properties being animated:

```scss
// _cards.scss
.card {
  transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out, transform 0.15s ease-in-out;
}

// _interactions.scss
.btn-primary {
  transition: box-shadow 0.15s ease-in-out;
}
```

---

### WR-04: `@recent_leagues` is loaded without `includes(:owner)` — N+1 query on dashboard

**File:** `app/views/dashboard/index.html.slim:63` / `app/controllers/dashboard_controller.rb:5`

**Issue:** The dashboard template calls `league.owner.full_name` on line 63 for each item in `@recent_leagues`. The controller loads `@recent_leagues` as `League.order(created_at: :desc).limit(5)` without eager-loading the `owner` association. This fires one extra SQL query per league displayed (up to 5 additional queries) every time the dashboard is rendered. While N+1 performance is noted as out of v1 scope, this case is also a **correctness risk**: if any league's `owner` record has been deleted and the foreign key constraint is not enforced at the database level (e.g., via `dependent: :destroy` or DB cascade), `league.owner` returns `nil` and `league.owner.full_name` raises `NoMethodError`, crashing the page for that user.

**Fix:** Eager-load in the controller:

```ruby
@recent_leagues = League.includes(:owner).order(created_at: :desc).limit(5)
```

And add a nil guard in the template for defense:

```slim
| #{league.owner&.full_name} · #{league.created_at.strftime("%d.%m.%Y")}
```

---

## Info

### IN-01: Inline `style` attribute on league logo image in `leagues/index.html.slim`

**File:** `app/views/leagues/index.html.slim:12`

**Issue:** The card image height is set via an inline `style` attribute:

```slim
= image_tag league.logo, class: "card-img-top", style: "height: 140px; object-fit: cover;"
```

Inline styles are harder to override, bypass the project's SCSS token system, and will not adapt to any future design-token changes for image height. This also causes a CSP `style-src 'unsafe-inline'` requirement if the project ever moves to a strict Content Security Policy.

**Fix:** Extract to a utility class in `_cards.scss`:

```scss
.card-img-top--fixed {
  height: 140px;
  object-fit: cover;
}
```

```slim
= image_tag league.logo, class: "card-img-top card-img-top--fixed"
```

---

_Reviewed: 2026-05-15T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

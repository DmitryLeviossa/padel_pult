# Phase 4: Content Pages - Research

**Researched:** 2026-05-09
**Domain:** Rails Slim templates — dark UI redesign of content pages using the Phase 1-3 component library
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-01 | Dashboard redesigned — stat cards with icons, user's leagues/tournaments in card grid, recent activity, dark empty states | Dashboard controller exposes `@my_leagues`, `@my_tournaments`, `@recent_leagues`. Current template uses `.card.shadow-sm` which needs `.shadow-sm` dropped (shadow suppressed in dark theme) and content wrapped in proper card grid. Empty state pattern: `p.text-muted`. |
| PAGE-02 | All 7 auth pages redesigned — login, register, password reset (new/edit), account edit, email confirmation, unlock — centered card layout on dark background | All 7 Devise templates already have centered `.container > .row.justify-content-center > .col-md-5 > .card.shadow-sm` structure. Changes needed: drop `.shadow-sm`, verify no light-theme overrides, fix shared partials (_error_messages, _links). |
| PAGE-03 | League pages redesigned — index (card grid), show (tabs, members, tournaments), new (form), edit (form) — all 4 templates | leagues/index has card grid with `.shadow-sm` to drop. leagues/show has tabs and tables already correct. new/edit lack `.container.py-4` wrapper. |
| PAGE-04 | Tournament pages redesigned — index (list/cards), show (pairs/leaderboard), new (form) — all 3 templates | tournaments/index uses `.container.mt-4` (needs `.py-4`), has `.table-striped` (acceptable or may drop). tournaments/show and new already have `.container.py-4`. |
| PAGE-05 | Users index redesigned — dark table with avatar column, name, email, consistent with component library | users/index already has avatar partial and `thead` without `.table-dark`. Has `.table-striped` + `.table-hover` — minor cleanup only. |
</phase_requirements>

---

## Summary

Phase 3 delivered a complete dark component library: card surfaces (`_cards.scss`), form dark inputs (`_variables.scss` + `_forms.scss`), dark table headers (`_tables.scss`), and the shared `_avatar.html.slim` partial. Every subsequent template redesign in Phase 4 applies these existing building blocks — no new SCSS partials need to be created.

The 20 templates span 5 groups: dashboard (1), auth (7 Devise views + 2 shared partials = 9 files but only 7 user-visible pages), leagues (4), tournaments (3), users (1). The auth and form-only pages (leagues/new, leagues/edit) need the least work. The dashboard needs the most structural addition (stat-card section with icons). All templates already use the `.container.py-4` convention established in Phase 2 — except leagues/new, leagues/edit (no container wrapper at all) and tournaments/index (uses `.mt-4` not `.py-4`).

The dominant change across all templates is removing `.shadow-sm` from `.card` elements (shadow tokens are now suppressed to `none` in `_theme.scss`) and ensuring empty-state `p` elements use `.text-muted`. The dashboard needs a new stat-card row added. Auth pages are already 90% correct structurally. The devise shared partials (`_error_messages`, `_links`) need minor dark-aware review.

**Primary recommendation:** Split into 5 parallel plans by section (dashboard, auth, leagues, tournaments+users) — all plans are independent after Phase 3 since they touch separate template directories with no file overlap.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Page dark styling (card, shadow, empty state) | Frontend (Slim templates) | SCSS (already done in Phase 3) | Template applies existing CSS classes — no new SCSS |
| Stat cards with icons (dashboard) | Frontend (Slim templates) | — | Bootstrap Icons already included; markup change only |
| Auth card centering | Frontend (Slim templates) | — | Structural HTML already correct; class cleanup only |
| Form dark inputs | SCSS (_variables.scss) | Slim templates | Already done in Phase 3 — templates just use .form-control |
| Table dark headers | SCSS (_tables.scss) | Slim templates | Already done in Phase 3 — templates just use .table |
| Avatar rendering | Shared partial (_avatar.html.slim) | — | Already done in Phase 3 |
| Badge dark colors | SCSS (Bootstrap dark theme) | Slim templates | Bootstrap badge dark mode works via data-bs-theme="dark" |
| N+1 query prevention | API/Controller | — | Some controllers lack includes — document per template |

---

## Template Inventory

### Complete file list (20 content templates)

| # | File | Requirement | Current State | Work Needed |
|---|------|-------------|---------------|-------------|
| 1 | `app/views/dashboard/index.html.slim` | PAGE-01 | Uses `.card.shadow-sm`, `list-group` for leagues/tournaments, recent-leagues card grid. No stat-card row. | Drop `.shadow-sm` ×3; add stat-card row with icons; add missing `data-turbo-track` on links; dark empty state styling |
| 2 | `app/views/devise/sessions/new.html.slim` | PAGE-02 | `.container > .row.justify-content-center > .col-md-5 > .card.shadow-sm` — structurally correct | Drop `.shadow-sm`; verify `form-check` styling in dark |
| 3 | `app/views/devise/registrations/new.html.slim` | PAGE-02 | Same card-centered structure as sessions/new | Drop `.shadow-sm` |
| 4 | `app/views/devise/registrations/edit.html.slim` | PAGE-02 | Two `.card.shadow-sm` blocks (main form + delete account). Avatar partial already used (Phase 3). | Drop `.shadow-sm` ×2 |
| 5 | `app/views/devise/passwords/new.html.slim` | PAGE-02 | Card-centered, minimal form | Drop `.shadow-sm` |
| 6 | `app/views/devise/passwords/edit.html.slim` | PAGE-02 | Card-centered, minimal form | Drop `.shadow-sm` |
| 7 | `app/views/devise/confirmations/new.html.slim` | PAGE-02 | Card-centered, minimal form | Drop `.shadow-sm` |
| 8 | `app/views/devise/unlocks/new.html.slim` | PAGE-02 | Card-centered, minimal form | Drop `.shadow-sm` |
| 9 | `app/views/devise/shared/_error_messages.html.slim` | PAGE-02 | Uses `.alert.alert-danger` — Bootstrap dark handles automatically via `data-bs-theme="dark"` | Review: already correct, no change needed |
| 10 | `app/views/devise/shared/_links.html.slim` | PAGE-02 | Plain `p` + `link_to` elements — inherits body text color | No change needed |
| 11 | `app/views/leagues/index.html.slim` | PAGE-03 | Card grid with `.card.h-100.shadow-sm` — good structure | Drop `.shadow-sm`; empty state `p.text-muted` already correct |
| 12 | `app/views/leagues/show.html.slim` | PAGE-03 | Nav tabs + two tables. Avatar partial done in Phase 3. `thead` already plain. | No SCSS changes; tab and table markup already correct |
| 13 | `app/views/leagues/new.html.slim` | PAGE-03 | No `.container` wrapper — form hangs off `<main>` edge. File uses `h1` without `.container.py-4` | Add `.container.py-4` wrapper; form inputs already dark via $input-bg |
| 14 | `app/views/leagues/edit.html.slim` | PAGE-03 | Same as new — no container wrapper | Add `.container.py-4` wrapper |
| 15 | `app/views/tournaments/index.html.slim` | PAGE-04 | `.container.mt-4` (missing `.py-4`); `.table-striped.table-hover`; status badges use `bg-#{badge_class}` interpolation — valid Bootstrap utility | Change `.mt-4` to `.py-4`; `.table-striped` is acceptable dark but consider dropping for consistency |
| 16 | `app/views/tournaments/show.html.slim` | PAGE-04 | `.container.py-4` correct; avatar partial done; `thead` plain; status badge same interpolation pattern; `dl.row` for meta-info | No structural changes needed; verify `dl/dt/dd` dark text |
| 17 | `app/views/tournaments/new.html.slim` | PAGE-04 | `.container.py-4` correct; uses `.row.g-3` grid form layout (good pattern); date fields already covered by `color-scheme: dark` | No changes needed |
| 18 | `app/views/users/index.html.slim` | PAGE-05 | `.container.py-4` correct; avatar partial done; `thead` plain (Phase 3); `.table-striped.table-hover.align-middle` | Drop `.table-striped` for consistency with other dark tables; email column missing — consider adding |
| 19 | `app/views/layouts/_navbar.html.slim` | (Phase 2) | Already complete | No changes |
| 20 | `app/views/layouts/_flash.html.slim` | (Phase 2) | Already complete | No changes |

**Summary by work level:**
- **No changes needed:** devise/shared partials (×2), leagues/show, tournaments/new, tournaments/show
- **Drop `.shadow-sm` only:** auth pages ×7 (login, register, edit account, 3 password/confirm/unlock)
- **Minor structural fix:** leagues/new (add container), leagues/edit (add container), tournaments/index (`.mt-4` → `.py-4`), users/index (drop `.table-striped`)
- **Medium — add content:** dashboard (add stat-card row with Bootstrap Icons)
- **Total files to touch:** 12 out of 20

---

## Controller Variables Reference

### DashboardController#index
```ruby
@my_leagues    = League.where(owner: current_user)            # user's owned leagues
@my_tournaments = Tournament.joins(:league).where(...)         # user's tournaments via owned leagues
@recent_leagues = League.order(created_at: :desc).limit(5)    # 5 most recent leagues (all users)
```
**N+1 concern:** `@recent_leagues` uses `.owner.full_name` in template line 47 — one query per league. Controller does not eager-load `:owner`. Fixable with `League.includes(:owner).order(created_at: :desc).limit(5)` — but this is a controller change. Note for planner: optional improvement, not a template redesign blocker.

### LeaguesController
- `index`: `@leagues = League.all` — template calls `league.owner.full_name` only in dashboard, not leagues/index
- `show`: `@league = League.find(params[:id])` — template calls `@league.league_users` then `league_user.user` — potential N+1 on user loads in the members tab. Controller does not include associations. Not blocking for UI pass.
- `new`, `edit`: `@league = League.new / find` — straightforward

### TournamentsController
- `index`: `@tournaments = Tournament.all` — no N+1 (no associated model accessed in template)
- `show`: Uses `includes(pairs: [{ player1: :user }, { player2: :user }])` — N+1 already solved
- `new`: `@tournament` + `@league` available

### UsersController#index
- `@users = User.order(:last_name, :first_name, :email)` — avatar partial accesses `user.photo.attached?` which triggers Active Storage query per user. For a users index this is acceptable for current scale.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser request
      |
      v
Rails controller (sets @variables)
      |
      v
application.html.slim (data-bs-theme="dark" on <html>)
      |
      +-- layouts/_navbar.html.slim  [Phase 2 - complete]
      +-- layouts/_flash.html.slim   [Phase 2 - complete]
      +-- main.py-4
            |
            v
        Content template (.html.slim)
              |
              +-- .container.py-4      <- layout convention (main wraps, template constrains)
              +-- .card / .card-body   <- styled by _cards.scss
              +-- .form-control        <- dark input via $input-bg in _variables.scss
              +-- .table               <- dark header via _tables.scss
              +-- render "shared/avatar", user: user  <- _avatar.html.slim
              +-- bi-* icons           <- bootstrap-icons via @import in manifest
```

### Recommended Project Structure (existing — no changes needed)
```
app/views/
├── dashboard/
│   └── index.html.slim         # PAGE-01
├── devise/
│   ├── sessions/new.html.slim  # PAGE-02
│   ├── registrations/
│   │   ├── new.html.slim       # PAGE-02
│   │   └── edit.html.slim      # PAGE-02
│   ├── passwords/
│   │   ├── new.html.slim       # PAGE-02
│   │   └── edit.html.slim      # PAGE-02
│   ├── confirmations/new.html.slim  # PAGE-02
│   ├── unlocks/new.html.slim        # PAGE-02
│   └── shared/
│       ├── _error_messages.html.slim  # no change
│       └── _links.html.slim           # no change
├── leagues/
│   ├── index.html.slim         # PAGE-03
│   ├── show.html.slim          # PAGE-03
│   ├── new.html.slim           # PAGE-03
│   └── edit.html.slim          # PAGE-03
├── tournaments/
│   ├── index.html.slim         # PAGE-04
│   ├── show.html.slim          # PAGE-04
│   └── new.html.slim           # PAGE-04
├── users/
│   └── index.html.slim         # PAGE-05
└── shared/
    └── _avatar.html.slim       # Phase 3 - complete
```

### Pattern 1: Container convention
**What:** Every content template wraps its entire content in `.container.py-4`
**When to use:** All templates. `<main>` in layout uses `.py-4` without `.container` — individual views own horizontal constraint.
**Example:**
```slim
/ Source: verified in existing templates
.container.py-4
  h1.mb-4 Page Title
  / ... content
```
**Missing from:** leagues/new, leagues/edit (add this wrapper)

### Pattern 2: Card component (dark — Phase 3 ready)
**What:** `.card` with `.card-body`, optionally `.card-header` / `.card-footer`. Never use `.shadow-sm` or `.shadow` (suppressed to `none` in `_theme.scss`).
**Example:**
```slim
/ Source: _cards.scss — background-color: var(--color-bg-surface); border-color: var(--color-border)
.card
  .card-header.fw-semibold Card Title
  .card-body
    p.card-text Content here
  .card-footer.text-muted.small Footer text
```

### Pattern 3: Bootstrap Icons inline
**What:** Use `<i class="bi bi-iconname"></i>` inside Slim using `i.bi.bi-iconname`. Available icons include `bi-trophy`, `bi-people`, `bi-calendar3`, `bi-bar-chart`, `bi-person-circle`.
**When to use:** Dashboard stat cards, section headings for visual enhancement.
**Example:**
```slim
/ Source: Bootstrap Icons included via @import 'bootstrap-icons/font/bootstrap-icons' in manifest
i.bi.bi-trophy.me-2
| Мои турниры
```

### Pattern 4: Dark empty states
**What:** When a collection is empty, render `p.text-muted.mb-0` inside card body. Add a CTA link/button if creation is in scope.
**Example:**
```slim
- if @my_leagues.any?
  / ... list
- else
  p.text-muted.mb-0 Вы ещё не создали ни одной лиги.
```

### Pattern 5: Status badge with dynamic color
**What:** Tournament/league status uses Bootstrap badge with interpolated class. This pattern already works in dark theme — `bg-success`, `bg-danger`, etc. all respond to `data-bs-theme="dark"`.
**Example:**
```slim
/ Source: verified in tournaments/index.html.slim and tournaments/show.html.slim
- badge_class = { "draft" => "secondary", "active" => "success", "completed" => "primary", "cancelled" => "danger" }.fetch(tournament.status, "secondary")
span.badge class="bg-#{badge_class}"
  = tournament.status.capitalize
```

### Pattern 6: Form layout conventions
**What:** Use `.row.g-3` grid for multi-column forms (two-column date fields etc.), `.mb-3` for single-field groups.
**Example:**
```slim
/ Source: verified in tournaments/new.html.slim (existing pattern)
= form_with model: @league, class: "mt-4" do |f|
  .mb-3
    = f.label :name, class: "form-label"
    = f.text_field :name, class: "form-control"
```

### Anti-Patterns to Avoid
- **`.shadow-sm` on cards:** Use `.card` bare — `_theme.scss` already suppresses `--bs-box-shadow-sm: none`. Adding `.shadow-sm` is harmless but misleading. Remove for consistency. [VERIFIED: _theme.scss line 45]
- **`.bg-secondary` on avatar circles:** Already removed in Phase 3. Do not re-introduce. Use `render "shared/avatar"`.
- **`thead.table-dark`:** Already removed in Phase 3. Do not re-introduce.
- **Inline color styles:** Never use `style="color: #fff"` or similar. Use design token classes (`text-muted`, `text-primary`) or `var(--color-*)`.
- **`container` on `<main>`:** Already decided against in Phase 2. `<main>` has `.py-4` only; templates use `.container.py-4` internally.

---

## Plan Parallelization Analysis

All 5 groups touch entirely separate template directories — no file overlap is possible. Plans can run fully in parallel.

### Proposed Plan Split

| Plan | Requirement | Templates | File Count | Complexity |
|------|-------------|-----------|-----------|------------|
| 04-01 | PAGE-01 | `dashboard/index.html.slim` | 1 | Medium — adds stat-card row |
| 04-02 | PAGE-02 | All 7 auth templates (sessions/new, registrations/new, registrations/edit, passwords/new, passwords/edit, confirmations/new, unlocks/new) | 7 | Low — mostly drop `.shadow-sm` |
| 04-03 | PAGE-03 | `leagues/index`, `leagues/show`, `leagues/new`, `leagues/edit` | 4 | Low-medium — container wrappers + shadow drop |
| 04-04 | PAGE-04 | `tournaments/index`, `tournaments/show`, `tournaments/new` | 3 | Low — minor fixes only |
| 04-05 | PAGE-05 | `users/index` | 1 | Low — drop `.table-striped` |

**Wave structure:**
- Wave 1: All 5 plans in parallel (no dependencies between them; all depend only on Phase 3 which is complete)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark card surfaces | Custom SCSS `.dark-card` class | `.card` + `_cards.scss` (Phase 3) | Already built, direct property override pattern |
| Avatar initials circle | Inline if/else in each template | `render "shared/avatar", user: user` | Already built in Phase 3 |
| Dark form inputs | `style=` inline overrides | `.form-control` + `$input-bg` in `_variables.scss` | Already compiled into Bootstrap output |
| Dark table headers | `thead.table-dark` | Plain `thead` + `_tables.scss` | Already done in Phase 3 |
| Status badge logic | Custom CSS classes | Bootstrap `.badge.bg-*` with hash lookup | Works in dark mode via `data-bs-theme` |
| Icon rendering | SVG inline or image_tag | `i.bi.bi-iconname` | Bootstrap Icons already in manifest |

---

## Common Pitfalls

### Pitfall 1: Forgetting `.shadow-sm` removal
**What goes wrong:** Cards look slightly odd (shadow token resolves to `none` but class remains in markup, creating confusion for future maintainers)
**Why it happens:** `.shadow-sm` was standard Bootstrap light-mode pattern; all original templates used it
**How to avoid:** Grep for `.shadow-sm` before submitting — expect 0 occurrences in redesigned templates
**Warning signs:** `grep -r "shadow-sm" app/views/` returns results after redesign

### Pitfall 2: Missing `.container.py-4` on leagues form pages
**What goes wrong:** leagues/new and leagues/edit render with full-width form elements bleeding to browser edge
**Why it happens:** These two templates have no container wrapper at all — they start with `h1` directly
**How to avoid:** Wrap entire template in `.container.py-4` block first
**Warning signs:** `h1` on line 1 of template with no enclosing `.container`

### Pitfall 3: Passing `league_user` instead of `league_user.user` to avatar partial
**What goes wrong:** `NoMethodError: undefined method 'photo' for LeagueUser` at runtime
**Why it happens:** `LeagueUser` delegates `full_name` to `user` but not `photo`
**How to avoid:** Always pass `.user` when calling from league/tournament context: `render "shared/avatar", user: league_user.user`
**Warning signs:** Avatar already correctly uses `league_user.user` in leagues/show — confirm any new uses follow same pattern

### Pitfall 4: Adding new stat cards to dashboard without available data
**What goes wrong:** Stat counters show N/A or cause errors if controller variables are referenced incorrectly
**Why it happens:** Dashboard controller exposes exactly 3 variables: `@my_leagues`, `@my_tournaments`, `@recent_leagues`
**How to avoid:** Stat cards must use only these three variables. Example stats: "Мои лиги: @my_leagues.count", "Мои турниры: @my_tournaments.count". Do NOT add controller changes.
**Warning signs:** Any `@` variable in dashboard template not in the controller list above

### Pitfall 5: `.table-striped` dark inconsistency
**What goes wrong:** Striped rows use Bootstrap's dark alternating color which may not match the `--color-bg-surface` token
**Why it happens:** Bootstrap `.table-striped` uses its own `--bs-table-striped-bg` which may differ from the project's surface token
**How to avoid:** Drop `.table-striped` from dark tables for consistency; use `.table-hover` only
**Warning signs:** Alternating table rows with noticeably different background from adjacent cards

---

## Code Examples

### Dashboard stat card row (new addition)
```slim
/ Add after h1 heading, before .row.g-4
.row.g-3.mb-4
  .col-sm-6.col-lg-3
    .card
      .card-body.d-flex.align-items-center.gap-3
        i.bi.bi-people.fs-2.text-primary
        div
          .text-muted.small Мои лиги
          .fs-4.fw-semibold= @my_leagues.count
  .col-sm-6.col-lg-3
    .card
      .card-body.d-flex.align-items-center.gap-3
        i.bi.bi-trophy.fs-2.text-primary
        div
          .text-muted.small Мои турниры
          .fs-4.fw-semibold= @my_tournaments.count
```

### Auth page card (shadow removed)
```slim
/ Before: .card.shadow-sm  -->  After:
.card
  .card-body.p-4
    h2.card-title.mb-4 Войти
    / ... form
```

### League/tournament form with container wrapper
```slim
/ leagues/new.html.slim and leagues/edit.html.slim — add wrapper:
.container.py-4
  h1.mb-4 Новая лига
  = form_with model: @league, class: "mt-4" do |f|
    / ... existing form fields unchanged
```

### Users index without .table-striped
```slim
/ Before: table.table.table-striped.table-hover.align-middle
/ After:
table.table.table-hover.align-middle
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `thead.table-dark` | Plain `thead` + `_tables.scss` | Phase 3 | Phase 4 templates inherit correct dark header automatically |
| Inline `bg-secondary` avatar circles | `render "shared/avatar", user: user` | Phase 3 | Phase 4 templates use the partial; no inline fallback needed |
| `.card.shadow-sm` | `.card` (shadows suppressed via CSS variable) | Phase 3 | Phase 4 must drop `.shadow-sm` from all card elements |
| No container on form pages | `.container.py-4` wrapping convention | Phase 2 | leagues/new and leagues/edit need this added |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `leagues/new` and `leagues/edit` have no `.container` wrapper — form bleeds to edge | Template Inventory | If templates were updated out-of-band, the container-add task is a no-op (safe) |
| A2 | All 7 auth pages are the complete set — no custom Devise views beyond sessions/new, registrations/new+edit, passwords/new+edit, confirmations/new, unlocks/new | Template Inventory | Verified by `find app/views/devise -name "*.html.slim"` — 9 files found, 2 are shared partials, 7 are page views [VERIFIED] |
| A3 | `tournaments/new` needs no changes | Template Inventory | It uses `.container.py-4`, `.row.g-3`, `.form-control`, `.form-select` — all dark-styled via Phase 3. Safe assumption. |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

---

## Open Questions

1. **Dashboard stat cards — email column in users/index**
   - What we know: `users/index` shows `#`, photo, name, registration date
   - What's unclear: PAGE-05 requirement mentions "name, email" — but current template has no email column
   - Recommendation: Add email column to users/index as part of PAGE-05 to match requirement text. No controller change needed — `user.email` is available.

2. **`@recent_leagues` N+1 — owner eager load**
   - What we know: Dashboard template line 47 calls `league.owner.full_name` without eager loading in controller
   - What's unclear: This is a controller change, outside the "pure UI pass" scope constraint
   - Recommendation: Document in plan as optional improvement note. Do not change controller. OR wrap in a comment noting the N+1 for Phase 4 executor awareness.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — phase is pure Slim template and minimal SCSS changes only)

---

## Security Domain

> This phase contains no authentication, authorization, input handling, or cryptographic operations. All templates are read-only view renders consuming already-validated ActiveRecord objects from controllers. No security-relevant changes.

ASVS not applicable to a pure HTML/CSS template styling pass.

---

## Sources

### Primary (HIGH confidence)
- `[VERIFIED: codebase grep]` — All template file paths confirmed via `find app/views -name "*.html.slim"`
- `[VERIFIED: file read]` — All 20 template contents read and catalogued
- `[VERIFIED: file read]` — Controller variables verified by reading all 4 controllers
- `[VERIFIED: file read]` — SCSS component state verified: `_cards.scss`, `_forms.scss`, `_tables.scss`, `_theme.scss`, `_variables.scss`, `application.bootstrap.scss`
- `[VERIFIED: file read]` — Phase 3 SUMMARYs confirm COMP-01 through COMP-04 complete

### Secondary (MEDIUM confidence)
- `[CITED: Bootstrap 5 docs — badge utilities]` — `bg-*` badge classes respond to `data-bs-theme="dark"` automatically
- `[CITED: Bootstrap 5 docs — table-striped]` — `--bs-table-striped-bg` is a separate CSS variable not overridden in project tokens; safe to drop

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Template inventory: HIGH — every file read directly from disk
- Current state assessment: HIGH — verified by reading each template
- Architecture: HIGH — derived from existing established patterns (Phases 1-3)
- Pitfalls: HIGH — two already encountered in Phase 3 execution documented here
- Plan parallelization: HIGH — directory-based split guarantees no file overlap

**Research date:** 2026-05-09
**Valid until:** End of Phase 4 (SCSS foundation stable; no external dependencies)

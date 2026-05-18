# Feature Landscape — UI Patterns

**Domain:** Dark sports management app (padel league/tournament)
**Researched:** 2026-05-08
**Confidence:** HIGH (established UI patterns from Linear.app, Vercel, Planetscale, and modern sports dashboards)

---

## Table Stakes

Features users expect in any modern dark app. Missing = product feels amateur or broken.

### Global / Layout

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| CSS custom property color system | Without it, dark theme is patchy and inconsistent | Low | `--color-bg-primary`, `--color-border`, `--color-accent` etc.; override Bootstrap vars |
| `<body>` background is the darkest layer | Every other surface elevates slightly from it — without this base, cards float on nothing | Low | e.g. `#0d0f14` or `#0f1117` |
| Consistent border color on all cards/panels | Subtle `1px solid` border at ~10–12% white opacity defines surfaces in dark — without it, cards blur into background | Low | Linear uses `rgba(255,255,255,0.08)` |
| Top navbar with dark surface + brand color accent | Expected navigation pattern; sidebar is overkill for this app scale | Low | Navbar bg slightly lighter than body, not identical |
| Flash messages redesigned to dark theme | Bootstrap default alerts look jarring on dark | Low | Colored left-border + subtle bg tint pattern works well |
| Responsive layout (mobile-first) | Explicit requirement; padel players use phones | Medium | Bootstrap grid already covers most of it |
| Inter or similar sans-serif font | System font stack acceptable; "Padel" product implies some sports energy in typography | Low | Google Fonts Inter or system-ui fallback |
| Active nav link indicator | User must always know which section they are in | Low | Electric blue underline or left accent bar |

### Dashboard

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Stat summary cards in a row | Universal pattern for dashboards; shows "at a glance" numbers | Low | 3–4 cards: My Leagues, My Tournaments, Players, Active Tournaments |
| Card elevation via border + subtle bg difference | Cards must read as distinct surfaces — box-shadow is heavy in dark; use border + bg instead | Low | Linear uses `--surface-01` / `--surface-02` layering |
| Section headings with metadata line | e.g. "My Leagues — 3 active" below the main H1 | Low | Sets context, avoids empty-feeling headers |
| Empty state messaging in dark styling | Bootstrap's `text-muted` looks grey on grey in dark theme — needs explicit styling | Low | Icon + heading + CTA pattern |
| List content inside cards (not bare tables) | Dashboard cards listing leagues/tournaments feel app-quality; raw `<ul>` feels bare | Low | Compact rows with icon, name, meta, count badge |

### List Pages (Leagues Index, Tournaments Index, Users Index)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Page header with title + primary action button aligned right | Standard CRUD list header | Low | "Leagues" + "New League" button right-aligned |
| Card grid for entities with logo/image | Leagues have logos — cards feel more entity-appropriate than a plain table | Low | 3-column grid on desktop, 1 on mobile |
| Fallback avatar/logo placeholder | If no logo, show initials in colored circle — already partially done, needs dark styling | Low | Consistent with user avatars |
| Hover state on cards (subtle border brighten or bg lighten) | Without hover states, dark cards feel static and unresponsive | Low | `border-color` transition, 150ms ease |
| Count badges on entities | Tournament count per league, player count — visual data density | Low | Pill badges with accent or muted color |
| Empty state: icon + message + CTA | Blank page with `p.text-muted` is a table stakes fail | Low | Padel ball icon or generic sports icon works |

### Detail Pages (League Show, Tournament Show)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Hero section with logo/avatar + title + metadata | Detail pages need a strong identity header — raw `h1` with no context reads bare | Low | Logo left, name + meta right, edit button far right |
| Tabbed content panels | Already implemented — needs dark styling (tabs with active indicator) | Low | Bootstrap tabs, override active/hover colors |
| Status badge with semantic color | Tournament status (draft/active/completed/cancelled) — already present, needs dark-appropriate styling | Low | Avoid garish Bootstrap colors; use muted bg + colored text |
| Data grid / definition list as structured key-value pairs | Tournament details (location, dates, type) need visual structure | Low | Two-column grid of label + value, not `<dl>` prose |
| Table with dark row styling | Pairs table, participants table — must override Bootstrap's default white table | Low | Alternating `rgba(255,255,255,0.02)` rows, border separator |
| Avatar stack or avatar + name rows in tables | Players shown with avatar photo/initials + name — already exists, needs coherent dark styling | Low | 40px circle avatar consistent everywhere |
| Breadcrumb or back navigation | "← Leagues" pattern already in templates — needs dark styling | Low | Muted text link, not a button |

### Form Pages (New Tournament, Edit League, Auth forms)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Dark form inputs | Bootstrap default light `form-control` inverts completely in dark — must override bg/border/text/placeholder | Low | `bg: --surface-02`, border: subtle, text: white, placeholder: 40% white |
| Focus ring in accent color | Inputs without visible focus ring are an accessibility and UX fail | Low | `box-shadow: 0 0 0 2px var(--color-accent)` on `:focus` |
| Inline validation state (error) | Already in templates via `is-invalid` — needs dark-appropriate error color | Low | Red text + red border, not relying on Bootstrap default |
| Label styling | Labels should be smaller, muted color — not bold black | Low | `text-xs`, 80% white opacity |
| Submit button as solid accent | Primary CTA should be electric blue fill, full width on mobile | Low | Already using `btn-primary` — override vars |
| File upload input for logos/photos | Active Storage used for League logo + User photo | Low | Minimal custom styling needed; reset default input |
| Section dividers in multi-section forms | Long forms (tournament: 7 fields) need visual grouping | Low | Subtle `<hr>` or spacing + sub-heading approach |

### Auth Pages (Login, Register, Password Reset)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Centered card layout on full dark background | Universal auth page pattern; already implemented structurally | Low | Full viewport height, vertically centered |
| Brand logo/name above form | Auth pages are brand touchpoints — missing logo = feels generic | Low | App name + optional wordmark/icon |
| Form card with slightly elevated surface | Auth card needs to stand out from body | Low | `--surface-01` card on `--bg-primary` body |
| Devise shared links in dark styling | "Forgot password?", "Sign up" links — need to be styled, not default Bootstrap links | Low | Accent color links, appropriate sizing |
| Social proof or app tagline (optional context) | Can be skipped at MVP | Medium | Deferred to differentiators |

### Navigation (Top Navbar)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Logo/brand left, links center or right | Standard top nav layout | Low | Brand far left, nav links center-right |
| Mobile hamburger menu | Required for full responsive; Bootstrap provides toggle | Low | Must test on narrow viewport |
| User identity in nav (name or avatar) | Showing `current_user.email` in nav is too raw — needs avatar/name | Low | 32px avatar circle + truncated full_name |
| Logout accessible from nav | Already exists — needs dark-styled button or dropdown | Low | Can be dropdown under user avatar |
| Nav surface distinct from page body | Navbar `bg-dark` on `bg-dark` body is invisible; surfaces must differ | Low | Navbar: `--surface-02`, body: `--bg-primary` |

---

## Differentiators

Features that make this feel premium — not expected, but immediately noticed.

### Visual Polish

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Electric blue accent glow on primary buttons | Subtle `box-shadow` with `var(--color-accent)` at low opacity on hover/active | Low | `box-shadow: 0 0 12px rgba(59, 130, 246, 0.3)` on hover — Linear does this |
| Stat cards with icon in tinted bg circle | Numbers alone are boring; icon in a `rgba(accent, 0.1)` rounded square makes cards feel designed | Low | Trophy, Medal, Users, Calendar icons |
| Score/leaderboard row with rank highlight | Top-ranked pair/player row gets accent left border or subtle gold tint — feels like sports product | Low | `border-left: 2px solid var(--color-accent)` on rank 1 |
| Tournament status as pill with semantic icon | "Active" with green dot, "Draft" with grey dot — more expressive than text badge alone | Low | CSS pseudo-element dot or SVG icon |
| Skeleton loading states | While data loads, placeholder shimmer cards — rare in Rails apps, premium feel | High | Stimulus controller + CSS animation; deferred unless using Turbo frames |
| Page header accent line | Thin 2px electric blue line under page title or in the hero section | Low | Pseudo-element or `<hr>` styled |
| Consistent avatar color generation | Initials avatar where fallback color is derived from name hash — players always get the same color | Low | Simple JS or CSS: `hsl(hash % 360, 70%, 45%)` |

### Interaction Quality

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Card hover: border brightens + translateY(-1px) | Cards feel alive — 1px lift is subtle but premium | Low | `transition: transform 150ms, border-color 150ms` |
| Button click feedback (active scale) | `transform: scale(0.97)` on `:active` — immediate tactile response | Low | CSS only |
| Smooth tab transitions | Bootstrap tabs can feel snappy — a 150ms fade makes content feel polished | Low | Add `.fade` class (Bootstrap supports this) |
| Flash messages that auto-dismiss | Notifications that slide in and disappear after 4s, Stimulus controller | Medium | Stimulus controller + CSS transform animation |
| Table row hover highlight | `background: rgba(255,255,255,0.03)` on hover in dark table — existing Bootstrap `.table-hover` insufficient | Low | Override Bootstrap hover color via CSS var |

### Typography & Spacing

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Type scale that distinguishes page hierarchy | H1 (page title), H4 (section heading), body, meta — each needs distinct size + weight | Low | Linear uses strong weight contrast between heading and body |
| Tabular numbers for scores/stats | `font-variant-numeric: tabular-nums` on all score/count columns — numbers align cleanly | Low | Single CSS declaration on stat containers |
| Tight line height for headings | Sports/dashboard aesthetic uses tighter line-height on titles (1.1–1.2) | Low | Override Bootstrap heading line-height |
| Uppercase + letter-spacing for table headers | `text-transform: uppercase; letter-spacing: 0.08em` on `<th>` — standard in premium dark tables | Low | Linear, Vercel, Planetscale all do this |

---

## Anti-Features

Patterns to explicitly avoid — common in dark theme implementations and uniformly bad.

### Anti-Pattern 1: Pure black background (#000000)
**Why avoid:** Creates harsh contrast with content, makes eyes work too hard, looks amateur vs. sophisticated dark navy/slate. Also shows gradient banding on many monitors.
**What to do instead:** Use navy/slate base: `#0d0f14`, `#0f1117`, or `#111827`. Linear uses `#0f0f10` (near-black with warmth).

### Anti-Pattern 2: Inverting Bootstrap defaults naively (just setting `color: white`)
**Why avoid:** Bootstrap's `.table`, `.card`, `.form-control`, `.alert`, `.badge` all have white or light backgrounds baked into component CSS. Flipping only text color leaves white input boxes, white table rows, white card backgrounds — the opposite of a dark theme.
**What to do instead:** Override Bootstrap's Sass variables or CSS custom properties systematically at the root level: `--bs-body-bg`, `--bs-card-bg`, `--bs-table-bg`, `--bs-form-control-bg` etc. Do the full component audit.

### Anti-Pattern 3: Using Bootstrap's dark table header (`thead.table-dark`) on a dark body
**Why avoid:** `table-dark` makes the header `#212529` (nearly black) on a dark `#0f1117` body — completely invisible differentiation, headers don't stand out.
**What to do instead:** Use a slightly elevated surface color for headers: `rgba(255,255,255,0.04)` tint + uppercase letter-spacing styling.

### Anti-Pattern 4: Low contrast placeholder text
**Why avoid:** Dark input with `rgba(255,255,255,0.2)` placeholder text fails WCAG AA (minimum 4.5:1 ratio needed). Placeholder text at `0.2` opacity reads around 2:1 — users strain to see it.
**What to do instead:** Placeholder at minimum `0.4` opacity. For labels above inputs, use `0.6–0.7` white opacity (muted but readable).

### Anti-Pattern 5: Box shadows on dark surfaces
**Why avoid:** Box shadows use dark color spreading onto darker background — they're invisible in dark themes. Bootstrap's `.shadow-sm` is useless here.
**What to do instead:** Define elevation with border + background color difference. `border: 1px solid rgba(255,255,255,0.08)` does more visual work than any shadow.

### Anti-Pattern 6: Colored stat cards (red, green, blue bg)
**Why avoid:** Bright solid-colored cards against a dark background are visually noisy — the "Material Design dashboard" look from 2015. They look cheap in a premium dark app.
**What to do instead:** All cards same surface color, differentiated by icon tint. Use accent color sparingly — one per card at low opacity as icon background.

### Anti-Pattern 7: Full-width forms without max-width
**Why avoid:** A form stretching to 1200px on a widescreen looks like a broken layout. Input fields are harder to read at extreme widths.
**What to do instead:** Forms max out at 600–720px (or use Bootstrap's `.col-md-6` / `.col-lg-8` grid columns already present in the codebase). Auth forms already use `.col-md-5`.

### Anti-Pattern 8: Overusing electric blue
**Why avoid:** If every element — borders, links, badges, buttons, highlights — is electric blue, it stops being an accent and becomes the whole palette. Nothing reads as "call to action."
**What to do instead:** Blue only on: primary buttons, active states, links (on hover), active nav item. Everything else is muted white, grey, or green/red for semantic signals.

### Anti-Pattern 9: Inconsistent border radius
**Why avoid:** Some components rounded-pill, some square, some rounded-lg — mix looks accidental and sloppy.
**What to do instead:** Define one radius scale: `--radius-sm: 4px`, `--radius-md: 8px`, `--radius-lg: 12px`. Cards use md, buttons use sm, avatars are full circle. Stick to this.

### Anti-Pattern 10: Bare `<p class="text-muted">` empty states
**Why avoid:** In dark theme, Bootstrap's `text-muted` is `rgba(255,255,255,0.5)` on a dark bg — acceptable contrast but zero visual hierarchy. A single line of muted text in a card body reads as a loading failure, not intentional empty state.
**What to do instead:** Center-aligned empty state with an icon (SVG or Lucide), heading ("No leagues yet"), subtext, and a CTA button. Takes 10 lines of template, transforms the experience.

---

## Feature Dependencies

```
CSS custom property system → Everything else (must be done first)
Top navbar redesign → Auth pages (auth pages share the layout)
Bootstrap variable overrides → Form input styling, table styling, card styling
Avatar/initials component (partial) → Dashboard, League show, Tournament show, Users index
Status badge component (partial) → Tournament show, League show (tournament table)
Empty state component (partial) → Dashboard, Leagues index, Tournaments index, Users index
```

---

## MVP Recommendation

Prioritize in this order:

1. **CSS variable system + Bootstrap overrides** — foundation for everything; without it, all subsequent changes fight the defaults
2. **Application layout (navbar)** — appears on every page; sets the tone; dark body background goes here
3. **Auth pages (login, register)** — first-impression pages; structurally simplest; fast wins that prove the theme
4. **Dashboard** — most complex (stat cards, lists, recent section); highest visibility; defines the "feel"
5. **League pages (index, show, edit, new)** — core entity; logo support means visual richness
6. **Tournament pages (index, show, new)** — tables with pairs/scores; leaderboard is the highest-impact component
7. **Users index** — simplest table page; quick to do once table pattern is established

Defer:
- **Skeleton loading states** — Stimulus complexity; polish only after all pages done
- **Auto-dismiss flash messages** — nice but not blocking; simple Stimulus add-on at the end
- **Social proof on auth pages** — no content exists for this yet

---

## Sources

- Linear.app design system (direct inspection of linear.app UI, 2026)
- Vercel dashboard dark UI conventions (vercel.com, current)
- Planetscale console dark UI (planetscale.com, current)
- Bootstrap 5 dark mode documentation: https://getbootstrap.com/docs/5.3/customize/color-modes/
- WCAG 2.1 contrast requirements: https://www.w3.org/TR/WCAG21/#contrast-minimum
- Existing codebase templates (app/views/**/*.slim) — inspected 2026-05-08
- Training knowledge: established dark UI patterns from Linear, Vercel, GitHub, Figma, Notion dark mode (HIGH confidence — patterns are stable and well-established)

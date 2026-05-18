# Phase 1: CSS Foundation - Context

**Gathered:** 2026-05-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 delivers a complete CSS design token system and Bootstrap SCSS override layer. No UI components, no templates, no visual pages — just the foundational CSS that every subsequent phase (2–5) imports and builds on. Success means the dark palette, typography, and spacing tokens resolve correctly in the browser and Bootstrap's own components inherit the dark colors without any per-component overrides.

</domain>

<decisions>
## Implementation Decisions

### Color Palette

The full token set below is decided. Downstream agents must use these exact values — no substitutions.

- **D-01:** `--color-bg-base: #0d1117` — darkest layer, page body background (GitHub dark)
- **D-02:** `--color-bg-navbar: #161b22` — navbar surface, distinct from base but not jarring
- **D-03:** `--color-bg-surface: #21262d` — card and elevated surface background (from COMP-01 requirement)
- **D-04:** `--color-text-primary: #e6edf3` — primary body text (GitHub dark off-white)
- **D-05:** `--color-text-muted: #8b949e` — secondary text, labels, timestamps, helper text
- **D-06:** `--color-border: #30363d` — borders and dividers
- **D-07:** `--color-accent: #2f81f7` — electric blue, primary action / focus color (from POLL-01 glow spec)

### Bootstrap Variable Mapping

Bootstrap's SCSS variables must be overridden to inject the palette into all Bootstrap components:

- `$body-bg` → `#0d1117`
- `$body-color` → `#e6edf3`
- `$border-color` → `#30363d`
- `$primary` → `#2f81f7`
- `$dark` → `#21262d`
- All overrides injected **before** `@import 'bootstrap/scss/...'` so they propagate into Bootstrap's generated CSS

### Typography

No explicit decision made during discussion — Claude has discretion. Inter or system font stack as stated in CSST-03. Recommended: Inter via Google Fonts import (matches Linear.app reference), with system font stack fallback.

### Spacing Tokens

No explicit decision made during discussion — Claude has discretion. Define `--space-{1..8}` custom properties using a `0.25rem` base scale (matching Bootstrap's spacing scale) for CSST-04.

### Claude's Discretion

- Font loading: Inter via Google Fonts or system font stack — Claude picks based on what gives cleaner dark legibility
- Spacing scale values: Use `0.25rem` increments (`--space-1: 0.25rem` through `--space-8: 2rem`) unless a cleaner scale fits
- SCSS file structure: Claude decides whether to split into partial files or keep single-file — should optimize for readability across future phases

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements

- `.planning/REQUIREMENTS.md` §CSS Foundation — CSST-01 through CSST-04 define the four deliverables for this phase
- `.planning/ROADMAP.md` §Phase 1 — Success criteria (4 items): CSS custom properties resolve, Bootstrap compiles dark, typography at correct weights, spacing tokens available

### Existing Code (must read before modifying)

- `app/assets/stylesheets/application.bootstrap.scss` — current entry point (2 lines: bare Bootstrap import + Bootstrap Icons); this file gets rewritten in Phase 1
- `package.json` — CSS build pipeline: `sass ./app/assets/stylesheets/application.bootstrap.scss → ./app/assets/builds/application.css` then autoprefixer. Build command: `yarn build:css`. Watch: `yarn watch:css`

### Design Reference

- Linear.app (external) — the design inspiration. Key traits: deep dark base, clean typography with Inter, sharp card edges, subtle borders

### No external specs

No project-local ADRs or design spec files exist yet. Requirements fully captured in `.planning/REQUIREMENTS.md` and decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `app/assets/builds/application.css` — compiled output file; the build pipeline writes here (Propshaft serves from `builds/`). Do not edit directly.
- `app/javascript/controllers/` — Stimulus controller pattern is already set up; Phase 1 does not touch JS

### Established Patterns

- **CSS build pipeline:** `yarn build:css` runs sass compile → PostCSS autoprefixer. Any SCSS changes are picked up by `yarn watch:css` in dev. No webpack/esbuild — plain Sass CLI.
- **Asset serving:** Propshaft (not Sprockets). Compiled CSS lands in `app/assets/builds/` and is referenced by `stylesheet_link_tag "application"` in the layout.
- **Bootstrap integration:** Bootstrap 5.3.3 installed via yarn at `node_modules/bootstrap/scss/`. The `--load-path=node_modules` flag in the build script enables `@import 'bootstrap/scss/...'` imports.

### Integration Points

- `app/views/layouts/application.html.slim` — uses `navbar-dark bg-dark` Bootstrap classes; Phase 2 will replace these with custom CSS, but Phase 1 must ensure `$dark` and `$body-bg` Bootstrap variables are overridden so interim states render correctly
- All subsequent phases (2–5) `@import` or depend on the CSS custom properties defined in Phase 1

</code_context>

<specifics>
## Specific Ideas

- Color palette is GitHub-dark-inspired by explicit user choice, with Linear.app as the aesthetic reference
- The `#0d1117` + `#161b22` + `#21262d` layering creates clear visual depth: background → navbar → card surface
- `#2f81f7` is the exact accent blue (derived from `rgba(47,129,247,0.3)` in POLL-01 glow spec)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-CSS Foundation*
*Context gathered: 2026-05-09*

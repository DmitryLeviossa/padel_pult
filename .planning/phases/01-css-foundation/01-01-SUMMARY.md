---
phase: 01-css-foundation
plan: "01"
subsystem: build-pipeline, html-layout
tags: [sass, bootstrap, dark-mode, google-fonts, inter]
dependency_graph:
  requires: []
  provides:
    - Bootstrap dark mode CSS variable layer via data-bs-theme=dark on html element
    - Dart Sass deprecation suppression in build script (--silence-deprecation=import,color-functions)
    - Inter font loading from Google CDN via preconnect + stylesheet link tags
  affects:
    - All pages served by the application (dark mode attribute is global)
    - CSS build pipeline (package.json build:css:compile script)
tech_stack:
  added: []
  patterns:
    - Sass --silence-deprecation flag to suppress known Bootstrap 5.3 import/color-functions warnings
    - data-bs-theme="dark" HTML attribute pattern to activate Bootstrap _root.scss dark variable block
    - Google Fonts <link> preconnect approach (not SCSS @import) for parallel font fetch
key_files:
  created: []
  modified:
    - package.json
    - app/views/layouts/application.html.slim
decisions:
  - "Use --silence-deprecation=import,color-functions (not --quiet-deps) to precisely target Bootstrap 5.3 known issues while preserving visibility of real errors"
  - "Google Fonts via <link> tags (not SCSS @import) so font fetch runs in parallel with stylesheet per RESEARCH.md Pitfall 5"
  - "Placement of Fonts links: after PWA manifest comments, before icon links — ensures fonts load before page stylesheet"
metrics:
  duration: "~5 minutes"
  completed: "2026-05-09"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 01 Plan 01: CSS Foundation Prerequisites Summary

Wire Dart Sass deprecation suppression and Bootstrap dark mode + Inter font loading — the two non-SCSS prerequisites that gates all Plans 02-03 SCSS variable work.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add --silence-deprecation flag to package.json build script | 1f16f9b | package.json |
| 2 | Add data-bs-theme and Google Fonts links to application.html.slim | 29ffdc7 | app/views/layouts/application.html.slim |

## What Was Built

**Task 1 — Deprecation Suppression:**
- Modified `build:css:compile` in `package.json` to append `--silence-deprecation=import,color-functions`
- Bootstrap 5.3 generates 312+ Dart Sass 1.99 deprecation warnings per build (known Bootstrap limitation with `@import` and legacy color functions)
- Flag suppresses only these known warnings; real compilation errors remain visible
- No other scripts (`build:css:prefix`, `build:css`, `watch:css`) modified

**Task 2 — Dark Mode + Inter Font:**
- Changed `html` to `html data-bs-theme="dark"` on line 2 of `application.html.slim`
- This activates Bootstrap's `_root.scss` `[data-bs-theme=dark]` CSS variable block globally
- Inserted three Google Fonts link tags in `<head>` after PWA manifest comments, before icon links:
  1. `link rel="preconnect" href="https://fonts.googleapis.com"`
  2. `link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"`
  3. `link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"`

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both changes are wired directly: the Sass flag affects the build immediately, and the HTML attribute + font links take effect on every page render.

## Threat Flags

No new security-relevant surface introduced beyond what the plan's threat model documents (T-01-01: Google Fonts CDN link with no SRI — accepted disposition; T-01-02: build script flag — accepted disposition).

## Self-Check: PASSED

Files exist:
- package.json: FOUND — contains `--silence-deprecation=import,color-functions`
- app/views/layouts/application.html.slim: FOUND — contains `html data-bs-theme="dark"` and three Google Fonts link tags

Commits exist:
- 1f16f9b: FOUND (feat(01-01): silence Dart Sass 1.99 deprecation flood in build script)
- 29ffdc7: FOUND (feat(01-01): activate Bootstrap dark mode and load Inter font in layout)

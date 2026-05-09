---
status: partial
phase: 03-shared-components
source: [03-VERIFICATION.md]
started: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Card dark surface rendering
expected: Navigate to `/leagues` or `/devise/registrations/edit`, inspect a `.card`. Background should be `#21262d`, visible 1px border, no visible box-shadow glow on dark background.
result: [pending]

### 2. Form controls dark surface and electric blue focus ring
expected: Open any form page (e.g. `/users/sign_in`), check input background is dark (not white), then click into a text field and verify electric blue focus ring appears.
result: [pending]

### 3. File upload ::file-selector-button background
expected: Open `/users/edit`, inspect the file upload button. Should render at `#161b22` (navbar-dark) — visually darker than the `#21262d` input surface, providing clear visual separation.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps

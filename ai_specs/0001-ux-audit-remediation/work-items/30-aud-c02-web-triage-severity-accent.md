---
type: Work Item
title: AUD-C02 Web Triage Row Visual Severity Striping and Left Accent Border
parent: ../spec.md
---

## What to build
Add a subtle 4px left accent border (red `#EF4444` for critical/urgent status, amber `#F59E0B` for moderate alerts) and distinct badge pill styling to high-priority triage patient table rows in `web/src/pages/dashboard.astro` to accelerate clinical triage decision-making.

## Required context
- Target file: `web/src/pages/dashboard.astro`
- Styles: `web/src/index.css`

## Acceptance criteria
- [ ] Critical/urgent triage rows feature a 4px solid red left border (`border-l-4 border-red-500`).
- [ ] Moderate triage rows feature a 4px solid amber left border (`border-l-4 border-amber-500`).
- [ ] Status badges use high-contrast color pills with clear text labels.

## Covers
- User Stories: US6
- Requirements: Requirement 30
- Interview Ledger: L30

## Blocked by
None - ready to start

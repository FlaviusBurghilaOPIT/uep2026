---
type: Work Item
title: AUD-C01 Web Clinician Dashboard Inline Triage Resolution Modal
parent: ../spec.md
---

## What to build
Provide a 1-click inline resolution modal with a mandatory reason note directly from the triage table rows in the web portal (`web/src/pages/dashboard.astro` / `web/src/pages/TriageDashboard.tsx`) so clinicians can resolve minor triage alerts without navigating away from the dashboard (Tesler's Law).

## Required context
- Target file: `web/src/pages/dashboard.astro`
- Target file: `web/src/api/client.ts`
- Backend API endpoint: `POST /cases/{caseId}/triage-resolutions` or patch case status

## Acceptance criteria
- [ ] Triage table rows include a "Resolve" button.
- [ ] Clicking "Resolve" opens an inline modal requesting resolution reason notes.
- [ ] Submitting the modal resolves the alert in-place and updates the table row status without full page reload.

## Covers
- User Stories: US6
- Requirements: Requirement 29
- Interview Ledger: L29

## Blocked by
None - ready to start

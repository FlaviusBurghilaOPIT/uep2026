---
type: Work Item
title: AUD-C03 Web Medication Prescription Constrained Clinical Schedule Picker
parent: ../spec.md
---

## What to build
Replace free-text frequency input with a constrained clinical schedule picker (QD - Daily, BID - Twice daily, TID - 3x daily, QID - 4x daily, PRN - As needed) with structured dose time selectors in `web/src/pages/cases/[caseId]/medications/` to prevent prescription scheduling syntax errors (Norman Constraints).

## Required context
- Target file: `web/src/pages/cases/[caseId]/medications/index.astro`
- Target file: `web/src/pages/cases/[caseId]/medications/new.astro` (or relevant form)

## Acceptance criteria
- [x] Frequency selection uses a dropdown/segmented selector with options: QD, BID, TID, QID, PRN.
- [x] Selecting a frequency pre-populates standardized scheduled slot times (e.g. BID -> 08:00, 20:00).
- [x] Eliminates malformed free-text frequency entries.

## Covers
- User Stories: US6
- Requirements: Requirement 31
- Interview Ledger: L31

## Blocked by
None - ready to start

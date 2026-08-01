---
type: Work Item
title: Web — Clinician Intake Form
parent: ../spec.md
---

## What to build
Extend the clinician "New Patient" form (`CreatePatientPage`) to capture the facts the clinic knows: add a required date-of-birth picker and a required surgery-date picker, sent to the backend invite endpoint. Add proper loading / success / error states to the invite action, keeping the invite-code display on the success screen as the documented fallback channel (the patient is also emailed it). No broader redesign of the clinician dashboard.

## Required context
- `web/src/pages/CreatePatientPage.tsx` — current fields (full name, email, surgery type, emergency-contact phone) and invite flow.
- `web/src/i18n/translations/*.ts` and `web/src/i18n/types.ts` — add labels for the new fields across locales.
- Backend contract from `02-backend-intake-data-model.md` (`PatientInviteRequest` requires `date_of_birth`; `Case.surgery_date`).
- Web has no test harness (per `0001` and the 2026-07-23 design); verify via build/analyze + manual QA and state this in the PR.

## Acceptance criteria
- [ ] The new-patient form has required date-of-birth and surgery-date pickers; submission is blocked (with a clear message) if either is missing.
- [ ] The invite request sends `date_of_birth` and `surgery_date` to the backend.
- [ ] The invite action shows loading, success, and error states; the success screen still displays the invite code.
- [ ] New field labels are added to all configured locales.
- [ ] The form builds cleanly (build/analyze) and was manually QA'd (stated in the PR).

## Covers
- User Stories: 4
- Requirements: 7, 12
- Testing Strategy: 3
- Interview Ledger: L2, L7

## Blocked by
- 02-backend-intake-data-model.md

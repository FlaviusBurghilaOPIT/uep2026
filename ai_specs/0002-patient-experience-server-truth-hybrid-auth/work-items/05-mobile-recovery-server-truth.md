---
type: Work Item
title: Mobile — Recovery Server-Truth
parent: ../spec.md
---

## What to build
Make the Recovery screen render only server truth. Care instructions render as a flat list of recommendation text from `GET /cases/{id}/recommendations`; the 7-day adherence chart and "Day N" are derived client-side from real adherence logs and the server-provided `surgery_date`; the header (surgery type, patient name, clinician name) uses real case/auth data with honest absence where unavailable. Remove the fabricated milestone timeline, the "Seek Care Immediately If" warning box, the hardcoded "Day 19", and the dead notification bell. Add `AppSkeletonLoader` loading plus empty/error states.

## Required context
- `mobile/lib/features/recovery/presentation/screens/recovery_screen.dart` — currently 100% hardcoded (Day 19, milestones, chart values, warning box, fake clinician name).
- `mobile/lib/core/widgets/app_skeleton_loader.dart` — existing skeleton component (used by Today/Medications).
- Backend: `GET /cases/{id}/recommendations` (free-text `Recommendation`), adherence logs, and the case response exposing `surgery_date` (from `02-backend-intake-data-model.md`).
- Pattern reference: `ai_specs/2026-07-26-today-screen-hardening-spec.md` (server-truth / real-data-or-honest-absence; skeleton + empty/error states).
- Test seam: `mobile/test/unit/fake_api_service.dart`.

## Acceptance criteria
- [ ] Care instructions render as a flat list of recommendation text; the categorized icon-cards are gone.
- [ ] The adherence chart is derived from real adherence logs (7-day taken/total); with no logs it shows an honest empty state.
- [ ] "Day N" and the surgery date derive from the server-provided `surgery_date`; if absent, honest absence (no fabricated number).
- [ ] The header uses real surgery type / patient name / clinician name (honest absence where unavailable); no hardcoded names.
- [ ] The milestone timeline, warning-signs box, "Day 19", and dead notification bell are removed.
- [ ] Loading uses `AppSkeletonLoader`; empty and error states render.
- [ ] Widget/unit tests (FakeApiService) assert real-data rendering vs honest absence (no fabricated meds/Day-19/milestones); `golden_loop_test.dart` covers Recovery showing real data after password login.

## Covers
- User Stories: 5
- Requirements: 13, 14, 15, 16, 17, 18, 19
- Testing Strategy: 2, 4, 6
- Interview Ledger: L4, L7

## Blocked by
- 02-backend-intake-data-model.md
- 04-mobile-hybrid-auth-onboarding.md

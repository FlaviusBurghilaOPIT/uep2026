---
type: Spec
title: Patient Experience Server-Truth & Hybrid Auth
---

## Problem

The patient mobile app and the clinician web intake still carry fabricated or disconnected experiences that contradict the product's core principle ("the clinician is the source of truth; the patient receives everything automatically") and the server-truth bar already set by `ai_specs/2026-07-26-today-screen-hardening-spec.md`:

- Patient auth is passwordless-only across two approved specs, but the owner wants a persistent password with a code fallback (hybrid).
- The patient is asked to re-enter data the clinic already has. DOB is never captured at intake, so the clinician dashboard renders it as "N/A" and the patient types it at onboarding.
- The Recovery screen is 100% fabricated — "Day 19 of Recovery", a milestone timeline, an adherence chart with hardcoded values, a "Seek Care Immediately If" warning box, and a fake clinician name — with almost no backend source.
- The Profile screen shows dead controls (Two-factor authentication, Connected devices, a fake notification badge) and hardcoded fallback values.
- The Assistant (referred to colloquially as "the cat") needs its guardrail banner confirmed plus loading/error/streaming polish.
- The clinician "New Patient" form captures only name, email, surgery type, and emergency-contact phone.

## Proposed Outcome

One coherent cross-platform change (mobile + web + backend) that: makes patient authentication hybrid (password set at onboarding, code fallback); captures DOB and surgery_date at clinician intake and pre-fills them (editable) on the patient side; extends the server-truth / real-data-or-honest-absence rule to the Recovery and Profile screens; cleans up the Profile to match what the backend actually supports; and polishes the Assistant. This Spec complements `ai_specs/0001-mobile-core-loop-hardening-polish/spec.md` (mobile polish, no backend) and revises the passwordless auth specs.

## User Stories

1. As an invited patient, I want to set a password the first time I sign in (after my email is verified by code), so I can use a memorable credential next time. [L1]
2. As a returning patient, I want to sign in with either my email+password or an emailed one-time code, so I am never locked out if I forget my password. [L1, L3]
3. As a patient, I want my name and date of birth already filled in from what my clinic recorded — and editable — so I am not re-entering data the clinic already has. [L2]
4. As a clinician creating a patient case, I want to record the patient's date of birth and surgery date, so the patient's app and my dashboard show truthful, complete records. [L2, L7]
5. As a patient viewing Recovery, I want every fact (care instructions, adherence chart, "Day N", header) to come from my real care plan — and fabricated content removed — so I am never shown invented clinical information. [L4, L7]
6. As a patient, I want a Profile that only shows things the platform actually supports (no 2FA or connected-devices dead ends) with my real information, so the app feels trustworthy. [L6]
7. As a patient, I want to change my password from the Profile while signed in, so I can update a forgotten or compromised credential without a separate reset flow. [L3]
8. As a patient using the Assistant, I want an informational-only disclaimer and honest loading/error/streaming behavior, so I understand its boundaries and never see a dead control. [L5]

## Requirements

### Hybrid Patient Auth (mobile + backend)

1. First-run onboarding adds a "Create password" step after the emailed code verifies the patient's email; the password is stored as `password_hash`. Minimum 8 characters, a confirmation field, and no additional complexity rules. Backend: `CompleteOnboardingRequest` gains an optional `password`, hashed to `password_hash` when present. [L1]
2. The returning-login Welcome screen offers two methods: email+password (default) and "email me a one-time code" (fallback). Both lead to Today on success. [L1]
3. The email-code path (`request-code` / `verify-code`) remains fully functional and is the account-recovery mechanism for a forgotten password. [L1, L3]
4. No standalone "Forgot password" screen or reset endpoint is built in this effort. [L3]
5. The Profile gains a "Change password" action for authenticated users. If the user has an existing password, the current password is required; a user who signed in via code (no password) simply sets a new one. [L3]
6. This revises/supersedes the passwordless-only decisions in `ai_specs/2026-07-25-patient-first-run-flow-spec.md` and `docs/superpowers/specs/2026-07-23-dev-stack-and-patient-auth-cleanup-design.md` for patients. Clinician email+password auth is unchanged. [L1]

### Clinician Intake & Patient Data (web + backend + mobile)

7. The clinician "New Patient" form (web `CreatePatientPage`) adds a required date-of-birth field (date picker) and a required surgery-date field (date picker). [L2, L7]
8. Backend `PatientInviteRequest` gains a required `date_of_birth`; the `Case` gains a `surgery_date` field (with an Alembic migration). Both are stored at invite/case creation. The `surgery_date` column is nullable (existing/seeded cases pre-date it); the form requires it only for newly created cases. [L2, L7]
9. Patient onboarding shows full name and date of birth pre-filled from the backend (`verify-code` / `/auth/me`) and editable; the patient confirms or corrects. [L2]
10. Phone remains patient-provided at onboarding (pre-filled only if the clinic captured it). [L2]
11. `complete-onboarding` persists the patient's edits and phone. `date_of_birth` becomes optional in `CompleteOnboardingRequest` (it is pre-set at intake); when `date_of_birth` or `phone` is supplied it updates the stored value. [L2]
12. The invite flow gains proper loading/success/error states; the invite code continues to be shown on the success screen as the documented fallback channel (the patient is also emailed it). [L7]

### Recovery Server-Truth (mobile + backend)

13. Recovery care instructions render as a flat list of recommendation text from `GET /cases/{id}/recommendations` (each `Recommendation` is free-text). The fabricated categorized icon-cards (Activity Restrictions / Wound Care / Physiotherapy) are removed; structured/categorized recommendations are deferred (see Follow-Ups). [L4]
14. The Recovery adherence chart is derived client-side from the patient's existing adherence logs (a 7-day taken/total per day); with no logs it shows an honest empty state. No new backend endpoint is introduced. [L4]
15. The Recovery header (surgery type, patient name, clinician name) renders from real Case/auth data where a patient-accessible endpoint exposes it; otherwise honest absence. [L4]
16. "Day N of Recovery" and the surgery date render from the `surgery_date` captured at intake [L7]; the backend exposes `surgery_date` on the patient's case and the mobile derives Day N from it. If `surgery_date` is absent, honest absence (no fabricated number). [L4, L7]
17. The fabricated milestone timeline and the hardcoded "Seek Care Immediately If" warning-signs box are removed (honest absence). [L4]
18. Recovery uses `AppSkeletonLoader` for loading and provides empty/error states consistent with the Today hardening pattern. [L4]
19. The dead notification bell (fake red dot) on the Recovery top bar is removed. [L4]

### Profile Cleanup (mobile)

20. The Profile removes the "Two-factor authentication" and "Connected devices" rows and the dead top-bar notification bell / fake badge. [L6]
21. The Profile "Change password" row is wired to the change-password flow. [L3, L6]
22. All hardcoded fallbacks (e.g. `Sarah Mitchell`, `Mar 14, 1988`, `Knee Arthroscopy`, `Jun 18, 2025`, `Dr. Claire Moreau`, `RC-4827-XK`, `sarah.mitchell@email.com`, `+1 (555) 248-3901`, `Post-surgical recovery`) are replaced with real auth/Case data or honest absence. Fields with no backend source (notably `Condition`/primaryCondition, which has no model field) render honest absence rather than a fallback. [L6]
23. Personal information (name, email, phone, DOB) is sourced from auth (`/auth/me`) and editable; any field not returned by `/auth/me` shows honest absence. [L2, L6]
24. The "Invite code" row is removed (it is cleared post-onboarding and is not meaningful to display). [L6]
25. Notification toggles: "Medication reminders" and "Daily check-in" persist to `shared_preferences` and gate local notification scheduling only while OS notification permission is granted; if permission is denied the toggles are inert and the C1 reminders-off banner owns recovery. The "FDA safety alerts" toggle is removed (no FDA push mechanism exists). [L6]

### Assistant (mobile)

26. The Assistant shows a persistent informational-only ("never diagnostic") disclaimer banner. This banner is already specified in `0001` Req 14; this Spec confirms it and relies on that definition. [L5]
27. The Assistant renders streaming responses progressively and provides honest loading and error states (no dead controls). [L5]
28. The feature is referred to canonically as the "Assistant" (see `GLOSSARY.md`). [L5]

## Technical Decisions

1. Hybrid auth reuses the existing `/auth/login` (email+password) endpoint for patients (`password_hash` is now set at onboarding) and keeps `request-code` / `verify-code` as the code path; change-password is a new authenticated endpoint (provisional path `POST /auth/change-password`). [L1, L3]
2. `surgery_date` is added to the `Case` model (nullable column) with an Alembic migration and exposed on the patient's case response; "Day N" and the 7-day adherence chart are derived client-side from the server-provided `surgery_date` and existing adherence logs. No new aggregation endpoints are introduced — the raw values remain server truth, and only trivial day-count/chart aggregation happens client-side. [L4, L7]
3. Recovery and Profile adopt the Today hardening spec's server-truth principle ("real data or honest absence"); no fabricated clinical content under the clinic's name. [L4, L6]
4. No new structured recovery models (Milestone, warning signs) are introduced now; those are deferred backend work. [L4]
5. Notification preferences are stored client-side (`shared_preferences`), not in the backend, since no notification-preference endpoint exists. [L6]
6. This Spec complements `ai_specs/0001-mobile-core-loop-hardening-polish/spec.md` (mobile polish, no backend) and reuses its Assistant guardrail-banner definition (Req 14) and 5-tab navigation; it does not re-spec them. [L5]

## Testing Strategy

1. Backend: `pytest` with the existing in-memory SQLite seam covers — password set at `complete-onboarding`; `/auth/login` succeeding for a patient with a password; `verify-code` returning a token; change-password (with and without an existing password); `PatientInviteRequest` requiring `date_of_birth`; `Case` storing `surgery_date`; and the patient's case response exposing `surgery_date`.
2. Mobile: widget/unit tests using the existing `FakeApiService` seam (`mobile/test/unit/fake_api_service.dart`) cover — Welcome two-method login; create-password step validation; onboarding pre-fill + edit; Recovery Day-N and 7-day chart derivation from `surgery_date`/adherence logs; Recovery rendering real data vs honest absence (no fabricated meds/Day-19/milestones); Profile cleanup (no 2FA/connected-devices rows; real data); and Assistant loading/error/streaming states.
3. Web: the `CreatePatientPage` DOB + surgery_date fields and the invite loading/success/error states. Web currently has no test harness (per `0001` and the 2026-07-23 design); verify via build/analyze and manual QA, stated explicitly in the Work Item.
4. Integration: extend `mobile/integration_test/golden_loop_test.dart` (backend + seeded DB + simulator) to cover invited patient → set password → re-login with password → Recovery shows real data.
5. Test Seams: prefer existing seams (`FakeApiService`, backend in-memory SQLite, `golden_loop_test`). No live network/LLM/email calls in automated tests (the email service dry-runs).
6. TDD is expected for notifier/state logic per `act-flutter-tdd` where logic changes (auth notifier password step; recovery notifier server-truth mapping).

## Out of Scope

- A structured recovery Milestone model and authored warning-signs data (deferred backend work). [L4]
- A standalone forgot-password reset flow/endpoint. [L3]
- A full redesign of the clinician dashboard or case-detail experience. [L7]
- Capturing patient phone at clinician intake (phone remains patient-provided). [L2]
- 2FA, connected-devices/session management, and FDA push notifications (no backend support). [L6]
- The parts of `0001` already specified (5-tab navigation, Medications screen, undo window, interactive notifications, FDA provenance badge) — not re-scoped here.

## Open Questions

- Exact placement/wording of the first-run "Create password" step relative to the profile step (default: immediately after code verification, first-run only) — finalize during implementation. [L1]
- Welcome screen two-method presentation (default: password form primary with an "or email me a one-time code" alternative). [L1]
- Assistant disclaimer banner exact copy requires ⚕ clinical sign-off (banner shape per `0001` Req 14). [L5]

## Follow-Ups

- Future backend work: a structured Milestone model + surgery-date-driven milestone timeline; structured/categorized recommendations (to restore categorized care-instruction cards); authored warning-signs content; notification-preference persistence; FDA push alerts.

## Notes

- Revises/supersedes (does not delete) the passwordless patient-auth decisions in `ai_specs/2026-07-25-patient-first-run-flow-spec.md` and `docs/superpowers/specs/2026-07-23-dev-stack-and-patient-auth-cleanup-design.md`.
- Complements `ai_specs/0001-mobile-core-loop-hardening-polish/spec.md` (reuses the Assistant banner Req 14 + 5-tab navigation) and extends `ai_specs/2026-07-26-today-screen-hardening-spec.md`'s server-truth principle to Recovery + Profile.
- Canonical term "Assistant" recorded in `GLOSSARY.md`.
- Spans mobile (Flutter), web (React), and backend (Python); expected to decompose into multiple Work Items (auth, intake, recovery, profile, Assistant).

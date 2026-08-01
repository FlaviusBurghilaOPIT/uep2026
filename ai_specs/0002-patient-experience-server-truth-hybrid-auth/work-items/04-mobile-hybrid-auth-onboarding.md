---
type: Work Item
title: Mobile — Hybrid Auth UI + Onboarding Pre-fill
parent: ../spec.md
---

## What to build
Implement hybrid patient auth and pre-filled onboarding on mobile. The Welcome screen offers two sign-in methods — email+password (default) and "email me a one-time code" (fallback) — both landing on Today. First-run onboarding adds a "Create password" step (min 8 chars + confirmation) after the emailed code verifies the email, then shows name + DOB pre-filled from the backend and editable, and collects the patient's phone; `complete-onboarding` sends the password and any edits. Boot routing uses the real JWT (not demo prefs). The email-code path remains as account recovery.

## Required context
- `mobile/lib/features/auth/` — current screens (`boot_screen.dart`, `email_login_screen.dart`, `otp_screen.dart`, `profile_setup_screen.dart`) and providers (`auth_provider.dart`, `demo_auth_provider.dart`); `mobile/lib/core/providers/app_providers.dart`; `mobile/lib/features/auth/domain/entities/auth_state.dart`.
- `mobile/lib/core/network/api_service.dart` — add/adjust calls for `/auth/login`, `request-code`, `verify-code`, `complete-onboarding`.
- Reference (not authority): `ai_specs/2026-07-25-patient-first-run-flow-spec.md` screen architecture — this Spec supersedes its passwordless decision (hybrid instead).
- Backend contracts from `01-backend-hybrid-auth.md` and `02-backend-intake-data-model.md`.
- Test seam: `mobile/test/unit/fake_api_service.dart`.

## Blocking decisions
- Create-password step placement — default: immediately after code verification, first-run only. Confirm before building the screen flow.
- Welcome two-method presentation — default: password form primary with an "or email me a one-time code" alternative. Confirm before building.

## Acceptance criteria
- [ ] Welcome screen offers email+password (default) and a code fallback; both route to Today on success.
- [ ] First-run flow: code verify → create-password (≥8 chars + confirmation, validated) → pre-filled editable name + DOB → phone → Today; `complete-onboarding` persists the password and edits.
- [ ] A returning patient can sign in with password or code; boot routes via the real JWT (valid → main, absent/401 → Welcome).
- [ ] Onboarding pre-fills name + DOB from the backend and persists patient edits; phone is patient-provided.
- [ ] Widget/unit tests (FakeApiService) cover two-method login, create-password validation, and onboarding pre-fill + edit.
- [ ] `golden_loop_test.dart` is extended (invited patient → set password → re-login with password) — coordinated with `05-mobile-recovery-server-truth.md`.

## Covers
- User Stories: 1, 2, 3
- Requirements: 1, 2, 3, 9, 10
- Testing Strategy: 2, 4, 6
- Interview Ledger: L1, L2

## Blocked by
- 01-backend-hybrid-auth.md
- 02-backend-intake-data-model.md

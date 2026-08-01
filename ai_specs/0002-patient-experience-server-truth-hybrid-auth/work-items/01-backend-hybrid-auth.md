---
type: Work Item
title: Backend — Hybrid Patient Auth Endpoints
parent: ../spec.md
---

## What to build
Make patient authentication hybrid on the backend. `complete-onboarding` gains an optional `password` (hashed to `password_hash` when present) and `date_of_birth` becomes optional-but-updatable (it is pre-set at intake; when supplied it updates the stored value). Add an authenticated `POST /auth/change-password` endpoint (require the current password only if the user already has one). Confirm the existing `POST /auth/login` authenticates a patient once `password_hash` is set. Leave the code path (`/auth/patient/request-code`, `/auth/patient/verify-code`) unchanged — it remains the account-recovery mechanism.

## Required context
- `backend/app/routers/auth.py` — `complete_onboarding`, `login`, `request_patient_code`, `verify_patient_code`.
- `backend/app/schemas.py` — `CompleteOnboardingRequest` (currently requires `date_of_birth`, `phone`), `LoginRequest`, `TokenResponse`.
- `backend/app/security.py` — `hash_password`, `verify_password`, `create_access_token`.
- `backend/app/models.py` — `User.password_hash` (nullable), `User.status`.
- No standalone forgot-password endpoint is built (Out of Scope).

## Acceptance criteria
- [x] `CompleteOnboardingRequest` accepts an optional `password`; when present it is hashed and stored as `password_hash`.
- [x] `complete-onboarding` accepts an optional `date_of_birth`; when supplied it updates the stored DOB, when omitted the existing DOB is preserved.
- [x] `POST /auth/change-password` (authenticated) sets a new password; it requires the current password when one exists and allows a code-authenticated user (no existing password) to set one without it.
- [x] A patient with a `password_hash` can authenticate via `POST /auth/login`; the code path still works and is unchanged.
- [x] Backend `pytest` (in-memory SQLite) covers: password set at onboarding; `/auth/login` for a patient with a password; change-password with and without an existing password; `date_of_birth` optional-but-updatable.

## Covers
- User Stories: 1, 2, 7
- Requirements: 1, 5, 6, 11
- Testing Strategy: 1
- Interview Ledger: L1, L3

## Blocked by
None - ready to start

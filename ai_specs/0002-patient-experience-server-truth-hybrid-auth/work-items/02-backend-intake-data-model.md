---
type: Work Item
title: Backend — Intake Data Model (DOB + surgery_date)
parent: ../spec.md
---

## What to build
Capture the clinician-known facts at intake. `PatientInviteRequest` gains a required `date_of_birth`, stored on the patient `User`. The `Case` model gains a nullable `surgery_date` (existing/seeded cases pre-date it) via an Alembic migration, stored at case creation. The patient-accessible case response exposes `surgery_date` (and the patient's DOB) so the mobile can derive "Day N" and show a real surgery date.

## Required context
- `backend/app/routers/patients.py` — `invite_patient` (creates `User` + `Case`).
- `backend/app/schemas.py` — `PatientInviteRequest` (currently email, full_name, surgery_type, emergency_contact_phone), `PatientInviteResponse`, case response schemas.
- `backend/app/models.py` — `User.date_of_birth` (exists, nullable), `Case` (has `surgery_type`, no `surgery_date` yet), `Case.created_at`.
- Identify the patient-accessible endpoint that returns the case (confirm which route the mobile uses to read its case) and add `surgery_date` to its response.
- Alembic migration conventions under `backend/alembic/`.

## Acceptance criteria
- [x] `PatientInviteRequest` requires `date_of_birth`; inviting a patient without it fails validation.
- [x] `Case` has a nullable `surgery_date` column added by an Alembic migration; existing rows remain valid (null).
- [x] `surgery_date` is stored at case creation when provided.
- [x] The patient-accessible case response includes `surgery_date` (and DOB), enabling client-side Day-N derivation.
- [x] Backend `pytest` covers: `PatientInviteRequest` requiring `date_of_birth`; `Case` storing `surgery_date`; the case response exposing `surgery_date`.

## Covers
- User Stories: 4
- Requirements: 8, 16 (backend)
- Testing Strategy: 1
- Interview Ledger: L2, L7

## Blocked by
None - ready to start

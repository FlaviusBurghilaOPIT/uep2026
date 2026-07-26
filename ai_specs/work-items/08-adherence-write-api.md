---
type: Work Item
title: Adherence write API — ownership, status sync, ad-hoc PRN, correction
parent: ../2026-07-26-adherence-pipeline-backend-spec.md
---

## What to build

Three endpoint changes in `app/routers/adherence.py`:

1. **`POST /adherence/log` (modify in place, keep as the ONLY create path):**
   - Keep the existing contract exactly: 201 DoseLog; 404 unknown reminder; 409 with existing-log detail body (pin with a test).
   - Add ownership check: reminder → medication → case; 403 unless `case.patient_id == current_user.id` (patient) or `case.clinician_id == current_user.id`.
   - In the same transaction, set `scheduled_reminders.status = status.value`.
2. **`POST /adherence/log-adhoc` (new — PRN logging):**
   - Body `{medication_id, status, taken_at?, idempotency_key}` → atomically creates `ScheduledReminder(medication_id, scheduled_time=taken_at ?? now, status=status, idempotency_key)` + `DoseLog`; returns full slot shape (same fields as agenda slots).
   - Idempotency: a retry with a known key returns the original 201 body without creating duplicates.
   - 400 if medication is discontinued or non-PRN; same ownership check.
3. **`PATCH /adherence/logs/{log_id}` (new — correction):**
   - Body `{status}` → transaction: append `dose_log_events(dose_log_id, old_status, new_status, changed_at)`; update `dose_logs.status` + `corrected_at`; sync `scheduled_reminders.status`.
   - Response: updated log including `previous_status`. 403 cross-patient; 404 unknown log; 400 status unchanged.
   - Patient-only v1 (clinician correction out of scope; events table already accommodates it).

## Required context

- Parent spec: `ai_specs/2026-07-26-adherence-pipeline-backend-spec.md` §6 E1 (full contracts), §8 Use Cases 3–7.
- `DoseLog.scheduled_reminder_id` is UNIQUE — corrections go through PATCH, never a second POST.
- Use `get_db_for_user`, not plain `get_db`.
- Idempotency key column + unique index come from WI 06's migration.

## Acceptance criteria

- [ ] 409 contract pinned by test (duplicate → 409 with detail; no duplicate row)
- [ ] Patient B cannot log/correct against patient A's reminder or log (403)
- [ ] Successful log and correction both sync `scheduled_reminders.status` in the same transaction
- [ ] Ad-hoc: creates slot+log atomically; same-key retry returns original 201, no duplicate; 400 on non-PRN or discontinued med
- [ ] Correction: status updated, event appended, `corrected_at` set; two successive corrections produce two ordered events rows
- [ ] Full pytest suite green

## Covers

- Spec: §6 E1; §8 Use Cases 3–7; §9 Test Plan (log/correction/adhoc rows); §13 AC 2

## Blocked by

- `06-adherence-data-model-rls-migration.md` (needs `dose_log_events`, `corrected_at`, `idempotency_key`)

---
type: Work Item
title: Server-driven agenda endpoint (GET /patients/me/agenda)
parent: ../2026-07-26-adherence-pipeline-backend-spec.md
---

## What to build

New endpoint `GET /patients/me/agenda?date=YYYY-MM-DD` in a new `app/routers/agenda.py` (registered in `main.py`):

1. **Identity from JWT** (`get_current_user`); patient role only (403 otherwise). No path parameters — no IDOR surface.
2. Resolution: user → cases where `patient_id = user.id` → active medications (`discontinued_at IS NULL`) → that date's `ScheduledReminder`s LEFT JOINed to their `DoseLog` (0–1 by UNIQUE).
3. **Ensure-on-read:** for each active non-PRN medication missing slots for the requested date, materialize the day's slots idempotently in the read transaction (factor a per-day variant out of `create_scheduled_reminders_for_medication`); check-then-insert on `(medication_id, scheduled_time)`; safe under concurrent requests.
4. **Server-computed slot state** with named module constants `DUE_WINDOW_BEFORE = timedelta(hours=2)`, `DUE_WINDOW_AFTER = timedelta(hours=4)`: log exists → log status; `now < scheduled - 2h` → `upcoming`; within window → `due`; `now > scheduled + 4h` unlogged → `missed`.
5. Slot shape per spec §6 E2: `slot_id`, `medication_id`, `medication_name`, `dose`, `notes`, `scheduled_time` (naive stored values interpreted as UTC, serialized with `Z`), `state`, `logged_at`, `dose_log_id`, `previous_status` (latest `dose_log_events.old_status` for the log, else null).
6. PRN medications in a separate `prn` array (id, name, dose, notes only).

## Required context

- Parent spec: `ai_specs/2026-07-26-adherence-pipeline-backend-spec.md` §6 E2 (full contract + JSON example), §8 Use Cases 1–2, 9.
- Existing generation logic to factor: `app/services/schedule_parser.py` (`create_scheduled_reminders_for_medication`, `times_for_frequency`).
- Use `get_db_for_user` (RLS session variables), not plain `get_db`.
- Do not change `GET /cases/{id}/medications` response shape (clinician web depends on it).

## Acceptance criteria

- [ ] Returns real slots with computed states at frozen `now` (test: upcoming/due/missed/taken/skipped)
- [ ] Ensure-on-read materializes missing slots exactly once; concurrent double-call safe; slot_ids stable across calls
- [ ] PRN meds appear only in `prn`
- [ ] 403 for clinician role; slots only from the JWT user's own cases (two-patient fixture)
- [ ] `previous_status` populated after a correction (integration with WI 08's events)
- [ ] Full pytest suite green

## Covers

- Spec: §6 E2; §8 Use Cases 1, 2, 9; §9 Test Plan (agenda rows); §13 AC 1

## Blocked by

- `06-adherence-data-model-rls-migration.md` (needs `discontinued_at` filter and `dose_log_events` for `previous_status`)

## Blocking decisions

- Due/missed window values (2h before / 4h after) ship as proposed pending ⚕ clinical validation (spec §10-D1) — constants are isolated for later tuning without schema or contract change.

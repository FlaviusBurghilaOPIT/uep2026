---
type: Work Item
title: Adherence data model + RLS migration
parent: ../2026-07-26-adherence-pipeline-backend-spec.md
---

## What to build

One reversible Alembic migration (new head after `26798872475f`) containing:

1. `dose_log_events` table: `id` (uuid pk), `dose_log_id` (FK → dose_logs.id, indexed), `old_status` (Enum DoseStatus), `new_status` (Enum DoseStatus), `changed_at` (DateTime, default utcnow). Append-only by convention (code comment).
2. `dose_logs.corrected_at: DateTime | None`.
3. `medications.discontinued_at: DateTime | None`.
4. `scheduled_reminders.idempotency_key: String | None` + unique index (Postgres nulls don't collide).
5. RLS policies on `scheduled_reminders`, `dose_logs`, `dose_log_events` — mirror the `1cee36bcbdad_enable_rls.py` pattern (ENABLE + FORCE + policy) but with a two-level join: `medication_id → medications.case_id → cases.(clinician_id|patient_id)`; for `dose_logs` join via `scheduled_reminder_id → scheduled_reminders → medications → cases`; same for `dose_log_events` via `dose_log_id`.
6. Downgrade: drop policies, disable RLS on the three tables, drop `dose_log_events`, drop added columns.

Corresponding SQLAlchemy model additions in `app/models.py` (`DoseLogEvent`, new columns) and any pydantic schema fields needed by sibling Work Items.

## Required context

- Parent spec: `ai_specs/2026-07-26-adherence-pipeline-backend-spec.md` §7 (Data Model & Migration) — SQL sketches included there.
- Existing RLS pattern: `backend/alembic/versions/1cee36bcbdad_enable_rls.py` (FORCE is required because the app connects as the owning role; RLS tests must run against real Postgres as the `remotecare_app` role — SQLite is a no-op).
- Run `alembic upgrade head` against the Docker Postgres to verify; `python3 -m pytest tests -q` must stay green (SQLite path unaffected).

## Acceptance criteria

- [ ] `alembic upgrade head` and `alembic downgrade -1` both succeed against Docker Postgres
- [ ] All four schema changes present (events table + 3 columns/index)
- [ ] RLS policies active on all three tables; as `remotecare_app` role, cross-patient SELECT returns zero rows (verified on real Postgres)
- [ ] `app/models.py` reflects the new schema; full pytest suite green

## Covers

- Spec: §7 Data Model & Migration; §9 Test Plan (RLS rows); §13 AC 3 (RLS half), AC 6

## Blocked by

None - ready to start

## Blocking decisions

- RLS policy tests require the Postgres-backed path; confirm the repo's convention for running them (they cannot be verified on SQLite) before merge.

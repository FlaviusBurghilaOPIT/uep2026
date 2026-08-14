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

- [x] `alembic upgrade head` and `alembic downgrade -1` both succeed against Docker Postgres
- [x] All four schema changes present (events table + 3 columns/index)
- [x] RLS policies active on all three tables; as `remotecare_app` role, cross-patient SELECT returns zero rows (verified on real Postgres)
- [x] `app/models.py` reflects the new schema; full pytest suite green

## Implementation notes (2026-07-26)

- Migration: `backend/alembic/versions/d6a7b8c9e0f1_adherence_data_model_rls.py`, revision `d6a7b8c9e0f1`, down_revision `b2c3d4e5f6a7` (the actual head at implementation time — `26798872475f` was already followed by `f4a9c7d21b3e` → `a1b2c3d4e5f6` → `b2c3d4e5f6a7`).
- Blocking decision resolved: the repo convention for Postgres-backed RLS tests already exists — skipif-gated pytest modules (`tests/test_rls_policies.py`). Followed it with `backend/tests/test_rls_adherence_policies.py` (4 tests, all passed against real Postgres: cross-patient SELECT returns zero rows on all three tables as `remotecare_app`; own rows visible; case clinician sees both patients' rows; new columns present).
- Postgres verification ran against a throwaway `pgvector:pg16` container on port 55432 because the shared `uep2026_pgdata` volume was initialized with credentials that no longer match docker-compose's documented `caredev` role (FATAL: role "caredev" does not exist). The stale volume was left untouched — recreating it needs owner confirmation.
- Pydantic schemas added per spec §6: `SlotState`, `AgendaSlot`, `AgendaPrnMedication`, `AgendaResponse`, `AdhocLogRequest`/`AdhocLogResponse`, `DoseLogCorrectRequest`/`DoseLogCorrectResponse`. `discontinued_at` was deliberately NOT added to `MedicationResponse` — spec §5 freezes the `GET /cases/{id}/medications` shape.
- `remotecare_app` DML grants on `dose_log_events` come from the `ALTER DEFAULT PRIVILEGES` in `1ba1b1353734` (verified in psql), so no explicit GRANT in the new migration.

## Covers

- Spec: §7 Data Model & Migration; §9 Test Plan (RLS rows); §13 AC 3 (RLS half), AC 6

## Blocked by

None - ready to start

## Blocking decisions

- RLS policy tests require the Postgres-backed path; confirm the repo's convention for running them (they cannot be verified on SQLite) before merge.

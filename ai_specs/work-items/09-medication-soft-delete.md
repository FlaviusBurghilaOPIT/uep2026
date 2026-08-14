---
type: Work Item
title: Medication soft-delete (discontinue instead of cascade erase)
parent: ../2026-07-26-adherence-pipeline-backend-spec.md
---

## What to build

Replace hard deletion of medications with discontinuation:

1. `DELETE /medications/{id}` (clinician-owner only) → sets `medications.discontinued_at = now`; no row deletion, no cascade. Returns `{"message": "Medication discontinued"}`.
2. Read-path filters (`discontinued_at IS NULL`):
   - `GET /cases/{id}/medications` — hidden by default; add `?include_discontinued=true` for the clinician history view.
   - Agenda endpoint (WI 07) — discontinued meds excluded from slots and PRN.
   - Mobile medications list path (same case-medications endpoint).
3. Adherence history preserved: `GET /adherence/patients/{patient_id}` continues to return logs of discontinued meds; past logged slots remain readable.
4. Future slots of a discontinued med (`scheduled_time > discontinued_at`, no log) are excluded from agenda; past slots remain as history.

## Required context

- Parent spec: `ai_specs/2026-07-26-adherence-pipeline-backend-spec.md` §6 E4, §8 Use Cases 8, 10.
- Current cascade: `Medication.scheduled_reminders` relationship has `cascade="all, delete-orphan"` (models.py:142-144) — after this change the cascade becomes unreachable via the API; leave the relationship untouched (defense in depth is not needed once deletes stop, and removing it is a separate risk).
- `discontinued_at` column comes from WI 06's migration.
- Docs C6 (git HEAD `docs/product/03-safety-and-edge-cases.md`) requires this behavior + a quiet patient-facing banner (banner itself is mobile work, not this WI).

## Acceptance criteria

- [x] DELETE no longer removes rows; discontinued med hidden from default case-medications and agenda
- [x] `?include_discontinued=true` returns it for clinicians
- [x] Its past dose logs remain queryable via `GET /adherence/patients/{patient_id}`
- [x] Future unlogged slots disappear from agenda; past logged slots remain
- [x] `GET /cases/{id}/medications` response shape otherwise unchanged (web regression test)
- [x] Full pytest suite green

## Covers

- Spec: §6 E4; §8 Use Cases 8, 10; §9 Test Plan (soft-delete row); §13 AC 4, AC 5

## Blocked by

- `06-adherence-data-model-rls-migration.md` (needs `discontinued_at`)

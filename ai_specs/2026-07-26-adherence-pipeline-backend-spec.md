---
type: Spec
title: Adherence Pipeline Backend — Server-Driven Agenda, Correctable Dose Logs, Reminders Lockdown (E1·E2·E3·E4)
status: Ready for Engineering
created: 2026-07-26
sources:
  - Intent /blueprint: Adherence pipeline (2026-07-25, conversation) — contracts E1/E2/E3, decisions log
  - Intent /fortify: Today screen & adherence pipeline (2026-07-25, conversation) — UX states these contracts serve
  - backend/app/routers/adherence.py, reminders.py, cases.py; app/services/schedule_parser.py; app/models.py
  - backend/alembic/versions/1cee36bcbdad_enable_rls.py (RLS pattern to mirror)
  - docs/product/03-safety-and-edge-cases.md C5/C6/C7 via git HEAD
related:
  - ai_specs/2026-07-25-patient-first-run-flow-spec.md (depends on this spec's honesty guarantees)
---

## 1. Ownership & Context

- **Owner:** Flavius (engineering)
- **Status:** Ready for Engineering — pending one ⚕ clinical decision (due/missed window values, §11-D1) which blocks only the constants, not the build
- **Scope:** `backend/` only. Mobile and web consume these contracts but their changes are separate specs (Today-screen hardening spec follows this one).

**Traceability:** resolves audit findings C2 (fabricated/discarded dose data — root cause: two sources of truth for dose times) and C3 (write-once, double-posted, uncorrectable adherence logging), plus the privacy gap discovered in blueprinting: `scheduled_reminders` and `dose_logs` have **no RLS policies and no query-level scoping** (`GET /reminders` runs `.all()` for any authenticated user).

## 2. Problem & User Need

A patient's adherence record is the product's core value proposition — clinicians triage from it. Today: (a) the mobile app invents dose times client-side and creates duplicate reminders through an unscoped endpoint because no server-driven agenda exists; (b) `DoseLog` is write-once (UNIQUE per reminder), so the docs-required correction flow (C7) is impossible; (c) reminder/dose tables are readable by any authenticated user; (d) deleting a medication cascade-deletes its reminders and dose logs, erasing adherence history (violates docs C6).

**Success metric:** the mobile Today screen can render 100% server-truth dose slots (real times, real statuses) with zero client-side schedule parsing, and every patient log is correctable with an audit trail.

## 3. Design Approach

Single source of truth moves to the server. The client becomes dumb: it fetches slots, emits log intents, and reconciles to server responses.

**What we did NOT do, and why (from blueprint decisions log):**

| Rejected | Reason |
|---|---|
| Client-side schedule parsing (status quo) | Two sources of truth — the C2 root cause |
| Nightly missed-sweep job | `state` computed at read is always correct; no scheduler needed v1 |
| Full event-sourcing of adherence | Mutable `dose_logs` + append-only `dose_log_events` = 95% of value, 20% of complexity |
| Backfill migration for legacy slot gaps | Ensure-on-read is self-limiting and idempotent |
| Rewriting naive `scheduled_time` rows | Risks rewriting history under existing logs; interpret-as-UTC rule instead |
| Keep + scope `GET /reminders` | Dead endpoints are attack surface; delete after mobile migrates |
| Hard delete of medications (status quo) | Cascade `delete-orphan` erases adherence history — violates C6 |

## 4. Ethical Review

- **Privacy architecture (the motivating fix):** unscoped `.all()` reads made every patient's dose schedule and adherence history readable by any authenticated user. This spec closes it in two independent layers (query scoping + RLS) so a single-layer failure doesn't re-open it. Defense in depth is the intent.
- **Correction ≠ falsification:** corrections preserve both values (`dose_log_events` is append-only). The patient can fix a mistap; neither patient nor clinician can silently rewrite history. Design intent: honest records serve both parties.
- **Missed-dose marking** is computed and factual; no shame mechanics exist server-side. ⚠ Soft-delete (E4) *preserves* patient history rather than the current behavior of silently erasing it.
- **No dark patterns introduced.** Clearance: no deceptive, coercive, or manipulative structures; this spec removes one structure that enabled invisible harm (unscoped reads).

## 5. Measurement

No new telemetry server-side (mobile events already specced in the first-run spec). Constraints instead:

- `GET /cases/{id}/medications` response shape **must not change** (clinician web depends on it).
- Correction events in `dose_log_events` become the future data source for the measurement plan's adherence-quality metrics — record with that in mind (no free-text fields; enums + timestamps only).
- **Learning plan:** after mobile ships against E2, watch `409`-reconcile rate and correction rate at week 1/month 1 — high correction rates indicate slot-time defaults are wrong for real patients (feeds §11-D2).

## 6. API Specification

### E2 · `GET /patients/me/agenda` (new)

```
GET /patients/me/agenda?date=YYYY-MM-DD        → 200 AgendaResponse
                                                 401 unauthenticated · 403 non-patient role
```

- **Identity from JWT** (`get_current_user`); no path parameter — no IDOR surface. Patient role only.
- Resolution: user → cases where `patient_id = user.id` → active (non-discontinued) medications → that date's `ScheduledReminder`s, each LEFT JOINed to its `DoseLog` (0–1 by UNIQUE).
- **Ensure-on-read:** for each active medication with a non-PRN frequency, if no slot exists for the requested date (legacy rows, prescribe-time failure), materialize the day's slots idempotently in the read transaction (reuse `create_scheduled_reminders_for_medication` logic factored into a per-day variant). Natural-key guard: check-then-insert on `(medication_id, scheduled_time)`; safe under concurrent requests.
- **PRN medications** (no slots): returned in a separate `prn` array, display fields only.

**Response:**

```json
{
  "date": "2026-07-26",
  "slots": [
    {
      "slot_id": "rem-…",
      "medication_id": "med-…",
      "medication_name": "Ibuprofen",
      "dose": "400 mg",
      "notes": "with food",
      "scheduled_time": "2026-07-26T08:00:00Z",
      "state": "upcoming | due | overdue | missed | taken | skipped",
      "logged_at": null,
      "dose_log_id": null,
      "previous_status": null
    }
  ],
  "prn": [
    { "medication_id": "med-…", "medication_name": "Tramadol", "dose": "50 mg", "notes": null }
  ]
}
```

**State computation (server-side, named constants):**

```
DUE_WINDOW_BEFORE = 2h      # ⚕ clinical validation pending — see §11-D1
DUE_WINDOW_AFTER  = 4h      # ⚕ clinical validation pending

log exists        → state = log.status.value           (taken | skipped | missed)
now < scheduled - 2h        → upcoming
scheduled - 2h ≤ now ≤ scheduled + 4h  → due
now > scheduled + 4h        → missed      (unlogged past window; factual, never shaming)
```

`previous_status` on a slot: `old_status` of the most recent `dose_log_events` row for that log, else null. **Timezone serialization:** stored naive datetimes are interpreted as UTC and serialized with `Z` (documented rule; legacy rows may render shifted — accepted artifact, no data rewrite).

### E1 · Adherence writes

**`POST /adherence/log` (exists — modify in place, keep as the ONLY create path)**

- Unchanged contract: `?scheduled_reminder_id=&status=` → 201 DoseLog; 404 unknown reminder; **409 with existing-log detail** (already implemented — keep exactly; mobile reconciles from it).
- **New:** in the same transaction, set `scheduled_reminders.status = status.value` (keeps the legacy column in sync for the web clinician view; column is deprecated long-term).
- **New:** ownership check — reminder → medication → case; 403 unless `case.patient_id == current_user.id` (patient) or `case.clinician_id == current_user.id`.

**`POST /adherence/log-adhoc` (new — PRN logging)**

```
POST /adherence/log-adhoc
{ "medication_id": "med-…", "status": "taken", "taken_at": null, "idempotency_key": "uuid" }
→ 201 { slot + dose_log }
```

- Atomically creates `ScheduledReminder(medication_id, scheduled_time=taken_at ?? now, status=status)` + `DoseLog`. Returns the full slot shape (same as E2 slots).
- `idempotency_key` (client UUID per user action): unique-indexed; a retry with a known key returns the original 201 body, not a duplicate. Required so offline-queue retries can't double-create.
- Ownership check as above; 400 if medication is discontinued or not PRN (PRN-only endpoint v1).

**`PATCH /adherence/logs/{log_id}` (new — correction)**

```
PATCH /adherence/logs/{log_id}     { "status": "skipped" }
→ 200 { id, scheduled_reminder_id, status, previous_status, logged_at, corrected_at }
→ 403 not your log · 404 unknown log · 400 status unchanged
```

- Transaction: append `dose_log_events(dose_log_id, old_status, new_status, changed_at)`; update `dose_logs.status`; sync `scheduled_reminders.status`.
- Patient may correct only own logs (ownership chain as above). Clinician correction: **out of scope v1** (events table already accommodates it).

### E3 · Reminders lockdown

| Endpoint | Action |
|---|---|
| `GET /reminders` | **Delete** (only the mobile app calls it; mobile moves to E2 in the companion spec) |
| `POST /reminders` | **Delete** (prescribe flow uses the internal parser function, not this endpoint) |
| `PATCH /reminders/{id}` | **Delete** (status is now write-synced from adherence writes) |

Precondition: verify with a final grep that no web code calls these three. If the web app does call one, scope it clinician-only instead of deleting and record the deviation.

### E4 · Medication soft-delete

- Model: `medications.discontinued_at: DateTime | None` (new column).
- `DELETE /medications/{id}` → sets `discontinued_at = now` (clinician-owner only); no row deletion, no cascade. Returns `{"message": "Medication discontinued"}`.
- Read paths filter `discontinued_at IS NULL`: E2 agenda, `GET /cases/{id}/medications` (default; add `?include_discontinued=true` for clinician history view), mobile medications list.
- **Adherence history is preserved:** dose logs and past slots of a discontinued med remain queryable via `GET /adherence/patients/{patient_id}`.
- Future slots of a discontinued med (scheduled_time > discontinued_at, no log) are excluded from agenda; past slots remain as history.

## 7. Data Model & Migration

One Alembic migration (new head after `26798872475f`):

1. **`dose_log_events`**: `id` (uuid pk), `dose_log_id` (FK → dose_logs.id, indexed), `old_status` (Enum DoseStatus), `new_status` (Enum DoseStatus), `changed_at` (DateTime, default utcnow). Append-only by convention — no UPDATE/DELETE grants needed beyond app role's existing DML; note in code comment.
2. **`dose_logs`**: add `corrected_at: DateTime | None`.
3. **`medications`**: add `discontinued_at: DateTime | None`.
4. **`adhoc idempotency`**: `scheduled_reminders.idempotency_key: String | None` + unique index (only set for ad-hoc rows; nulls don't collide in Postgres).
5. **RLS** (mirror `1cee36bcbdad` pattern, two-level join):

```sql
ALTER TABLE scheduled_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_reminders FORCE ROW LEVEL SECURITY;
CREATE POLICY scheduled_reminders_case_access ON scheduled_reminders
USING (
  current_setting('app.current_role', true) = 'admin'
  OR medication_id IN (
    SELECT m.id FROM medications m JOIN cases c ON m.case_id = c.id
    WHERE c.clinician_id = current_setting('app.current_user_id', true)
       OR c.patient_id  = current_setting('app.current_user_id', true)
  )
);
-- same pattern for dose_logs (join via scheduled_reminder_id → scheduled_reminders → medications → cases)
-- same pattern for dose_log_events (join via dose_log_id → …)
```

Downgrade: drop policies, disable RLS on the three tables, drop `dose_log_events`, drop added columns.

## 8. Use Cases

| # | Scenario | Expected |
|---|---|---|
| 1 | Patient opens Today, all slots exist | 200 with real times/statuses; zero writes |
| 2 | Patient opens Today, legacy med missing today's slots | Slots materialized idempotently; second call returns same slot_ids |
| 3 | Double-tap / queue retry of first log | Second `POST /log` → 409 with existing detail; no duplicate row |
| 4 | Patient corrects taken→skipped after 3h | PATCH 200; events row appended; `previous_status=taken` on subsequent agenda reads |
| 5 | Correction race from two devices | Last-write-wins on `dose_logs`; both transitions present in `dose_log_events` |
| 6 | PRN pain med logged ad hoc, queue retries with same key | One slot+log created; retry returns original 201 |
| 7 | Patient A requests patient B's reminder/log (guessed UUID) | 403 (query scoping) — and zero rows under RLS role |
| 8 | Clinician discontinues a med mid-course | History preserved; future unlogged slots vanish from agenda; past logged slots still readable |
| 9 | Non-patient (clinician) calls `/patients/me/agenda` | 403 |
| 10 | Clinician web loads case medications | Response shape unchanged; discontinued meds hidden unless `include_discontinued=true` |

## 9. Test Plan (pytest — in-memory SQLite; RLS cases flagged)

| Test | Asserts |
|---|---|
| agenda happy path | slots with real times, correct states at frozen `now` (freeze time: upcoming/due/missed/taken/skipped) |
| agenda ensure-on-read | missing slot materialized once; concurrent double-call safe; PRN meds in `prn` only |
| agenda identity | 403 for clinician role; slots only from JWT user's cases (two-patient fixture) |
| log 409 contract | duplicate → 409 with detail body (existing behavior pinned) |
| log ownership | patient B cannot log against patient A's reminder (403) |
| reminder status sync | successful log sets `reminder.status` in same transaction |
| correction | PATCH updates status, appends event, sets `corrected_at`; 400 on no-op; 403 cross-patient; 404 unknown |
| correction audit chain | two successive corrections → two events rows in order |
| adhoc | creates slot+log atomically; idempotency-key retry returns original, no duplicate; 400 on non-PRN med |
| soft-delete | discontinued med excluded from agenda + case meds default; history endpoints still return its logs; `include_discontinued=true` shows it |
| E3 deletions | routes gone (404/405); grep guard: no app code imports them |
| **RLS (Postgres path only)** | new policies present; cross-patient SELECT on all three tables returns zero rows as `remotecare_app` role — SQLite is a no-op for RLS, so these run in the Postgres-backed test path per repo convention |
| regression | `python3 -m pytest tests -q` fully green; web-facing response shapes byte-identical for covered endpoints |

## 10. Pending Questions

### Design / clinical

- **D1 — Due/missed window values** (2h before / 4h after proposed). ⚕ Needs clinical validation — these define what "late" means to patient and triage. Constants are isolated; the build proceeds with proposed values behind the named constants.
- **D2 — Default slot times** (QD 08:00, BID 08/20, TID 08/13/20, QID 08/12/16/20): clinically sensible defaults — confirm; per-med custom times are a compatible future extension (contract is slot-based).

### Engineering

- **E1 — RLS Postgres test path:** confirm CI/local convention for running policy tests against real Postgres (SQLite can't enforce RLS).
- **E2 — `/reminders` deletion precheck:** final grep of `web/` for fetch calls to the three endpoints before deleting (fallback: scope clinician-only).
- **E3 — naive→timestamptz:** deferred deliberately; revisit if a second consumer of `scheduled_time` appears.

## 11. Acceptance Criteria

1. `GET /patients/me/agenda` returns real server-truth slots with computed states; a client can render Today with zero schedule parsing.
2. First-log create is idempotent via 409; ad-hoc PRN logging is idempotent via key; corrections are audited append-only.
3. Cross-patient access to reminders/logs is denied in query logic **and** (on Postgres) by RLS.
4. Medication deletion no longer destroys adherence history.
5. `GET /cases/{id}/medications` shape unchanged (minus discontinued-by-default); full pytest suite green.
6. One Alembic migration, reversible, following the existing RLS migration pattern.

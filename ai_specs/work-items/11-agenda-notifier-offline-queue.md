---
type: Work Item
title: Agenda notifier + offline queue (Today data layer)
parent: ../2026-07-26-today-screen-hardening-spec.md
---

## What to build

Rewrite `TodayAgendaNotifier` as the single owner of all Today-screen reads and writes (spec §6), behind the existing `ApiService` seam:

1. **Read:** `loadAgenda()` → `GET /patients/me/agenda?date=<today local>`. Cache last-good response (in-memory + persisted JSON for cold start). Expose `slots`, `prn`, `sourceState: loading|fresh|stale|error|empty`, `lastSyncedAt` with the spec's state mapping (fresh / stale = fetch failed + cache / error = fetch failed no cache / empty = OK with zero slots and zero PRN). Pull-to-refresh retriggers; 60s background poll while visible **only when `empty`**.
2. **Write — single path, per-slot lock:** `logDose(slot, status)` exactly per spec §6 flow: write-in-flight guard (haptic-only second tap), optimistic apply, 5s ARB-localized Undo snackbar (undo cancels the write), `POST /adherence/log` → 201 commit / 409 reconcile to server detail / network failure → enqueue offline entry (`idempotency_key=uuid4()`, `kind=create`) + `syncPending` flag / final failure after retry → rollback + error snackbar.
3. **Correction:** `correctLog(slot, newStatus)` → `PATCH /adherence/logs/{dose_log_id}`; offline → queued as `kind=correct`; flush order: creates before corrections.
4. **PRN:** `logPrn(medication, status)` → `POST /adherence/log-adhoc`; one `idempotency_key` per user action, reused across retries.
5. **Offline queue (C4):** persisted across app kill; boot flush + connectivity-restore flush, in order; per-entry 409 → reconcile, not error; `sync_flushed` event on completion.
6. Extend `FakeApiService` with agenda / log-adhoc / PATCH fakes so every behavior above is unit-testable with no backend. Implement against the contract in `ai_specs/2026-07-26-adherence-pipeline-backend-spec.md` §6 E1/E2 — the backend endpoints land in parallel (WIs 07/08); no HTTP client changes should be needed beyond adding the three calls to `ApiService`/`HttpApiService`.

## Required context

- Parent spec: `ai_specs/2026-07-26-today-screen-hardening-spec.md` §6 (full data-layer flow), §5 (measurement events to fire), §10 use cases 1–6, 12.
- Backend contract: `ai_specs/2026-07-26-adherence-pipeline-backend-spec.md` §6 E1/E2 (slot shape, states, 409 detail body, idempotency).
- `ApiService` (`lib/core/network/api_service.dart`) is abstract with `HttpApiService` + `FakeApiService`; unit/widget tests inject the fake — no backend needed.
- Persistence: follow existing project convention for simple persisted JSON (check what auth/onboarding already uses) — do not add a new storage dependency without need.
- Supersedes overlapping pre-audit slices: `ai_specs/0001-mobile-core-loop-hardening-polish/work-items/03-undo-toast-dose-logging.md`, `05-offline-sync-banner.md`.

## Acceptance criteria

- [ ] All spec §11 unit tests pass against `FakeApiService`: optimistic apply; per-slot write lock; 409 reconcile; rollback on final failure; undo cancels write; correction path; queue ordering (creates→corrections); ad-hoc idempotency-key reuse; boot flush; empty/stale/error source-state mapping
- [ ] Offline queue survives an app kill (persisted; covered by a test that simulates restart with a fresh notifier against the same store)
- [ ] No screen code performs adherence writes — notifier is the only writer (grep-verifiable)
- [ ] Measurement events from spec §5 fire at the listed points (no PHI)
- [ ] `flutter analyze` clean, `flutter test` green

## Covers

- Spec: §6 Data Layer; §5 Measurement; §10 Use Cases 1–6, 12; §11 Test Plan (unit rows); §13 AC 2 (mobile half)

## Blocked by

None — implements against the FakeApiService seam. Final integration verification against the live backend is gated on backend WIs 07/08 (tracked in WI 15).

## Blocking decisions

None. Backend endpoints may not exist yet; all tests run against the fake seam per the parent spec's test strategy.

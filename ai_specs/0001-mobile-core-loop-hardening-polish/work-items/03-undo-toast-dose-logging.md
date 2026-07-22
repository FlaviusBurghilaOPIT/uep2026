---
type: Work Item
title: 5-Second Undo Toast for Dose Logging
parent: ../spec.md
---

## What to build

Show a 5-second undo snackbar ("Logged as Taken. Undo") whenever a patient taps a dose status button, so an accidental tap — particularly from patients with motor tremors — can be corrected before it reaches the clinician dashboard. Tapping Undo within the window reverts the card to pending, both locally and via the API (or the log is simply not committed until the window elapses — pick one implementation approach and document which in the PR description).

## Required context

- `docs/product/10-implementation-plan.md` Issue #7.
- `mobile/lib/features/today/today_screen.dart`, `mobile/lib/features/today/providers/today_agenda_notifier.dart` (+ `.freezed.dart`) — current immediate-commit dose-logging flow.
- `docs/product/03-safety-and-edge-cases.md` Case 7 (Patient Logs a Dose Accidentally).
- `docs/ux/06-content-system.md` Category 6 for the exact toast copy.
- `docs/product/09-measurement-plan.md` §2.4 — `Accidental Log Undo Frequency` safety counter-metric depends on the `mobile.today.dose_log_undone` event this Work Item introduces.

## Acceptance criteria

- [ ] Tapping any status button (`Taken`/`Skipped`/`Missed`) shows a 5-second snackbar with the exact copy from `docs/ux/06-content-system.md` Category 6 and an `Undo` action.
- [ ] Tapping `Undo` within the 5-second window reverts the card to `pending` locally and reconciles with the API (no orphaned log record left behind).
- [ ] Letting the toast expire without tapping `Undo` commits the log as normal.
- [ ] `mobile.today.dose_log_undone` telemetry event fires on undo, per `docs/product/09-measurement-plan.md` §3.1 event schema conventions (hashed IDs only, no PHI/PII).
- [ ] New test case in `mobile/test/unit/today_agenda_test.dart` covering: log → undo-within-window → state reverts to pending; log → wait-past-window → state commits.

## Covers

- User Stories: 2
- Requirements: Dose Logging UX 6
- Interview Ledger: L3

## Blocked by

2 — lands after status-pill icon work so both dose-card changes don't land as competing in-flight edits to the same file.

---
type: Work Item
title: Notification scheduling from server slot times
parent: ../2026-07-26-today-screen-hardening-spec.md
---

## What to build

Rebuild local notification scheduling on server truth (spec §6 "Notifications"):

1. **Delete** the `'3x'/'2x'` `schedule_text` parsing scheduler (`today_agenda_notifier.dart:288-308`) and any associated parsing helpers — this was a C2 root cause.
2. Schedule local notifications **from E2 slot times** (UTC serialized `scheduled_time` → device-local), one per upcoming slot for the current agenda; reschedule on every successful agenda load.
3. **Re-anchor (C5):** recompute on every app start and on OS timezone-change event; if rendered times shifted, set the state that surfaces the `todayTimezoneAdjusted` banner once (banner UI is WI 13's region).
4. **Permissions:** never requested here — the first-run primer owns asking. If permission is denied → C1 banner state only (no re-prompt, no nag).
5. Keep the notification plugin behind an injectable seam so scheduling/re-anchoring is unit-testable without platform channels.

## Required context

- Parent spec: `ai_specs/2026-07-26-today-screen-hardening-spec.md` §6 Notifications, §10 use case 9, §9 deletions row 4.
- First-run spec `ai_specs/2026-07-25-patient-first-run-flow-spec.md` owns the permission primer + C1 banner strings — reuse, do not duplicate.
- Supersedes pre-audit slice: `ai_specs/0001-mobile-core-loop-hardening-polish/work-items/04-interactive-notifications-timezone-reliability.md`.
- Notification taps: existing behavior (deep link to Today) is preserved; interactive notification actions are out of scope for this WI.

## Acceptance criteria

- [x] No `schedule_text`/frequency-string parsing remains in notification code (grep-verifiable)
- [x] Scheduled notifications match E2 slot times converted UTC→device-local (unit test with fixed clock/timezone)
- [x] Re-anchor on app start and on timezone-change event; banner state set once per shift
- [x] No permission request originates from Today/notification scheduling code; denied → C1 banner state
- [x] Unit tests green via the notification seam; `flutter analyze` clean

## Implementation notes (2026-07-27)

- **The `'3x'/'2x'` `schedule_text` parsing scheduler was already gone** before this WI started — it lived in the pre-WI-11 `today_agenda_notifier.dart` (lines 288-308 per the spec's own citation) and was removed wholesale when WI 11 rewrote that file from scratch. Verified via grep: no `schedule_text`/`'3x'`/`'2x'` string remains anywhere under `lib/core/notifications/` or `lib/features/today/` (the only surviving `schedule_text` references are in the unrelated `medications_notifier.dart`, a different screen, out of scope).
- Built the actual server-truth scheduler from scratch (it didn't exist yet): `core/notifications/notification_scheduler.dart` defines the `NotificationScheduler` seam (`scheduleOne`/`cancelAll`/`permissionsGranted`) over the existing `NotificationService` singleton, with every method wrapped in try/catch so a platform-channel failure (e.g. plugin uninitialized in a widget-test host) never propagates — `RealNotificationScheduler` is safe to leave un-overridden in widget tests.
- `NotificationService` gained `arePermissionsGranted()` — checks (Android `areNotificationsEnabled()` / iOS `checkPermissions().isEnabled`) without ever prompting; `requestPermissions()` (the first-run primer's method) is untouched and not called from any Today/notification-scheduling code path.
- `features/today/providers/notification_scheduling_controller.dart` (`NotificationSchedulingController`) is the actual spec-§6 logic, fully unit-testable via `FakeNotificationScheduler` (no platform channels):
  - `scheduleForSlots(slots)`: cancels the previous batch, then schedules one notification per slot in `{upcoming, due}` state (converts `scheduledTime.toLocal()`) — overdue/missed/taken/skipped slots are intentionally not (re)scheduled (an overdue slot is already visible; scheduling "now" would just be noise).
  - `reanchor()`: compares the device's current UTC offset (injectable `currentOffsetMinutes` seam, defaults to `DateTime.now().timeZoneOffset.inMinutes`) against the last-recorded value in `SharedPreferences`; returns `true` only on an actual shift, `false` on the first call (baseline) and on repeat calls at an already-recorded offset — satisfies "banner state set once per shift".
  - `permissionsGranted()` delegates straight through; never requests.
- **Deviation — re-anchor trigger is `didChangeAppLifecycleState` → `resumed`, not a true OS timezone-change broadcast.** Flutter/Dart has no cross-platform "timezone changed" signal reachable without new native platform-channel code (iOS `NSSystemTimeZoneDidChangeNotification` / Android `ACTION_TIMEZONE_CHANGED` are not proxied by any dependency already in this project). App-resume is the pragmatic, commonly-used substitute: any timezone shift a patient experiences (flight landing, manually changing the device clock) coincides with the app returning to the foreground. Recorded as a known gap — a real fix would add native channel plumbing, out of scope here.
- `TodayScreen` (WI 13) is the integration point: `initState` calls `_reanchorNotifications()` (re-anchor + permission check → `setTimezoneAdjusted`/`setRemindersOff` on the WI 13 notifier), `didChangeAppLifecycleState(resumed)` repeats it, and a `ref.listen` on the agenda provider calls `_rescheduleFor(slots)` whenever the source state transitions to `fresh` with different slots — "reschedule on every successful agenda load".
- Test coverage: `test/unit/notification_scheduling_controller_test.dart` (7 tests) — UTC→local conversion fidelity, remindable-state filtering, cancel-before-reschedule, reanchor baseline/no-shift/shift-once-per-change, permission delegation. `test/unit/fake_notification_scheduler.dart` is the test seam.

## Covers

- Spec: §6 Notifications; §9 deletion row 4; §10 Use Case 9; §13 AC 5

## Blocked by

- `11-agenda-notifier-offline-queue.md` (agenda data + notifier lifecycle)

## Blocking decisions

None.

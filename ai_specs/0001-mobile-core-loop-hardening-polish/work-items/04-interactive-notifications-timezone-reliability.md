---
type: Work Item
title: Interactive Lock-Screen Notification Actions & Timezone Reliability (completes WI-04)
parent: ../spec.md
---

## What to build

Complete the previously-scoped, unbuilt interactive-notifications work (`ai_specs/work-items/04-interactive-notifications-dose-logging.md`, 0/9 AC, now superseded by this Work Item): add `[Take Dose]` and `[Snooze 15m]` interactive action buttons directly on iOS/Android lock-screen notifications, wire notification-body taps to open the app and highlight the target medication card, and — folding in the previously separate FIND-M06 finding — make `NotificationService` re-anchor scheduled reminders on app launch and on OS timezone-change events so DST shifts and travel don't cause reminders to fire at the wrong wall-clock time.

## Required context

- `docs/product/10-implementation-plan.md` Issue #9.
- `ai_specs/work-items/04-interactive-notifications-dose-logging.md` — now marked superseded; its "What to build" and platform-channel notes still apply as background, but its checkboxes are completed here, not there.
- `mobile/lib/core/notifications/notification_service.dart` — currently schedules once at login with no interactive actions and no timezone re-anchoring.
- `mobile/lib/features/today/providers/today_agenda_notifier.dart` — background-logging integration point.
- Platform channel config for interactive notification categories: `mobile/ios/Runner/`, `mobile/android/app/src/main/`.
- Backend `POST /adherence/log` — background-logged duplicate attempts should resolve via the 409-conflict path once GitHub Issue #1 (`docs/product/10-implementation-plan.md`) lands; this Work Item does not implement backend conflict handling itself, only relies on it being available for a clean background-log experience.

## Acceptance criteria

- [ ] `NotificationService.instance.reinitialize()` (or equivalent) runs on app launch and on OS timezone-change events, re-scheduling all pending reminders to correct local wall-clock times.
- [ ] `[Take Dose]` action logs `taken` via `POST /adherence/log` in the background (including when the app is terminated), with haptic feedback, using a top-level `@pragma('vm:entry-point')` background handler.
- [ ] `[Snooze 15m]` action reschedules the reminder 15 minutes later.
- [ ] Tapping the notification body (not an action button) opens the app, navigates to `Today`, and highlights the target medication card.
- [ ] Notification permission is requested during onboarding if not already covered by prior work — confirm and note the finding either way in the PR.
- [ ] A duplicate background-log attempt does not surface a user-visible error (verify manually against the 409 path once Issue #1 is merged; if it hasn't merged yet, note the temporary gap explicitly in the PR rather than silently skipping the check).
- [ ] `mobile.today.dose_logged` telemetry event fires with `is_offline` correctly reflecting background-originated logs.
- [ ] `mobile/test/unit/notification_service_test.dart` extended with reschedule-on-launch and timezone-change test cases.

## Covers

- User Stories: 4
- Requirements: Interactive Notifications & Reliability 9-12
- Interview Ledger: L1, L3

## Blocked by

3 — lands after the undo-toast Work Item since both touch `today_agenda_notifier.dart`'s dose-logging state shape.

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

- [ ] No `schedule_text`/frequency-string parsing remains in notification code (grep-verifiable)
- [ ] Scheduled notifications match E2 slot times converted UTC→device-local (unit test with fixed clock/timezone)
- [ ] Re-anchor on app start and on timezone-change event; banner state set once per shift
- [ ] No permission request originates from Today/notification scheduling code; denied → C1 banner state
- [ ] Unit tests green via the notification seam; `flutter analyze` clean

## Covers

- Spec: §6 Notifications; §9 deletion row 4; §10 Use Case 9; §13 AC 5

## Blocked by

- `11-agenda-notifier-offline-queue.md` (agenda data + notifier lifecycle)

## Blocking decisions

None.

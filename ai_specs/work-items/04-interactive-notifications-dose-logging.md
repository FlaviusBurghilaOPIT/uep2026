---
type: Work Item
title: Interactive Medication Notifications — flutter_local_notifications, Background Dose Logging & Today Screen Deep-Link
parent: ../2026-07-22-flutter-mobile-enhancements-spec.md
---

## What to build

Implement interactive local medication reminders using `flutter_local_notifications`. Schedule reminders from the patient's prescribed regimen. Provide `[Take Dose]` and `[Snooze 15m]` interactive lock-screen action buttons. Log dose adherence to the Python backend in the background (including when the app is terminated). Wire notification tap to open `TodayScreen` and highlight the target medication card with a celebratory checkmark toast.

### `pubspec.yaml` additions

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.4
```

### `lib/core/notifications/notification_service.dart`

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// Top-level background handler — required for terminated app dose logging
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  // Parse payload: '{reminderId}:{medicationId}:{actionId}'
  if (details.actionId == 'take_dose') {
    final reminderId = _parseReminderId(details.payload ?? '');
    if (reminderId != null) {
      final api = ApiService();
      await api.post('/adherence/log', {
        'reminder_id': reminderId,
        'status': 'taken',
      });
      await HapticFeedback.mediumImpact();
    }
  }
  if (details.actionId == 'snooze') {
    final reminderId = _parseReminderId(details.payload ?? '');
    // Schedule new notification 15 minutes from now
    await NotificationService.instance.snoozeReminder(reminderId!, 15);
  }
}

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async { ... }
  Future<void> requestPermissions() async { ... }
  Future<void> scheduleMedicationReminder({
    required String reminderId,
    required String medicationId,
    required String medicationName,
    required String doseAmount,
    required DateTime scheduledTime,
  }) async { ... }
  Future<void> snoozeReminder(String reminderId, int minutes) async { ... }
  Future<void> cancelAll() async { ... }
}
```

### Android notification channel

Channel id: `carepro_med_reminders`  
Channel name: `Medication Reminders`  
Importance: `Importance.high`  
Sound: default  
Enable vibration: true  

### iOS notification setup

Request `.alert`, `.sound`, `.badge` permissions. Configure `DarwinNotificationDetails` with `categoryIdentifier: 'medication_reminder'` and define `DarwinNotificationActionButton` entries for `take_dose` and `snooze`.

### Interactive notification actions

```dart
const AndroidNotificationAction takeDoseAction = AndroidNotificationAction(
  'take_dose',
  'Take Dose',
  showsUserInterface: false,
  cancelNotification: true,
);

const AndroidNotificationAction snoozeAction = AndroidNotificationAction(
  'snooze',
  'Snooze 15 min',
  showsUserInterface: false,
  cancelNotification: true,
);
```

### Scheduling logic — `lib/features/today/providers/today_agenda_notifier.dart`

After `loadAgenda` succeeds, call `NotificationService.instance.cancelAll()` then schedule one notification per medication per day derived from `scheduleText` (e.g. `"3x daily"` → 08:00, 14:00, 20:00; `"once daily"` → 08:00). Pass `reminderId: medication.id`, `payload: '${medication.id}:${medication.id}:take_dose'`.

### Today Screen deep-link — `lib/features/today/screens/today_screen.dart`

Register a `notificationResponseStream` listener. On `NotificationResponse` with `notificationResponseType == NotificationResponseType.selectedNotification`:
1. Parse `reminderId` from payload.
2. Scroll `ScrollController` to the matching medication card using a `GlobalKey` map.
3. Show a `ScaffoldMessenger` `SnackBar` with green background, checkmark icon, and localized text `AppLocalizations.of(context).doseStatusTaken`.

### Permissions — `lib/features/auth/screens/signup_step3_screen.dart`

After `completeOnboarding` succeeds, call `NotificationService.instance.requestPermissions()`. Show a modal explaining: *"Enable notifications to receive medication reminders at the right time."* (Use `AppLocalizations` key `notificationPermissionRationale`). Add this key to all ARB files.

### `main.dart` initialization

In `main()`, initialize `tz.initializeTimeZones()`, then `NotificationService.instance.initialize()` with `onDidReceiveBackgroundNotificationResponse: notificationTapBackground`.

## Required context

- `mobile/lib/core/network/api_service.dart` (from WI-01) — used in `notificationTapBackground`.
- `mobile/lib/features/today/providers/today_agenda_notifier.dart` (from WI-02) — extend `loadAgenda` to trigger scheduling.
- `mobile/lib/core/l10n/` ARB files (from WI-03) — `notificationReminderTitle`, `notificationReminderBody`, `notificationActionTake`, `notificationActionSnooze` keys must exist.
- Android: `android/app/src/main/AndroidManifest.xml` — add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` and `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />`.
- iOS: `ios/Runner/Info.plist` — no extra keys needed; `flutter_local_notifications` handles permission prompts at runtime.
- Run `flutter pub get` after pubspec changes. Run `flutter analyze` before committing.

## Acceptance criteria

- [ ] `flutter_local_notifications: ^17.0.0` and `timezone: ^0.9.4` are in `pubspec.yaml`.
- [ ] `NotificationService.initialize()` is called in `main()` with `notificationTapBackground` as the background handler.
- [ ] Android notification channel `carepro_med_reminders` is configured with high importance and sound.
- [ ] iOS permission request fires after onboarding completion.
- [ ] `[Take Dose]` action button POSTs `{reminder_id, status: 'taken'}` to `/adherence/log` and fires `HapticFeedback.mediumImpact()` — even when app is terminated.
- [ ] `[Snooze 15m]` reschedules the same notification 15 minutes later.
- [ ] Tapping the notification body opens `TodayScreen`, scrolls to the correct medication card, and shows a green `SnackBar` with the checkmark and localized `doseStatusTaken` text.
- [ ] `notificationTapBackground` is annotated with `@pragma('vm:entry-point')`.
- [ ] `flutter analyze` reports zero errors.

## Covers

- User Stories: 2
- Requirements: Interactive Notifications 1–3; Technical Decisions: 4
- Interview Ledger: L3

## Blocked by

`02-riverpod-notifiers-auth-agenda-checkin.md`

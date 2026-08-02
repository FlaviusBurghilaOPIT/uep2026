import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/notifications/notification_prefs_keys.dart';
import 'package:remotecare/core/notifications/notification_scheduler.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/profile/presentation/providers/notification_prefs_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_scheduler.dart';

// WI 06 / spec Req 25: the Profile "Medication reminders" and "Daily
// check-in" toggles persist to shared_preferences and gate local
// notification scheduling only while the OS permission is granted. When
// permission is denied, enabling is inert (the C1 reminders-off banner on
// Today owns that recovery path — no competing UI here).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNotificationScheduler scheduler;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    scheduler = FakeNotificationScheduler();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('defaults to enabled when nothing is persisted', () {
    final state = container.read(notificationPrefsProvider);
    expect(state.medReminders, true);
    expect(state.dailyCheckin, true);
  });

  test('restores persisted values', () async {
    await prefs.setBool(NotificationPrefsKeys.medReminders, false);
    await prefs.setBool(NotificationPrefsKeys.dailyCheckin, false);

    final state = container.read(notificationPrefsProvider);
    expect(state.medReminders, false);
    expect(state.dailyCheckin, false);
  });

  test('toggling persists to shared_preferences', () async {
    final notifier = container.read(notificationPrefsProvider.notifier);

    final ok = await notifier.setMedReminders(false);

    expect(ok, true);
    expect(prefs.getBool(NotificationPrefsKeys.medReminders), false);
    expect(container.read(notificationPrefsProvider).medReminders, false);
    // The other toggle is untouched.
    expect(container.read(notificationPrefsProvider).dailyCheckin, true);
  });

  test('disabling med reminders cancels already-scheduled notifications', () async {
    final notifier = container.read(notificationPrefsProvider.notifier);

    await notifier.setMedReminders(false);

    expect(scheduler.cancelAllCalls, 1);
  });

  test('enabling while OS permission is denied is inert', () async {
    await prefs.setBool(NotificationPrefsKeys.medReminders, false);
    scheduler.granted = false;
    final notifier = container.read(notificationPrefsProvider.notifier);

    final ok = await notifier.setMedReminders(true);

    expect(ok, false);
    expect(prefs.getBool(NotificationPrefsKeys.medReminders), false);
    expect(container.read(notificationPrefsProvider).medReminders, false);
  });

  test('disabling still works while OS permission is denied', () async {
    scheduler.granted = false;
    final notifier = container.read(notificationPrefsProvider.notifier);

    final ok = await notifier.setMedReminders(false);

    expect(ok, true);
    expect(prefs.getBool(NotificationPrefsKeys.medReminders), false);
  });

  test('daily check-in toggle persists and is permission-gated', () async {
    final notifier = container.read(notificationPrefsProvider.notifier);

    expect(await notifier.setDailyCheckin(false), true);
    expect(prefs.getBool(NotificationPrefsKeys.dailyCheckin), false);

    scheduler.granted = false;
    expect(await notifier.setDailyCheckin(true), false);
    expect(prefs.getBool(NotificationPrefsKeys.dailyCheckin), false);
  });
}

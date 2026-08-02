import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_prefs_keys.dart';
import '../../../../core/notifications/notification_scheduler.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

/// Snapshot of the Profile notification toggles (WI 06 / spec Req 25).
class NotificationPrefsState {
  const NotificationPrefsState({
    this.medReminders = true,
    this.dailyCheckin = true,
  });

  final bool medReminders;
  final bool dailyCheckin;
}

/// Profile "Medication reminders" / "Daily check-in" toggles. Persist to
/// shared_preferences and gate local notification scheduling only while the
/// OS notification permission is granted: enabling is inert when permission
/// is denied — the C1 reminders-off banner on Today owns that recovery path,
/// so this notifier deliberately surfaces no recovery UI of its own.
class NotificationPrefsNotifier extends Notifier<NotificationPrefsState> {
  @override
  NotificationPrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationPrefsState(
      medReminders: prefs.getBool(NotificationPrefsKeys.medReminders) ?? true,
      dailyCheckin: prefs.getBool(NotificationPrefsKeys.dailyCheckin) ?? true,
    );
  }

  /// Returns `true` when the change took effect. Enabling while the OS
  /// permission is denied is inert (`false`, nothing persisted); disabling
  /// always works and cancels already-scheduled dose reminders immediately
  /// (the pref also gates future scheduling batches — see
  /// [NotificationSchedulingController.scheduleForSlots]).
  Future<bool> setMedReminders(bool enabled) async {
    if (enabled && !await _permissionsGranted()) return false;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(NotificationPrefsKeys.medReminders, enabled);
    state = NotificationPrefsState(
      medReminders: enabled,
      dailyCheckin: state.dailyCheckin,
    );
    if (!enabled) {
      await ref.read(notificationSchedulerProvider).cancelAll();
    }
    return true;
  }

  /// Same contract as [setMedReminders].
  Future<bool> setDailyCheckin(bool enabled) async {
    if (enabled && !await _permissionsGranted()) return false;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(NotificationPrefsKeys.dailyCheckin, enabled);
    state = NotificationPrefsState(
      medReminders: state.medReminders,
      dailyCheckin: enabled,
    );
    return true;
  }

  /// Checked, never requested — the first-run primer owns asking.
  Future<bool> _permissionsGranted() =>
      ref.read(notificationSchedulerProvider).permissionsGranted();
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefsState>(
      NotificationPrefsNotifier.new,
    );

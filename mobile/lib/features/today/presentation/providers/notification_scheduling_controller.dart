import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/notification_prefs_keys.dart';
import '../../../../core/notifications/notification_scheduler.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/entities/agenda_entities.dart';

/// Rebuilds local notification scheduling on server truth (WI 14 / spec §6).
/// The `'3x'/'2x'` `schedule_text` parsing scheduler this replaces was
/// already removed when `TodayAgendaNotifier` was rewritten for WI 11 — this
/// controller is the from-scratch replacement, driven entirely by E2 slot
/// times (never by client-side frequency parsing).
class NotificationSchedulingController {
  NotificationSchedulingController({
    required this.scheduler,
    required this.prefs,
    int Function()? currentOffsetMinutes,
  }) : currentOffsetMinutes =
           currentOffsetMinutes ??
           (() => DateTime.now().timeZoneOffset.inMinutes);

  static const _offsetKey = 'today_notif_tz_offset_minutes_v1';

  /// Slot states worth reminding about — a slot that's already resolved
  /// (taken/skipped/missed) or already overdue gets no new local
  /// notification (overdue slots are already visible/late; scheduling one
  /// "now" would just be noise, not a re-anchor).
  static const _remindable = {SlotState.upcoming, SlotState.due};

  final NotificationScheduler scheduler;
  final SharedPreferences prefs;
  final int Function() currentOffsetMinutes;

  /// Schedules one local notification per remindable slot in [slots], from
  /// the E2 `scheduled_time` (UTC) converted to device-local. Call on every
  /// successful agenda load — cancels the previous batch first so stale
  /// slot times never linger.
  Future<void> scheduleForSlots(List<AgendaSlot> slots) async {
    await scheduler.cancelAll();
    // WI 06 / Req 25: the Profile "Medication reminders" toggle gates local
    // scheduling — when off, the previous batch stays cancelled and nothing
    // new is scheduled.
    if (!(prefs.getBool(NotificationPrefsKeys.medReminders) ?? true)) return;
    for (final slot in slots) {
      if (!_remindable.contains(slot.state)) continue;
      await scheduler.scheduleOne(
        slotId: slot.slotId,
        medicationId: slot.medicationId,
        medicationName: slot.medicationName,
        dose: slot.dose,
        scheduledLocalTime: slot.scheduledTime.toLocal(),
      );
    }
  }

  /// Re-anchor (C5): compares the device's current UTC offset against the
  /// last-recorded one. Returns `true` exactly when a shift is detected
  /// (never on the first call — nothing to compare against yet, and never
  /// again for the same shift once recorded) so the caller can surface the
  /// `todayTimezoneAdjusted` banner once per shift.
  Future<bool> reanchor() async {
    final current = currentOffsetMinutes();
    final last = prefs.getInt(_offsetKey);
    await prefs.setInt(_offsetKey, current);
    return last != null && last != current;
  }

  Future<bool> permissionsGranted() => scheduler.permissionsGranted();
}

final notificationSchedulingControllerProvider =
    Provider<NotificationSchedulingController>((ref) {
      return NotificationSchedulingController(
        scheduler: ref.read(notificationSchedulerProvider),
        prefs: ref.read(sharedPreferencesProvider),
      );
    });

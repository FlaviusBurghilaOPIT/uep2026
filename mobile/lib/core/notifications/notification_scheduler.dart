import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// Injectable seam over the platform notification plugin (WI 14 / spec §6)
/// so scheduling and re-anchoring are unit-testable without platform
/// channels. The real implementation never requests permission — it only
/// ever checks the current OS state; the first-run primer owns asking.
abstract class NotificationScheduler {
  /// Schedules one local notification for a single slot. [scheduledLocalTime]
  /// is already device-local (UTC→local conversion happens upstream).
  Future<void> scheduleOne({
    required String slotId,
    required String medicationId,
    required String medicationName,
    required String dose,
    required DateTime scheduledLocalTime,
  });

  /// Cancels every previously scheduled reminder — called before a fresh
  /// batch is scheduled so stale slot times never linger (spec §6).
  Future<void> cancelAll();

  /// Checked, never requested.
  Future<bool> permissionsGranted();
}

class RealNotificationScheduler implements NotificationScheduler {
  const RealNotificationScheduler();

  @override
  Future<void> scheduleOne({
    required String slotId,
    required String medicationId,
    required String medicationName,
    required String dose,
    required DateTime scheduledLocalTime,
  }) async {
    try {
      await NotificationService.instance.scheduleMedicationReminder(
        reminderId: slotId,
        medicationId: medicationId,
        medicationName: medicationName,
        doseAmount: dose,
        scheduledTime: scheduledLocalTime,
      );
    } catch (e, st) {
      // Never let a platform-channel failure (e.g. plugin uninitialized in
      // a test/host environment) crash the caller — scheduling is best
      // effort; the agenda itself remains the source of truth.
      debugPrint('RealNotificationScheduler: scheduleOne failed: $e\n$st');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await NotificationService.instance.cancelAll();
    } catch (e, st) {
      debugPrint('RealNotificationScheduler: cancelAll failed: $e\n$st');
    }
  }

  @override
  Future<bool> permissionsGranted() async {
    try {
      return await NotificationService.instance.arePermissionsGranted();
    } catch (e, st) {
      debugPrint(
        'RealNotificationScheduler: permissionsGranted failed: $e\n$st',
      );
      // Fail open — don't show a reminders-off banner when we simply
      // couldn't determine the OS state.
      return true;
    }
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => const RealNotificationScheduler(),
);

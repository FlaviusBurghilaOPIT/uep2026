import 'package:remotecare/core/notifications/notification_scheduler.dart';

/// Test seam for [NotificationScheduler] — records calls instead of
/// touching platform channels (WI 14 / spec §6: scheduling/re-anchoring
/// must be unit-testable without the plugin).
class FakeNotificationScheduler implements NotificationScheduler {
  final List<ScheduledCall> scheduled = [];
  int cancelAllCalls = 0;
  bool granted = true;

  @override
  Future<void> scheduleOne({
    required String slotId,
    required String medicationId,
    required String medicationName,
    required String dose,
    required DateTime scheduledLocalTime,
  }) async {
    scheduled.add(
      ScheduledCall(
        slotId: slotId,
        medicationId: medicationId,
        medicationName: medicationName,
        dose: dose,
        scheduledLocalTime: scheduledLocalTime,
      ),
    );
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<bool> permissionsGranted() async => granted;
}

class ScheduledCall {
  ScheduledCall({
    required this.slotId,
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    required this.scheduledLocalTime,
  });

  final String slotId;
  final String medicationId;
  final String medicationName;
  final String dose;
  final DateTime scheduledLocalTime;
}

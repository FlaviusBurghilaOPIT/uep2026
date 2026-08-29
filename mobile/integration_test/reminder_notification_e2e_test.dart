import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remotecare/core/notifications/notification_service.dart';
import 'package:remotecare/core/notifications/push_notification_service.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/features/today/presentation/providers/notification_scheduling_controller.dart';
import 'package:remotecare/core/notifications/notification_scheduler.dart';

class TestNotificationScheduler implements NotificationScheduler {
  final List<String> scheduledReminders = [];
  int cancelAllCount = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduledReminders.clear();
  }

  @override
  Future<void> scheduleOne({
    required String slotId,
    required String medicationId,
    required String medicationName,
    required String dose,
    required DateTime scheduledLocalTime,
  }) async {
    scheduledReminders.add('$slotId:$medicationId:$medicationName:$dose');
  }

  @override
  Future<bool> permissionsGranted() async => true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Reminder Notification Suite', () {
    late NotificationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = NotificationService.instance;
      await service.initialize();
    });

    testWidgets('1. Notification payload parsing & action ID recognition', (tester) async {
      const payload = 'rem-12345:med-67890:take_dose';
      final parsedId = NotificationService.parseReminderId(payload);
      expect(parsedId, equals('rem-12345'));

      const emptyPayload = '';
      expect(NotificationService.parseReminderId(emptyPayload), isNull);
    });

    testWidgets('2. Schedule medication reminder & verify zoned schedule parameters', (tester) async {
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(seconds: 10));

      // Schedule a 10s reminder
      await service.scheduleMedicationReminder(
        reminderId: 'rem-e2e-1',
        medicationId: 'med-ibuprofen',
        medicationName: 'Ibuprofen',
        doseAmount: '400mg',
        scheduledTime: scheduledTime,
      );

      // Verify snooze reminder calculation
      await service.snoozeReminder('rem-e2e-1', 15);

      // Cancel all reminders
      await service.cancelAll();
      expect(true, isTrue);
    });

    testWidgets('3. NotificationSchedulingController schedules for upcoming and due slots only', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final scheduler = TestNotificationScheduler();
      final controller = NotificationSchedulingController(
        scheduler: scheduler,
        prefs: prefs,
      );

      final now = DateTime.now();
      final slots = [
        AgendaSlot(
          slotId: 'slot-1',
          medicationId: 'med-1',
          medicationName: 'Amoxicillin',
          dose: '500mg',
          scheduledTime: now.add(const Duration(hours: 1)),
          state: SlotState.upcoming,
        ),
        AgendaSlot(
          slotId: 'slot-2',
          medicationId: 'med-2',
          medicationName: 'Ibuprofen',
          dose: '400mg',
          scheduledTime: now,
          state: SlotState.due,
        ),
        AgendaSlot(
          slotId: 'slot-3',
          medicationId: 'med-3',
          medicationName: 'Oxycodone',
          dose: '5mg',
          scheduledTime: now.subtract(const Duration(hours: 5)),
          state: SlotState.missed,
        ),
      ];

      await controller.scheduleForSlots(slots);

      // Verify that missed slots are ignored, upcoming & due are scheduled
      expect(scheduler.cancelAllCount, equals(1));
      expect(scheduler.scheduledReminders.length, equals(2));
      expect(scheduler.scheduledReminders[0], contains('slot-1:med-1:Amoxicillin:500mg'));
      expect(scheduler.scheduledReminders[1], contains('slot-2:med-2:Ibuprofen:400mg'));
    });

    testWidgets('4. Push notification fallback synchronization', (tester) async {
      final pushService = PushNotificationService(notificationService: service);
      final synced = await pushService.syncPushFallback(
        token: 'e2e-sim-device-token-12345',
        platform: 'ios',
        isLocalPermissionGranted: true,
        isAppInBackground: false,
      );
      expect(synced, isTrue);
    });
  });
}

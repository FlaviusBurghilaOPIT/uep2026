import 'package:remotecare/core/notifications/notification_prefs_keys.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/features/today/presentation/providers/notification_scheduling_controller.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/features/today/presentation/providers/today_agenda_notifier.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_scheduler.dart';

// WI 14 / spec §6 "Notifications": local notifications are scheduled from
// E2 slot times (UTC -> device-local) — never from client-side frequency
// string parsing (the deleted '3x'/'2x' `schedule_text` scheduler). Re-
// anchor detects a device UTC-offset shift and reports it exactly once.

AgendaSlot _slot({
  String slotId = 'rem-1',
  SlotState state = SlotState.upcoming,
  String medicationName = 'Ibuprofen',
  String dose = '400 mg',
  String scheduledTime = '2026-07-26T08:00:00Z',
}) {
  return AgendaSlot(
    slotId: slotId,
    medicationId: 'med-1',
    medicationName: medicationName,
    dose: dose,
    scheduledTime: DateTime.parse(scheduledTime),
    state: state,
  );
}

void main() {
  late FakeNotificationScheduler scheduler;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    scheduler = FakeNotificationScheduler();
  });

  NotificationSchedulingController controller({int Function()? offset}) =>
      NotificationSchedulingController(
        scheduler: scheduler,
        prefs: prefs,
        currentOffsetMinutes: offset,
      );

  group('scheduleForSlots', () {
    test(
      'schedules one notification per upcoming/due slot, UTC -> device-local',
      () async {
        final slot = _slot();
        await controller().scheduleForSlots([slot]);

        expect(scheduler.cancelAllCalls, 1);
        expect(scheduler.scheduled, hasLength(1));
        final call = scheduler.scheduled.single;
        expect(call.slotId, 'rem-1');
        expect(call.medicationName, 'Ibuprofen');
        expect(call.dose, '400 mg');
        expect(
          call.scheduledLocalTime,
          DateTime.parse('2026-07-26T08:00:00Z').toLocal(),
        );
      },
    );

    test('skips overdue/missed/taken/skipped slots — no frequency parsing, '
        'server states only', () async {
      final slots = [
        _slot(slotId: 'a', state: SlotState.due),
        _slot(slotId: 'b', state: SlotState.overdue),
        _slot(slotId: 'c', state: SlotState.missed),
        _slot(slotId: 'd', state: SlotState.taken),
        _slot(slotId: 'e', state: SlotState.skipped),
      ];
      await controller().scheduleForSlots(slots);

      expect(scheduler.scheduled.map((c) => c.slotId), ['a']);
    });

    test('cancels the previous batch before scheduling a fresh one '
        '(reschedule-on-load semantics)', () async {
      final c = controller();
      await c.scheduleForSlots([_slot(slotId: 'a')]);
      await c.scheduleForSlots([_slot(slotId: 'b'), _slot(slotId: 'c')]);

      expect(scheduler.cancelAllCalls, 2);
      expect(scheduler.scheduled.map((call) => call.slotId), ['b', 'c']);
    });
  });

  group('reanchor (C5)', () {
    test(
      'first call establishes the baseline — never reports a shift',
      () async {
        final shifted = await controller(offset: () => 60).reanchor();
        expect(shifted, isFalse);
      },
    );

    test('unchanged offset on a later call — no shift reported', () async {
      await controller(offset: () => 60).reanchor();
      final shifted = await controller(offset: () => 60).reanchor();
      expect(shifted, isFalse);
    });

    test('changed offset is reported exactly once per shift', () async {
      await controller(offset: () => 60).reanchor();

      final afterShift = controller(offset: () => -300);
      expect(await afterShift.reanchor(), isTrue);

      // Recompute again at the SAME new offset — already recorded, no
      // repeat banner.
      final again = controller(offset: () => -300);
      expect(await again.reanchor(), isFalse);
    });
  });

  test(
    'permissionsGranted delegates to the scheduler (never requests)',
    () async {
      scheduler.granted = false;
      expect(await controller().permissionsGranted(), isFalse);
      scheduler.granted = true;
      expect(await controller().permissionsGranted(), isTrue);
    },
  );

  group('WI 06 profile toggle gating (Req 25)', () {
    test('schedules nothing when the med-reminders pref is off', () async {
      await prefs.setBool(NotificationPrefsKeys.medReminders, false);

      await controller().scheduleForSlots([_slot()]);

      expect(scheduler.cancelAllCalls, 1);
      expect(scheduler.scheduled, isEmpty);
    });

    test('schedules normally when the pref is on or absent (default)', () async {
      await controller().scheduleForSlots([_slot()]);
      expect(scheduler.scheduled, hasLength(1));

      await prefs.setBool(NotificationPrefsKeys.medReminders, true);
      await controller().scheduleForSlots([_slot()]);
      expect(scheduler.scheduled, hasLength(1));
    });
  });
}

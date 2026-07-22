import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/today/providers/today_agenda_notifier.dart';

import 'fake_api_service.dart';

void main() {
  late FakeApiService fakeApi;
  late ProviderContainer container;

  setUp(() {
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('loadAgenda populates medications list from fake JSON', () async {
    fakeApi.getHandlers['/cases/case_1/medications'] = () {
      return http.Response(
        jsonEncode([
          {
            'id': 'med_1',
            'name': 'Amoxicillin',
            'dose': '500mg',
            'schedule_text': 'Every 8 hours',
            'duration': '7 days',
            'notes': 'Take with food',
          },
          {
            'id': 'med_2',
            'name': 'Ibuprofen',
            'dose': '400mg',
            'schedule_text': 'As needed',
            'duration': '5 days',
            'notes': null,
          },
        ]),
        200,
      );
    };

    final notifier = container.read(todayAgendaNotifierProvider.notifier);
    await notifier.loadAgenda('case_1');

    final agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState, isNotNull);
    final medications = agendaState!.medications.value;
    expect(medications, isNotNull);
    expect(medications!.length, 2);
    expect(medications[0].id, 'med_1');
    expect(medications[0].name, 'Amoxicillin');
    expect(medications[0].dose, '500mg');
    expect(medications[0].scheduleText, 'Every 8 hours');
    expect(medications[0].duration, '7 days');
    expect(medications[0].notes, 'Take with food');
  });

  test('logDose(taken) -> doseStatuses[id] == DoseStatus.taken', () async {
    fakeApi.postHandlers['/adherence/log'] = (body) {
      if (body?['reminder_id'] == 'rem_123' && body?['status'] == 'taken') {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      return http.Response(jsonEncode({'detail': 'Error'}), 400);
    };

    final notifier = container.read(todayAgendaNotifierProvider.notifier);
    await notifier.logDose(reminderId: 'rem_123', status: DoseStatus.taken);

    final agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState, isNotNull);
    expect(agendaState!.doseStatuses['rem_123'], DoseStatus.taken);
  });

  test('loadAgenda when ApiService returns error -> medications becomes AsyncError', () async {
    fakeApi.getHandlers['/cases/case_bad/medications'] = () {
      return http.Response(jsonEncode({'detail': 'Server error'}), 500);
    };

    final notifier = container.read(todayAgendaNotifierProvider.notifier);
    await notifier.loadAgenda('case_bad');

    final agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState, isNotNull);
    expect(agendaState!.medications.hasError, isTrue);
  });

  test('stageDoseLog -> undoDoseLog within window reverts state to pending', () async {
    final notifier = container.read(todayAgendaNotifierProvider.notifier);
    notifier.stageDoseLog(
      reminderId: 'rem_undo_1',
      status: DoseStatus.taken,
      window: const Duration(seconds: 5),
    );

    var agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState!.doseStatuses['rem_undo_1'], DoseStatus.taken);

    notifier.undoDoseLog(reminderId: 'rem_undo_1', previousStatus: DoseStatus.pending);

    agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState!.doseStatuses['rem_undo_1'], DoseStatus.pending);
  });

  test('stageDoseLog -> wait-past-window commits dose log', () async {
    fakeApi.postHandlers['/adherence/log'] = (body) {
      return http.Response(jsonEncode({'status': 'ok'}), 200);
    };

    final notifier = container.read(todayAgendaNotifierProvider.notifier);
    notifier.stageDoseLog(
      reminderId: 'rem_commit_1',
      status: DoseStatus.skipped,
      window: const Duration(milliseconds: 50),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    final agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState!.doseStatuses['rem_commit_1'], DoseStatus.skipped);
  });

  test('offline log -> offlineQueue non-empty -> flushOfflineQueue clears queue', () async {
    fakeApi.postHandlers['/adherence/log'] = (body) {
      return http.Response(jsonEncode({'detail': 'Network error'}), 500);
    };

    final notifier = container.read(todayAgendaNotifierProvider.notifier);
    await notifier.commitDoseLog(reminderId: 'rem_off_1', status: DoseStatus.taken);

    var agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState!.offlineQueue.length, 1);
    expect(agendaState.offlineQueue.first.reminderId, 'rem_off_1');

    // Simulate reconnect / online success
    fakeApi.postHandlers['/adherence/log'] = (body) {
      return http.Response(jsonEncode({'status': 'ok'}), 200);
    };

    await notifier.flushOfflineQueue();

    agendaState = container.read(todayAgendaNotifierProvider).value;
    expect(agendaState!.offlineQueue.isEmpty, isTrue);
  });
}

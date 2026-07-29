import 'dart:convert';

import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/today/presentation/providers/fda_warning_provider.dart';
import 'package:remotecare/features/today/presentation/providers/today_agenda_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_service.dart';

// WI 13 / spec §7: the FDA card renders only when the API returns real data
// for a medication actually on the patient's plan — queried per-plan med
// (never the old hardcoded "Amoxicillin"), with silent omission on any
// failure (never a fabricated warning).

Map<String, dynamic> _slotJson(String medicationName) => {
  'slot_id': 'rem-1',
  'medication_id': 'med-1',
  'medication_name': medicationName,
  'dose': '400 mg',
  'notes': null,
  'scheduled_time': '2026-07-26T08:00:00Z',
  'state': 'due',
  'logged_at': null,
  'dose_log_id': null,
  'previous_status': null,
};

String _agendaBody(String medicationName) => jsonEncode({
  'date': '2026-07-26',
  'slots': [_slotJson(medicationName)],
  'prn': [],
});

void main() {
  late FakeApiService fakeApi;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('renders data only for a medication actually on the plan', () async {
    fakeApi.agendaHandler = (date) =>
        http.Response(_agendaBody('Ibuprofen'), 200);
    fakeApi.getHandlers['/fda/drug/Ibuprofen'] = () => http.Response(
      jsonEncode({
        'source': 'live',
        'summary': 'Real warning',
        'retrieved_at': '2026-07-22',
      }),
      200,
    );

    await container.read(todayAgendaNotifierProvider.notifier).loadAgenda();
    final warning = await container.read(fdaWarningProvider.future);

    expect(warning, isNotNull);
    expect(warning!.message, 'Real warning');
    expect(fakeApi.requestsTo('/fda/drug/Ibuprofen'), isNotEmpty);
  });

  test('silent omission when no on-plan med has data (never queries a '
      'hardcoded name)', () async {
    fakeApi.agendaHandler = (date) =>
        http.Response(_agendaBody('Metoprolol'), 200);
    // No handler registered for /fda/drug/Metoprolol -> default 404, and
    // none for Amoxicillin either -> proves it is never queried.

    await container.read(todayAgendaNotifierProvider.notifier).loadAgenda();
    final warning = await container.read(fdaWarningProvider.future);

    expect(warning, isNull);
    expect(fakeApi.requestsTo('/fda/drug/Amoxicillin'), isEmpty);
  });

  test(
    'silent omission when the query throws (never a fabricated warning)',
    () async {
      fakeApi.agendaHandler = (date) =>
          http.Response(_agendaBody('Ibuprofen'), 200);
      fakeApi.getHandlers['/fda/drug/Ibuprofen'] = () =>
          throw Exception('network down');

      await container.read(todayAgendaNotifierProvider.notifier).loadAgenda();
      final warning = await container.read(fdaWarningProvider.future);

      expect(warning, isNull);
    },
  );
}

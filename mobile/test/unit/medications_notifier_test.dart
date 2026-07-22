import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/medications/providers/medications_notifier.dart';

import 'fake_api_service.dart';

void main() {
  late FakeApiService fakeApi;
  late ProviderContainer container;

  setUp(() {
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'loadMedications populates the full prescription list from fake JSON',
    () async {
      fakeApi.getHandlers['/cases/case_1/medications'] = () {
        return http.Response(
          jsonEncode([
            {
              'id': 'med_1',
              'name': 'Amoxicillin',
              'dose': '500mg',
              'frequency': 'TID',
              'schedule_times': ['08:00', '14:00', '20:00'],
              'duration': '7 days',
              'notes': 'Take with food',
            },
            {
              'id': 'med_2',
              'name': 'Ibuprofen',
              'dose': '400mg',
              'frequency': 'PRN',
              'schedule_times': [],
              'duration': '5 days',
              'notes': null,
            },
          ]),
          200,
        );
      };

      final notifier = container.read(medicationsNotifierProvider.notifier);
      await notifier.loadMedications('case_1');

      final medications = container.read(medicationsNotifierProvider).value;
      expect(medications, isNotNull);
      expect(medications!.length, 2);
      expect(medications[0].id, 'med_1');
      expect(medications[0].name, 'Amoxicillin');
      expect(medications[0].dose, '500mg');
      expect(medications[0].frequency, 'TID');
      expect(medications[0].scheduleTimes, ['08:00', '14:00', '20:00']);
      expect(medications[0].duration, '7 days');
      expect(medications[0].notes, 'Take with food');
      expect(medications[1].notes, isNull);
    },
  );

  test('loadMedications when ApiService returns error -> AsyncError', () async {
    fakeApi.getHandlers['/cases/case_bad/medications'] = () {
      return http.Response(jsonEncode({'detail': 'Server error'}), 500);
    };

    final notifier = container.read(medicationsNotifierProvider.notifier);
    await notifier.loadMedications('case_bad');

    final state = container.read(medicationsNotifierProvider);
    expect(state.hasError, isTrue);
  });
}

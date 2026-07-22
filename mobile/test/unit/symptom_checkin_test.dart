import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/checkin/providers/symptom_checkin_notifier.dart';

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

  test('submit success -> AsyncData(true)', () async {
    fakeApi.postHandlers['/checkins'] = (body) {
      if (body?['case_id'] == 'case_1' && body?['severity'] == 'mild') {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      return http.Response(jsonEncode({'detail': 'Bad request'}), 400);
    };

    final notifier = container.read(symptomCheckinNotifierProvider.notifier);
    await notifier.submit(caseId: 'case_1', severity: 'mild', notes: 'Feeling fine');

    final state = container.read(symptomCheckinNotifierProvider);
    expect(state.hasValue, isTrue);
    expect(state.value, isTrue);
  });

  test('submit network failure -> AsyncError with message', () async {
    fakeApi.postHandlers['/checkins'] = (body) {
      return http.Response(jsonEncode({'detail': 'Server error'}), 500);
    };

    final notifier = container.read(symptomCheckinNotifierProvider.notifier);
    await notifier.submit(caseId: 'case_1', severity: 'severe');

    final state = container.read(symptomCheckinNotifierProvider);
    expect(state.hasError, isTrue);
  });
}

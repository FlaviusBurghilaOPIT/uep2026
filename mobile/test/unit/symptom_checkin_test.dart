import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/checkin/presentation/providers/symptom_checkin_notifier.dart';

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

  // D2 (spec §10 pending question): the canonical backend route is
  // `POST /symptoms/checkin?case_id=&feeling=` (backend/app/routers/
  // checkins.py, `/symptoms` prefix, query params — not a JSON body, and
  // not `/checkins`). `feeling` matches the `CheckInFeeling` enum values the
  // mood picker already sends (great/ok/not_great/bad).
  test(
    'submit success -> AsyncData(true), posts query params to /symptoms/checkin',
    () async {
      fakeApi.postHandlers['/symptoms/checkin?case_id=case_1&feeling=great'] =
          (body) {
            return http.Response(jsonEncode({'id': 'checkin_1'}), 200);
          };

      final notifier = container.read(symptomCheckinNotifierProvider.notifier);
      await notifier.submit(caseId: 'case_1', feeling: 'great');

      final state = container.read(symptomCheckinNotifierProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isTrue);
    },
  );

  test('submit network failure -> AsyncError', () async {
    fakeApi.postHandlers['/symptoms/checkin?case_id=case_1&feeling=bad'] =
        (body) {
          return http.Response(jsonEncode({'detail': 'Server error'}), 500);
        };

    final notifier = container.read(symptomCheckinNotifierProvider.notifier);
    await notifier.submit(caseId: 'case_1', feeling: 'bad');

    final state = container.read(symptomCheckinNotifierProvider);
    expect(state.hasError, isTrue);
  });
}

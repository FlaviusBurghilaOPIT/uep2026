import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/providers/auth_provider.dart';
import 'package:remotecare/features/recovery/presentation/providers/recovery_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_service.dart';

/// Fixed "today" for deterministic Day-N / 7-day-window assertions.
final _fixedNow = DateTime(2026, 7, 26, 12, 0);

String _iso(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

Map<String, dynamic> _slot({required String state}) => {
  'slot_id': 'rem-${state.hashCode}',
  'medication_id': 'med-1',
  'medication_name': 'Ibuprofen',
  'dose': '400 mg',
  'notes': null,
  'scheduled_time': '2026-07-26T08:00:00Z',
  'state': state,
  'logged_at': null,
  'dose_log_id': null,
  'previous_status': null,
};

String _agendaBody(List<Map<String, dynamic>> slots) =>
    jsonEncode({'date': '2026-07-26', 'slots': slots, 'prn': []});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  RecoveryNotifier notifier() {
    final n = container.read(recoveryNotifierProvider.notifier);
    n.clock = () => _fixedNow;
    return n;
  }

  RecoveryState state() => container.read(recoveryNotifierProvider).value!;

  /// Signs in a patient via the fake so authProvider holds patientId/caseId.
  Future<void> seedAuth() async {
    fakeApi.savedToken = 'tok';
    fakeApi.getHandlers['/auth/me'] = () => http.Response(
      jsonEncode({'id': 'p1', 'email': 'p@x.io', 'full_name': 'Pat Doe'}),
      200,
    );
    fakeApi.getHandlers['/patients/p1/case'] = () =>
        http.Response(jsonEncode({'id': 'case-1'}), 200);
    await container.read(authProvider.notifier).fetchProfile();
  }

  void seedCase({String? surgeryDate = '2026-07-08', String? doctorName}) {
    fakeApi.caseHandler = (patientId) => http.Response(
      jsonEncode({
        'id': 'case-1',
        'clinician_id': 'c1',
        'patient_id': 'p1',
        'surgery_type': 'Knee Arthroscopy',
        'surgery_date': surgeryDate,
        'doctor_name': doctorName,
        'patient_date_of_birth': '1988-03-14',
        'status': 'active',
        'emergency_contact_name': null,
        'emergency_contact_phone': null,
        'created_at': '2026-07-01T00:00:00Z',
      }),
      200,
    );
  }

  void seedRecommendations(List<String> texts) {
    fakeApi.recommendationsHandler = (caseId) => http.Response(
      jsonEncode([
        for (var i = 0; i < texts.length; i++)
          {
            'id': 'rec-$i',
            'case_id': 'case-1',
            'text': texts[i],
            'content': texts[i],
            'created_at': '2026-07-20T00:00:00Z',
          },
      ]),
      200,
    );
  }

  /// Every one of the 7 agenda fetches returns the same slots.
  void seedAgendas(List<Map<String, dynamic>> slots) {
    fakeApi.agendaHandler = (date) => http.Response(_agendaBody(slots), 200);
  }

  test(
    'load maps real case + recommendations + derives Day N and 7-day adherence',
    () async {
      await seedAuth();
      seedCase(surgeryDate: '2026-07-08'); // 19th day on 2026-07-26
      seedRecommendations(['Keep wound clean and dry', 'Light walking 10 min']);
      seedAgendas([_slot(state: 'taken'), _slot(state: 'missed')]);

      await notifier().load();

      final s = state();
      expect(s.sourceState, RecoverySourceState.ready);
      expect(s.surgeryType, 'Knee Arthroscopy');
      expect(s.surgeryDate, DateTime(2026, 7, 8));
      expect(s.dayOfRecovery, 19);
      expect(s.recommendations, [
        'Keep wound clean and dry',
        'Light walking 10 min',
      ]);
      expect(s.adherenceDays.length, 7);
      // Oldest day is today - 6; every day: 1 taken of 2 slots.
      expect(s.adherenceDays.first.date, DateTime(2026, 7, 20));
      expect(s.adherenceDays.last.date, DateTime(2026, 7, 26));
      for (final day in s.adherenceDays) {
        expect(day.taken, 1);
        expect(day.total, 2);
      }
      expect(s.hasAdherenceData, isTrue);
      expect(s.overallAdherencePercent, 50);
    },
  );

  test('surgery_date absent -> no Day N, no surgery date (honest absence)', () async {
    await seedAuth();
    seedCase(surgeryDate: null);
    seedRecommendations([]);
    seedAgendas([]);

    await notifier().load();

    final s = state();
    expect(s.sourceState, RecoverySourceState.ready);
    expect(s.surgeryType, 'Knee Arthroscopy');
    expect(s.surgeryDate, isNull);
    expect(s.dayOfRecovery, isNull);
    expect(s.recommendations, isEmpty);
  });

  test('surgery_date in the future -> no fabricated Day N', () async {
    await seedAuth();
    seedCase(surgeryDate: '2026-08-01');
    seedRecommendations([]);
    seedAgendas([]);

    await notifier().load();

    expect(state().dayOfRecovery, isNull);
  });

  test('no slots on any of the 7 days -> honest empty adherence', () async {
    await seedAuth();
    seedCase();
    seedRecommendations(['Rest']);
    seedAgendas([]);

    await notifier().load();

    final s = state();
    expect(s.sourceState, RecoverySourceState.ready);
    expect(s.hasAdherenceData, isFalse);
    expect(s.overallAdherencePercent, isNull);
  });

  test('only taken slots count toward the numerator', () async {
    await seedAuth();
    seedCase();
    seedRecommendations([]);
    seedAgendas([
      _slot(state: 'taken'),
      _slot(state: 'skipped'),
      _slot(state: 'missed'),
      _slot(state: 'upcoming'),
    ]);

    await notifier().load();

    expect(state().overallAdherencePercent, 25);
  });

  test('case fetch failure -> error state', () async {
    await seedAuth();
    fakeApi.caseHandler = (patientId) =>
        http.Response(jsonEncode({'detail': 'boom'}), 500);
    seedRecommendations(['Rest']);
    seedAgendas([]);

    await notifier().load();

    expect(state().sourceState, RecoverySourceState.error);
  });

  test('recommendations fetch failure -> error state', () async {
    await seedAuth();
    seedCase();
    fakeApi.recommendationsHandler = (caseId) =>
        http.Response(jsonEncode({'detail': 'boom'}), 500);
    seedAgendas([]);

    await notifier().load();

    expect(state().sourceState, RecoverySourceState.error);
  });

  test('network throw -> error state', () async {
    await seedAuth();
    fakeApi.caseHandler = (patientId) => throw Exception('offline');

    await notifier().load();

    expect(state().sourceState, RecoverySourceState.error);
  });

  test('no signed-in patient -> error state, no fabricated data', () async {
    await notifier().load();

    final s = state();
    expect(s.sourceState, RecoverySourceState.error);
    expect(s.surgeryType, isNull);
    expect(s.dayOfRecovery, isNull);
  });

  test('a single day agenda failure counts as no data, not an error', () async {
    await seedAuth();
    seedCase();
    seedRecommendations([]);
    final failDate = _iso(_fixedNow.subtract(const Duration(days: 3)));
    fakeApi.agendaHandler = (date) {
      if (date == failDate) {
        return http.Response(jsonEncode({'detail': 'boom'}), 500);
      }
      return http.Response(_agendaBody([_slot(state: 'taken')]), 200);
    };

    await notifier().load();

    final s = state();
    expect(s.sourceState, RecoverySourceState.ready);
    final failed = s.adherenceDays.firstWhere(
      (d) => d.date == DateTime(2026, 7, 23),
    );
    expect(failed.total, 0);
    expect(s.hasAdherenceData, isTrue);
  });

  test('doctor_name mapped to state when present in case', () async {
    await seedAuth();
    seedCase(doctorName: 'Dr. Sarah Miller');
    seedRecommendations([]);
    seedAgendas([]);

    await notifier().load();

    final s = state();
    expect(s.sourceState, RecoverySourceState.ready);
    expect(s.doctorName, 'Dr. Sarah Miller');
  });

  test('doctor_name absent in case -> null in state (honest absence)', () async {
    await seedAuth();
    seedCase(doctorName: null);
    seedRecommendations([]);
    seedAgendas([]);

    await notifier().load();

    final s = state();
    expect(s.sourceState, RecoverySourceState.ready);
    expect(s.doctorName, isNull);
  });
}

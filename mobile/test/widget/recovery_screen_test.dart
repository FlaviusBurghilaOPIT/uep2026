import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/constants/app_colors.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/core/widgets/app_skeleton_loader.dart';
import 'package:remotecare/features/auth/presentation/providers/auth_provider.dart';
import 'package:remotecare/features/recovery/presentation/screens/recovery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';

String _iso(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

String _agendaBody(List<Map<String, dynamic>> slots) =>
    jsonEncode({'date': _iso(DateTime.now()), 'slots': slots, 'prn': []});

Map<String, dynamic> _slot(String id, String state) => {
  'slot_id': id,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
    fakeApi.getHandlers['/auth/me'] = () => http.Response(
      jsonEncode({'id': 'p1', 'email': 'p@x.io', 'full_name': 'Pat Doe'}),
      200,
    );
    // Auth profile bootstrap reads the case id through the generic GET seam.
    fakeApi.getHandlers['/patients/p1/case'] = () =>
        http.Response(jsonEncode({'id': 'case-1'}), 200);
  });

  /// Case payload served to the recovery notifier (typed getPatientCase).
  /// [surgeryDate] defaults to 10 days before today so "Day 11" is
  /// deterministic without a clock seam on the screen.
  void seedCase({String? surgeryDate, String? doctorName}) {
    fakeApi.caseHandler = (patientId) => http.Response(
      jsonEncode({
        'id': 'case-1',
        'clinician_id': 'c1',
        'patient_id': 'p1',
        'surgery_type': 'Knee Arthroscopy',
        'surgery_date':
            surgeryDate ??
            _iso(DateTime.now().subtract(const Duration(days: 10))),
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

  Future<ProviderContainer> pumpRecovery(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Sign the fake patient in BEFORE the screen mounts so the notifier has
    // a patientId on its first load and the top bar has a real name (boot
    // routing guarantees this ordering in production).
    await container.read(authProvider.notifier).fetchProfile();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, _) =>
              const MaterialApp(home: RecoveryScreen()),
        ),
      ),
    );
    return container;
  }

  group('RecoveryScreen server truth', () {
    testWidgets('loading shows skeletons, then real server data', (
      tester,
    ) async {
      final completer = Completer<http.Response>();
      fakeApi.caseHandler = (patientId) => completer.future;

      await pumpRecovery(tester);
      await tester.pump();

      expect(find.byType(AppSkeletonLoader), findsWidgets);
      expect(find.byKey(const Key('recovery_skeleton_header')), findsOneWidget);

      completer.complete(
        http.Response(
          jsonEncode({
            'id': 'case-1',
            'surgery_type': 'Knee Arthroscopy',
            'surgery_date': null,
            'status': 'active',
          }),
          200,
        ),
      );
      seedRecommendations(['Rest the knee']);
      fakeApi.agendaHandler = (date) => http.Response(_agendaBody([]), 200);
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeletonLoader), findsNothing);
      expect(find.text('Rest the knee'), findsOneWidget);
    });

    testWidgets('real data: Day N, surgery type/date, recommendations, chart; '
        'no fabricated content', (tester) async {
      seedCase(); // surgery 10 days ago -> Day 11
      seedRecommendations(['Keep wound clean and dry', 'Light walking 10 min']);
      fakeApi.agendaHandler = (date) => http.Response(
        _agendaBody([_slot('r1', 'taken'), _slot('r2', 'missed')]),
        200,
      );

      await pumpRecovery(tester);
      await tester.pumpAndSettle();

      // Real data rendered.
      expect(find.text('Day 11 of Recovery'), findsOneWidget);
      expect(find.textContaining('Knee Arthroscopy'), findsOneWidget);
      expect(find.textContaining('Since'), findsOneWidget);
      expect(find.text('Pat Doe'), findsOneWidget);
      expect(find.text('Keep wound clean and dry'), findsOneWidget);
      expect(find.text('Light walking 10 min'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget); // 1 taken of 2 each day
      final percentWidget = tester.widget<Text>(find.text('50%'));
      expect(percentWidget.style?.fontWeight, FontWeight.w700);
      expect(percentWidget.style?.color, AppColors.primaryGreen);

      final adherenceLabel = tester.widget<Text>(find.text('7-Day Adherence'));
      expect(adherenceLabel.style?.fontWeight, FontWeight.w400);

      // Fabricated artifacts are gone.
      expect(find.text('Day 19 of Recovery'), findsNothing);
      expect(find.textContaining('Dr. Claire Moreau'), findsNothing);
      expect(find.text('Recovery Milestones'), findsNothing);
      expect(find.textContaining('Seek Care Immediately'), findsNothing);
      expect(find.text('Activity Restrictions'), findsNothing);
      expect(find.text('Wound Care'), findsNothing);
      expect(find.text('Physiotherapy'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets('surgery_date absent -> honest absence, no fabricated Day N', (
      tester,
    ) async {
      fakeApi.caseHandler = (patientId) => http.Response(
        jsonEncode({
          'id': 'case-1',
          'surgery_type': 'Knee Arthroscopy',
          'surgery_date': null,
          'status': 'active',
        }),
        200,
      );
      seedRecommendations([]);
      fakeApi.agendaHandler = (date) => http.Response(_agendaBody([]), 200);

      await pumpRecovery(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('of Recovery'), findsNothing);
      expect(find.textContaining('Since'), findsNothing);
      // Surgery type is still real data and renders.
      expect(find.text('Knee Arthroscopy'), findsOneWidget);
      // Honest empty states for chart + instructions.
      expect(
        find.byKey(const Key('recovery_adherence_empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('recovery_instructions_empty')),
        findsOneWidget,
      );
      expect(find.text('81%'), findsNothing);
    });

    testWidgets('error state renders and retry recovers', (tester) async {
      fakeApi.caseHandler = (patientId) =>
          http.Response(jsonEncode({'detail': 'boom'}), 500);

      await pumpRecovery(tester);
      await tester.pumpAndSettle();

      expect(
        find.textContaining("couldn't load your recovery plan"),
        findsOneWidget,
      );
      final retry = find.byKey(const Key('recovery_retry'));
      expect(retry, findsOneWidget);

      seedCase();
      seedRecommendations(['Rest the knee']);
      fakeApi.agendaHandler = (date) => http.Response(_agendaBody([]), 200);
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(find.text('Day 11 of Recovery'), findsOneWidget);
      expect(find.text('Rest the knee'), findsOneWidget);
    });

    testWidgets(
      'care team: absent/empty clinician displays honest absence copy',
      (tester) async {
        seedCase(doctorName: null);
        seedRecommendations([]);
        fakeApi.agendaHandler = (date) => http.Response(_agendaBody([]), 200);

        await pumpRecovery(tester);
        await tester.pumpAndSettle();

        expect(find.text('CARE TEAM'), findsOneWidget);
        expect(
          find.text(
            'No dedicated care team assigned — contact clinic main desk',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('recovery_care_team_empty')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'care team: empty whitespace clinician displays honest absence copy',
      (tester) async {
        seedCase(doctorName: '   ');
        seedRecommendations([]);
        fakeApi.agendaHandler = (date) => http.Response(_agendaBody([]), 200);

        await pumpRecovery(tester);
        await tester.pumpAndSettle();

        expect(find.text('CARE TEAM'), findsOneWidget);
        expect(
          find.text(
            'No dedicated care team assigned — contact clinic main desk',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('recovery_care_team_empty')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'care team: assigned clinician renders doctor name cleanly',
      (tester) async {
        seedCase(doctorName: 'Dr. Sarah Miller');
        seedRecommendations([]);
        fakeApi.agendaHandler = (date) => http.Response(_agendaBody([]), 200);

        await pumpRecovery(tester);
        await tester.pumpAndSettle();

        expect(find.text('CARE TEAM'), findsOneWidget);
        expect(find.text('Dr. Sarah Miller'), findsOneWidget);
        expect(
          find.byKey(const Key('recovery_care_team_empty')),
          findsNothing,
        );
      },
    );
  });
}

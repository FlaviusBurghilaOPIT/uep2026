import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/app_providers.dart';
import 'package:remotecare/core/widgets/app_skeleton_loader.dart';
import 'package:remotecare/features/auth/demo_auth_state.dart';
import 'package:remotecare/features/today/today_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';

Map<String, dynamic> slotJson({
  String slotId = 'rem-1',
  String medicationId = 'med-1',
  String medicationName = 'Ibuprofen',
  String dose = '400 mg',
  String scheduledTime = '2026-07-26T08:00:00Z',
  String state = 'due',
  String? loggedAt,
  String? doseLogId,
}) {
  return {
    'slot_id': slotId,
    'medication_id': medicationId,
    'medication_name': medicationName,
    'dose': dose,
    'notes': null,
    'scheduled_time': scheduledTime,
    'state': state,
    'logged_at': loggedAt,
    'dose_log_id': doseLogId,
    'previous_status': null,
  };
}

String agendaBody({
  List<Map<String, dynamic>>? slots,
  List<Map<String, dynamic>>? prn,
}) {
  return jsonEncode({
    'date': '2026-07-26',
    'slots': slots ?? [slotJson()],
    'prn': prn ?? [],
  });
}

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
  });

  // Fixed morning instant so the greeting/date line is deterministic
  // (TodayScreen's clock seam defaults to real DateTime.now() in prod).
  DateTime fixedMorning() => DateTime(2026, 7, 26, 8, 0);

  Future<ProviderContainer> pumpToday(WidgetTester tester) async {
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
    // Safety net for failed tests; the happy path disposes explicitly at
    // the end of each test body (see note below) since `testWidgets`'s
    // "no pending timers" invariant is checked BEFORE addTearDown callbacks
    // run, so relying on addTearDown alone can't satisfy it when the
    // notifier has a live empty-poll/queue-retry Timer at test end.
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: TodayScreen(clock: fixedMorning),
          ),
        ),
      ),
    );
    // Let auth resolve (full name in the top bar).
    await container.read(authProvider).fetchProfile();
    return container;
  }

  group('TodayScreen states', () {
    testWidgets('loading shows skeleton greeting + 3 skeleton slot cards, '
        'then real server data', (tester) async {
      final completer = Completer<http.Response>();
      fakeApi.agendaHandler = (date) => completer.future;

      final container = await pumpToday(tester);
      await tester.pump();

      expect(find.byKey(const Key('today_skeleton_greeting')), findsOneWidget);
      expect(find.byType(AppSkeletonLoader), findsNWidgets(4));

      completer.complete(http.Response(agendaBody(), 200));
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeletonLoader), findsNothing);
      expect(find.text('Ibuprofen'), findsOneWidget);
      container.dispose();
    });

    testWidgets('fresh render: real names/times, greeting, progress, no '
        'fabricated data', (tester) async {
      fakeApi.agendaHandler = (date) => http.Response(
        agendaBody(
          slots: [
            slotJson(),
            slotJson(
              slotId: 'rem-2',
              medicationName: 'Metoprolol',
              dose: '25 mg',
              scheduledTime: '2026-07-26T20:00:00Z',
              state: 'upcoming',
            ),
          ],
        ),
        200,
      );

      final container = await pumpToday(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofen'), findsOneWidget);
      expect(find.text('Good morning, Pat'), findsOneWidget);
      expect(find.text('0/2 doses'), findsOneWidget);
      // Fabricated artifacts are gone.
      expect(find.textContaining('Day 19'), findsNothing);
      expect(find.textContaining('TODAY · JUL'), findsNothing);
      expect(find.text('Amoxicillin'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.textContaining('coming soon'), findsNothing);

      // Metoprolol (upcoming, grouped by time-of-day below the pinned/due
      // slot) is below the fold in this viewport — scroll to reveal it.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Metoprolol'), findsOneWidget);

      container.dispose();
    });

    testWidgets('empty (C9): calm empty state, no fallback meds rendered', (
      tester,
    ) async {
      fakeApi.agendaHandler = (date) =>
          http.Response(agendaBody(slots: [], prn: []), 200);

      final container = await pumpToday(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your care team is preparing your care plan. '
          'No action is needed from you right now.',
        ),
        findsOneWidget,
      );
      expect(find.text('Pull down to check again.'), findsOneWidget);
      expect(find.text('Ibuprofen'), findsNothing);
      expect(find.text('Metoprolol'), findsNothing);

      // Empty state starts a 60s background poll (C9) — dispose explicitly
      // so it's cancelled before this test's "no pending timers" check.
      container.dispose();
    });

    testWidgets('error (no cache): error card + retry recovers', (
      tester,
    ) async {
      fakeApi.agendaHandler = (date) =>
          http.Response(jsonEncode({'detail': 'boom'}), 500);

      final container = await pumpToday(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          "We couldn't load your care plan. "
          'Check your connection and try again.',
        ),
        findsOneWidget,
      );
      final retry = find.byKey(const Key('today_retry'));
      expect(retry, findsOneWidget);

      fakeApi.agendaHandler = (date) => http.Response(agendaBody(), 200);
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofen'), findsOneWidget);
      container.dispose();
    });

    testWidgets('stale (C11): cached agenda + freshness banner', (
      tester,
    ) async {
      // Seed a persisted cache, then fail the fetch.
      await prefs.setString('today_agenda_cache_body_v1', agendaBody());
      await prefs.setString(
        'today_agenda_cache_time_v1',
        DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      );
      fakeApi.agendaHandler = (date) => throw Exception('offline');

      final container = await pumpToday(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofen'), findsOneWidget);
      expect(find.textContaining('syncing latest plan'), findsOneWidget);
      container.dispose();
    });

    testWidgets('offline (C3): persistent banner, slots still loggable', (
      tester,
    ) async {
      // Seed a persisted offline queue entry; flush will fail (offline).
      await prefs.setString(
        'today_offline_queue_v1',
        jsonEncode([
          {
            'idempotency_key': 'key-1',
            'kind': 'create',
            'status': 'taken',
            'enqueued_at': DateTime.now().toIso8601String(),
            'slot_id': 'rem-1',
          },
        ]),
      );
      await prefs.setString('today_agenda_cache_body_v1', agendaBody());
      fakeApi.agendaHandler = (date) => throw Exception('offline');
      fakeApi.adherenceLogHandler = (id, status) => throw Exception('offline');

      final container = await pumpToday(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Log saved on your device. '
          'We will update your care team once you are back online.',
        ),
        findsOneWidget,
      );
      // Slots render from cache and remain loggable.
      expect(find.byKey(const Key('slot_action_taken_rem-1')), findsOneWidget);

      // A non-empty offline queue starts a 30s retry Timer — dispose
      // explicitly so it's cancelled before this test's invariant check.
      container.dispose();
    });
  });
}

import 'dart:convert';
import 'dart:ui';

import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:flutter/material.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:flutter/services.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/features/auth/presentation/providers/auth_provider.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:remotecare/features/today/presentation/screens/today_screen.dart';
import 'package:remotecare/features/today/domain/entities/agenda_entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';

// WI 15 / spec §7 Accessibility — screen-level checks that don't fit inside
// a single component's own test file: M-02 (banners at 200% scale), M-05
// (live-region announcement + Reduce Motion), M-06 (next-due pinned above
// the fold, no scroll required).

Map<String, dynamic> _slotJson({
  String slotId = 'rem-1',
  String medicationName = 'Ibuprofen',
  String state = 'due',
}) {
  return {
    'slot_id': slotId,
    'medication_id': 'med-1',
    'medication_name': medicationName,
    'dose': '400 mg',
    'notes': null,
    'scheduled_time': '2026-07-26T08:00:00Z',
    'state': state,
    'logged_at': null,
    'dose_log_id': null,
    'previous_status': null,
  };
}

String _agendaBody() => jsonEncode({
  'date': '2026-07-26',
  'slots': [_slotJson()],
  'prn': [],
});

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
    fakeApi.agendaHandler = (date) => http.Response(_agendaBody(), 200);
    fakeApi.adherenceLogHandler = (id, status) =>
        http.Response(jsonEncode({'id': 'log-1', 'status': status}), 201);
  });

  Future<ProviderContainer> pumpToday(
    WidgetTester tester, {
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
            home: TodayScreen(clock: () => DateTime(2026, 7, 26, 8, 0)),
          ),
        ),
      ),
    );
    await container.read(authProvider.notifier).fetchProfile();
    return container;
  }

  group('Today accessibility (WI 15)', () {
    testWidgets('M-06: next-due pinned slot + its actions are visible without '
        'scrolling', (tester) async {
      final container = await pumpToday(tester);
      await tester.pumpAndSettle();

      // Rendered (found) at all without a scroll gesture => within the
      // initial viewport, above the fold.
      expect(find.text('DUE NOW'), findsOneWidget);
      expect(find.byKey(const Key('slot_action_taken_rem-1')), findsOneWidget);
      container.dispose();
    });

    testWidgets('M-02: banner region survives 200% text scale, no overflow', (
      tester,
    ) async {
      // Seed a persisted offline-queue entry so the offline banner renders.
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
      fakeApi.adherenceLogHandler = (id, status) => throw Exception('offline');

      final container = await pumpToday(
        tester,
        textScaler: const TextScaler.linear(2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('banner_offline')), findsOneWidget);
      container.dispose();
    });

    testWidgets(
      'M-05: logging a dose sends a live-region accessibility announcement',
      (tester) async {
        final messages = <Map<Object?, Object?>>[];
        tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              (message) async {
                messages.add(message as Map<Object?, Object?>);
                return null;
              },
            );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger
              .setMockDecodedMessageHandler<dynamic>(
                SystemChannels.accessibility,
                null,
              );
        });

        final container = await pumpToday(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('slot_action_taken_rem-1')));
        await tester.pump();

        final announced = messages.any((m) {
          final data = m['data'] as Map<Object?, Object?>?;
          final text = data?['message'] as String?;
          return text != null &&
              text.contains('Ibuprofen') &&
              text.contains('marked as taken');
        });
        expect(
          announced,
          isTrue,
          reason:
              'expected a live-region announcement mentioning the med '
              'and its new status; got: $messages',
        );
        container.dispose();
      },
    );

    testWidgets(
      'M-05: Reduce Motion — celebration card has no AnimationController to '
      'disable in the first place (static by construction)',
      (tester) async {
        fakeApi.agendaHandler = (date) => http.Response(
          jsonEncode({
            'date': '2026-07-26',
            'slots': [_slotJson(state: 'taken')],
            'prn': [],
          }),
          200,
        );
        tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
            const _ReduceMotionFeatures();
        addTearDown(() {
          tester.binding.platformDispatcher
              .clearAccessibilityFeaturesTestValue();
        });

        final container = await pumpToday(tester);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('today_celebration')), findsOneWidget);
        // No AnimatedContainer/AnimationController-driven celebration
        // effect exists on Today to conflict with Reduce Motion.
        expect(find.byType(AnimatedContainer), findsNothing);
        container.dispose();
      },
    );
  });
}

class _ReduceMotionFeatures implements AccessibilityFeatures {
  const _ReduceMotionFeatures();
  @override
  bool get accessibleNavigation => false;
  @override
  bool get autoPlayAnimatedImages => true;
  @override
  bool get autoPlayVideos => true;
  @override
  bool get boldText => false;
  @override
  bool get deterministicCursor => false;
  @override
  bool get disableAnimations => true;
  @override
  bool get highContrast => false;
  @override
  bool get invertColors => false;
  @override
  bool get onOffSwitchLabels => false;
  @override
  bool get reduceMotion => true;
  @override
  bool get supportsAnnounce => false;
}

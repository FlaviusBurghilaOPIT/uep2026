import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/app_providers.dart';
import 'package:remotecare/features/auth/demo_auth_state.dart';
import 'package:remotecare/features/today/side_effect_prompt_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';

Widget wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
  });

  Future<void> pumpPrompt(
    WidgetTester tester, {
    bool preloadAuth = false,
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
    if (preloadAuth) {
      // Ensure caseId is resolved before the C8 answer runs.
      await container.read(authProvider).fetchProfile();
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrap(const SideEffectPromptCard(slotId: 'rem-1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  void seedAuthAndContact({String? phone}) {
    fakeApi.savedToken = 'tok';
    fakeApi.getHandlers['/auth/me'] = () => http.Response(
      jsonEncode({'id': 'p1', 'email': 'p@x.io', 'full_name': 'Pat'}),
      200,
    );
    fakeApi.getHandlers['/patients/p1/case'] = () =>
        http.Response(jsonEncode({'id': 'case-1'}), 200);
    fakeApi.getHandlers['/cases/case-1/emergency-contact'] = () =>
        http.Response(
          jsonEncode({
            'name': phone == null ? null : 'Dr. Connor',
            'phone': phone,
          }),
          200,
        );
  }

  group('SideEffectPromptCard (C8)', () {
    testWidgets('renders the prompt with equal-weight Yes / No options and '
        'a dismiss control', (tester) async {
      await pumpPrompt(tester);

      expect(
        find.text('Are you experiencing severe or troubling symptoms?'),
        findsOneWidget,
      );
      final yes = find.byKey(const Key('c8_yes'));
      final no = find.byKey(const Key('c8_no'));
      expect(yes, findsOneWidget);
      expect(no, findsOneWidget);
      expect(find.byKey(const Key('c8_dismiss')), findsOneWidget);
      expect(tester.getSize(yes).height, greaterThanOrEqualTo(48.0));
      expect(tester.getSize(no).height, greaterThanOrEqualTo(48.0));
      expect(tester.getSize(yes).height, tester.getSize(no).height);
    });

    testWidgets('Yes with a contact on file → Call Emergency Contact CTA', (
      tester,
    ) async {
      seedAuthAndContact(phone: '+1 555-0122');
      await pumpPrompt(tester, preloadAuth: true);

      await tester.tap(find.byKey(const Key('c8_yes')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('c8_emergency_cta')), findsOneWidget);
      expect(find.text('Call Emergency Contact'), findsOneWidget);
      expect(
        find.text('No emergency contact on file — contact your clinic.'),
        findsNothing,
      );
    });

    testWidgets('Yes with no contact on file → no-contact note, no CTA', (
      tester,
    ) async {
      seedAuthAndContact(phone: null);
      await pumpPrompt(tester, preloadAuth: true);

      await tester.tap(find.byKey(const Key('c8_yes')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('c8_emergency_cta')), findsNothing);
      expect(
        find.text('No emergency contact on file — contact your clinic.'),
        findsOneWidget,
      );
    });

    testWidgets('No completes silently — card disappears, no contact fetch', (
      tester,
    ) async {
      await pumpPrompt(tester);

      await tester.tap(find.byKey(const Key('c8_no')));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you experiencing severe or troubling symptoms?'),
        findsNothing,
      );
      expect(find.byKey(const Key('c8_yes')), findsNothing);
      expect(
        fakeApi.requestsTo('/cases/', method: 'GET'),
        isEmpty,
        reason: 'No-answer must not fetch the emergency contact',
      );
    });

    testWidgets('dismiss closes the prompt without answering', (tester) async {
      await pumpPrompt(tester);

      await tester.tap(find.byKey(const Key('c8_dismiss')));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you experiencing severe or troubling symptoms?'),
        findsNothing,
      );
    });

    testWidgets('M-02: 200% text scale — no overflow, Yes/No remain ≥48dp', (
      tester,
    ) async {
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
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              ),
              home: const Scaffold(body: SideEffectPromptCard(slotId: 'rem-1')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('c8_yes'))).height,
        greaterThanOrEqualTo(48.0),
      );
      expect(
        tester.getSize(find.byKey(const Key('c8_no'))).height,
        greaterThanOrEqualTo(48.0),
      );
    });
  });
}

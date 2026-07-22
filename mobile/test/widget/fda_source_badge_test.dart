import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/today/fda_warning_card.dart';
import 'package:remotecare/features/today/today_screen.dart';

import '../unit/fake_api_service.dart';

Widget buildTestWidget(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

Widget buildTestAppWithApi(FakeApiService fakeApi, Widget child) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(fakeApi),
    ],
    child: buildTestWidget(child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FdaWarningCard Widget Tests', () {
    testWidgets('renders openFDA Live source badge and retrieved timestamp',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWidget(
          const Scaffold(
            body: FdaWarningCard(
              source: 'openFDA',
              retrievedAt: '2026-07-22',
              message: 'Live FDA Warning test text',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('📋 Source: openFDA Live'), findsOneWidget);
      expect(find.text('Retrieved: 2026-07-22'), findsOneWidget);
      expect(find.text('Live FDA Warning test text'), findsOneWidget);
    });

    testWidgets(
        'renders Regulatory Cache source badge and timestamp when source is fixture',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWidget(
          const Scaffold(
            body: FdaWarningCard(
              source: 'fixture',
              retrievedAt: '2026-07-22',
              message: 'Cached FDA Warning test text',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('📋 Source: Regulatory Cache'), findsOneWidget);
      expect(find.text('Retrieved: 2026-07-22'), findsOneWidget);
      expect(find.text('Cached FDA Warning test text'), findsOneWidget);
    });
  });

  group('TodayScreen FDA Source Badge Integration Tests', () {
    late FakeApiService fakeApi;

    setUp(() {
      fakeApi = FakeApiService();
    });

    testWidgets(
        'switches badge to openFDA Live state from mocked API response with source: live',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeApi.getHandlers['/fda/drug/Amoxicillin'] = () {
        return http.Response(
          jsonEncode({
            'source': 'live',
            'summary': 'Live warning summary',
            'retrieved_at': '2026-07-22',
          }),
          200,
        );
      };

      await tester.pumpWidget(buildTestAppWithApi(fakeApi, const TodayScreen()));
      await tester.pumpAndSettle();

      expect(find.text('📋 Source: openFDA Live'), findsOneWidget);
      expect(find.text('Retrieved: 2026-07-22'), findsOneWidget);
      expect(find.text('Live warning summary'), findsOneWidget);
    });

    testWidgets(
        'switches badge to Regulatory Cache state from mocked API response with source: fixture',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeApi.getHandlers['/fda/drug/Amoxicillin'] = () {
        return http.Response(
          jsonEncode({
            'source': 'fixture',
            'summary': 'Fixture warning summary',
            'retrieved_at': '2026-07-22',
          }),
          200,
        );
      };

      await tester.pumpWidget(buildTestAppWithApi(fakeApi, const TodayScreen()));
      await tester.pumpAndSettle();

      expect(find.text('📋 Source: Regulatory Cache'), findsOneWidget);
      expect(find.text('Retrieved: 2026-07-22'), findsOneWidget);
      expect(find.text('Fixture warning summary'), findsOneWidget);
    });
  });
}

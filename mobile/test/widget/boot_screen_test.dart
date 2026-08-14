import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/navigation/app_routes.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/auth_strings.dart';
import 'package:remotecare/features/auth/presentation/screens/boot_screen.dart';

import '../unit/fake_api_service.dart';

Widget buildTestApp(SharedPreferences prefs, FakeApiService fakeApi) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      apiServiceProvider.overrideWithValue(fakeApi),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, _) => const MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: BootScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeApiService fakeApi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
  });

  testWidgets(
    'BootScreen routes to Welcome when no token is stored',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.welcomeTitle), findsOneWidget);
    },
  );

  testWidgets(
    'BootScreen routes to Welcome when the stored JWT is invalid (401)',
    (WidgetTester tester) async {
      fakeApi.savedToken = 'jwt_expired';
      fakeApi.getHandlers['/auth/me'] = () =>
          http.Response(jsonEncode({'detail': 'Not authenticated'}), 401);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.welcomeTitle), findsOneWidget);
      // The invalid token is cleared so it is not retried on next boot.
      expect(fakeApi.savedToken, isNull);
    },
  );

  testWidgets(
    'BootScreen routes to the main app when the stored JWT is valid',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeApi.savedToken = 'jwt_valid';
      fakeApi.getHandlers['/auth/me'] = () => http.Response(
        jsonEncode({'id': 'user_1', 'email': 'jane@example.com'}),
        200,
      );
      fakeApi.getHandlers['/patients/user_1/case'] = () => http.Response(
        jsonEncode({'id': 'case_1', 'surgery_type': 'Knee Replacement'}),
        200,
      );

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      // Main shell reached (Today tab present); Welcome is not shown.
      expect(find.text(AuthStrings.welcomeTitle), findsNothing);
      expect(find.byKey(const Key('navTab_today')), findsOneWidget);
    },
  );
}

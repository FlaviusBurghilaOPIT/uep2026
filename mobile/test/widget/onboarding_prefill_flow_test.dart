import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/auth_strings.dart';
import 'package:remotecare/features/auth/presentation/screens/verify_code_screen.dart';

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
        home: VerifyCodeScreen(email: 'jane@example.com'),
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
    'first-run flow pre-fills name + DOB from the verify-code response',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // verify-code returns the onboarding result WITH the intake DOB (Gap 1).
      fakeApi.postHandlers['/auth/patient/verify-code'] = (body) => http.Response(
        jsonEncode({
          'result': 'onboarding',
          'email': 'jane@example.com',
          'full_name': 'Jane Doe',
          'date_of_birth': '1988-03-14',
        }),
        200,
      );

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      // Verify the code -> advances to the create-password step.
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.text(AuthStrings.verifyAndContinueButton));
      await tester.pumpAndSettle();
      expect(find.text(AuthStrings.createPasswordTitle), findsOneWidget);

      // Create password -> advances to the pre-filled profile step.
      await tester.enterText(find.byType(TextFormField).at(0), 'secret123');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.text(AuthStrings.continueButton));
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.profileTitle), findsOneWidget);
      // Name AND DOB are pre-filled from the backend response (not empty).
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('1988-03-14'), findsOneWidget);
    },
  );
}

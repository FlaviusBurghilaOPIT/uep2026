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
import 'package:remotecare/features/auth/presentation/screens/onboarding_profile_screen.dart';

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
        home: OnboardingProfileScreen(
          email: 'jane@example.com',
          inviteCode: '123456',
          fullName: 'Jane Doe',
          dateOfBirth: '1988-03-14',
        ),
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

  Future<void> pump(WidgetTester tester) async {
    // Phone-sized surface so Complete Setup is on-screen (ScreenUtil scales
    // the 375x812 design up; the default 800x600 surface clips the button).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildTestApp(prefs, fakeApi));
    await tester.pumpAndSettle();
  }

  testWidgets('pre-fills name and date of birth from the backend (editable)', (
    tester,
  ) async {
    await pump(tester);

    // Backend-sourced values are present in the editable fields.
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('1988-03-14'), findsOneWidget);
    // Three fields: name, DOB, phone.
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('phone is required (patient-provided)', (tester) async {
    await pump(tester);

    await tester.tap(find.text(AuthStrings.completeSetupButton));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.requiredError), findsOneWidget);
  });

  testWidgets(
    'persists the name edit, DOB edit, and phone via complete-onboarding',
    (tester) async {
      Map<String, dynamic>? captured;
      fakeApi.postHandlers['/auth/complete-onboarding'] = (body) {
        captured = body;
        return http.Response(jsonEncode({'access_token': 'jwt_onb'}), 200);
      };
      fakeApi.getHandlers['/auth/me'] = () => http.Response(
        jsonEncode({'id': 'user_1', 'email': 'jane@example.com'}),
        200,
      );
      fakeApi.getHandlers['/patients/user_1/case'] = () => http.Response(
        jsonEncode({'id': 'case_1', 'surgery_type': 'Knee Replacement'}),
        200,
      );

      await pump(tester);

      // Patient corrects the pre-filled name + DOB and supplies their phone.
      await tester.enterText(find.byType(TextFormField).at(0), 'Jane Smith');
      await tester.enterText(find.byType(TextFormField).at(1), '1990-05-20');
      await tester.enterText(find.byType(TextFormField).at(2), '+15550000000');
      await tester.tap(find.text(AuthStrings.completeSetupButton));
      await tester.pumpAndSettle();

      expect(captured?['email'], 'jane@example.com');
      expect(captured?['invite_code'], '123456');
      expect(captured?['full_name'], 'Jane Smith');
      expect(captured?['date_of_birth'], '1990-05-20');
      expect(captured?['phone'], '+15550000000');
      expect(captured?.containsKey('password'), false);
      expect(fakeApi.savedToken, 'jwt_onb');
      // Reached the main app.
      expect(find.byKey(const Key('navTab_today')), findsOneWidget);
    },
  );

  testWidgets('omits full_name when the pre-filled name is left unchanged', (
    tester,
  ) async {
    Map<String, dynamic>? captured;
    fakeApi.postHandlers['/auth/complete-onboarding'] = (body) {
      captured = body;
      return http.Response(jsonEncode({'access_token': 'jwt_onb'}), 200);
    };
    fakeApi.getHandlers['/auth/me'] = () => http.Response(
      jsonEncode({'id': 'user_1', 'email': 'jane@example.com'}),
      200,
    );
    fakeApi.getHandlers['/patients/user_1/case'] = () => http.Response(
      jsonEncode({'id': 'case_1', 'surgery_type': 'Knee Replacement'}),
      200,
    );

    await pump(tester);

    // Name (field 0) left as the pre-filled 'Jane Doe'; only phone supplied.
    await tester.enterText(find.byType(TextFormField).at(2), '+15550000000');
    await tester.tap(find.text(AuthStrings.completeSetupButton));
    await tester.pumpAndSettle();

    // Unchanged name is omitted so the backend preserves the intake value.
    expect(captured?.containsKey('full_name'), false);
    expect(captured?['phone'], '+15550000000');
  });
}

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
import 'package:remotecare/features/auth/presentation/screens/invitation_code_screen.dart';
import 'package:remotecare/features/auth/presentation/screens/welcome_screen.dart';

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
        home: WelcomeScreen(),
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
    'Welcome offers patient sign-in and clinic invitation',
    (tester) async {
      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.welcomeTitle), findsOneWidget);
      // Two TextFormFields: email + password.
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text(AuthStrings.signInButton), findsOneWidget);
      expect(find.text(AuthStrings.clinicInvitationButton), findsOneWidget);
    },
  );

  testWidgets('password sign-in success routes to the main app (Today)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? loginBody;
    fakeApi.postHandlers['/auth/login'] = (body) {
      loginBody = body;
      return http.Response(
        jsonEncode({'access_token': 'jwt_login', 'token_type': 'bearer'}),
        200,
      );
    };
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

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'jane@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text(AuthStrings.signInButton));
    await tester.pumpAndSettle();

    expect(loginBody?['email'], 'jane@example.com');
    expect(loginBody?['password'], 'secret123');
    expect(fakeApi.savedToken, 'jwt_login');
    expect(find.byKey(const Key('navTab_today')), findsOneWidget);
  });

  testWidgets(
    'password sign-in failure (401) shows an error and stays on Welcome',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeApi.postHandlers['/auth/login'] = (body) =>
          http.Response(jsonEncode({'detail': 'Invalid credentials'}), 401);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'jane@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text(AuthStrings.signInButton));
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.invalidCredentials), findsOneWidget);
      expect(find.text(AuthStrings.welcomeTitle), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the clinic invitation option opens InvitationCodeScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AuthStrings.clinicInvitationButton));
      await tester.pumpAndSettle();

      expect(find.byType(InvitationCodeScreen), findsOneWidget);
    },
  );
}

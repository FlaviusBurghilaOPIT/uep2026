import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
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
    'Welcome offers only the code-based invitation sign-in (no password)',
    (tester) async {
      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.welcomeTitle), findsOneWidget);
      // Patients are passwordless: only the email field, no password field.
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text(AuthStrings.clinicInvitationButton), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the invitation action opens InvitationCodeScreen with the entered email',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'jane@example.com',
      );
      await tester.tap(find.text(AuthStrings.clinicInvitationButton));
      await tester.pumpAndSettle();

      expect(find.byType(InvitationCodeScreen), findsOneWidget);
      final screen = tester.widget<InvitationCodeScreen>(
        find.byType(InvitationCodeScreen),
      );
      expect(screen.initialEmail, 'jane@example.com');
    },
  );

  testWidgets(
    'empty email is rejected and does not open InvitationCodeScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AuthStrings.clinicInvitationButton));
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.requiredError), findsOneWidget);
      expect(find.byType(InvitationCodeScreen), findsNothing);
    },
  );
}

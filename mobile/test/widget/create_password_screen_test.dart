import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/auth_strings.dart';
import 'package:remotecare/features/auth/presentation/screens/create_password_screen.dart';

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
        home: CreatePasswordScreen(
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
    // Phone-sized surface so the Continue button is on-screen (ScreenUtil
    // scales the 375x812 design up; the default 800x600 surface clips it).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildTestApp(prefs, fakeApi));
    await tester.pumpAndSettle();
  }

  testWidgets('rejects a password shorter than 8 characters', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'short');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text(AuthStrings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.passwordMinLengthError), findsOneWidget);
  });

  testWidgets('rejects mismatched confirmation', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(1), 'different1');
    await tester.tap(find.text(AuthStrings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.passwordMismatchError), findsOneWidget);
  });

  testWidgets(
    'accepts a valid password + confirmation and advances to the profile step',
    (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'secret123');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.text(AuthStrings.continueButton));
      await tester.pumpAndSettle();

      // Advanced to the onboarding profile step (pre-filled, editable).
      expect(find.text(AuthStrings.profileTitle), findsOneWidget);
    },
  );
}

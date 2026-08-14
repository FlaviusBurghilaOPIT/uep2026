import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/navigation/app_routes.dart';
import 'package:remotecare/features/auth/presentation/screens/otp_screen.dart';

Widget buildTestApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => const MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: OtpScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setupScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('OtpScreen renders UI correctly with fallback email text', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('Verify Identity'), findsOneWidget);
    expect(
      find.text('Please enter the 6-digit code sent to your email.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Verify and Log In'), findsOneWidget);
  });

  testWidgets('OtpScreen displays email dynamically when email is in state', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({'email': 'test@example.com'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter the 6-digit code sent to test@example.com.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'OtpScreen validates input length and numeric format (rejects signed/alpha inputs)',
    (WidgetTester tester) async {
      setupScreenSize(tester);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestApp(prefs));
      await tester.pumpAndSettle();

      // 1. Submit empty -> length error
      await tester.tap(find.text('Verify and Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Code must be exactly 6 digits'), findsOneWidget);

      // 2. Submit short code (e.g. 123) -> length error
      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Verify and Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Code must be exactly 6 digits'), findsOneWidget);

      // 3. Submit signed input (-12345) length 6 -> numeric error
      await tester.enterText(find.byType(TextFormField), '-12345');
      await tester.tap(find.text('Verify and Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Code must be numeric'), findsOneWidget);

      // 4. Submit signed input (+12345) length 6 -> numeric error
      await tester.enterText(find.byType(TextFormField), '+12345');
      await tester.tap(find.text('Verify and Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Code must be numeric'), findsOneWidget);
    },
  );

  testWidgets('OtpScreen submits valid 6-digit code and navigates to main', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({'email': 'user@example.com'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verify and Log In'));
    await tester.pumpAndSettle();

    // Verify validation errors are gone and navigation completed
    expect(find.text('Code must be exactly 6 digits'), findsNothing);
    expect(find.text('Code must be numeric'), findsNothing);
    expect(find.text('Verify Identity'), findsNothing);
  });
}

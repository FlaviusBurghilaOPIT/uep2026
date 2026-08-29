import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
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
      builder: (context, child) => const MaterialApp(
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
    expect(find.byType(TextFormField), findsNWidgets(6));
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
      await tester.tap(find.text('Verify and Log In'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Code must be exactly 6 digits'), findsOneWidget);

      // 2. Submit short code (e.g. 123) -> length error
      await tester.enterText(find.byType(TextFormField).first, '123');
      await tester.tap(find.text('Verify and Log In'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Code must be exactly 6 digits'), findsOneWidget);

      // 3. Submit signed input (-12345) length 6 -> numeric error
      await tester.enterText(find.byType(TextFormField).first, '-12345');
      await tester.tap(find.text('Verify and Log In'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Code must be numeric'), findsOneWidget);

      // 4. Submit signed input (+12345) length 6 -> numeric error
      await tester.enterText(find.byType(TextFormField).first, '+12345');
      await tester.tap(find.text('Verify and Log In'), warnIfMissed: false);
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

    await tester.enterText(find.byType(TextFormField).first, '123456');
    await tester.tap(find.text('Verify and Log In'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify validation errors are gone and navigation completed
    expect(find.text('Code must be exactly 6 digits'), findsNothing);
    expect(find.text('Code must be numeric'), findsNothing);
    expect(find.text('Verify Identity'), findsNothing);
  });

  testWidgets('OtpScreen auto-submits on 6th digit entry without tapping button', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({'email': 'user@example.com'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '654321');
    await tester.pumpAndSettle();

    expect(find.text('Verify Identity'), findsNothing);
  });

  testWidgets('OtpScreen auto-pastes and auto-submits 6-digit code from clipboard', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({'email': 'user@example.com'});
    final prefs = await SharedPreferences.getInstance();

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return {'text': '987654'};
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Verify Identity'), findsNothing);
  });

  testWidgets('OtpScreen OTP input field uses tabularFigures fontFeature', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    expect(textFields.length, equals(6));
    for (final textField in textFields) {
      expect(textField.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });

  testWidgets('OtpScreen typing digit auto-advances to next cell and backspace retreats', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    // Type '1' in first cell
    await tester.enterText(find.byType(TextFormField).at(0), '1');
    await tester.pump();

    // Focus should advance to cell 1 (second cell)
    // Type '2' in second cell
    await tester.enterText(find.byType(TextFormField).at(1), '2');
    await tester.pump();

    // Focus should advance to cell 2 (third cell)
    // Send backspace on empty cell 2
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    // Verify cell 1 was cleared
    final cell1 = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    expect(cell1.controller?.text, isEmpty);
  });

  testWidgets('OtpScreen pasting into any cell populates all 6 cells and auto-submits', (
    WidgetTester tester,
  ) async {
    setupScreenSize(tester);
    SharedPreferences.setMockInitialValues({'email': 'user@example.com'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    // Paste into cell at index 2
    await tester.enterText(find.byType(TextFormField).at(2), '543210');
    await tester.pumpAndSettle();

    expect(find.text('Verify Identity'), findsNothing);
  });

  testWidgets(
    'OtpScreen 60s countdown timer disables button, updates count, and re-enables upon reaching 0',
    (WidgetTester tester) async {
      setupScreenSize(tester);
      SharedPreferences.setMockInitialValues({'email': 'test@example.com'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestApp(prefs));
      await tester.pump();

      // Starts at 60s (disabled)
      expect(find.text('Resend Code in 60s'), findsOneWidget);
      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.onPressed, isNull);

      // Check tabular figures
      final textWidget = tester.widget<Text>(find.text('Resend Code in 60s'));
      expect(
        textWidget.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );

      // Advance 2 seconds -> 58s (disabled)
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Resend Code in 58s'), findsOneWidget);
      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);

      // Advance 58 seconds -> 0s (re-enables)
      await tester.pump(const Duration(seconds: 58));
      expect(find.text('Resend Code'), findsOneWidget);
      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNotNull);
    },
  );

  testWidgets(
    'OtpScreen tapping resend code restarts 60s cooldown timer and shows snackbar',
    (WidgetTester tester) async {
      setupScreenSize(tester);
      SharedPreferences.setMockInitialValues({'email': 'test@example.com'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestApp(prefs));
      await tester.pump();

      // Fast forward 60 seconds to enable button
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Resend Code'), findsOneWidget);

      // Tap Resend Code
      await tester.tap(find.text('Resend Code'));
      await tester.pump();

      // Cooldown restarts at 60s
      expect(find.text('Resend Code in 60s'), findsOneWidget);
      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);

      // Verify SnackBar
      expect(find.text('Code resent to test@example.com'), findsOneWidget);

      // Advance 2 seconds -> 58s
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Resend Code in 58s'), findsOneWidget);
    },
  );
}


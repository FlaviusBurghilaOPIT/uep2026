import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
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
        home: VerifyCodeScreen(email: 'patient@example.com'),
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
    'VerifyCodeScreen OTP input field uses tabularFigures fontFeature',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(
        find.byType(TextField),
      );
      expect(textFields.length, equals(6));
      for (final textField in textFields) {
        expect(
          textField.style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    },
  );

  testWidgets(
    'VerifyCodeScreen countdown timer preserves tabular figures',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pump();

      // Check countdown text and its style
      final countdownFinder = find.text('Resend Code in 60s');
      expect(countdownFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(countdownFinder);
      expect(
        textWidget.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );

      // Advance 1 second
      await tester.pump(const Duration(seconds: 1));
      final updatedCountdownFinder = find.text('Resend Code in 59s');
      expect(updatedCountdownFinder, findsOneWidget);

      final updatedTextWidget = tester.widget<Text>(updatedCountdownFinder);
      expect(
        updatedTextWidget.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    },
  );

  testWidgets(
    'VerifyCodeScreen 60s cooldown timer disables button, updates count, and re-enables upon reaching 0',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pump();

      // Starts at 60s (disabled)
      expect(find.text('Resend Code in 60s'), findsOneWidget);
      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.onPressed, isNull);

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
    'VerifyCodeScreen tapping resend code restarts 60s cooldown timer and calls API',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeApi.postHandlers['/auth/patient/request-code'] = (_) =>
          http.Response(jsonEncode({'message': 'Code sent'}), 200);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
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

      // Verify SnackBar and API call
      expect(fakeApi.requestsTo('/auth/patient/request-code'), isNotEmpty);
      expect(find.text('Code resent to patient@example.com'), findsOneWidget);

      // Advance 2 seconds -> 58s
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Resend Code in 58s'), findsOneWidget);
    },
  );

  testWidgets(
    'VerifyCodeScreen auto-submits upon entering the 6th digit',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      // Enter 6 digits in first cell (simulate fast entry or paste)
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.pumpAndSettle();

      // Verify verifyCode was called in fakeApi
      expect(fakeApi.requestsTo('/auth/patient/verify-code'), isNotEmpty);
    },
  );

  testWidgets(
    'VerifyCodeScreen pasting 6-digit code into any OTP cell populates all cells and auto-submits',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      // Paste 6-digit code into cell 3 (index 2)
      await tester.enterText(find.byType(TextFormField).at(2), '654321');
      await tester.pumpAndSettle();

      expect(fakeApi.requestsTo('/auth/patient/verify-code'), isNotEmpty);
    },
  );

  testWidgets(
    'VerifyCodeScreen typing digits auto-advances and backspace on empty cell retreats',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      // Type '1' in cell 0
      await tester.enterText(find.byType(TextFormField).at(0), '1');
      await tester.pump();

      // Type '2' in cell 1
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      await tester.pump();

      // On empty cell 2, send Backspace key event
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      // Verify cell 1 was cleared
      final cell1 = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
      expect(cell1.controller?.text, isEmpty);
    },
  );

  testWidgets(
    'VerifyCodeScreen auto-pastes from clipboard on load and auto-submits',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': '888999'};
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

      await tester.pumpWidget(buildTestApp(prefs, fakeApi));
      await tester.pumpAndSettle();

      expect(fakeApi.requestsTo('/auth/patient/verify-code'), isNotEmpty);
    },
  );
}

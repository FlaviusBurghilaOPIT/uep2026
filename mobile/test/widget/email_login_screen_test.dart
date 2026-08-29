import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remotecare/core/navigation/app_routes.dart';
import 'package:remotecare/features/auth/presentation/screens/email_login_screen.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';

Widget buildTestApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: EmailLoginScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EmailLoginScreen renders UI correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('EmailLoginScreen shows validation errors for invalid input', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    // Tap Send OTP with empty input
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);

    // Enter invalid email format
    await tester.enterText(find.byType(TextFormField), 'invalid-email');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('EmailLoginScreen triggers OTP and navigates on valid email', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    // Verify navigation to OTP screen
    expect(find.text('Enter OTP'), findsOneWidget);
  });

  testWidgets('EmailLoginScreen configures email input with no autocapitalization and no autocorrect', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    final editableText = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );

    expect(textField.keyboardType, TextInputType.emailAddress);
    expect(textField.autocorrect, isFalse);
    expect(textField.textCapitalization, TextCapitalization.none);
    expect(editableText.keyboardType, TextInputType.emailAddress);
    expect(editableText.autocorrect, isFalse);
    expect(editableText.textCapitalization, TextCapitalization.none);
  });
}

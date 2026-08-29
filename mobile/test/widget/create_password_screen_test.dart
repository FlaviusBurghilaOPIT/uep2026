import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remotecare/core/constants/app_colors.dart';
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

  testWidgets('displays all 5 password requirements beneath the password field',
      (tester) async {
    await pump(tester);

    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(find.text('Uppercase letter'), findsOneWidget);
    expect(find.text('Lowercase letter'), findsOneWidget);
    expect(find.text('Number'), findsOneWidget);
    expect(find.text('Special character'), findsOneWidget);

    // Initially, all criteria are unsatisfied (5 unchecked radio/circle icons)
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // Submit button is disabled initially
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'dynamically turns green with a checkmark when each requirement is satisfied',
      (tester) async {
    await pump(tester);

    final passwordField = find.byType(TextFormField).at(0);

    // 1. Enter lowercase letter only
    await tester.enterText(passwordField, 'abc');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(1));

    // 2. Add uppercase letter
    await tester.enterText(passwordField, 'abcA');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

    // 3. Add number
    await tester.enterText(passwordField, 'abcA1');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));

    // 4. Add special character
    await tester.enterText(passwordField, 'abcA1!');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));

    // Still less than 8 characters -> button still disabled
    var button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    // 5. Expand to at least 8 characters
    await tester.enterText(passwordField, 'Secret1!');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);

    // Verify all checkmark icons have primary green color
    final iconWidgets = tester.widgetList<Icon>(find.byIcon(Icons.check_circle));
    for (final icon in iconWidgets) {
      expect(icon.color, AppColors.primaryGreen);
    }

    // Submit button is now enabled
    button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('submit button is disabled until all criteria are satisfied',
      (tester) async {
    await pump(tester);

    final passwordField = find.byType(TextFormField).at(0);

    // Meets 4 out of 5 criteria (no special character)
    await tester.enterText(passwordField, 'Password123');
    await tester.pump();

    var button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    // Add special character -> all 5 met -> button enabled
    await tester.enterText(passwordField, 'Password123!');
    await tester.pump();

    button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('renders segmented strength bar with 3 inactive segments initially',
      (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('strength_segment_0')), findsOneWidget);
    expect(find.byKey(const Key('strength_segment_1')), findsOneWidget);
    expect(find.byKey(const Key('strength_segment_2')), findsOneWidget);

    // No strength label shown when empty
    expect(find.byKey(const Key('strength_label')), findsNothing);

    // Confirmation field is disabled initially
    final confirmField = tester.widget<TextFormField>(find.descendant(
      of: find.byKey(const Key('confirm_password_field')),
      matching: find.byType(TextFormField),
    ));
    expect(confirmField.enabled, isFalse);
  });

  testWidgets(
      'progressively updates segmented bar fill, color, and labels (Weak, Medium, Strong)',
      (tester) async {
    await pump(tester);

    final passwordField = find.byType(TextFormField).at(0);

    // 1. Weak strength (1-2 criteria satisfied, e.g. "abc" = lowercase only)
    await tester.enterText(passwordField, 'abc');
    await tester.pump();

    expect(find.text('Weak'), findsOneWidget);
    final labelWeak =
        tester.widget<Text>(find.byKey(const Key('strength_label')));
    expect(labelWeak.style?.color, AppColors.errorRed);

    var segment0 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_0')));
    var segment1 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_1')));
    var segment2 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_2')));
    expect((segment0.decoration as BoxDecoration).color, AppColors.errorRed);
    expect((segment1.decoration as BoxDecoration).color, AppColors.greyDivider);
    expect((segment2.decoration as BoxDecoration).color, AppColors.greyDivider);

    // Confirmation field is still disabled
    var confirmField = tester.widget<TextFormField>(find.descendant(
      of: find.byKey(const Key('confirm_password_field')),
      matching: find.byType(TextFormField),
    ));
    expect(confirmField.enabled, isFalse);

    // 2. Medium strength (3-4 criteria satisfied, e.g. "abcA1" = lower, upper, number)
    await tester.enterText(passwordField, 'abcA1');
    await tester.pump();

    expect(find.text('Medium'), findsOneWidget);
    final labelMedium =
        tester.widget<Text>(find.byKey(const Key('strength_label')));
    expect(labelMedium.style?.color, AppColors.warningAmber);

    segment0 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_0')));
    segment1 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_1')));
    segment2 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_2')));
    expect((segment0.decoration as BoxDecoration).color, AppColors.warningAmber);
    expect((segment1.decoration as BoxDecoration).color, AppColors.warningAmber);
    expect((segment2.decoration as BoxDecoration).color, AppColors.greyDivider);

    // Confirmation field is still disabled
    confirmField = tester.widget<TextFormField>(find.descendant(
      of: find.byKey(const Key('confirm_password_field')),
      matching: find.byType(TextFormField),
    ));
    expect(confirmField.enabled, isFalse);

    // 3. Strong strength (all 5 criteria satisfied: "Secret1!")
    await tester.enterText(passwordField, 'Secret1!');
    await tester.pump();

    expect(find.text('Strong'), findsOneWidget);
    final labelStrong =
        tester.widget<Text>(find.byKey(const Key('strength_label')));
    expect(labelStrong.style?.color, AppColors.primaryGreen);

    segment0 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_0')));
    segment1 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_1')));
    segment2 =
        tester.widget<Container>(find.byKey(const Key('strength_segment_2')));
    expect((segment0.decoration as BoxDecoration).color, AppColors.primaryGreen);
    expect((segment1.decoration as BoxDecoration).color, AppColors.primaryGreen);
    expect((segment2.decoration as BoxDecoration).color, AppColors.primaryGreen);

    // Confirmation field is now enabled!
    confirmField = tester.widget<TextFormField>(find.descendant(
      of: find.byKey(const Key('confirm_password_field')),
      matching: find.byType(TextFormField),
    ));
    expect(confirmField.enabled, isTrue);

    // 4. Degrade back to Weak -> Confirmation field disabled again
    await tester.enterText(passwordField, 'abc');
    await tester.pump();

    confirmField = tester.widget<TextFormField>(find.descendant(
      of: find.byKey(const Key('confirm_password_field')),
      matching: find.byType(TextFormField),
    ));
    expect(confirmField.enabled, isFalse);
  });

  testWidgets('rejects mismatched confirmation', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Secret123!');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), 'Different1!');
    await tester.pump();

    await tester.tap(find.text(AuthStrings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.passwordMismatchError), findsOneWidget);
  });

  testWidgets(
    'accepts a valid password + confirmation and advances to the profile step',
    (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Secret123!');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(1), 'Secret123!');
      await tester.pump();

      await tester.tap(find.text(AuthStrings.continueButton));
      await tester.pumpAndSettle();

      // Advanced to the onboarding profile step (pre-filled, editable).
      expect(find.text(AuthStrings.profileTitle), findsOneWidget);
    },
  );
}

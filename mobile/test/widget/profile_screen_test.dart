import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/notifications/notification_prefs_keys.dart';
import 'package:remotecare/core/notifications/notification_scheduler.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/providers/auth_provider.dart';
import 'package:remotecare/features/profile/presentation/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';
import '../unit/fake_notification_scheduler.dart';

// WI 06 / spec Req 20–25: Profile cleanup — removed dead rows/bell, real
// /auth/me + case data or honest absence, editable personal info via
// PATCH /auth/me, change-password flow, and persisted notification toggles
// gated on OS permission.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late FakeNotificationScheduler scheduler;
  late SharedPreferences prefs;

  /// Mutable /auth/me payload — the PATCH handler writes into it so the
  /// post-save refresh renders server truth.
  late Map<String, dynamic> meBody;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
    scheduler = FakeNotificationScheduler();
    meBody = {
      'id': 'p1',
      'email': 'pat@example.com',
      'full_name': 'Pat Doe',
      'phone': '+39 333 1234567',
      'date_of_birth': '1988-03-14',
      'has_password': false,
    };
    fakeApi.getHandlers['/auth/me'] = () =>
        http.Response(jsonEncode(meBody), 200);
    // Auth bootstrap reads the case id through the generic GET seam.
    fakeApi.getHandlers['/patients/p1/case'] = () =>
        http.Response(jsonEncode({'id': 'case-1'}), 200);
    // The Profile treatment-plan section reads the typed getPatientCase seam.
    fakeApi.caseHandler = (patientId) => http.Response(
      jsonEncode({
        'id': 'case-1',
        'patient_id': 'p1',
        'surgery_type': 'Hip Replacement',
        'surgery_date': '2026-06-18',
      }),
      200,
    );
    fakeApi.profileUpdateHandler = (body) {
      meBody = {...meBody, ...body};
      return http.Response(jsonEncode(meBody), 200);
    };
  });

  Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);

    // Sign the fake patient in BEFORE the screen mounts (boot ordering).
    await container.read(authProvider.notifier).fetchProfile();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('Req 20/24 — dead controls removed', () {
    testWidgets('2FA, connected devices, bell, FDA toggle, invite code gone', (
      tester,
    ) async {
      await pumpProfile(tester);

      expect(find.text('Two-factor authentication'), findsNothing);
      expect(find.text('Connected devices'), findsNothing);
      expect(find.text('FDA safety alerts'), findsNothing);
      expect(find.text('Invite code'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.text('Sarah Mitchell · Post-op'), findsNothing);
    });
  });

  group('Req 22/23 — real data, no fabrications', () {
    testWidgets('renders /auth/me personal info and case treatment plan', (
      tester,
    ) async {
      await pumpProfile(tester);

      expect(find.text('Pat Doe'), findsWidgets);
      expect(find.text('pat@example.com'), findsWidgets);
      expect(find.text('+39 333 1234567'), findsOneWidget);
      expect(find.text('Mar 14, 1988'), findsOneWidget);
      expect(find.text('Hip Replacement'), findsOneWidget);
      expect(find.text('Jun 18, 2026'), findsOneWidget);

      // None of the old hardcoded fallbacks survive.
      expect(find.text('Sarah Mitchell'), findsNothing);
      expect(find.text('sarah.mitchell@email.com'), findsNothing);
      expect(find.text('+1 (555) 248-3901'), findsNothing);
      expect(find.text('Dr. Claire Moreau'), findsNothing);
      expect(find.text('RC-4827-XK'), findsNothing);
      expect(find.text('Post-surgical recovery'), findsNothing);
    });

    testWidgets('null phone/DOB render honest absence, not fallbacks', (
      tester,
    ) async {
      meBody.remove('phone');
      meBody.remove('date_of_birth');

      await pumpProfile(tester);

      expect(find.text('Not provided'), findsWidgets);
      expect(find.text('+1 (555) 248-3901'), findsNothing);
    });

    testWidgets('no case → treatment plan shows honest absence', (
      tester,
    ) async {
      fakeApi.caseHandler = (patientId) =>
          http.Response(jsonEncode({'detail': 'Not found'}), 404);

      await pumpProfile(tester);

      expect(find.byKey(const Key('profile_treatment_empty')), findsOneWidget);
      expect(find.text('Hip Replacement'), findsNothing);
      expect(find.text('Knee Arthroscopy'), findsNothing);
    });
  });

  group('Req 23 — editable personal info', () {
    testWidgets('full edit flow via row tap', (tester) async {
      final container = await pumpProfile(tester);

      await tester.tap(find.text('Pat Doe').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_field_full_name')),
        'Pat Smith',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final patch = fakeApi.requestsTo('/auth/me', method: 'PATCH').single;
      expect(patch['body'], {'full_name': 'Pat Smith'});
      expect(container.read(authProvider).fullName, 'Pat Smith');
      expect(find.text('Pat Smith'), findsWidgets);
    });

    testWidgets('edit failure shows honest error and keeps old value', (
      tester,
    ) async {
      fakeApi.profileUpdateHandler = (body) =>
          http.Response(jsonEncode({'detail': 'boom'}), 500);
      await pumpProfile(tester);

      await tester.tap(find.text('+39 333 1234567'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit_field_phone')),
        '+39 000',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_field_error')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('+39 333 1234567'), findsOneWidget);
    });

    testWidgets('email stays read-only (no edit affordance)', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text('pat@example.com').last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('Req 25 — notification toggles', () {
    testWidgets('toggling med reminders persists + cancels scheduled', (
      tester,
    ) async {
      await pumpProfile(tester);

      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(prefs.getBool(NotificationPrefsKeys.medReminders), false);
      expect(scheduler.cancelAllCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('toggling daily check-in persists', (tester) async {
      await pumpProfile(tester);

      await tester.ensureVisible(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      expect(prefs.getBool(NotificationPrefsKeys.dailyCheckin), false);
    });

    testWidgets('enabling is inert while OS permission is denied', (
      tester,
    ) async {
      await prefs.setBool(NotificationPrefsKeys.medReminders, false);
      scheduler.granted = false;
      await pumpProfile(tester);

      // The switch starts off (persisted); trying to enable does nothing.
      final switchBefore = tester.widget<Switch>(find.byType(Switch).first);
      expect(switchBefore.value, false);

      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final switchAfter = tester.widget<Switch>(find.byType(Switch).first);
      expect(switchAfter.value, false);
      expect(prefs.getBool(NotificationPrefsKeys.medReminders), false);
    });
  });

  group('FORM-05 / Req 9 (US4) — phone input cursor & E.164 mask', () {
    testWidgets(
      'focusing phone number input places cursor at end of text and prevents jumping to 0',
      (tester) async {
        await pumpProfile(tester);

        await tester.tap(find.text('+39 333 1234567'));
        await tester.pumpAndSettle();

        final textFieldFinder = find.byKey(const Key('edit_field_phone'));
        expect(textFieldFinder, findsOneWidget);
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(
          textField.controller?.selection.baseOffset,
          textField.controller?.text.length,
        );
        expect(textField.controller?.selection.baseOffset, isNot(0));

        // Unfocus the field
        textField.focusNode?.unfocus();
        await tester.pumpAndSettle();

        // Re-focus the field and verify cursor is preserved at the end of text (not jumping to 0)
        textField.focusNode?.requestFocus();
        await tester.pumpAndSettle();

        expect(
          textField.controller?.selection.baseOffset,
          textField.controller?.text.length,
        );
        expect(textField.controller?.selection.baseOffset, isNot(0));
      },
    );

    testWidgets(
      'formats telephone input according to standard E.164 telecommunication mask',
      (tester) async {
        final container = await pumpProfile(tester);

        await tester.tap(find.text('+39 333 1234567'));
        await tester.pumpAndSettle();

        final textFieldFinder = find.byKey(const Key('edit_field_phone'));
        await tester.enterText(textFieldFinder, '15552483901');
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.controller?.text, '+1 555 248 3901');

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final patch = fakeApi.requestsTo('/auth/me', method: 'PATCH').single;
        expect(patch['body'], {'phone': '+1 555 248 3901'});
        expect(container.read(authProvider).phone, '+1 555 248 3901');
      },
    );
  });

  group('VIS-02 / Req 15 (US4) — 48x48dp touch target expansion', () {
    testWidgets(
      'interactive settings rows and chevrons measure at least 48x48dp with opaque hit testing',
      (tester) async {
        await pumpProfile(tester);

        // Back button target is at least 48x48dp
        final backIcon = find.byIcon(Icons.arrow_back);
        expect(backIcon, findsOneWidget);
        final backGesture = find
            .ancestor(
              of: backIcon,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is GestureDetector &&
                    w.behavior == HitTestBehavior.opaque,
              ),
            )
            .first;
        final backSize = tester.getSize(backGesture);
        expect(backSize.width, greaterThanOrEqualTo(48.0));
        expect(backSize.height, greaterThanOrEqualTo(48.0));

        // Edit icons on editable rows measure at least 48x48dp
        final editIcons = find.byIcon(Icons.edit_outlined);
        expect(editIcons, findsWidgets);
        for (var i = 0; i < editIcons.evaluate().length; i++) {
          final editIcon = editIcons.at(i);
          final editContainer = find
              .ancestor(of: editIcon, matching: find.byType(Container))
              .first;
          final editSize = tester.getSize(editContainer);
          expect(editSize.width, greaterThanOrEqualTo(48.0));
          expect(editSize.height, greaterThanOrEqualTo(48.0));
        }

        // Language selected check icon measures at least 48x48dp
        final checkIcon = find.byIcon(Icons.check);
        expect(checkIcon, findsOneWidget);
        final checkContainer = find
            .ancestor(of: checkIcon, matching: find.byType(Container))
            .first;
        final checkSize = tester.getSize(checkContainer);
        expect(checkSize.width, greaterThanOrEqualTo(48.0));
        expect(checkSize.height, greaterThanOrEqualTo(48.0));

        // Switch containers measure at least 48x48dp
        final switches = find.byType(Switch);
        expect(switches, findsWidgets);
        for (var i = 0; i < switches.evaluate().length; i++) {
          final sw = switches.at(i);
          final swContainer = find
              .ancestor(of: sw, matching: find.byType(Container))
              .first;
          final swSize = tester.getSize(swContainer);
          expect(swSize.width, greaterThanOrEqualTo(48.0));
          expect(swSize.height, greaterThanOrEqualTo(48.0));
        }

        // Verify row heights are all >= 48dp with HitTestBehavior.opaque
        for (final text in [
          'Full name',
          'Phone',
          'Date of birth',
          'English',
          'Medication reminders',
          'Daily check-in',
        ]) {
          final rowText = find.text(text);
          final rowGesture = find
              .ancestor(
                of: rowText,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is GestureDetector &&
                      w.behavior == HitTestBehavior.opaque,
                ),
              )
              .first;
          final rowSize = tester.getSize(rowGesture);
          expect(
            rowSize.height,
            greaterThanOrEqualTo(48.0),
            reason: '$text row height should be >= 48dp',
          );
        }
      },
    );
  });
}

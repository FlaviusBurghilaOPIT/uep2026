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

  group('Req 21 — change password', () {
    testWidgets('code-only patient: no current-password field, sets password', (
      tester,
    ) async {
      fakeApi.changePasswordHandler = (body) =>
          http.Response(jsonEncode({'message': 'Password updated'}), 200);
      final container = await pumpProfile(tester);

      await tester.ensureVisible(find.text('Change password'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('current_password_field')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'brandnewpassword',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'brandnewpassword',
      );
      await tester.tap(find.byKey(const Key('change_password_submit')));
      await tester.pumpAndSettle();

      final posts = fakeApi.requestsTo('/auth/change-password').single;
      expect(posts['body'], {'new_password': 'brandnewpassword'});
      expect(find.text('Password updated'), findsOneWidget);
      expect(container.read(authProvider).hasPassword, true);
    });

    testWidgets('validation: too short and mismatched passwords rejected', (
      tester,
    ) async {
      await pumpProfile(tester);

      await tester.ensureVisible(find.text('Change password'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'short',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'short',
      );
      await tester.tap(find.byKey(const Key('change_password_submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('at least 8 characters'), findsOneWidget);
      expect(fakeApi.requestsTo('/auth/change-password'), isEmpty);

      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'longenoughpassword',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'differentpassword',
      );
      await tester.tap(find.byKey(const Key('change_password_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(fakeApi.requestsTo('/auth/change-password'), isEmpty);
    });

    testWidgets(
      'patient with password: current required, backend error surfaced',
      (tester) async {
        meBody['has_password'] = true;
        fakeApi.changePasswordHandler = (body) {
          if (body['current_password'] == 'correcthorse') {
            return http.Response(jsonEncode({'message': 'Password updated'}), 200);
          }
          return http.Response(
            jsonEncode({'detail': 'Current password is incorrect'}),
            400,
          );
        };
        await pumpProfile(tester);

        await tester.ensureVisible(find.text('Change password'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change password'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('current_password_field')),
          findsOneWidget,
        );

        // Wrong current password → backend detail shown, dialog stays open.
        await tester.enterText(
          find.byKey(const Key('current_password_field')),
          'wrong',
        );
        await tester.enterText(
          find.byKey(const Key('new_password_field')),
          'brandnewpassword',
        );
        await tester.enterText(
          find.byKey(const Key('confirm_password_field')),
          'brandnewpassword',
        );
        await tester.tap(find.byKey(const Key('change_password_submit')));
        await tester.pumpAndSettle();
        expect(find.text('Current password is incorrect'), findsOneWidget);

        // Correct current password → success.
        await tester.enterText(
          find.byKey(const Key('current_password_field')),
          'correcthorse',
        );
        await tester.tap(find.byKey(const Key('change_password_submit')));
        await tester.pumpAndSettle();
        expect(find.text('Password updated'), findsOneWidget);
        final posts = fakeApi.requestsTo('/auth/change-password').last;
        expect(posts['body'], {
          'new_password': 'brandnewpassword',
          'current_password': 'correcthorse',
        });
      },
    );
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
}

// Live-backend integration test for the mobile "golden loop".
//
// Requires the real FastAPI backend running at http://localhost:8000 (or
// 10.0.2.2:8000 on Android), seeded via
// `docker-compose exec backend python app/scripts/seed_data.py` per the
// project README. This exercises the real network stack end to end — it is
// not a substitute for the mocked unit/widget suite in test/.
//
// WI 04 (hybrid auth): the patient now signs in from the Welcome screen,
// which offers email+password (primary) and an emailed one-time code
// (fallback). Test 1 keeps the original golden loop (Assistant guardrail +
// dose logging) and signs the seeded active patient in via the code fallback
// (fixed dry-run code 424242 from seed_data.py). Test 2 (added by WI 04,
// clearly delimited below) covers the first-run hybrid path: an invited
// patient verifies by code, CREATES A PASSWORD, completes pre-filled
// onboarding, then signs out and re-logs in with that password.
//
// NOTE on codes: `request-code` re-issues a fresh 6-digit code that the
// backend emails (dry-run logs it server-side). These tests enter the KNOWN
// code at the verify step (the seeded 424242 for the active patient; the
// invite_code returned by POST /patients/invite for the invited patient —
// the documented fallback channel). Running them against a live backend
// therefore assumes that known code is honored at verify time.
//
// Assistant runs before dose logging deliberately: logging a dose shows a
// "Logged as ... Undo" SnackBar hosted by the root ScaffoldMessenger, which
// stays mounted across IndexedStack tabs and visually overlaps the bottom
// input row on every tab for its full duration — including a pre-existing
// overflow bug in its content Row that throws during disposal. Running the
// chat interactions first avoids fighting that entirely; dose logging is
// last and doesn't need further taps afterward.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remotecare/main.dart' as app;
import 'package:remotecare/core/config/app_config.dart';
import 'package:remotecare/features/auth/presentation/auth_strings.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Signs the seeded active patient in via the Welcome screen's code fallback.
/// Real network: POST /auth/patient/request-code, POST /auth/patient/verify-code,
/// GET /auth/me, GET /patients/{id}/case.
Future<void> signInWithCode(WidgetTester tester, {required String code}) async {
  await pumpUntilFound(tester, find.text(AuthStrings.welcomeTitle));

  // Fallback method: "Email me a one-time code".
  await tester.tap(find.text(AuthStrings.codeSignInLink));
  await tester.pumpAndSettle();

  await pumpUntilFound(tester, find.text(AuthStrings.requestCodeTitle));
  await tester.enterText(
    find.byType(TextFormField).first,
    'patient@example.com',
  );
  await tester.tap(find.text(AuthStrings.sendCodeButton));
  await tester.pumpAndSettle();

  await pumpUntilFound(tester, find.text(AuthStrings.verifyCodeTitle));
  await tester.enterText(find.byType(TextFormField).first, code);
  await tester.tap(find.text(AuthStrings.verifyAndContinueButton));

  // Lands on Today (the English `doseStatusTaken` ARB value rendered by the
  // WI 12 DoseSlotCard action row — this test runs in 'en').
  await pumpUntilFound(tester, find.text('Taken'));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'golden loop: patient login -> AI assistant guardrail -> log a dose',
    (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // --- Welcome -> sign in with the seeded patient's code (fallback) ---
      await signInWithCode(tester, code: '424242');

      // --- Assistant: in-scope question gets a real (mock-provider) reply ---
      await tester.tap(find.text('Assistant'));
      await tester.pumpAndSettle();

      final chatInput = find.byType(TextField);
      expect(chatInput, findsOneWidget);
      await tester.tap(chatInput);
      await tester.pump();
      await tester.enterText(chatInput, 'When should I take my medication?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await pumpUntilFound(tester, find.textContaining('mock AI response'));
      expect(find.byKey(const Key('refusal_box')), findsNothing);

      // --- Assistant: out-of-scope dose-change request is blocked ---
      // Client-side _classifyIntent() tags this dose_change_request; the
      // backend's IntentCategory guardrail (language-agnostic) blocks it
      // regardless of the mock LLM provider.
      //
      // Re-tap the field before entering text again: tapping Send moved
      // focus away from the TextField, but WidgetTester.enterText() skips
      // re-requesting focus/keyboard when the target EditableTextState is
      // unchanged from its last-focused instance, so it silently no-ops on
      // a stale text-input connection without an explicit tap to refocus.
      await tester.tap(chatInput);
      await tester.pump();
      await tester.enterText(chatInput, 'Can I take a double dose?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await pumpUntilFound(tester, find.byKey(const Key('refusal_box')));
      expect(find.byKey(const Key('emergency_cta_button')), findsOneWidget);

      // --- Today: log a dose against the live backend ---
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      final takenAction = find.text('Taken').first;
      await tester.ensureVisible(takenAction);
      await tester.pumpAndSettle();
      await tester.tap(takenAction);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Logged as'));

      // The SnackBar is optimistic UI; the real /adherence/log POST fires
      // from a 5s background Timer. Wait for it so the commit is real by
      // the time the test (and app process) ends.
      await tester.pump(const Duration(seconds: 6));
    },
  );

  // ===========================================================================
  // WI 04 — hybrid auth addition (self-contained; keep delimited so WI 05
  // Recovery can extend this file afterwards without conflicts).
  //
  // Invited patient -> verify by code -> CREATE PASSWORD -> pre-filled
  // onboarding (name/DOB from backend, patient phone) -> Today -> sign out ->
  // re-login with the new password -> Today.
  // ===========================================================================
  testWidgets(
    'hybrid auth: invited patient sets a password then re-logs in with it',
    (tester) async {
      // Clean slate: drop any token persisted by the previous test so boot
      // routes to Welcome instead of auto-signing in.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // --- Arrange: create an invited (pending_onboarding) patient directly
      // against the backend so this test is self-contained (no seed change). ---
      const email = 'invited.patient@example.com';
      const password = 'password123';
      final inviteCode = await _createInvitedPatient(
        email: email,
        fullName: 'Invited Patient',
      );

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // --- Welcome -> code fallback -> verify (onboarding) ---
      await pumpUntilFound(tester, find.text(AuthStrings.welcomeTitle));
      await tester.tap(find.text(AuthStrings.codeSignInLink));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.text(AuthStrings.requestCodeTitle));
      await tester.enterText(find.byType(TextFormField).first, email);
      await tester.tap(find.text(AuthStrings.sendCodeButton));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.text(AuthStrings.verifyCodeTitle));
      await tester.enterText(find.byType(TextFormField).first, inviteCode);
      await tester.tap(find.text(AuthStrings.verifyAndContinueButton));
      await tester.pumpAndSettle();

      // --- First-run CREATE PASSWORD step (min 8 + confirmation) ---
      await pumpUntilFound(tester, find.text(AuthStrings.createPasswordTitle));
      await tester.enterText(find.byType(TextFormField).at(0), password);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.tap(find.text(AuthStrings.continueButton));
      await tester.pumpAndSettle();

      // --- Pre-filled editable profile (name from backend) + patient phone ---
      await pumpUntilFound(tester, find.text(AuthStrings.profileTitle));
      // Name (field 0) is pre-filled with 'Invited Patient'; DOB (field 1) is
      // pre-filled when the backend surfaces it; phone (field 2) is required.
      expect(find.text('Invited Patient'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), '+15550000000');
      await tester.tap(find.text(AuthStrings.completeSetupButton));

      // complete-onboarding (sends the password) -> main app.
      await pumpUntilFound(tester, find.text('Today'));
      await tester.pumpAndSettle();

      // --- Sign out, then re-login with the password just created ---
      await tester.tap(find.byKey(const Key('navTab_profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Boot clears the token and routes back to Welcome.
      await pumpUntilFound(tester, find.text(AuthStrings.welcomeTitle));
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.tap(find.text(AuthStrings.signInButton));
      await tester.pumpAndSettle();

      // POST /auth/login (email+password) succeeds -> Today.
      await pumpUntilFound(tester, find.text('Today'));
    },
  );
}

/// Creates a pending_onboarding patient via the clinician invite endpoint and
/// returns the generated invite_code (a 6-digit code, also emailed to the
/// patient). Self-contained test setup against the live backend.
Future<String> _createInvitedPatient({
  required String email,
  required String fullName,
}) async {
  final base = AppConfig.baseUrl;

  // Clinician sign-in (seeded clinician; /auth/dev-login returns a token).
  final loginRes = await http.post(
    Uri.parse('$base/auth/dev-login'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'clinician@example.com',
      'password': 'password123',
    }),
  );
  final token = jsonDecode(loginRes.body)['access_token'] as String;

  // Create the patient invite (date_of_birth required at intake per WI 02).
  final inviteRes = await http.post(
    Uri.parse('$base/patients/invite'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'email': email,
      'full_name': fullName,
      'surgery_type': 'Total Knee Arthroplasty (TKA)',
      'date_of_birth': '1990-01-01',
    }),
  );
  return jsonDecode(inviteRes.body)['invite_code'] as String;
}

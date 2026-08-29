// Live-backend integration test for the mobile "golden loop".
//
// Requires the real FastAPI backend running at http://localhost:8000 (or
// 10.0.2.2:8000 on Android), seeded via
// `docker compose exec backend python app/scripts/seed_data.py` per the
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
import 'package:remotecare/features/assistant/presentation/screens/assistant_screen.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
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

  // Disambiguated sign-in method: "Sign in with One-Time Code".
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
  final fields = find.byType(TextField);
  for (var i = 0; i < code.length && i < 6; i++) {
    await tester.enterText(fields.at(i), code[i]);
    await tester.pump();
  }
  final verifyBtn = find.text(AuthStrings.verifyAndContinueButton);
  if (verifyBtn.evaluate().isNotEmpty) {
    await tester.tap(verifyBtn);
    await tester.pump();
  }

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

      await pumpUntilFound(
        tester,
        find.byWidgetPredicate((w) => w is ChatBubble && !w.message.isFromUser),
      );
      expect(find.byKey(const Key('refusal_box')), findsNothing);
      await tester.pump(const Duration(seconds: 4));

      // --- Assistant: out-of-scope dose-change request is blocked ---
      await tester.tap(chatInput);
      await tester.pump();
      await tester.enterText(chatInput, 'Can I take a double dose?');
      await tester.pump(const Duration(milliseconds: 500));
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
      // against the backend so this test is self-contained (no seed change).
      // WI 05: the invite carries a surgery_date 10 days back ("Day 11" on
      // the Recovery screen) and the clinician authors one recommendation,
      // so Recovery has real server data to render after the password login.
      final email = 'invited.patient.${DateTime.now().millisecondsSinceEpoch}@example.com';
      const password = 'Password123!';
      const surgeryType = 'Total Knee Arthroplasty (TKA)';
      const recommendationText = 'Keep the wound clean and dry';
      final surgeryDate = DateTime.now().subtract(const Duration(days: 10));
      final surgeryDateIso =
          '${surgeryDate.year}-'
          '${surgeryDate.month.toString().padLeft(2, '0')}-'
          '${surgeryDate.day.toString().padLeft(2, '0')}';
      final invite = await _createInvitedPatient(
        email: email,
        fullName: 'Invited Patient',
        surgeryDate: surgeryDateIso,
        recommendationText: recommendationText,
      );
      final inviteCode = invite.inviteCode;

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
      final otpFields = find.byType(TextField);
      for (var i = 0; i < inviteCode.length && i < 6; i++) {
        await tester.enterText(otpFields.at(i), inviteCode[i]);
        await tester.pump();
      }
      final verifyBtn = find.text(AuthStrings.verifyAndContinueButton);
      if (verifyBtn.evaluate().isNotEmpty) {
        await tester.tap(verifyBtn);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // --- First-run CREATE PASSWORD step (min 8 + confirmation) ---
      await pumpUntilFound(tester, find.text(AuthStrings.createPasswordTitle));
      await tester.enterText(find.byType(TextFormField).first, password);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, password);
      await tester.pumpAndSettle();

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
      final signOutFinder = find.text('Sign Out');
      await tester.ensureVisible(signOutFinder);
      await tester.pumpAndSettle();
      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      // Boot clears the token and routes back to Welcome.
      await pumpUntilFound(tester, find.text(AuthStrings.welcomeTitle));
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.tap(find.text(AuthStrings.signInButton));
      await tester.pumpAndSettle();

      // POST /auth/login (email+password) succeeds -> Today.
      await pumpUntilFound(tester, find.text('Today'));

      // =========================================================================
      // WI 05 — Recovery server-truth after the password login: real Day N,
      // surgery type, and the clinician-authored recommendation; none of the
      // removed fabrications.
      // =========================================================================
      await tester.tap(find.text('Recovery'));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.text('Day 11 of Recovery'));
      expect(find.textContaining(surgeryType), findsOneWidget);
      expect(find.text(recommendationText), findsOneWidget);
      expect(find.text('Day 19 of Recovery'), findsNothing);
      expect(find.text('Recovery Milestones'), findsNothing);
      expect(find.textContaining('Seek Care Immediately'), findsNothing);
    },
  );
}

/// Creates a pending_onboarding patient via the clinician invite endpoint.
/// Returns the generated invite_code (a 6-digit code, also emailed to the
/// patient) plus the patient_id. Self-contained test setup against the live
/// backend. When [recommendationText] is given, the clinician also authors
/// one recommendation on the new case so the Recovery screen has real data.
Future<({String inviteCode, String patientId})> _createInvitedPatient({
  required String email,
  required String fullName,
  String? surgeryDate,
  String? recommendationText,
}) async {
  final base = AppConfig.baseUrl;

  // Clinician sign-in (seeded clinician; /auth/login returns a token).
  final loginRes = await http.post(
    Uri.parse('$base/auth/login'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'clinician@example.com',
      'password': 'CarePro#2026!Secure',
    }),
  );
  final token = jsonDecode(loginRes.body)['access_token'] as String;
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Create the patient invite (date_of_birth required at intake per WI 02).
  final inviteRes = await http.post(
    Uri.parse('$base/patients/invite'),
    headers: headers,
    body: jsonEncode({
      'email': email,
      'full_name': fullName,
      'surgery_type': 'Total Knee Arthroplasty (TKA)',
      'date_of_birth': '1990-01-01',
      'surgery_date': ?surgeryDate,
    }),
  );
  final inviteBody = jsonDecode(inviteRes.body) as Map<String, dynamic>;
  final patientId = inviteBody['patient_id'] as String;

  if (recommendationText != null) {
    final caseRes = await http.get(
      Uri.parse('$base/patients/$patientId/case'),
      headers: headers,
    );
    final caseId = jsonDecode(caseRes.body)['id'] as String;
    await http.post(
      Uri.parse('$base/cases/$caseId/recommendations'),
      headers: headers,
      body: jsonEncode({'text': recommendationText}),
    );
  }

  return (inviteCode: inviteBody['invite_code'] as String, patientId: patientId);
}

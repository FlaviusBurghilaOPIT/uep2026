// Live-backend integration test for the mobile "golden loop":
// patient sign-in via emailed code -> Assistant (in-scope reply + language-agnostic guardrail
// refusal) -> Today (dose logging). Requires the real FastAPI backend
// running at http://localhost:8000 (or 10.0.2.2:8000 on Android), seeded via
// `docker-compose exec backend python app/scripts/seed_data.py` per the
// project README. This exercises the real network stack end to end — it is
// not a substitute for the mocked unit/widget suite in test/.
//
// Signs in with the seeded demo patient's fixed, long-lived code
// (424242, set in seed_data.py) rather than a password — patients no
// longer have passwords.
//
// Assistant runs before dose logging deliberately: logging a dose shows a
// "Logged as ... Undo" SnackBar hosted by the root ScaffoldMessenger, which
// stays mounted across IndexedStack tabs and visually overlaps the bottom
// input row on every tab for its full duration — including a pre-existing
// overflow bug in its content Row that throws during disposal. Running the
// chat interactions first avoids fighting that entirely; dose logging is
// last and doesn't need further taps afterward.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:remotecare/main.dart' as app;
import 'package:remotecare/core/constants/app_strings.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'golden loop: patient login -> AI assistant guardrail -> log a dose',
    (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // --- Onboarding -> Sign in with the seeded patient's demo code ---
      await tester.tap(find.text(AppStrings.signInToAccount));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'patient@example.com',
      );
      await tester.tap(find.text(AppStrings.signIn));
      await tester.pumpAndSettle();

      // Real network round trip: POST /auth/patient/request-code.
      await pumpUntilFound(tester, find.text(AppStrings.verifyEmail));
      await tester.enterText(find.byType(TextFormField).first, '424242');
      await tester.tap(find.text(AppStrings.verifyAndContinue));

      // Real network round trip: POST /auth/patient/verify-code, GET /auth/me, GET /patients/{id}/case.
      await pumpUntilFound(tester, find.text(AppStrings.taken));
      await tester.pumpAndSettle();

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

      final takenAction = find.text(AppStrings.taken).first;
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
}

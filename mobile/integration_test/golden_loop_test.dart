// Live-backend integration test for the mobile "golden loop":
// patient login -> Today (dose logging) -> Assistant (in-scope reply +
// language-agnostic guardrail refusal). Requires the real FastAPI backend
// running at http://localhost:8000 (or 10.0.2.2:8000 on Android), seeded via
// `docker-compose exec backend python app/scripts/seed_data.py` per the
// project README. This exercises the real network stack end to end — it is
// not a substitute for the mocked unit/widget suite in test/.
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
    'golden loop: patient login -> log a dose -> AI assistant guardrail',
    (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // --- Onboarding -> Login ---
      await tester.tap(find.text(AppStrings.signInToAccount));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.at(0), 'patient@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.tap(find.text(AppStrings.signIn));

      // Real network round trip: POST /auth/login, GET /auth/me, GET /patients/{id}/case.
      await pumpUntilFound(tester, find.text(AppStrings.taken));
      await tester.pumpAndSettle();

      // --- Today: log a dose against the live backend ---
      final takenAction = find.text(AppStrings.taken).first;
      await tester.ensureVisible(takenAction);
      await tester.pumpAndSettle();
      await tester.tap(takenAction);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Logged as'));

      // Let the 5s undo window elapse so the real /adherence/log POST fires,
      // then let the SnackBar's dismiss animation finish — it's hosted by the
      // root ScaffoldMessenger, which stays mounted across IndexedStack tabs,
      // so a still-animating "Undo" SnackBar can intercept taps on other tabs.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      // --- Assistant: in-scope question gets a real (mock-provider) reply ---
      await tester.tap(find.text('Assistant'));
      await tester.pumpAndSettle();

      final chatInput = find.byType(TextField);
      expect(chatInput, findsOneWidget);
      await tester.enterText(chatInput, 'When should I take my medication?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await pumpUntilFound(tester, find.textContaining('mock AI response'));
      expect(find.byKey(const Key('refusal_box')), findsNothing);

      // --- Assistant: out-of-scope dose-change request is blocked ---
      // Client-side _classifyIntent() tags this dose_change_request; the
      // backend's IntentCategory guardrail (language-agnostic) blocks it
      // regardless of the mock LLM provider.
      await tester.enterText(chatInput, 'Can I take a double dose?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await pumpUntilFound(tester, find.byKey(const Key('refusal_box')));
      expect(find.byKey(const Key('emergency_cta_button')), findsOneWidget);
    },
  );
}

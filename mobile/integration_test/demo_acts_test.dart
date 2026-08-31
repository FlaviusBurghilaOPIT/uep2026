// Mobile Flutter Integration Test for 2-Minute Demo Video Recording
//
// Exercises Acts 2, 3, and 4 (mobile-side) against a live seeded backend.
// Driven directly via:
//   flutter test integration_test/demo_acts_test.dart -d <UDID>
//
// The Web-side acts (1, 4-web, 5) are handled by Playwright scripts in
// demo/acts/. This test provides clear act-boundary beats so the demo
// orchestrator (demo/orchestrator.sh) can interleave web + mobile recordings.
//
// Notification Strategy:
//   The orchestrator fires `xcrun simctl push booted com.example.remotecare
//   <payload.json>` during the "📱 NOTIFICATION WINDOW" beat to surface a push
//   banner on-camera. This test issues a companion POST /notifications/send-test
//   to exercise the backend notification path. The combination ensures the
//   push banner appears visually on the simulator during recording.

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps frames until [finder] matches at least one widget, or fails after
/// [timeout]. Default 30 s matches golden_loop_test.dart.
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

/// Camera-friendly pause — holds the current frame for [milliseconds] so the
/// video recording captures the UI state at a natural reading pace.
Future<void> beat(WidgetTester tester, int milliseconds) async {
  await tester.pump(Duration(milliseconds: milliseconds));
}

/// Finds all scheduled-dose "Taken" action buttons by key prefix.
///
/// This avoids matching the "Taken" badge labels on already-logged slots (which
/// share the same l10n string) or PRN medication "Taken" buttons (which use a
/// `prn_log_` key prefix and remain visible after tapping).
Finder findScheduledTakenButtons() {
  return find.byWidgetPredicate(
    (widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('slot_action_taken_');
    },
    description: 'scheduled dose "Taken" action button',
  );
}

/// Trigger a test notification via the backend API (best-effort).
///
/// The actual on-screen APNS push banner is delivered by the demo orchestrator
/// via `xcrun simctl push booted com.example.remotecare <payload.json>` — that
/// command must run on the host Mac, not from inside the iOS app sandbox. This
/// HTTP call exercises the backend notification path and logs the push event.
Future<void> triggerTestNotification() async {
  try {
    final base = AppConfig.baseUrl;

    // Authenticate as clinician
    final loginRes = await http.post(
      Uri.parse('$base/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'clinician@example.com',
        'password': 'CarePro#2026!Secure',
      }),
    );
    if (loginRes.statusCode != 200) return;
    final token = jsonDecode(loginRes.body)['access_token'] as String;

    // Resolve patient user_id from the cases list
    final casesRes = await http.get(
      Uri.parse('$base/cases'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (casesRes.statusCode != 200) return;
    final cases = jsonDecode(casesRes.body) as List<dynamic>;
    if (cases.isEmpty) return;
    final userId = cases.first['patient_id'] as String?;
    if (userId == null) return;

    // Fire the test notification
    await http.post(
      Uri.parse('$base/notifications/send-test'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'title': 'Medication Reminder: Ibuprofen 400 mg',
        'body': 'Scheduled for 08:00 AM. Tap to log as taken.',
      }),
    );
  } catch (_) {
    // Non-fatal: the orchestrator handles the visual push banner.
  }
}

// ---------------------------------------------------------------------------
// Main test
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Automated 2-Minute Demo Recording: Acts 2, 3, and 4',
      (tester) async {
    // Clean slate — drop any persisted token so boot routes to Welcome.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // =========================================================================
    // ACT 2: Patient Onboarding & 1-Tap Adherence        [0:25 – 0:55]
    // =========================================================================

    // --- 2.1 Sign in via Invitation Code (email + 6-digit OTP) ---
    // Welcome → "I have an invitation code" → InvitationCodeScreen
    // The InvitationCodeScreen features clipboard auto-paste and auto-submit.
    await pumpUntilFound(tester, find.text(AuthStrings.welcomeTitle));
    await beat(tester, 1500); // Showcase Welcome screen

    // Tap "I have an invitation code" to open InvitationCodeScreen
    await tester.tap(find.text(AuthStrings.clinicInvitationButton));
    await tester.pumpAndSettle();

    // InvitationCodeScreen — enter email + 6-digit code
    await pumpUntilFound(tester, find.text('Activate Your Account'));
    await beat(tester, 800);

    // Email field (first TextFormField)
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'patient@example.com');
    await beat(tester, 600);

    // 6-digit invitation code (second TextFormField) — demo bypass 424242
    final codeField = find.byType(TextFormField).last;
    await tester.enterText(codeField, '424242');
    await beat(tester, 800); // Show the code filled in

    // Tap "Verify & Activate Account"
    final verifyBtn = find.text('Verify & Activate Account');
    if (verifyBtn.evaluate().isNotEmpty) {
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn, warnIfMissed: false);
      await tester.pump();
    }

    // --- 2.2 Land on Today agenda: time-grouped cards, pill-form badges ---
    await pumpUntilFound(tester, find.text('Taken'));
    await tester.pumpAndSettle();
    await beat(tester, 2000); // Showcase: greeting card, progress bar, groups

    // --- 📱 NOTIFICATION WINDOW ---
    // The orchestrator fires `xcrun simctl push booted ...` here so the
    // medication reminder banner appears over the Today screen on camera.
    // See: backend/app/scripts/trigger_notifications_demo.py
    await triggerTestNotification();
    await beat(tester, 4000); // Hold for notification banner visibility

    // --- 2.3 Tap first "Taken" — optimistic checkmark, ring progress, SnackBar ---
    final scheduledTaken = findScheduledTakenButtons();
    if (scheduledTaken.evaluate().isNotEmpty) {
      final firstBtn = scheduledTaken.first;
      await tester.ensureVisible(firstBtn);
      await tester.pumpAndSettle();
      await beat(tester, 800); // Frame the card before tapping
      await tester.tap(firstBtn);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Logged as'));
      // Hold: optimistic checkmark + progress ring update + 5 s undo SnackBar
      await tester.pump(const Duration(milliseconds: 5500));
    }

    // --- 2.4 Complete remaining scheduled doses for Day Complete ---
    var remaining = findScheduledTakenButtons();
    var doseCount = 0;
    const maxDoses = 10; // Safety: prevent infinite loop
    while (remaining.evaluate().isNotEmpty && doseCount < maxDoses) {
      final nextBtn = remaining.first;
      await tester.ensureVisible(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pump();
      await pumpUntilFound(tester, find.textContaining('Logged as'));
      // Shorter hold for subsequent doses — the 5 s background POST timer
      // fires independently; the optimistic UI is instant.
      await tester.pump(const Duration(milliseconds: 2500));
      doseCount++;
      remaining = findScheduledTakenButtons();
    }

    // --- 2.5 Day Complete celebration ring (600 ms emerald sweep) ---
    final celebrationFinder = find.byKey(const Key('today_celebration'));
    await pumpUntilFound(tester, celebrationFinder,
        timeout: const Duration(seconds: 10));
    await tester.ensureVisible(celebrationFinder);
    await tester.pumpAndSettle();
    await beat(tester, 3500); // Showcase ring closure celebration

    // =========================================================================
    // ACT 3: Guardrailed AI Recovery Assistant            [0:55 – 1:25]
    // =========================================================================

    // --- 3.1 Open Assistant tab — persistent medical disclaimer banner ---
    await tester.tap(find.byKey(const Key('navTab_assistant')));
    await tester.pumpAndSettle();
    await beat(tester, 2500); // Showcase GuardrailBanner

    // --- 3.2 Tap "When can I shower?" → SSE streaming with NICE citations ---
    final showerChip = find.text('When can I shower?');
    if (showerChip.evaluate().isNotEmpty) {
      await tester.tap(showerChip);
      await tester.pump();
    } else {
      // Fallback: type the question manually
      final chatInputFallback = find.byType(TextField);
      await tester.tap(chatInputFallback);
      await tester.enterText(chatInputFallback, 'When can I shower?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
    }

    // Wait for SSE streaming response with NICE guideline citations
    await pumpUntilFound(
      tester,
      find.byWidgetPredicate(
        (w) => w is ChatBubble && !w.message.isFromUser,
      ),
      timeout: const Duration(seconds: 30),
    );
    // Hold for read time — the response contains multi-paragraph clinical
    // advice with guideline citations that should be clearly visible on video.
    await tester.pump(const Duration(seconds: 8));

    // --- 3.3 "Can I double my pain medication?" → deterministic refusal ---
    final chatInput = find.byType(TextField);
    await tester.tap(chatInput);
    await tester.pump();
    await tester.enterText(chatInput, 'Can I double my pain medication?');
    await beat(tester, 600); // Let typed text be visible on camera
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // Wait for the deterministic refusal box + clinic escalation CTA
    await pumpUntilFound(
      tester,
      find.byKey(const Key('refusal_box')),
      timeout: const Duration(seconds: 30),
    );
    await beat(tester, 5000); // Showcase: red refusal card + emergency CTA

    // =========================================================================
    // ACT 4: Emergency Interception (Mobile side)         [1:25 – 1:45]
    // =========================================================================

    // --- 4.1 Return to Today tab ---
    await tester.tap(find.byKey(const Key('navTab_today')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // --- 4.2 Scroll to daily check-in and select "Unwell" ---
    final checkinCard = find.byKey(const Key('checkin_card'));
    await pumpUntilFound(tester, checkinCard);
    await tester.ensureVisible(checkinCard);
    await tester.pumpAndSettle();
    await beat(tester, 1000); // Frame the check-in card

    final unwellChip = find.byKey(const Key('checkin_chip_bad'));
    if (unwellChip.evaluate().isNotEmpty) {
      await tester.tap(unwellChip);
      await tester.pumpAndSettle();
    } else {
      // Fallback: find by localized text
      final badText = find.text('Feeling Unwell 😣');
      if (badText.evaluate().isNotEmpty) {
        await tester.tap(badText);
        await tester.pumpAndSettle();
      }
    }

    // --- 4.3 Emergency Red Flag Banner with 911 / clinic dialers ---
    await pumpUntilFound(
      tester,
      find.byKey(const Key('emergency_red_flag_banner')),
    );
    await tester.ensureVisible(
      find.byKey(const Key('emergency_red_flag_banner')),
    );
    await tester.pumpAndSettle();
    // Hold: emergency banner is the critical safety moment — 911 and clinic
    // dialer buttons must be clearly visible on camera.
    await tester.pump(const Duration(seconds: 6));

    // =========================================================================
    // CLOSING — Clean exit for the recording session      [1:45+]
    // =========================================================================
    // Web-side Act 4 (clinician resolves Sarah Mitchell in the Critical queue)
    // and Act 5 (Arize Phoenix observability: trace waterfalls, token counts,
    // USD cost per query) are handled by Playwright scripts in demo/acts/.
    // This test's recording session ends here; the orchestrator stitches
    // mobile + web clips via demo/stitch-videos.mjs.
    await beat(tester, 2000);
  });
}

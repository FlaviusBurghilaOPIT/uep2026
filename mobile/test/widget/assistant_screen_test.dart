import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/core/telemetry/telemetry_service.dart';
import 'package:remotecare/features/assistant/data/assistant_stream_client.dart';
import 'package:remotecare/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';
import '../unit/fake_assistant_stream_client.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: AssistantScreen(),
  );
}

Widget buildTestApp(
  FakeApiService fakeApi,
  FakeAssistantStreamClient fakeStream,
  TelemetryService telemetryService,
  SharedPreferences prefs,
) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(fakeApi),
      assistantStreamClientProvider.overrideWithValue(fakeStream),
      telemetryServiceProvider.overrideWithValue(telemetryService),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      builder: _buildMaterialApp,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late FakeAssistantStreamClient fakeStream;
  late TelemetryService telemetryService;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
    fakeStream = FakeAssistantStreamClient();
    telemetryService = TelemetryService(fakeApi);
  });

  testWidgets('Guardrail banner is always visible and matches typography and styling spec', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
    );
    await tester.pumpAndSettle();

    final bannerFinder = find.byType(GuardrailBanner);
    expect(bannerFinder, findsOneWidget);

    final textFinder = find.descendant(
      of: bannerFinder,
      matching: find.text('Care Team Assistant • Informational only, never diagnostic'),
    );
    expect(textFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(textFinder);
    expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
    expect(textWidget.style?.color, equals(const Color(0xFF334155)));
    expect(textWidget.style?.height, equals(1.4));

    final containerFinder = find.descendant(
      of: bannerFinder,
      matching: find.byType(Container),
    ).first;
    final containerWidget = tester.widget<Container>(containerFinder);
    final decoration = containerWidget.decoration as BoxDecoration;
    expect(decoration.color, equals(const Color(0xFFF0FDF4)));
    final border = decoration.border as Border;
    expect(border.bottom.color, equals(const Color(0xFFDCFCE7)));
  });

  testWidgets(
    'Empty chat screen renders 3 pre-seeded prompt chips; tapping sends query automatically and hides chips',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeStream.handler = (c, m, i) {
        expect(m, 'Is mild swelling normal?');
        return Stream.value('Mild swelling is normal during early recovery.');
      };

      await tester.pumpWidget(
        buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
      );
      await tester.pumpAndSettle();

      // Verify all 3 pre-seeded clinical quick prompt chips are rendered
      expect(find.text('Is mild swelling normal?'), findsOneWidget);
      expect(find.text('When can I shower?'), findsOneWidget);
      expect(find.text('Medication instructions'), findsOneWidget);

      // Tap a chip: should fill and automatically send query
      await tester.tap(find.text('Is mild swelling normal?'));
      await tester.pumpAndSettle();

      // User message and AI reply rendered
      expect(find.text('Is mild swelling normal?'), findsOneWidget);
      expect(
        find.text('Mild swelling is normal during early recovery.'),
        findsOneWidget,
      );

      // Chips disappear once chat contains active messages
      expect(find.text('When can I shower?'), findsNothing);
      expect(find.text('Medication instructions'), findsNothing);
      expect(find.byType(SuggestionChips), findsNothing);
    },
  );

  testWidgets(
    'Typing indicator visible while awaiting first chunk; hidden once streaming starts',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = StreamController<String>();
      fakeStream.handler = (c, m, i) => controller.stream;

      await tester.pumpWidget(
        buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('typing_indicator')), findsNothing);

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Awaiting the first chunk: typing indicator is visible.
      expect(find.byKey(const Key('typing_indicator')), findsOneWidget);

      // First chunk arrives: the streaming bubble replaces the indicator.
      controller.add('Done');
      await tester.pump();
      expect(find.byKey(const Key('typing_indicator')), findsNothing);
      expect(find.text('Done'), findsOneWidget);

      await controller.close();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('typing_indicator')), findsNothing);
    },
  );

  testWidgets('Chat bubble appears after sendMessage success', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    fakeStream.handler = (c, m, i) => Stream.value('Here is your info.');

    await tester.pumpWidget(
      buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Can I take ibuprofen?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Can I take ibuprofen?'), findsOneWidget);
    expect(find.text('Here is your info.'), findsOneWidget);
  });

  testWidgets('Assistant reply renders progressively as chunks stream in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = StreamController<String>();
    fakeStream.handler = (c, m, i) => controller.stream;

    await tester.pumpWidget(
      buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Tell me about recovery');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // Partial chunk renders before the full reply exists.
    controller.add('Rest ');
    await tester.pump();
    expect(find.text('Rest '), findsOneWidget);
    expect(find.text('Rest and hydrate.'), findsNothing);

    // The next chunk grows the same bubble in place.
    controller.add('and hydrate.');
    await tester.pump();
    expect(find.text('Rest and hydrate.'), findsOneWidget);
    expect(find.text('Rest '), findsNothing);

    await controller.close();
    await tester.pumpAndSettle();
    expect(find.text('Rest and hydrate.'), findsOneWidget);
  });

  testWidgets(
    'Streaming error shows honest error state, keeps user message, no dead controls',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeStream.handler = (c, m, i) =>
          Stream.error(const AssistantStreamException('network down'));

      await tester.pumpWidget(
        buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      // Honest error surfaced; loading stopped; user message retained.
      expect(
        find.text('Could not reach assistant. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Hello?'), findsOneWidget);
      expect(find.byKey(const Key('typing_indicator')), findsNothing);

      // No dead controls: input + send re-enabled after the error.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isTrue);
      final sendButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.send_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(sendButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Out-of-scope response renders refusal box + emergency CTA + tel link + telemetry',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeApi.getHandlers['/cases/default_case/emergency-contact'] = () {
        return http.Response(
          jsonEncode({'name': 'Dr. Smith', 'phone': '+1-555-0199'}),
          200,
        );
      };
      fakeApi.postHandlers['/ai/chat'] = (body) {
        return http.Response(
          jsonEncode({
            'reply': 'I cannot assist with changing medication doses.',
            'in_scope': false,
            'escalate': true,
          }),
          200,
        );
      };

      await tester.pumpWidget(
        buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Can I double my dose?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('refusal_box')), findsOneWidget);
      expect(
        find.text('I Cannot Advise on Dose Changes or Urgent Symptoms'),
        findsOneWidget,
      );
      expect(find.text('Call Emergency Contact (+1-555-0199)'), findsOneWidget);

      expect(
        telemetryService.events.any(
          (e) => e.name == 'mobile.assistant.guardrail_triggered',
        ),
        isTrue,
      );

      await tester.tap(find.byKey(const Key('emergency_cta_button')));
      await tester.pumpAndSettle();

      expect(
        telemetryService.events.any(
          (e) => e.name == 'mobile.assistant.emergency_cta_tapped',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'Chat bubbles render conversational responses without boilerplate disclaimer prefixes while GuardrailBanner provides legal context',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const conversationalResponse =
          'It is common to experience mild swelling after surgery. Elevating the area and applying cold packs as directed can help.';

      fakeStream.handler = (c, m, i) => Stream.value(conversationalResponse);

      await tester.pumpWidget(
        buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
      );
      await tester.pumpAndSettle();

      // GuardrailBanner is visible at top providing legal guardrail context
      expect(find.byType(GuardrailBanner), findsOneWidget);
      expect(
        find.text('Care Team Assistant • Informational only, never diagnostic'),
        findsOneWidget,
      );

      // Send a user question
      await tester.enterText(find.byType(TextField), 'Is swelling normal?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Assistant chat bubble renders natural conversational text without disclaimer prefix
      final bubbleFinder = find.byType(ChatBubble);
      expect(bubbleFinder, findsNWidgets(2)); // User + Assistant

      final assistantBubbleText = find.text(conversationalResponse);
      expect(assistantBubbleText, findsOneWidget);

      // Verify no boilerplate disclaimer is prepended to the chat bubble
      expect(
        find.textContaining('Disclaimer: This is informational only'),
        findsNothing,
      );
    },
  );
}


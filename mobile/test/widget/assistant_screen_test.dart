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

  testWidgets('Guardrail banner is always visible (find by text key)', (
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

    expect(
      find.text('Care Team Assistant • Informational only, never diagnostic'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Suggestion chips shown when messages.isEmpty; hidden after first message',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeStream.handler = (c, m, i) => Stream.value('Chip reply');

      await tester.pumpWidget(
        buildTestApp(fakeApi, fakeStream, telemetryService, prefs),
      );
      await tester.pumpAndSettle();

      expect(find.text('Medication side effects'), findsOneWidget);
      expect(find.text('Wound care tips'), findsOneWidget);
      expect(find.text('Physio targets'), findsOneWidget);
      expect(find.text('Emergency contact'), findsOneWidget);

      await tester.tap(find.text('Medication side effects'));
      await tester.pumpAndSettle();

      expect(find.text('Wound care tips'), findsNothing);
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
}

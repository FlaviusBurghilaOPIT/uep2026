import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/telemetry/telemetry_service.dart';
import 'package:remotecare/features/assistant/assistant_screen.dart';

import '../unit/fake_api_service.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: AssistantScreen(),
  );
}

Widget buildTestApp(FakeApiService fakeApi, TelemetryService telemetryService) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(fakeApi),
      telemetryServiceProvider.overrideWithValue(telemetryService),
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
  late TelemetryService telemetryService;

  setUp(() {
    fakeApi = FakeApiService();
    telemetryService = TelemetryService(fakeApi);
  });

  testWidgets('Guardrail banner is always visible (find by text key)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(fakeApi, telemetryService));
    await tester.pumpAndSettle();

    expect(
      find.text('AI Assistant • Informational only, never diagnostic'),
      findsOneWidget,
    );
  });

  testWidgets('Suggestion chips shown when messages.isEmpty; hidden after first message', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    fakeApi.postHandlers['/ai/chat'] = (body) {
      return http.Response(jsonEncode({'reply': 'Chip reply'}), 200);
    };

    await tester.pumpWidget(buildTestApp(fakeApi, telemetryService));
    await tester.pumpAndSettle();

    expect(find.text('Medication side effects'), findsOneWidget);
    expect(find.text('Wound care tips'), findsOneWidget);
    expect(find.text('Physio targets'), findsOneWidget);
    expect(find.text('Emergency contact'), findsOneWidget);

    await tester.tap(find.text('Medication side effects'));
    await tester.pumpAndSettle();

    expect(find.text('Wound care tips'), findsNothing);
  });

  testWidgets('Typing indicator visible when isLoading; hidden when not loading', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    fakeApi.postHandlers['/ai/chat'] = (body) async {
      await Future.delayed(const Duration(milliseconds: 200));
      return http.Response(jsonEncode({'reply': 'Done'}), 200);
    };

    await tester.pumpWidget(buildTestApp(fakeApi, telemetryService));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('typing_indicator')), findsNothing);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.byKey(const Key('typing_indicator')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('typing_indicator')), findsNothing);
  });

  testWidgets('Chat bubble appears after sendMessage success', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    fakeApi.postHandlers['/ai/chat'] = (body) {
      return http.Response(jsonEncode({'reply': 'Here is your info.'}), 200);
    };

    await tester.pumpWidget(buildTestApp(fakeApi, telemetryService));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Can I take ibuprofen?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Can I take ibuprofen?'), findsOneWidget);
    expect(find.text('Here is your info.'), findsOneWidget);
  });

  testWidgets('Out-of-scope response renders refusal box + emergency CTA + tel link + telemetry', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    fakeApi.getHandlers['/cases/default_case/emergency-contact'] = () {
      return http.Response(jsonEncode({'name': 'Dr. Smith', 'phone': '+1-555-0199'}), 200);
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

    await tester.pumpWidget(buildTestApp(fakeApi, telemetryService));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Can I double my dose?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('refusal_box')), findsOneWidget);
    expect(find.text('I Cannot Advise on Dose Changes or Urgent Symptoms'), findsOneWidget);
    expect(find.text('Call Emergency Contact (+1-555-0199)'), findsOneWidget);

    expect(
      telemetryService.events.any((e) => e.name == 'mobile.assistant.guardrail_triggered'),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('emergency_cta_button')));
    await tester.pumpAndSettle();

    expect(
      telemetryService.events.any((e) => e.name == 'mobile.assistant.emergency_cta_tapped'),
      isTrue,
    );
  });
}

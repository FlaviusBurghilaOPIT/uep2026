import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/telemetry/telemetry_service.dart';
import 'package:remotecare/features/assistant/data/assistant_stream_client.dart';
import 'package:remotecare/features/assistant/presentation/providers/chat_assistant_notifier.dart';

import 'fake_api_service.dart';
import 'fake_assistant_stream_client.dart';

void main() {
  late FakeApiService fakeApi;
  late FakeAssistantStreamClient fakeStream;
  late TelemetryService telemetryService;
  late ProviderContainer container;

  setUp(() {
    fakeApi = FakeApiService();
    fakeStream = FakeAssistantStreamClient();
    telemetryService = TelemetryService(fakeApi);
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        telemetryServiceProvider.overrideWithValue(telemetryService),
        assistantStreamClientProvider.overrideWithValue(fakeStream),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('sendMessage appends user message immediately before awaiting stream', () async {
    final controller = StreamController<String>();
    fakeStream.handler = (c, m, i) => controller.stream;

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    final future = notifier.sendMessage(caseId: 'case_1', message: 'Hello AI');

    final stateBeforeApi = container.read(chatAssistantNotifierProvider);
    expect(stateBeforeApi.messages.length, 1);
    expect(stateBeforeApi.messages.first.text, 'Hello AI');
    expect(stateBeforeApi.messages.first.isFromUser, true);
    expect(stateBeforeApi.isLoading, true);

    controller.add('Hi there! How can I help you today?');
    await controller.close();
    await future;

    final stateAfterApi = container.read(chatAssistantNotifierProvider);
    expect(stateAfterApi.messages.length, 2);
    expect(stateAfterApi.messages.last.text, 'Hi there! How can I help you today?');
    expect(stateAfterApi.messages.last.isFromUser, false);
    expect(stateAfterApi.isLoading, false);
  });

  test('in-scope reply renders conversational message without disclaimer prefixes', () async {
    final controller = StreamController<String>();
    fakeStream.handler = (c, m, i) => controller.stream;

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    final future = notifier.sendMessage(caseId: 'case_1', message: 'Tell me about recovery');
    await pumpEventQueue();

    var state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.length, 1);
    expect(state.isLoading, true);

    controller.add('Rest ');
    await pumpEventQueue();
    state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.length, 2);
    expect(state.messages.last.isFromUser, false);
    expect(state.messages.last.text, 'Rest ');
    expect(state.isLoading, true);

    controller.add('and hydrate.');
    await pumpEventQueue();
    state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.length, 2);
    expect(state.messages.last.text, 'Rest and hydrate.');
    expect(state.isLoading, true);

    await controller.close();
    await future;
    state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.last.text, 'Rest and hydrate.');
    expect(state.messages.last.text.contains('Disclaimer'), isFalse);
    expect(state.messages.last.text.contains('Informational only'), isFalse);
    expect(state.isLoading, false);
    expect(state.errorMessage, isNull);
  });

  test('out-of-scope response fetches emergency contact and emits telemetry', () async {
    fakeApi.getHandlers['/cases/case_1/emergency-contact'] = () {
      return http.Response(
        jsonEncode({'name': 'Dr. Moreau', 'phone': '+1-555-0199'}),
        200,
      );
    };
    fakeApi.postHandlers['/ai/chat'] = (body) {
      return http.Response(
        jsonEncode({
          'reply': 'I cannot advise on changing medication doses.',
          'in_scope': false,
          'escalate': true,
        }),
        200,
      );
    };

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    await notifier.sendMessage(caseId: 'case_1', message: 'Can I double my dose?');

    final state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.length, 2);
    final aiMsg = state.messages[1];
    expect(aiMsg.inScope, false);
    expect(aiMsg.escalate, true);
    expect(aiMsg.emergencyPhone, '+1-555-0199');

    expect(fakeStream.requests, isEmpty);

    expect(
      telemetryService.events.any((e) => e.name == 'mobile.assistant.guardrail_triggered'),
      isTrue,
    );

    await notifier.onEmergencyCtaTapped('case_1', '+1-555-0199');
    expect(
      telemetryService.events.any((e) => e.name == 'mobile.assistant.emergency_cta_tapped'),
      isTrue,
    );
  });

  test('sendMessage on stream error sets errorMessage, keeps user message, isLoading: false', () async {
    fakeStream.handler = (c, m, i) =>
        Stream.error(const AssistantStreamException('network down'));

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    await notifier.sendMessage(caseId: 'case_1', message: 'Is this an error?');

    final state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.length, 1);
    expect(state.messages[0].text, 'Is this an error?');
    expect(state.messages[0].isFromUser, true);
    expect(state.isLoading, false);
    expect(state.errorMessage, 'Could not reach assistant. Please try again.');
  });

  test('sendSuggestion delegates to sendMessage with chip text', () async {
    fakeStream.handler = (c, m, i) {
      expect(m, 'Medication side effects');
      return Stream.value('Common side effects include nausea.');
    };

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    await notifier.sendSuggestion(
      caseId: 'case_1',
      chipText: 'Medication side effects',
    );

    final state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.length, 2);
    expect(state.messages[0].text, 'Medication side effects');
    expect(state.messages[1].text, 'Common side effects include nausea.');
  });

  test('clearChat resets messages to []', () async {
    fakeStream.handler = (c, m, i) => Stream.value('Response');

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    await notifier.sendMessage(caseId: 'case_1', message: 'Hello');
    expect(container.read(chatAssistantNotifierProvider).messages.isNotEmpty, true);

    notifier.clearChat();
    final state = container.read(chatAssistantNotifierProvider);
    expect(state.messages, isEmpty);
    expect(state.isLoading, false);
    expect(state.errorMessage, isNull);
  });
}

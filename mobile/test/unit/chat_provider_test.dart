import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/telemetry/telemetry_service.dart';
import 'package:remotecare/features/assistant/providers/chat_assistant_notifier.dart';

import 'fake_api_service.dart';

void main() {
  late FakeApiService fakeApi;
  late TelemetryService telemetryService;
  late ProviderContainer container;

  setUp(() {
    fakeApi = FakeApiService();
    telemetryService = TelemetryService(fakeApi);
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        telemetryServiceProvider.overrideWithValue(telemetryService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('sendMessage appends user message immediately before awaiting API', () async {
    final completer = Completer<http.Response>();
    fakeApi.postHandlers['/ai/chat'] = (body) {
      return completer.future;
    };

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    final future = notifier.sendMessage(caseId: 'case_1', message: 'Hello AI');

    final stateBeforeApi = container.read(chatAssistantNotifierProvider);
    expect(stateBeforeApi.messages.length, 1);
    expect(stateBeforeApi.messages.first.text, 'Hello AI');
    expect(stateBeforeApi.messages.first.isFromUser, true);
    expect(stateBeforeApi.isLoading, true);

    completer.complete(
      http.Response(
        jsonEncode({'reply': 'Hi there!', 'in_scope': true, 'escalate': false}),
        200,
      ),
    );
    await future;

    final stateAfterApi = container.read(chatAssistantNotifierProvider);
    expect(stateAfterApi.messages.length, 2);
    expect(stateAfterApi.isLoading, false);
  });

  test('sendMessage on success appends AI reply, sets isLoading: false', () async {
    fakeApi.postHandlers['/ai/chat'] = (body) {
      return http.Response(
        jsonEncode({
          'reply': 'Rest and drink water.',
          'in_scope': true,
          'escalate': false,
        }),
        200,
      );
    };

    final notifier = container.read(chatAssistantNotifierProvider.notifier);
    await notifier.sendMessage(caseId: 'case_1', message: 'What should I do?');

    final state = container.read(chatAssistantNotifierProvider);
    expect(state.messages.length, 2);
    expect(state.messages[0].text, 'What should I do?');
    expect(state.messages[0].isFromUser, true);
    expect(state.messages[1].text, 'Rest and drink water.');
    expect(state.messages[1].isFromUser, false);
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

  test('sendMessage on HTTP error sets errorMessage, keeps user message, isLoading: false', () async {
    fakeApi.postHandlers['/ai/chat'] = (body) {
      return http.Response(jsonEncode({'detail': 'Internal Server Error'}), 500);
    };

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
    fakeApi.postHandlers['/ai/chat'] = (body) {
      expect(body?['message'], 'Medication side effects');
      return http.Response(
        jsonEncode({'reply': 'Common side effects include nausea.'}),
        200,
      );
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
    fakeApi.postHandlers['/ai/chat'] = (body) {
      return http.Response(jsonEncode({'reply': 'Response'}), 200);
    };

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

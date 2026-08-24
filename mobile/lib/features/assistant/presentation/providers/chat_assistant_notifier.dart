import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/telemetry/telemetry_service.dart';
import '../../data/assistant_stream_client.dart';

part 'chat_assistant_notifier.freezed.dart';

// Client-side intent pre-classification keyword lists per locale-agnostic pattern.
// These tags are sent to the backend as the `intent_category` field.
// The backend enum check is the authoritative guardrail; this is a UX pre-classification only.
const List<String> _doseChangeKeywords = [
  // English
  'double dose',
  'double my dose',
  'double the dose',
  'extra dose',
  'extra pill',
  'extra pills',
  'take extra',
  'take more',
  'more pills',
  'stop taking',
  'change dose',
  'increase dose',
  'decrease dose',
  // Spanish
  'doble dosis',
  'dosis extra',
  'dejar de tomar',
  'cambiar dosis',
  'aumentar dosis',
  // Italian
  'doppia dose', 'dose extra', 'smettere di prendere', 'cambiare dose',
  // German
  'doppelte dosis', 'extra dosis', 'aufhören zu nehmen',
  // French
  'double dose', 'arrêter de prendre', 'changer la dose',
];

const List<String> _diagnosisKeywords = [
  'diagnose',
  'do i have',
  'what disease',
  'is this cancer',
  'diagnosticar',
  'tengo',
  'ho una',
  'habe ich',
  'j\'ai',
];

String _classifyIntent(String message) {
  final lower = message.toLowerCase();
  if (_doseChangeKeywords.any(lower.contains)) return 'dose_change_request';
  if (_diagnosisKeywords.any(lower.contains)) return 'diagnosis_request';
  return 'general_question';
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String text,
    required bool isFromUser,
    required DateTime timestamp,
    @Default(true) bool inScope,
    @Default(false) bool escalate,
    String? emergencyPhone,
  }) = _ChatMessage;
}

@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _ChatState;
}

/// Intents the backend treats as out-of-scope (see `_check_guardrail` in
/// `backend/app/routers/ai.py`). The backend's guardrail decision is a pure
/// function of the `intent_category` the client sends, so the client can
/// reliably route these to the JSON endpoint (which carries the authoritative
/// `in_scope`/`escalate` flags) while streaming everything else.
const Set<String> _outOfScopeIntents = {
  'dose_change_request',
  'diagnosis_request',
};

class ChatAssistantNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  ApiService get _api => ref.read(apiServiceProvider);
  TelemetryService get _telemetry => ref.read(telemetryServiceProvider);
  AssistantStreamClient get _streamClient =>
      ref.read(assistantStreamClientProvider);

  static const String _errorMessage =
      'Could not reach assistant. Please try again.';

  Future<void> sendMessage({
    required String caseId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmed,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

    final intentCategory = _classifyIntent(trimmed);
    if (_outOfScopeIntents.contains(intentCategory)) {
      // Out-of-scope: use the JSON endpoint so we keep the backend's
      // authoritative in_scope/escalate flags + emergency-contact lookup that
      // power the refusal box and emergency CTA.
      await _sendViaJson(
        caseId: caseId,
        message: trimmed,
        intentCategory: intentCategory,
      );
    } else {
      // In-scope: render the reply progressively via the streaming endpoint.
      await _sendViaStream(
        caseId: caseId,
        message: trimmed,
        intentCategory: intentCategory,
      );
    }
  }

  /// JSON `POST /ai/chat` path — used for out-of-scope intents so the refusal
  /// box can render the backend's authoritative `in_scope`/`escalate` flags and
  /// the fetched emergency-contact phone.
  Future<void> _sendViaJson({
    required String caseId,
    required String message,
    required String intentCategory,
  }) async {
    try {
      final res = await _api.post('/ai/chat', {
        'case_id': caseId,
        'message': message,
        'intent_category': intentCategory,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final replyText = data['reply'] as String? ?? '';
        final inScope = data['in_scope'] as bool? ?? true;
        final escalate = data['escalate'] as bool? ?? false;
        String? emergencyPhone;

        if (!inScope) {
          _telemetry.trackEvent('mobile.assistant.guardrail_triggered', {
            'patient_hash': caseId,
            'guardrail_rule_matched': 'out_of_scope',
            'escalate_flag_set': escalate,
          });

          try {
            final contactRes = await _api.get(
              '/cases/$caseId/emergency-contact',
            );
            if (contactRes.statusCode == 200) {
              final contactData =
                  jsonDecode(contactRes.body) as Map<String, dynamic>;
              emergencyPhone = contactData['phone'] as String?;
            }
          } catch (_) {}
        }

        final aiMsg = ChatMessage(
          id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
          text: replyText,
          isFromUser: false,
          timestamp: DateTime.now(),
          inScope: inScope,
          escalate: escalate,
          emergencyPhone: emergencyPhone,
        );

        state = state.copyWith(
          messages: [...state.messages, aiMsg],
          isLoading: false,
        );
      } else {
        state = state.copyWith(errorMessage: _errorMessage, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(errorMessage: _errorMessage, isLoading: false);
    }
  }

  /// Streaming `POST /ai/chat/stream` path — appends the Assistant message on
  /// the first chunk and grows its text on each subsequent chunk so the UI
  /// renders the reply progressively. The typing indicator stays visible until
  /// the first chunk arrives (the last message is still the user's).
  Future<void> _sendViaStream({
    required String caseId,
    required String message,
    required String intentCategory,
  }) async {
    final aiMsgId = (DateTime.now().microsecondsSinceEpoch + 1).toString();
    final buffer = StringBuffer();
    var created = false;

    try {
      final stream = _streamClient.streamReply(
        caseId: caseId,
        message: message,
        intentCategory: intentCategory,
      );

      await for (final chunk in stream) {
        buffer.write(chunk);
        if (!created) {
          final aiMsg = ChatMessage(
            id: aiMsgId,
            text: buffer.toString(),
            isFromUser: false,
            timestamp: DateTime.now(),
          );
          state = state.copyWith(messages: [...state.messages, aiMsg]);
          created = true;
        } else {
          _updateMessageText(aiMsgId, buffer.toString());
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (_) {
      // Honest error: stop loading and surface the message. If nothing was
      // streamed yet, only the user's message remains (no empty AI bubble).
      state = state.copyWith(errorMessage: _errorMessage, isLoading: false);
    }
  }

  /// Replaces the text of the message with [id] in place (immutable copy),
  /// used to grow the streaming Assistant bubble chunk-by-chunk.
  void _updateMessageText(String id, String text) {
    final messages = state.messages.toList();
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].id == id) {
        messages[i] = messages[i].copyWith(text: text);
        break;
      }
    }
    state = state.copyWith(messages: messages);
  }

  Future<void> onEmergencyCtaTapped(String caseId, String phone) async {
    _telemetry.trackEvent('mobile.assistant.emergency_cta_tapped', {
      'patient_hash': caseId,
      'phone': phone,
    });
    if (phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  void clearChat() {
    state = const ChatState();
  }

  Future<void> sendSuggestion({
    required String caseId,
    required String chipText,
  }) async {
    await sendMessage(caseId: caseId, message: chipText);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final chatAssistantNotifierProvider =
    NotifierProvider<ChatAssistantNotifier, ChatState>(
      ChatAssistantNotifier.new,
    );

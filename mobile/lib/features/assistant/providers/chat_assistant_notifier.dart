import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_service.dart';
import '../../../core/telemetry/telemetry_service.dart';

part 'chat_assistant_notifier.freezed.dart';

// Client-side intent pre-classification keyword lists per locale-agnostic pattern.
// These tags are sent to the backend as the `intent_category` field.
// The backend enum check is the authoritative guardrail; this is a UX pre-classification only.
const List<String> _doseChangeKeywords = [
  // English
  'double dose',
  'extra dose',
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

class ChatAssistantNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  ApiService get _api => ref.read(apiServiceProvider);
  TelemetryService get _telemetry => ref.read(telemetryServiceProvider);

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

    try {
      final intentCategory = _classifyIntent(trimmed);
      final res = await _api.post('/ai/chat', {
        'case_id': caseId,
        'message': trimmed,
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
        state = state.copyWith(
          errorMessage: 'Could not reach assistant. Please try again.',
          isLoading: false,
        );
      }
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Could not reach assistant. Please try again.',
        isLoading: false,
      );
    }
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

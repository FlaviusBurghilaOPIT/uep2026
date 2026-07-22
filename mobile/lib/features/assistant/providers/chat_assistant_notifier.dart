import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_service.dart';

part 'chat_assistant_notifier.freezed.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String text,
    required bool isFromUser,
    required DateTime timestamp,
  }) = _ChatMessage;
}

@freezed
class ChatState with _$ChatState {
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
      final res = await _api.post('/ai/chat', {
        'case_id': caseId,
        'message': trimmed,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final replyText = data['reply'] as String? ?? '';

        final aiMsg = ChatMessage(
          id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
          text: replyText,
          isFromUser: false,
          timestamp: DateTime.now(),
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

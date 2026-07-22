---
type: Work Item
title: AI Assistant Chat Screen — Guardrail Banner, Suggestion Chips, Typing Indicator & chatAssistantNotifierProvider with Unit Tests
parent: ../2026-07-22-flutter-mobile-enhancements-spec.md
---

## What to build

Build the full `AssistantScreen` in `lib/features/assistant/` with a persistent clinical guardrail banner, four one-tap suggestion chips, an animated 3-dot typing indicator, and scrollable chat bubble UI. Implement `chatAssistantNotifierProvider` that posts to `POST /ai/chat` on the Python backend, manages `ChatState` as `AsyncValue`, and appends messages to the conversation. Include unit tests for `chatAssistantNotifierProvider` using a `FakeApiService`.

### `chatAssistantNotifierProvider` — `lib/features/assistant/providers/chat_assistant_notifier.dart`

State:
```dart
@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _ChatState;
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String text,
    required bool isFromUser,
    required DateTime timestamp,
  }) = _ChatMessage;
}
```

Methods:
- `sendMessage({required String caseId, required String message})`:
  1. Appends `ChatMessage(isFromUser: true, text: message, ...)` to `state.messages`.
  2. Sets `state.copyWith(isLoading: true, errorMessage: null)`.
  3. POSTs `{case_id: caseId, message: message}` to `/ai/chat`.
  4. On success: appends AI reply `ChatMessage(isFromUser: false, text: response.reply, ...)`, sets `isLoading: false`.
  5. On error: sets `errorMessage: 'Could not reach assistant. Please try again.'`, sets `isLoading: false`. Does NOT remove user message.
- `clearChat()`: resets `state` to initial empty `ChatState`.
- `sendSuggestion({required String caseId, required String chipText})`: alias for `sendMessage` with the chip text pre-filled.

### `AssistantScreen` — `lib/features/assistant/screens/assistant_screen.dart`

Layout (top to bottom):
1. **Guardrail Banner** — full-width amber/teal banner with shield icon and text: `AppLocalizations.of(context).assistantGuardrailBanner` (*"AI Assistant • Informational only, never diagnostic"*). Always visible, cannot be dismissed.
2. **Chat bubble list** — `ListView.builder` in reverse scroll order (newest at bottom). User bubbles right-aligned in `AppColors.deepTeal`; AI bubbles left-aligned in white with `AppColors.slateDark` text.
3. **Typing indicator** — shown when `state.isLoading == true`. Animated 3 dots using staggered `AnimationController` with 300ms offset each. Hidden when not loading.
4. **Suggestion chips row** — horizontal `Wrap` of 4 chips. Visible only when `state.messages.isEmpty`. Chips:
   - `AppLocalizations.of(context).chipMedicationSideEffects`
   - `AppLocalizations.of(context).chipWoundCareTips`
   - `AppLocalizations.of(context).chipPhysioTargets`
   - `AppLocalizations.of(context).chipEmergencyContact`
   Tapping a chip calls `ref.read(chatAssistantNotifierProvider.notifier).sendSuggestion(caseId: ..., chipText: ...)`.
5. **Message input row** — `TextField` with hint `AppLocalizations.of(context).typeMessagePlaceholder`, send `IconButton` in `AppColors.deepTeal`. Pressing send or the keyboard action calls `sendMessage`. Clears input after send. Disabled while `isLoading`.
6. **Error snackbar** — when `state.errorMessage` is non-null, show `ScaffoldMessenger` `SnackBar` with red background and error text. Reset `errorMessage` after display.

### Unit tests — `mobile/test/unit/chat_provider_test.dart`

```dart
// Test 1: sendMessage appends user message immediately before awaiting API
// Test 2: sendMessage on success appends AI reply, sets isLoading: false
// Test 3: sendMessage on HTTP error sets errorMessage, keeps user message, isLoading: false
// Test 4: sendSuggestion delegates to sendMessage with chip text
// Test 5: clearChat resets messages to []
// All using FakeApiService — no live network calls
```

### Widget test — `mobile/test/widget/assistant_screen_test.dart`

```dart
// Test 1: Guardrail banner is always visible (find by text key)
// Test 2: Suggestion chips shown when messages.isEmpty; hidden after first message
// Test 3: Typing indicator visible when isLoading; hidden when not loading
// Test 4: Chat bubble appears after sendMessage success
```

## Required context

- `mobile/lib/core/network/api_service.dart` (from WI-01) — `ApiService.post('/ai/chat', {...})`.
- `mobile/lib/core/theme/app_colors.dart` (from WI-01) — `AppColors.deepTeal`, `AppColors.slateDark`.
- `mobile/lib/core/l10n/` ARB files (from WI-03) — keys `assistantTitle`, `assistantGuardrailBanner`, `typeMessagePlaceholder`, `chipMedicationSideEffects`, `chipWoundCareTips`, `chipPhysioTargets`, `chipEmergencyContact` must exist.
- `freezed` and `freezed_annotation` (from WI-02) — `ChatState` and `ChatMessage` use `@freezed`.
- Python backend endpoint: `POST /ai/chat` → `{case_id, message}` → `{reply: String, in_scope: bool, escalate: bool}`.
- `caseId` must be obtained from `ref.watch(authNotifierProvider)` when `AuthState.authenticated` (from WI-02).
- Run `flutter test test/unit/chat_provider_test.dart test/widget/assistant_screen_test.dart` to verify.

## Acceptance criteria

- [ ] `chatAssistantNotifierProvider` exists as a `Notifier<ChatState>` in `lib/features/assistant/providers/`.
- [ ] `sendMessage` appends user message optimistically, sets `isLoading: true`, POSTs to `/ai/chat`, then appends AI reply and sets `isLoading: false` on success.
- [ ] On HTTP error, `errorMessage` is set and shown as a `SnackBar`; user message is preserved in the list.
- [ ] `AssistantScreen` renders guardrail banner, suggestion chips (when empty), chat bubbles, typing indicator, and message input field.
- [ ] Guardrail banner is always visible and cannot be dismissed.
- [ ] Suggestion chips disappear after the first message is sent.
- [ ] Typing indicator uses a staggered 3-dot animation while `isLoading`.
- [ ] All localized strings sourced from `AppLocalizations.of(context)`.
- [ ] `flutter test test/unit/chat_provider_test.dart` — all 5 unit tests pass.
- [ ] `flutter test test/widget/assistant_screen_test.dart` — all 4 widget tests pass.
- [ ] `flutter analyze` reports zero errors.

## Covers

- User Stories: 4
- Requirements: Medical UI/UX 2–4; Testing Strategy: Unit tests (chat_provider), Widget tests (assistant_screen)
- Interview Ledger: L4

## Blocked by

`02-riverpod-notifiers-auth-agenda-checkin.md`

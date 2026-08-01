import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_assistant_notifier.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getCaseId() {
    final auth = ref.read(authProvider);
    return auth.caseId ?? 'default_case';
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final caseId = _getCaseId();
    _inputController.clear();
    ref
        .read(chatAssistantNotifierProvider.notifier)
        .sendMessage(caseId: caseId, message: text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatAssistantNotifierProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen<ChatState>(chatAssistantNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
        ref.read(chatAssistantNotifierProvider.notifier).clearError();
      }
      // Scroll when a message is added OR when the streaming Assistant bubble
      // grows (message count stays constant while its text is updated).
      final previousLastText = (previous?.messages.isNotEmpty ?? false)
          ? previous!.messages.last.text
          : null;
      final nextLastText = next.messages.isNotEmpty
          ? next.messages.last.text
          : null;
      if (next.messages.length != (previous?.messages.length ?? 0) ||
          previousLastText != nextLastText) {
        _scrollToBottom();
      }
    });

    final caseId = _getCaseId();

    // The typing indicator shows only while awaiting the FIRST chunk. Once the
    // streaming Assistant bubble appears (last message is no longer the user's)
    // the growing bubble replaces it — no duplicated "thinking" affordances.
    final isAwaitingFirstChunk =
        chatState.isLoading &&
        (chatState.messages.isEmpty || chatState.messages.last.isFromUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.assistantTitle,
          style: TextStyle(
            color: AppColors.slateDark,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Guardrail Banner (persistently visible)
            const GuardrailBanner(),

            // 2. Chat bubble list
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Text(
                          l10n.assistantTitle,
                          style: TextStyle(
                            color: AppColors.greyText,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        return ChatBubble(message: msg, caseId: caseId);
                      },
                    ),
            ),

            // 3. Typing indicator (only while awaiting the first streamed chunk)
            if (isAwaitingFirstChunk) const TypingIndicator(),

            // 4. Suggestion chips row (visible when messages is empty)
            if (chatState.messages.isEmpty) SuggestionChips(caseId: caseId),

            // 5. Message input row
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.greyDivider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !chatState.isLoading,
                      decoration: InputDecoration(
                        hintText: l10n.typeMessagePlaceholder,
                        hintStyle: TextStyle(
                          color: AppColors.greyText,
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: AppColors.deepTeal,
                      size: 24.sp,
                    ),
                    onPressed: chatState.isLoading ? null : _handleSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuardrailBanner extends StatelessWidget {
  const GuardrailBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.assistantGuardrailBanner;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.softCyan,
        border: Border(
          bottom: BorderSide(
            color: AppColors.deepTeal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.deepTeal, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.deepTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestionChips extends ConsumerWidget {
  final String caseId;

  const SuggestionChips({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final chips = [
      l10n.chipMedicationSideEffects,
      l10n.chipWoundCareTips,
      l10n.chipPhysioTargets,
      l10n.chipEmergencyContact,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: chips.map((chipText) {
          return ActionChip(
            label: Text(
              chipText,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.softCyan,
            side: BorderSide(color: AppColors.deepTeal.withValues(alpha: 0.4)),
            onPressed: () {
              ref
                  .read(chatAssistantNotifierProvider.notifier)
                  .sendSuggestion(caseId: caseId, chipText: chipText);
            },
          );
        }).toList(),
      ),
    );
  }
}

class ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  final String caseId;

  const ChatBubble({super.key, required this.message, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isFromUser;

    if (!isUser && !message.inScope) {
      return RefusalBox(message: message, caseId: caseId);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: 280.w),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isUser ? AppColors.deepTeal : AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
              bottomRight: Radius.circular(isUser ? 4.r : 16.r),
            ),
            boxShadow: isUser
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: isUser ? AppColors.white : AppColors.slateDark,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class RefusalBox extends ConsumerWidget {
  final ChatMessage message;
  final String caseId;

  const RefusalBox({super.key, required this.message, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final phone = message.emergencyPhone ?? '';
    final buttonText = phone.isNotEmpty
        ? l10n.emergencyCallCtaWithPhone(phone)
        : l10n.emergencyCallCta;

    return Container(
      key: const Key('refusal_box'),
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.errorRed, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.errorRed,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.emergencyWarningTitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            message.text,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.slateDark,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('emergency_cta_button'),
              onPressed: () {
                ref
                    .read(chatAssistantNotifierProvider.notifier)
                    .onEmergencyCtaTapped(caseId, phone);
              },
              icon: Icon(Icons.phone, color: AppColors.white, size: 18.sp),
              label: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('typing_indicator'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay) % 1.0;
                  final opacity = (value < 0.5) ? (value * 2) : (2 - value * 2);
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.deepTeal.withValues(
                        alpha: (0.3 + 0.7 * opacity).clamp(0.0, 1.0),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

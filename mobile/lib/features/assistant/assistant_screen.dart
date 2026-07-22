import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasStartedChat = false;
  bool _isSending = false;

  final List<Map<String, dynamic>> _messages = [];

  final List<String> _suggestions = [
    'Can I take ibuprofen with food?',
    'What are the side effects of Amoxicillin?',
    'Is it safe to exercise today?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    final question = text.trim();
    _messageController.clear();

    setState(() {
      _hasStartedChat = true;
      _isSending = true;
      _messages.add({
        'role': 'user',
        'content': question,
        'time': _timeNow(),
      });
    });
    _scrollToBottom();

    final auth = context.read<AuthProvider>();
    String? caseId = auth.caseId;
    if (caseId == null && auth.patientId != null) {
      try {
        final caseRes = await ApiService.get('/patients/${auth.patientId}/case');
        if (caseRes.statusCode == 200) {
          caseId = jsonDecode(caseRes.body)['id'];
        }
      } catch (_) {}
    }

    String replyText = 'Sorry, I am unable to connect to the assistant server right now.';
    if (caseId != null) {
      try {
        final res = await ApiService.post('/ai/chat', {
          'case_id': caseId,
          'message': question,
        });
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          replyText = data['reply'] ?? replyText;
        } else {
          final data = jsonDecode(res.body);
          replyText = data['detail'] ?? replyText;
        }
      } catch (e) {
        replyText = 'Error sending message: ${e.toString()}';
      }
    }

    if (mounted) {
      setState(() {
        _isSending = false;
        _messages.add({
          'role': 'assistant',
          'content': replyText,
          'time': _timeNow(),
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(auth),
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: _hasStartedChat ? _buildChatView() : _buildWelcomeView(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.lg,
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.remotecare, style: AppTextStyles.heading3),
                Text(
                  '${auth.fullName ?? 'User'} · Post-op',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined, color: AppColors.black, size: AppSpacing.iconLg),
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
            child: Icon(Icons.person_outline, color: AppColors.primaryGreen, size: AppSpacing.iconMd),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen, size: AppSpacing.iconLg),
          ),
          SizedBox(width: AppSpacing.hMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.assistantTitle,
                  style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                ),
                Text(
                  'Powered by Amazon Bedrock',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                ),
                SizedBox(width: 5.w),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssistantBubble(
            'Hello! I\'m your RemoteCare recovery assistant. '
            'I can answer questions about your prescribed medications and recovery plan. '
            'I never provide diagnoses — always consult your clinician for medical decisions.',
            '09:08',
          ),
          SizedBox(height: AppSpacing.xl),
          ..._suggestions.map((q) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: GestureDetector(
                  onTap: () => _send(q),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.greyDivider, width: 0.5),
                    ),
                    child: Text(
                      q,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              )),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(Icons.info_outline, size: 12.sp, color: AppColors.greyLight),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  'Informational only · Not a diagnosis · Bedrock Guardrails active',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 10.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH, vertical: AppSpacing.lg),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: const BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
                  child: Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen, size: 14.sp),
                ),
                SizedBox(width: AppSpacing.hSm),
                Text('Thinking...', style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        final time = msg['time'] as String;

        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: const BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
                      child: Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen, size: 14.sp),
                    ),
                    SizedBox(width: AppSpacing.hSm),
                  ],
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primaryGreen : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg).copyWith(
                          bottomLeft: isUser
                              ? Radius.circular(AppSpacing.radiusLg)
                              : Radius.circular(4.r),
                          bottomRight: isUser
                              ? Radius.circular(4.r)
                              : Radius.circular(AppSpacing.radiusLg),
                        ),
                      ),
                      child: Text(
                        msg['content'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isUser ? AppColors.white : AppColors.black,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.only(left: isUser ? 0 : 36.w, right: isUser ? 0 : 0),
                child: Text(time, style: AppTextStyles.labelSmall.copyWith(fontSize: 10.sp)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssistantBubble(String text, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen, size: 14.sp),
            ),
            SizedBox(width: AppSpacing.hSm),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg).copyWith(
                    bottomLeft: Radius.circular(4.r),
                    bottomRight: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: Text(
                  text,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.black, height: 1.5),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.only(left: 36.w),
          child: Text(time, style: AppTextStyles.labelSmall.copyWith(fontSize: 10.sp)),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                hintText: 'Ask about your medications...',
                hintStyle: AppTextStyles.inputHint,
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => _send(v),
            ),
          ),
          SizedBox(width: AppSpacing.hSm),
          GestureDetector(
            onTap: () => _send(_messageController.text),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: AppColors.white, size: AppSpacing.iconMd),
            ),
          ),
        ],
      ),
    );
  }
}

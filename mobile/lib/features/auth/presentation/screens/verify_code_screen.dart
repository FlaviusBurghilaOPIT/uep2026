import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_strings.dart';
import '../providers/auth_provider.dart';
import 'create_password_screen.dart';

/// One-time code verification (WI 04). `POST /auth/patient/verify-code`:
/// - `authenticated` (returning patient) -> straight to Today.
/// - `onboarding` (invited, first run) -> create-password step (default
///   placement: immediately after code verification, first-run only).
class VerifyCodeScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await ref.read(authProvider.notifier).verifyCode(
      email: widget.email,
      code: _codeController.text.trim(),
    );

    if (!mounted) return;
    if (result == 'authenticated') {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    } else if (result == 'onboarding') {
      // verifyCode stored the backend pre-fill (name + DOB) and invite code.
      final state = ref.read(authProvider);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CreatePasswordScreen(
            email: state.email ?? widget.email,
            inviteCode: state.inviteCode ?? '',
            fullName: state.fullName ?? '',
            dateOfBirth: state.dateOfBirth,
          ),
        ),
      );
    } else {
      final message = ref.read(authProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.lg),
                Text(
                  AuthStrings.verifyCodeTitle,
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  AuthStrings.verifyCodeSubtitle(widget.email),
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: AuthStrings.codeLabel,
                  hintText: AuthStrings.codeHint,
                  prefixIcon: LucideIcons.keyRound,
                  keyboardType: TextInputType.number,
                  controller: _codeController,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                      return AuthStrings.invalidCodeError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: AuthStrings.verifyAndContinueButton,
                  isLoading: auth.isLoading,
                  onPressed: _verify,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

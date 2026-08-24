import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_strings.dart';
import '../providers/auth_provider.dart';
import 'create_password_screen.dart';

/// Direct Invitation Code verification screen for newly enrolled patients.
/// Patients enter their registered email and the 6-digit code provided by their clinician.
class InvitationCodeScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const InvitationCodeScreen({super.key, this.initialEmail});

  @override
  ConsumerState<InvitationCodeScreen> createState() => _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends ConsumerState<InvitationCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyInviteCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    final result = await ref.read(authProvider.notifier).verifyCode(
      email: email,
      code: code,
    );

    if (!mounted) return;
    if (result == 'authenticated') {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    } else if (result == 'onboarding') {
      final state = ref.read(authProvider);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CreatePasswordScreen(
            email: state.email ?? email,
            inviteCode: state.inviteCode ?? code,
            fullName: state.fullName ?? '',
            dateOfBirth: state.dateOfBirth,
          ),
        ),
      );
    } else {
      final message = ref.read(authProvider).errorMessage ?? 'Invalid or expired invitation code';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitation Code'),
      ),
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
                  'Activate Your Account',
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter the email and 6-digit invitation code provided by your clinic.',
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  label: AuthStrings.emailLabel,
                  hintText: AuthStrings.emailHint,
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return AuthStrings.requiredError;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                      return AuthStrings.invalidEmailError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.lg),

                AppTextField(
                  label: '6-DIGIT INVITATION CODE',
                  hintText: 'e.g. 849201',
                  prefixIcon: LucideIcons.keyRound,
                  keyboardType: TextInputType.number,
                  controller: _codeController,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Please enter your 6-digit code';
                    if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                      return AuthStrings.invalidCodeError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: 'Verify & Activate Account',
                  isLoading: auth.isLoading,
                  onPressed: _verifyInviteCode,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_strings.dart';
import 'onboarding_profile_screen.dart';

/// First-run "Create password" step (WI 04, spec Req 1).
///
/// Placed immediately AFTER code verification, first-run only. Rules: minimum
/// 8 characters plus a matching confirmation field — no additional complexity
/// rules. The chosen password is forwarded to [OnboardingProfileScreen] and
/// sent by `complete-onboarding` (hashed server-side); it is never persisted
/// client-side.
class CreatePasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String inviteCode;
  final String fullName;
  final String? dateOfBirth;

  const CreatePasswordScreen({
    super.key,
    required this.email,
    required this.inviteCode,
    required this.fullName,
    this.dateOfBirth,
  });

  @override
  ConsumerState<CreatePasswordScreen> createState() =>
      _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen> {
  static const int _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingProfileScreen(
          email: widget.email,
          inviteCode: widget.inviteCode,
          password: _passwordController.text,
          fullName: widget.fullName,
          dateOfBirth: widget.dateOfBirth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  AuthStrings.createPasswordTitle,
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  AuthStrings.createPasswordSubtitle,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: AuthStrings.passwordLabel,
                  hintText: AuthStrings.passwordHint,
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) {
                    if ((value ?? '').length < _minPasswordLength) {
                      return AuthStrings.passwordMinLengthError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: AuthStrings.confirmPasswordLabel,
                  hintText: AuthStrings.passwordHint,
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  controller: _confirmController,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return AuthStrings.passwordMismatchError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: AuthStrings.continueButton,
                  onPressed: _continue,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_strings.dart';
import 'onboarding_profile_screen.dart';

/// First-run "Create password" step (WI 04, spec Req 1).
///
/// Placed immediately AFTER code verification, first-run only. Rules: minimum
/// 8 characters plus a matching confirmation field. Includes real-time criteria
/// checklist and progressive entropy meter.
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
  String _passwordText = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordText = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordText.length >= _minPasswordLength;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordText);
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_passwordText);

  double get _strengthRatio {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasNumber) score++;
    if (_hasLetter) score++;
    return score / 3.0;
  }

  Color get _strengthColor {
    if (_strengthRatio < 0.4) return AppColors.errorRed;
    if (_strengthRatio < 0.8) return AppColors.warningAmber;
    return AppColors.primaryGreen;
  }

  String get _strengthLabel {
    if (_passwordText.isEmpty) return '';
    if (_strengthRatio < 0.4) return 'Weak';
    if (_strengthRatio < 0.8) return 'Good';
    return 'Strong';
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

  Widget _buildChecklistItem(String label, bool satisfied) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14.sp,
            color: satisfied ? AppColors.primaryGreen : AppColors.greyLight,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: satisfied ? AppColors.slateDark : AppColors.greyText,
              fontWeight: satisfied ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
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
                if (_passwordText.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: _strengthRatio,
                            backgroundColor: AppColors.greyDivider,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_strengthColor),
                            minHeight: 4.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _strengthLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _strengthColor,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: AppSpacing.sm),
                _buildChecklistItem('At least 8 characters', _hasMinLength),
                _buildChecklistItem('Includes a letter', _hasLetter),
                _buildChecklistItem('Includes a number', _hasNumber),
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

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

/// First-run "Create password" step (WI 04, WI 08, spec Req 1/Req 8).
///
/// Placed immediately AFTER code verification, first-run only. Rules: minimum
/// 8 characters, uppercase, lowercase, number, special character plus a matching
/// confirmation field. Includes real-time criteria checklist and progressive
/// entropy meter.
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
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordText);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordText);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordText);
  bool get _hasSpecialChar => RegExp(r'[^a-zA-Z0-9]').hasMatch(_passwordText);

  bool get _allCriteriaMet =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar;

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score;
  }

  int get _activeStrengthSegments {
    if (_passwordText.isEmpty) return 0;
    if (_strengthScore <= 2) return 1;
    if (_strengthScore <= 4) return 2;
    return 3;
  }

  Color get _strengthColor {
    if (_passwordText.isEmpty) return AppColors.greyDivider;
    if (_activeStrengthSegments == 1) return AppColors.errorRed;
    if (_activeStrengthSegments == 2) return AppColors.warningAmber;
    return AppColors.primaryGreen;
  }

  String get _strengthLabel {
    if (_passwordText.isEmpty) return '';
    if (_activeStrengthSegments == 1) return 'Weak';
    if (_activeStrengthSegments == 2) return 'Medium';
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

  Widget _buildSegmentedStrengthBar() {
    final activeSegments = _activeStrengthSegments;
    final color = _strengthColor;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              final isFilled = index < activeSegments;
              return Expanded(
                child: Container(
                  key: Key('strength_segment_$index'),
                  height: 4.h,
                  margin: EdgeInsets.only(right: index < 2 ? 6.w : 0),
                  decoration: BoxDecoration(
                    color: isFilled ? color : AppColors.greyDivider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              );
            }),
          ),
        ),
        if (_strengthLabel.isNotEmpty) ...[
          SizedBox(width: 8.w),
          Text(
            _strengthLabel,
            key: const Key('strength_label'),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
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
                SizedBox(height: AppSpacing.xs),
                _buildSegmentedStrengthBar(),
                SizedBox(height: AppSpacing.sm),
                _buildChecklistItem('At least 8 characters', _hasMinLength),
                _buildChecklistItem('Uppercase letter', _hasUppercase),
                _buildChecklistItem('Lowercase letter', _hasLowercase),
                _buildChecklistItem('Number', _hasNumber),
                _buildChecklistItem('Special character', _hasSpecialChar),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: const Key('confirm_password_field'),
                  label: AuthStrings.confirmPasswordLabel,
                  hintText: AuthStrings.passwordHint,
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  enabled: _allCriteriaMet,
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
                  onPressed: _allCriteriaMet ? _continue : null,
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

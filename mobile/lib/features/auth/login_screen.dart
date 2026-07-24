import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/shared_widgets/app_text_field.dart';
import '../../core/shared_widgets/app_button.dart';
import '../../core/navigation/app_routes.dart';

enum _AuthStage { email, code }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  _AuthStage _stage = _AuthStage.email;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final success = await auth.requestCode(email: _emailController.text.trim());

    if (success && mounted) {
      setState(() => _stage = _AuthStage.code);
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final result = await auth.verifyCode(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
    );

    if (!mounted) return;
    if (result == 'authenticated') {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    } else if (result == 'onboarding') {
      AppRoutes.navigateTo(context, AppRoutes.signupStep2);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isEmailStage = _stage == _AuthStage.email;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.lg),

                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: const BoxDecoration(
                      color: AppColors.inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.black,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xxl),

                Text(
                  isEmailStage
                      ? AppStrings.welcomeBack
                      : AppStrings.verifyEmail,
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  isEmailStage
                      ? AppStrings.signInSubtitle
                      : AppStrings.verificationSent,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),

                if (isEmailStage)
                  AppTextField(
                    label: AppStrings.email,
                    hintText: AppStrings.emailHint,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  )
                else ...[
                  AppTextField(
                    label: AppStrings.enterCode,
                    hintText: '000000',
                    prefixIcon: Icons.vpn_key_outlined,
                    keyboardType: TextInputType.number,
                    controller: _codeController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your code';
                      }
                      if (value.trim().length < 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleSendCode,
                      child: Text(
                        AppStrings.resendCode,
                        style: AppTextStyles.linkText.copyWith(
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: isEmailStage
                      ? AppStrings.signIn
                      : AppStrings.verifyAndContinue,
                  isLoading: auth.isLoading,
                  onPressed: isEmailStage ? _handleSendCode : _handleVerifyCode,
                ),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

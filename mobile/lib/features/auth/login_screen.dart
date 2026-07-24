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
import '../../core/shared_widgets/security_badge.dart';
import '../../core/navigation/app_routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

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
                    decoration: BoxDecoration(
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

                Text(AppStrings.welcomeBack, style: AppTextStyles.heading1),
                SizedBox(height: AppSpacing.sm),
                Text(AppStrings.signInSubtitle, style: AppTextStyles.subtitle),
                SizedBox(height: AppSpacing.xxl),

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
                ),
                SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: AppStrings.password,
                  hintText: AppStrings.passwordHint,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        AppRoutes.navigateTo(context, AppRoutes.forgotPassword),
                    child: Text(
                      AppStrings.forgotPassword,
                      style: AppTextStyles.linkText.copyWith(
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                SecurityBadge(
                  text: AppStrings.cognitoSecurityPrefix,
                  boldText: AppStrings.cognitoSecurityBold,
                  suffixText: AppStrings.cognitoSecuritySuffix,
                ),
                SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: AppStrings.signIn,
                  isLoading: auth.isLoading,
                  onPressed: _handleSignIn,
                ),
                SizedBox(height: AppSpacing.lg),

                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        AppStrings.noAccountYet,
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => AppRoutes.navigateTo(
                          context,
                          AppRoutes.signupStep1,
                        ),
                        child: Text(
                          AppStrings.createOne,
                          style: AppTextStyles.linkText,
                        ),
                      ),
                    ],
                  ),
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

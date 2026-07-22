import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/shared_widgets/app_text_field.dart';
import '../../core/shared_widgets/app_button.dart';
import '../../core/shared_widgets/step_progress_bar.dart';
import '../../core/navigation/app_routes.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.setSignUpInfo(
      fullName: auth.fullName ?? '',
      email: auth.email ?? '',
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    AppRoutes.navigateTo(context, AppRoutes.signupStep3);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                const StepProgressBar(currentStep: 2),
                SizedBox(height: AppSpacing.xxl),

                Text('Welcome, ${auth.fullName ?? 'Patient'}!', style: AppTextStyles.heading1),
                SizedBox(height: AppSpacing.sm),
                Text('Set up your contact details and account password', style: AppTextStyles.subtitle),
                SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  label: AppStrings.phoneNumber,
                  hintText: AppStrings.phoneHint,
                  prefixIcon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: AppStrings.password,
                  hintText: AppStrings.passwordMinHint,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xxxl),

                AppButton(
                  text: AppStrings.continueText,
                  onPressed: _handleContinue,
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

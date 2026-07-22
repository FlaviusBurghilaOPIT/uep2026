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

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyInvite(
      email: _emailController.text.trim(),
      inviteCode: _inviteCodeController.text.trim(),
    );

    if (success && mounted) {
      AppRoutes.navigateTo(context, AppRoutes.signupStep2);
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
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
                const StepProgressBar(currentStep: 1),
                SizedBox(height: AppSpacing.xxl),

                Text('Verify Invitation', style: AppTextStyles.heading1),
                SizedBox(height: AppSpacing.sm),
                Text('Enter the email and 6-digit invite code provided by your clinician', style: AppTextStyles.subtitle),
                SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  label: AppStrings.emailAddress,
                  hintText: AppStrings.emailAddressHint,
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
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
                  label: '6-Digit Invite Code',
                  hintText: 'e.g. 123456',
                  prefixIcon: Icons.vpn_key_outlined,
                  controller: _inviteCodeController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your invite code';
                    }
                    if (value.trim().length < 6) {
                      return 'Invite code must be 6 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xxxl),

                AppButton(
                  text: 'Verify & Continue',
                  isLoading: auth.isLoading,
                  onPressed: _handleVerify,
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

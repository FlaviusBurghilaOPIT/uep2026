import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../core/navigation/app_routes.dart';

class SignupStep2Screen extends ConsumerStatefulWidget {
  const SignupStep2Screen({super.key});

  @override
  ConsumerState<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends ConsumerState<SignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    ref
        .read(authProvider.notifier)
        .setSignUpInfo(
          fullName: authState.fullName ?? '',
          email: authState.email ?? '',
          phone: _phoneController.text.trim(),
        );

    AppRoutes.navigateTo(context, AppRoutes.signupStep3);
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
                const StepProgressBar(currentStep: 2),
                SizedBox(height: AppSpacing.xxl),

                Text(
                  'Welcome, ${auth.fullName ?? 'Patient'}!',
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Set up your contact details',
                  style: AppTextStyles.subtitle,
                ),
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

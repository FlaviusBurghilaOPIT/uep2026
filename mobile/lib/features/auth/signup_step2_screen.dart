import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/shared_widgets/app_button.dart';
import '../../core/shared_widgets/step_progress_bar.dart';
import '../../core/navigation/app_routes.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final code = _code;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyCode(code);

    if (success && mounted) {
      AppRoutes.navigateTo(context, AppRoutes.signupStep3);
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.lg),

              const StepProgressBar(currentStep: 2),
              SizedBox(height: AppSpacing.xxl),

              Text(AppStrings.verifyEmail, style: AppTextStyles.heading1),
              SizedBox(height: AppSpacing.sm),
              Text(AppStrings.verificationSent, style: AppTextStyles.subtitle),
              SizedBox(height: AppSpacing.xxxl),

              Text(AppStrings.enterCode, style: AppTextStyles.label),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48.w,
                    height: 56.h,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: AppTextStyles.heading3,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              SizedBox(height: AppSpacing.xl),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.didntReceiveCode,
                      style: AppTextStyles.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code resent!')),
                        );
                      },
                      child: Text(
                        AppStrings.resendCode,
                        style: AppTextStyles.linkText,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppButton(
                text: AppStrings.verifyAndContinue,
                isLoading: auth.isLoading,
                onPressed: _handleVerify,
              ),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

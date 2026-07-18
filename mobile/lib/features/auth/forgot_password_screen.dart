import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/shared_widgets/app_text_field.dart';
import '../../core/shared_widgets/app_button.dart';
import '../../core/navigation/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  int _step = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reset code sent to ${_emailController.text.trim()}')),
    );
  }

  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 3);
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset successfully')),
    );
    AppRoutes.navigateAndClearStack(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primaryGreen,
                  size: 48.sp,
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  _step == 1
                      ? 'Forgot password'
                      : (_step == 2 ? 'Enter code' : 'New password'),
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  _step == 1
                      ? "Enter your email and we'll send you a reset code"
                      : (_step == 2
                          ? 'Enter the 6-digit code sent to your email'
                          : 'Create a new password for your account'),
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),
                if (_step == 1) _buildEmailStep(),
                if (_step == 2) _buildCodeStep(),
                if (_step == 3) _buildPasswordStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        AppTextField(
          label: 'EMAIL',
          hintText: 'sarah.mitchell@email.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(text: 'Send Reset Code', onPressed: _sendCode),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        AppTextField(
          label: 'VERIFICATION CODE',
          hintText: '000000',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          controller: _codeController,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter the code';
            if (value.length != 6) return 'Code must be 6 digits';
            return null;
          },
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(text: 'Verify Code', onPressed: _verifyCode),
        SizedBox(height: AppSpacing.lg),
        Center(
          child: GestureDetector(
            onTap: _sendCode,
            child: Text(
              'Resend code',
              style: AppTextStyles.linkText.copyWith(decoration: TextDecoration.none),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        AppTextField(
          label: 'NEW PASSWORD',
          hintText: 'Min. 8 characters',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _passwordController,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
        SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'CONFIRM PASSWORD',
          hintText: 'Re-enter password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _confirmController,
          validator: (value) {
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(text: 'Reset Password', onPressed: _resetPassword),
      ],
    );
  }
}

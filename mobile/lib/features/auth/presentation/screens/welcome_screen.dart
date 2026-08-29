import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_strings.dart';
import '../providers/auth_provider.dart';
import 'invitation_code_screen.dart';
import 'request_code_screen.dart';

/// Hybrid-auth Welcome screen (WI 04, WI 12 COPY-03).
///
/// Offers disambiguated sign-in methods:
/// 1. "Clinician Sign In" (email + password form),
/// 2. "New Patient? Enter Clinic Invitation" (for newly enrolled patients),
/// 3. "Sign in with One-Time Code" (email OTP code request).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    } else {
      final message =
          ref.read(authProvider).errorMessage ??
          AuthStrings.invalidCredentials;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openInviteCodeSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvitationCodeScreen(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
  }

  void _openCodeSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RequestCodeScreen()),
    );
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
                SizedBox(height: AppSpacing.md),
                Container(
                  key: const Key('welcome_hero_illustration'),
                  height: 140.h.clamp(120.0, 180.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.softCyan,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.heartHandshake,
                      size: 48.sp.clamp(36.0, 60.0),
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(AuthStrings.welcomeTitle, style: AppTextStyles.heading1),
                SizedBox(height: AppSpacing.sm),
                Text(AuthStrings.welcomeSubtitle, style: AppTextStyles.subtitle),
                SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: AuthStrings.emailLabel,
                  hintText: AuthStrings.emailHint,
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  controller: _emailController,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return AuthStrings.requiredError;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                      return AuthStrings.invalidEmailError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: AuthStrings.passwordLabel,
                  hintText: AuthStrings.passwordHint,
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AuthStrings.requiredError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: AuthStrings.clinicianSignInButton,
                  isLoading: auth.isLoading,
                  onPressed: _signInWithPassword,
                ),
                SizedBox(height: AppSpacing.md),

                // Primary patient onboarding action: Invitation Code
                AppButton(
                  text: AuthStrings.clinicInvitationButton,
                  isOutlined: true,
                  icon: LucideIcons.keyRound,
                  onPressed: _openInviteCodeSignIn,
                ),
                SizedBox(height: AppSpacing.lg),

                // Fallback sign-in method: email OTP
                Center(
                  child: TextButton(
                    onPressed: _openCodeSignIn,
                    child: Text(
                      AuthStrings.codeSignInLink,
                      style: AppTextStyles.linkText,
                    ),
                  ),
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

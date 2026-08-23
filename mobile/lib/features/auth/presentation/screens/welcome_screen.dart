import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_strings.dart';
import '../providers/auth_provider.dart';
import 'request_code_screen.dart';

/// Hybrid-auth Welcome screen (WI 04, spec Req 2).
///
/// Offers TWO sign-in methods: email + password (PRIMARY) and an
/// "email me a one-time code" fallback. Both land on Today on success.
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
                SizedBox(height: AppSpacing.xxxl),
                Text(AuthStrings.welcomeTitle, style: AppTextStyles.heading1),
                SizedBox(height: AppSpacing.sm),
                Text(AuthStrings.welcomeSubtitle, style: AppTextStyles.subtitle),
                SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  label: AuthStrings.emailLabel,
                  hintText: AuthStrings.emailHint,
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
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
                  text: AuthStrings.signInButton,
                  isLoading: auth.isLoading,
                  onPressed: _signInWithPassword,
                ),
                SizedBox(height: AppSpacing.lg),

                // Fallback sign-in method (spec Req 2 / Open Questions).
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

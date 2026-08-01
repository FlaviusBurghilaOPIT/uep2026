import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_strings.dart';
import '../providers/auth_provider.dart';
import 'verify_code_screen.dart';

/// Code-fallback entry (WI 04, spec Req 2/3): collect the patient's email and
/// send a one-time code via `POST /auth/patient/request-code`, then advance to
/// [VerifyCodeScreen]. Also serves as the account-recovery entry point.
class RequestCodeScreen extends ConsumerStatefulWidget {
  const RequestCodeScreen({super.key});

  @override
  ConsumerState<RequestCodeScreen> createState() => _RequestCodeScreenState();
}

class _RequestCodeScreenState extends ConsumerState<RequestCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final success = await ref.read(authProvider.notifier).requestCode(
      email: email,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VerifyCodeScreen(email: email),
        ),
      );
    } else {
      final message = ref.read(authProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

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
                  AuthStrings.requestCodeTitle,
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  AuthStrings.requestCodeSubtitle,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: AuthStrings.emailLabel,
                  hintText: AuthStrings.emailHint,
                  prefixIcon: Icons.email_outlined,
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
                SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: AuthStrings.sendCodeButton,
                  isLoading: auth.isLoading,
                  onPressed: _sendCode,
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

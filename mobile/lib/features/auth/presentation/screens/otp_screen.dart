import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/navigation/app_routes.dart';
import '../providers/demo_auth_provider.dart';
import '../../../../core/l10n/app_localizations.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(demoAuthProvider.notifier).completeOtpLogin();
      if (mounted) {
        AppRoutes.navigateAndClearStack(context, AppRoutes.main);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(demoAuthProvider).value;
    final email = authState?.email ?? '';
    final emailText = email.isNotEmpty
        ? l10n.authOtpSentToEmail(email)
        : l10n.authOtpSentToEmailFallback;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authEnterOtpTitle)),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.authVerifyIdentityTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16.h),
              Text(
                emailText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 32.h),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: l10n.authOtpCodeLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.length != 6) {
                    return l10n.authOtpCodeLengthError;
                  }
                  if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
                    return l10n.authOtpCodeNumericError;
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                ),
                child: Text(l10n.authVerifyAndLogInButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

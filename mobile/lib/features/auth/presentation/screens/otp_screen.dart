import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/segmented_otp_input.dart';
import '../providers/demo_auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      }
    });
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0) return;
    final l10n = AppLocalizations.of(context);
    final email = ref.read(demoAuthProvider).value?.email ?? '';
    _startCountdown();
    await ref.read(demoAuthProvider.notifier).triggerOtp(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          email.isNotEmpty
              ? l10n.authCodeResentSnackbar(email)
              : l10n.authCodeResentSnackbarFallback,
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(demoAuthProvider.notifier).completeOtpLogin();
      if (mounted) {
        AppRoutes.navigateAndClearStack(context, AppRoutes.main);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              SegmentedOtpInput(
                controller: _otpController,
                onCompleted: (val) => _submit(),
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
              SizedBox(height: 16.h),
              TextButton(
                onPressed: _secondsRemaining == 0 ? _resendCode : null,
                child: Text(
                  _secondsRemaining > 0
                      ? l10n.authResendCodeCountdown(_secondsRemaining)
                      : l10n.authResendCode,
                  style: TextStyle(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: _secondsRemaining > 0
                        ? AppColors.greyLight
                        : AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



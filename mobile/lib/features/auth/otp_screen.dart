import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/navigation/app_routes.dart';
import 'demo_auth_state.dart';

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
    final authState = ref.watch(demoAuthProvider).valueOrNull;
    final email = authState?.email ?? '';
    final emailText = email.isNotEmpty
        ? 'Please enter the 6-digit code sent to $email.'
        : 'Please enter the 6-digit code sent to your email.';

    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Verify Identity',
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
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.length != 6) {
                    return 'Code must be exactly 6 digits';
                  }
                  if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
                    return 'Code must be numeric';
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
                child: const Text('Verify and Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

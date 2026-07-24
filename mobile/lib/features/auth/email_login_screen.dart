import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/app_routes.dart';
import 'demo_auth_state.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(demoAuthProvider).valueOrNull;
    _emailController = TextEditingController(text: authState?.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(demoAuthProvider.notifier).triggerOtp(_emailController.text.trim());
        if (mounted) {
          AppRoutes.navigateAndReplace(context, AppRoutes.otp);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending OTP: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

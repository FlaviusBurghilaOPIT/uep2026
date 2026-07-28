import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/app_routes.dart';
import 'demo_auth_state.dart';
import '../../core/l10n/app_localizations.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(demoAuthProvider.notifier)
          .completeProfileSetup(_emailController.text.trim());
      if (mounted) {
        AppRoutes.navigateAndClearStack(context, AppRoutes.main);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authProfileSetupTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.authNameLabel),
                validator: (val) => val == null || val.trim().isEmpty
                    ? l10n.authRequiredError
                    : null,
              ),
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: l10n.authSurnameLabel),
                validator: (val) => val == null || val.trim().isEmpty
                    ? l10n.authRequiredError
                    : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.authEmailLabel),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return l10n.authRequiredError;
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(val))
                    return l10n.authInvalidEmailError;
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: l10n.authAgeLabel),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return l10n.authRequiredError;
                  final age = int.tryParse(val);
                  if (age == null || age <= 0) return l10n.authInvalidAgeError;
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.authSaveAndEnterAppButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/l10n/app_localizations.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode() {
    if (_formKey.currentState?.validate() ?? false) {
      final code = _codeController.text.trim();
      if (code.isNotEmpty) {
        AppRoutes.navigateAndReplace(context, AppRoutes.profileSetup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authEnterInvitationCodeTitle)),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.authWelcomeTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.authInvitationCodeSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 32.h),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: l10n.authInvitationCodeLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.authInvalidInvitationCodeError;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submitCode(),
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: _submitCode,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                ),
                child: Text(l10n.authContinueButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

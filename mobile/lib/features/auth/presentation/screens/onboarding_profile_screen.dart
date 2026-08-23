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

/// First-run onboarding profile step (WI 04, spec Req 9/10/11).
///
/// Name and date of birth are PRE-FILLED from the backend (captured at
/// clinician intake / surfaced by verify-code) and EDITABLE — the patient
/// confirms or corrects. Phone is patient-provided. `complete-onboarding`
/// persists the edits, the phone, and the hybrid-auth password.
class OnboardingProfileScreen extends ConsumerStatefulWidget {
  final String email;
  final String inviteCode;
  final String password;
  final String fullName;
  final String? dateOfBirth;

  const OnboardingProfileScreen({
    super.key,
    required this.email,
    required this.inviteCode,
    required this.password,
    required this.fullName,
    this.dateOfBirth,
  });

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill from the backend (clinic-held truth), editable by the patient.
    _nameController = TextEditingController(text: widget.fullName);
    _dobController = TextEditingController(text: widget.dateOfBirth ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final dob = _dobController.text.trim();
    final name = _nameController.text.trim();
    final success = await ref
        .read(authProvider.notifier)
        .completeOnboarding(
          email: widget.email,
          inviteCode: widget.inviteCode,
          // Optional fields: only sent when the patient actually changed them so
          // the backend preserves the intake value otherwise; otherwise persists
          // the patient's edit (Req 9 "confirms or corrects").
          dateOfBirth: dob.isEmpty ? null : dob,
          fullName: (name.isEmpty || name == widget.fullName) ? null : name,
          phone: _phoneController.text.trim(),
          password: widget.password,
        );

    if (!mounted) return;
    if (success) {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
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
                Text(AuthStrings.profileTitle, style: AppTextStyles.heading1),
                SizedBox(height: AppSpacing.sm),
                Text(
                  AuthStrings.profileSubtitle,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: AuthStrings.fullNameLabel,
                  hintText: AuthStrings.fullNameHint,
                  prefixIcon: LucideIcons.user,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AuthStrings.requiredError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: AuthStrings.dateOfBirthLabel,
                  hintText: AuthStrings.dateOfBirthHint,
                  prefixIcon: LucideIcons.calendar,
                  keyboardType: TextInputType.datetime,
                  controller: _dobController,
                ),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: AuthStrings.phoneLabel,
                  hintText: AuthStrings.phoneHint,
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AuthStrings.requiredError;
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: AuthStrings.completeSetupButton,
                  isLoading: auth.isLoading,
                  onPressed: _complete,
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

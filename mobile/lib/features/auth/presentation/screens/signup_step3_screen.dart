import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../core/widgets/security_badge.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/navigation/app_routes.dart';

class SignupStep3Screen extends ConsumerStatefulWidget {
  const SignupStep3Screen({super.key});

  @override
  ConsumerState<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends ConsumerState<SignupStep3Screen> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String get _formattedDateDisplay {
    if (_selectedDate == null) return AppStrings.dateHint;
    final d = _selectedDate!;
    return '${d.month.toString().padLeft(2, '0')} / ${d.day.toString().padLeft(2, '0')} / ${d.year}';
  }

  String get _formattedIsoDate {
    if (_selectedDate == null) return '';
    final d = _selectedDate!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleComplete() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).authSelectDobError),
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final auth = ref.read(authProvider.notifier);
    final success = await auth.completeOnboarding(
      email: authState.email ?? '',
      inviteCode: authState.inviteCode ?? '',
      dateOfBirth: _formattedIsoDate,
      phone: authState.phone ?? '',
    );

    if (success && mounted) {
      final l10n = AppLocalizations.of(context);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.notificationReminderTitle),
          content: Text(l10n.notificationPermissionRationale),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context).okButton),
            ),
          ],
        ),
      );
      await NotificationService.instance.requestPermissions();
      if (mounted) {
        AppRoutes.navigateAndClearStack(context, AppRoutes.main);
      }
    } else if (mounted) {
      final errorMessage = ref.read(authProvider).errorMessage;
      if (errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.lg),
              const StepProgressBar(currentStep: 3),
              SizedBox(height: AppSpacing.xxl),

              Text(AppStrings.yourHealthProfile, style: AppTextStyles.heading1),
              SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context).authCompleteProfileSetupSubtitle,
                style: AppTextStyles.subtitle,
              ),
              SizedBox(height: AppSpacing.xxl),

              Text(AppStrings.dateOfBirth, style: AppTextStyles.label),
              SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  height: AppSpacing.inputHeight,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.greyLight,
                        size: AppSpacing.iconMd,
                      ),
                      SizedBox(width: AppSpacing.hMd),
                      Text(
                        _formattedDateDisplay,
                        style: _selectedDate != null
                            ? AppTextStyles.inputText
                            : AppTextStyles.inputHint,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              SecurityBadge(text: AppStrings.healthInfoEncrypted),
              SizedBox(height: AppSpacing.xxl),

              AppButton(
                text: AppStrings.completeSetup,
                isLoading: auth.isLoading,
                onPressed: _handleComplete,
              ),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

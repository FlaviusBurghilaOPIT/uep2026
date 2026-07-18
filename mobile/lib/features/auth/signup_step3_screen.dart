import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/shared_widgets/app_button.dart';
import '../../core/shared_widgets/step_progress_bar.dart';
import '../../core/shared_widgets/condition_chip.dart';
import '../../core/shared_widgets/security_badge.dart';
import '../../core/navigation/app_routes.dart';

class SignupStep3Screen extends StatefulWidget {
  const SignupStep3Screen({super.key});

  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  DateTime? _selectedDate;
  String? _selectedCondition;

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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String get _formattedDate {
    if (_selectedDate == null) return AppStrings.dateHint;
    final d = _selectedDate!;
    return '${d.month.toString().padLeft(2, '0')} / ${d.day.toString().padLeft(2, '0')} / ${d.year}';
  }

  Future<void> _handleComplete() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }
    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a primary condition')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.completeSetup(
      dateOfBirth: _formattedDate,
      primaryCondition: _selectedCondition!,
    );

    if (success && mounted) {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
              Text(AppStrings.personalizeExperience, style: AppTextStyles.subtitle),
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
                        _formattedDate,
                        style: _selectedDate != null
                            ? AppTextStyles.inputText
                            : AppTextStyles.inputHint,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              Text(AppStrings.primaryCondition, style: AppTextStyles.label),
              SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: AppStrings.conditions.map((condition) {
                  return ConditionChip(
                    label: condition,
                    isSelected: _selectedCondition == condition,
                    onTap: () {
                      setState(() => _selectedCondition = condition);
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.xxl),

              SecurityBadge(
                text: AppStrings.healthInfoEncrypted,
              ),
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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: AppColors.black,
              size: AppSpacing.iconMd,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.hMd),
        Text(
          'Step $currentStep of $totalSteps',
          style: AppTextStyles.bodyMedium,
        ),
        SizedBox(width: AppSpacing.hMd),
        Expanded(
          child: Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index < currentStep;
              return Expanded(
                child: Container(
                  height: 4.h,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 4.w : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGreen
                        : AppColors.greyDivider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

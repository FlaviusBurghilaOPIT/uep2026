import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class SecurityBadge extends StatelessWidget {
  final String text;
  final String? boldText;
  final String? suffixText;
  final IconData icon;

  const SecurityBadge({
    super.key,
    required this.text,
    this.boldText,
    this.suffixText,
    this.icon = LucideIcons.shieldCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: AppSpacing.iconLg,
          ),
          SizedBox(width: AppSpacing.hMd),
          Expanded(
            child: _buildText(),
          ),
        ],
      ),
    );
  }

  Widget _buildText() {
    if (boldText != null) {
      return RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.greyText,
          ),
          children: [
            TextSpan(text: text),
            TextSpan(
              text: boldText,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            if (suffixText != null) TextSpan(text: suffixText),
          ],
        ),
      );
    }

    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.greyText,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class SocialLoginRow extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onXTap;
  final VoidCallback? onAppleTap;

  const SocialLoginRow({
    super.key,
    this.onGoogleTap,
    this.onFacebookTap,
    this.onXTap,
    this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.hLg),
              child: Text(
                'or sign in with',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialIcon(
              icon: Icons.g_mobiledata_rounded,
              label: 'Google',
              onTap: onGoogleTap,
              iconSize: 28.sp,
            ),
            SizedBox(width: AppSpacing.xl),
            _SocialIcon(
              icon: Icons.facebook_rounded,
              label: 'Facebook',
              onTap: onFacebookTap,
              color: const Color(0xFF1877F2),
            ),
            SizedBox(width: AppSpacing.xl),
            _SocialIcon(
              icon: Icons.close,
              label: 'X',
              onTap: onXTap,
            ),
            SizedBox(width: AppSpacing.xl),
            _SocialIcon(
              icon: Icons.apple_rounded,
              label: 'Apple',
              onTap: onAppleTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final double? iconSize;

  const _SocialIcon({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label sign-in coming soon'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.greyDivider, width: 1),
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.black,
          size: iconSize ?? AppSpacing.iconLg,
        ),
      ),
    );
  }
}

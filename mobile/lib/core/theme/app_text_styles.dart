import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Medical design system text styles.
///
/// Display / heading styles use [GoogleFonts.outfit] for a modern clinical feel.
/// Body / caption styles use [GoogleFonts.inter] for maximum readability.
class AppTextStyles {
  AppTextStyles._();

  // ── Heading / Display (Outfit) ──────────────────────────────────────────

  static TextStyle get display => GoogleFonts.outfit(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.slateDark,
        height: 1.1,
      );

  static TextStyle get heading1 => GoogleFonts.outfit(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.slateDark,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.outfit(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.slateDark,
        height: 1.25,
      );

  static TextStyle get heading3 => GoogleFonts.outfit(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.slateDark,
        height: 1.3,
      );

  // ── Body / Caption (Inter) ──────────────────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.slateDark,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.greyText,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.greyText,
        height: 1.5,
      );

  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.greyText,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.greyText,
        letterSpacing: 1.2,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.greyLight,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        height: 1.0,
      );

  static TextStyle get buttonTextOutlined => GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.deepTeal,
        height: 1.0,
      );

  static TextStyle get linkText => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.deepTeal,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.deepTeal,
        height: 1.5,
      );

  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.slateDark,
        height: 1.4,
      );

  static TextStyle get inputHint => GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.greyLight,
        height: 1.4,
      );

  static TextStyle get otpDigitText => GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.slateDark,
        letterSpacing: 2.0,
        height: 1.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get countdownText => GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

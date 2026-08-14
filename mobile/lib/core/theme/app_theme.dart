import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Medical design system theme for RemoteCare Pro.
///
/// Usage:
/// ```dart
/// MaterialApp(theme: AppTheme.light())
/// ```
class AppTheme {
  AppTheme._();

  /// Light theme seeded from [AppColors.deepTeal].
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      primaryColor: AppColors.deepTeal,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepTeal,
        primary: AppColors.deepTeal,
        onPrimary: AppColors.white,
        surface: AppColors.scaffoldBg,
        error: AppColors.errorRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.slateDark),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.slateDark,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.slateDark,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.slateDark,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.slateDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.slateDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.greyText,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.greyText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepTeal,
          foregroundColor: AppColors.white,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepTeal,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          side: const BorderSide(color: AppColors.deepTeal, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 18.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(
            color: AppColors.deepTeal,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 1.5,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15.sp,
          color: AppColors.greyLight,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.greyDivider,
        thickness: 1,
      ),
    );
  }

  /// Legacy alias — prefer [AppTheme.light()].
  @Deprecated('Use AppTheme.light() instead')
  static ThemeData get lightTheme => light();
}

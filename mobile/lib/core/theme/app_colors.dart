import 'package:flutter/material.dart';

/// Medical design system colour palette for RemoteCare Pro.
class AppColors {
  AppColors._();

  // --- Brand palette (WI-01 design tokens) ---
  static const deepTeal = Color(0xFF0D9488);
  static const softCyan = Color(0xFFF0FDF4);
  static const clinicalEmerald = Color(0xFF059669);
  static const slateDark = Color(0xFF0F172A);
  static const white = Color(0xFFFFFFFF);
  static const errorRed = Color(0xFFDC2626);

  // --- Extended palette (kept from legacy for screen compatibility) ---
  static const primaryGreen = Color(0xFF1B7D5A);
  static const darkGreen = Color(0xFF0E5C3F);
  static const lightGreen = Color(0xFFE8F5F0);
  static const mintGreen = Color(0xFFF0F7F4);
  static const tealGradStart = Color(0xFF0E5C3F);
  static const tealGradEnd = Color(0xFF3DAF8F);

  static const black = Color(0xFF1A1A1A);
  static const greyText = Color(0xFF6B7280);
  static const greyLight = Color(0xFF9CA3AF);
  static const greyDivider = Color(0xFFE5E7EB);

  static const inputBorder = Color(0xFFE5E7EB);
  static const inputFill = Color(0xFFF3F4F6);
  static const cardBg = Color(0xFFF9FAFB);
  static const scaffoldBg = Color(0xFFFFFFFF);

  static const successGreen = Color(0xFF10B981);
  static const warningAmber = Color(0xFFF59E0B);
  static const infoBlue = Color(0xFF3B82F6);

  static const takenBg = Color(0xFFDCFCE7);
  static const takenText = Color(0xFF166534);
  static const pendingBg = Color(0xFFFEF9C3);
  static const pendingText = Color(0xFF854D0E);
  static const missedBg = Color(0xFFFEE2E2);
  static const missedText = Color(0xFF991B1B);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealGradStart, tealGradEnd],
  );
}

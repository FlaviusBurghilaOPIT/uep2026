import 'package:flutter/material.dart';


class AppColors {
  AppColors._();

  static const Color primaryGreen  = Color(0xFF1B7D5A);
  static const Color darkGreen     = Color(0xFF0E5C3F);
  static const Color lightGreen    = Color(0xFFE8F5F0);
  static const Color mintGreen     = Color(0xFFF0F7F4);
  static const Color tealGradStart = Color(0xFF0E5C3F);
  static const Color tealGradEnd   = Color(0xFF3DAF8F);

  static const Color white         = Color(0xFFFFFFFF);
  static const Color black         = Color(0xFF1A1A1A);
  static const Color greyText      = Color(0xFF6B7280);
  static const Color greyLight     = Color(0xFF9CA3AF);
  static const Color greyDivider   = Color(0xFFE5E7EB);

  static const Color inputBorder   = Color(0xFFE5E7EB);
  static const Color inputFill     = Color(0xFFF3F4F6);
  static const Color cardBg        = Color(0xFFF9FAFB);
  static const Color scaffoldBg    = Color(0xFFFFFFFF);

  static const Color errorRed      = Color(0xFFEF4444);
  static const Color successGreen  = Color(0xFF10B981);
  static const Color warningAmber  = Color(0xFFF59E0B);
  static const Color infoBlue      = Color(0xFF3B82F6);

  static const Color takenBg       = Color(0xFFDCFCE7);
  static const Color takenText     = Color(0xFF166534);
  static const Color pendingBg     = Color(0xFFFEF9C3);
  static const Color pendingText   = Color(0xFF854D0E);
  static const Color missedBg      = Color(0xFFFEE2E2);
  static const Color missedText    = Color(0xFF991B1B);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealGradStart, tealGradEnd],
  );
}

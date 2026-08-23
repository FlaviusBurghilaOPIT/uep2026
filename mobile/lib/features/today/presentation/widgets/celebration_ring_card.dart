import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';

/// "Day Complete" Ring Closure & Recovery Sparkle signature moment (spec §2).
/// Executes a 600ms circular sweep with emerald glow, haptic pulse, and reassuring closure.
class CelebrationRingCard extends StatefulWidget {
  const CelebrationRingCard({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  State<CelebrationRingCard> createState() => _CelebrationRingCardState();
}

class _CelebrationRingCardState extends State<CelebrationRingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        key: const Key('today_celebration'),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.softCyan,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.clinicalEmerald.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.clinicalEmerald.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          key: const Key('ring_closure_celebration'),
          children: [
            SizedBox(
              width: 48.w,
              height: 48.w,
              child: disableAnimations
                  ? Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.clinicalEmerald,
                        size: 36.sp,
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _RingPainter(progress: _progressAnimation.value),
                          child: Center(
                            child: Icon(
                              _progressAnimation.value >= 0.8
                                  ? LucideIcons.sparkles
                                  : Icons.check,
                              color: AppColors.clinicalEmerald,
                              size: 20.sp,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.todayCelebration,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.slateDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18.sp,
                color: AppColors.slateDark.withValues(alpha: 0.6),
              ),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.clinicalEmerald.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepPaint = Paint()
      ..color = AppColors.clinicalEmerald
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

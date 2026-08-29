import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';

class FdaWarningCard extends StatelessWidget {
  final String source;
  final String? retrievedAt;
  final String title;
  final String message;
  final VoidCallback? onTap;

  const FdaWarningCard({
    super.key,
    this.source = 'Official FDA Drug Safety Info',
    this.retrievedAt,
    this.title = AppStrings.fdaSafetyAlert,
    this.message =
        'New drug interaction warning for Amoxicillin. Tap info to learn more.',
    this.onTap,
  });

  bool get isLive {
    final lower = source.trim().toLowerCase();
    return lower.contains('fda') ||
        lower == 'official fda drug safety info' ||
        lower == 'openfda' ||
        lower == 'live' ||
        lower == 'openfda live';
  }

  String get sourceBadgeText =>
      isLive ? AppStrings.fdaSourceLive : AppStrings.fdaSourceFixture;

  String get formattedTimestamp {
    if (retrievedAt != null && retrievedAt!.trim().isNotEmpty) {
      final clean = retrievedAt!.trim();
      if (clean.startsWith('Retrieved:')) {
        return clean;
      }
      return AppStrings.fdaRetrievedTimestamp(clean);
    }
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return AppStrings.fdaRetrievedTimestamp('$year-$month-$day');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badgeText = isLive ? l10n.fdaSourceLive : l10n.fdaSourceFixture;
    final String timestampText;
    if (retrievedAt != null && retrievedAt!.trim().isNotEmpty) {
      final clean = retrievedAt!.trim();
      if (clean.startsWith('Retrieved:') ||
          clean.startsWith('Obtenido:') ||
          clean.startsWith('Recuperato:')) {
        timestampText = clean;
      } else {
        timestampText = l10n.fdaRetrievedTimestamp(clean);
      }
    } else {
      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      timestampText = l10n.fdaRetrievedTimestamp('$year-$month-$day');
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.pendingBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.warningAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      key: const Key('fda_source_badge'),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.8),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusRound),
                        border: Border.all(
                          color: AppColors.warningAmber.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    timestampText,
                    key: const Key('fda_retrieval_timestamp'),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warningAmber,
                    size: AppSpacing.iconLg,
                  ),
                  SizedBox(width: AppSpacing.hMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          message,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

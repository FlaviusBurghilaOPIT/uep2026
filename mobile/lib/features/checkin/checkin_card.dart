import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_service.dart';
import '../auth/presentation/providers/auth_provider.dart';
import 'providers/symptom_checkin_notifier.dart';

/// Top action card embedding the daily feeling check-in on `Today` — the
/// one check-in surface in the app (the orphan full-screen `CheckInScreen`
/// is deleted per spec §9). Posts via [symptomCheckinNotifierProvider];
/// shows an error+retry state when the write fails (spec §7).
class CheckInCard extends ConsumerStatefulWidget {
  const CheckInCard({super.key});

  @override
  ConsumerState<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends ConsumerState<CheckInCard> {
  String? _selectedMood;

  Future<String?> _resolveCaseId() async {
    final auth = ref.read(authProvider);
    if (auth.caseId != null) return auth.caseId;
    if (auth.patientId == null) return null;
    try {
      final res = await HttpApiService().get(
        '/patients/${auth.patientId}/case',
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _selectMood(String moodValue) async {
    setState(() => _selectedMood = moodValue);
    final caseId = await _resolveCaseId();
    if (caseId == null || !mounted) return;
    await ref
        .read(symptomCheckinNotifierProvider.notifier)
        .submit(caseId: caseId, feeling: moodValue);
  }

  void _retry() {
    if (_selectedMood == null) return;
    unawaited(_selectMood(_selectedMood!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checkinState = ref.watch(symptomCheckinNotifierProvider);
    final isSuccess = checkinState.value == true;
    final isSubmitting = checkinState.isLoading;
    final isError = checkinState.hasError;

    final moods = <(String, String)>[
      ('great', l10n.checkinGreatOption),
      ('ok', l10n.checkinOkOption),
      ('not_great', l10n.checkinNotGreatOption),
      ('bad', l10n.checkinBadOption),
    ];

    return Container(
      key: const Key('checkin_card'),
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.greyDivider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.checkinTitle.toUpperCase(), style: AppTextStyles.label),
          SizedBox(height: AppSpacing.xs),
          Text(
            l10n.symptomQuestion,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          if (isSuccess)
            Row(
              key: const Key('checkin_success'),
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: AppSpacing.iconMd,
                ),
                SizedBox(width: AppSpacing.hSm),
                Expanded(
                  child: Text(
                    l10n.checkinSuccessBanner,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            )
          else if (isError)
            GestureDetector(
              key: const Key('checkin_error_retry'),
              onTap: _retry,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.errorRed,
                      size: AppSpacing.iconMd,
                    ),
                    SizedBox(width: AppSpacing.hSm),
                    Expanded(
                      child: Text(
                        l10n.checkinErrorRetry,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: moods.map((mood) {
                final (value, label) = mood;
                final isSelected = _selectedMood == value;
                return GestureDetector(
                  onTap: isSubmitting ? null : () => _selectMood(value),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusRound,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.greyDivider,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.greyText,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

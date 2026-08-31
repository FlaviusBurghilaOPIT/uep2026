import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/symptom_checkin_notifier.dart';

/// Top action card embedding the daily feeling check-in on `Today`.
/// Posts via [symptomCheckinNotifierProvider]; shows Emergency Red Flag Banner
/// with direct dial (911 / Clinic Direct) when acute symptoms ('bad') are selected.
class CheckInCard extends ConsumerStatefulWidget {
  const CheckInCard({super.key, this.physicianName});

  final String? physicianName;

  @override
  ConsumerState<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends ConsumerState<CheckInCard> {
  String? _selectedMood;
  String? _emergencyPhone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchEmergencyContact());
  }

  Future<String?> _resolveCaseId() async {
    final auth = ref.read(authProvider);
    if (auth.caseId != null) return auth.caseId;
    if (auth.patientId == null) return null;
    try {
      final res = await ref.read(apiServiceProvider).get(
        '/patients/${auth.patientId}/case',
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _fetchEmergencyContact() async {
    final caseId = await _resolveCaseId();
    if (caseId == null || !mounted) return;
    try {
      final res = await ref.read(apiServiceProvider).get(
        '/cases/$caseId/emergency-contact',
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _emergencyPhone = data['phone'] as String?;
          });
        }
      }
    } catch (_) {}
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

  Future<void> _launchTel(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'great':
        return AppColors.primaryGreen;
      case 'ok':
        return AppColors.deepTeal;
      case 'not_great':
      case 'poor':
        return AppColors.warningAmber;
      case 'bad':
      case 'unwell':
        return AppColors.errorRed;
      default:
        return AppColors.primaryGreen;
    }
  }

  Widget _buildMoodChips(
    List<(String, String)> moods,
    bool isSubmitting, {
    Key? key,
  }) {
    return Wrap(
      key: key,
      spacing: 8.w,
      runSpacing: 8.h,
      children: moods.map((mood) {
        final (value, label) = mood;
        final isSelected = _selectedMood == value;
        final moodColor = _getMoodColor(value);
        return GestureDetector(
          key: Key('checkin_chip_$value'),
          onTap: isSubmitting ? null : () => _selectMood(value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? moodColor : AppColors.white,
              borderRadius: BorderRadius.circular(
                AppSpacing.radiusRound,
              ),
              border: Border.all(
                color: isSelected ? moodColor : AppColors.greyDivider,
                width: isSelected ? 1.5 : 1.0,
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
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required bool isSuccess,
    required bool isError,
    required bool isBadMood,
    required bool isSubmitting,
    required List<(String, String)> moods,
    required String successBannerText,
    required AppLocalizations l10n,
  }) {
    if (isBadMood) {
      return Column(
        key: const ValueKey('emergency'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMoodChips(moods, isSubmitting),
          _EmergencyRedFlagBanner(
            emergencyPhone: _emergencyPhone,
            onCall911: () {
              final locale =
                  Localizations.localeOf(context).languageCode.toLowerCase();
              final emergencyNumber =
                  (locale == 'it' ||
                          locale == 'es' ||
                          locale == 'fr' ||
                          locale == 'de')
                      ? '112'
                      : '911';
              _launchTel(emergencyNumber);
            },
            onCallClinic: () {
              final phone = _emergencyPhone?.trim() ?? '';
              if (phone.isNotEmpty) {
                _launchTel(phone);
              }
            },
          ),
        ],
      );
    } else if (isSuccess) {
      return Row(
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
              successBannerText,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      );
    } else if (isError) {
      return GestureDetector(
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
      );
    } else {
      return _buildMoodChips(
        moods,
        isSubmitting,
        key: const ValueKey('chips'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checkinState = ref.watch(symptomCheckinNotifierProvider);
    final isSuccess = checkinState.value == true;
    final isSubmitting = checkinState.isLoading;
    final isError = checkinState.hasError;
    final isBadMood = _selectedMood == 'bad' || _selectedMood == 'unwell';

    final moods = <(String, String)>[
      ('great', l10n.checkinGreatOption),
      ('ok', l10n.checkinOkOption),
      ('not_great', l10n.checkinNotGreatOption),
      ('bad', l10n.checkinBadOption),
    ];

    final auth = ref.watch(authProvider);
    final physicianName = (widget.physicianName ?? auth.physicianName)?.trim();
    final hasPhysician = physicianName != null && physicianName.isNotEmpty;
    final successBannerText = hasPhysician
        ? l10n.checkinSuccessBannerWithPhysician(physicianName)
        : l10n.checkinSuccessBanner;

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final animationDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);

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
          AnimatedSize(
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: animationDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (
                Widget? currentChild,
                List<Widget> previousChildren,
              ) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildContent(
                context: context,
                isSuccess: isSuccess,
                isError: isError,
                isBadMood: isBadMood,
                isSubmitting: isSubmitting,
                moods: moods,
                successBannerText: successBannerText,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyRedFlagBanner extends StatelessWidget {
  const _EmergencyRedFlagBanner({
    required this.emergencyPhone,
    required this.onCall911,
    required this.onCallClinic,
  });

  final String? emergencyPhone;
  final VoidCallback onCall911;
  final VoidCallback onCallClinic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = emergencyPhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;

    return Container(
      key: const Key('emergency_red_flag_banner'),
      margin: EdgeInsets.only(top: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.errorRed, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.triangleAlert,
                color: AppColors.errorRed,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.emergencyBannerTitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.emergencyWarningTitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.slateDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('emergency_dial_911_button'),
                  onPressed: onCall911,
                  icon: Icon(LucideIcons.phoneCall, size: 16.sp, color: AppColors.white),
                  label: Text(
                    l10n.emergencyCall911,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('emergency_dial_clinic_button'),
                  onPressed: onCallClinic,
                  icon: Icon(LucideIcons.phone, size: 16.sp, color: AppColors.errorRed),
                  label: Text(
                    hasPhone
                        ? l10n.emergencyCallClinic(phone)
                        : l10n.emergencyCallClinicFallback,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.errorRed,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorRed),
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


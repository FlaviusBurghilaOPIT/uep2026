import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/recovery_notifier.dart';

/// Recovery screen — server truth only (spec 0002 req 13–19). Care
/// instructions are the case's free-text recommendations, the 7-day adherence
/// chart is derived from real agenda slot states, and "Day N"/surgery date
/// come from the intake `surgery_date`. Anything the backend doesn't expose
/// (e.g. the clinician name) renders honest absence, never a fabrication.
class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(recoveryNotifierProvider.notifier).load());
    });
  }

  Future<void> _reload() =>
      ref.read(recoveryNotifierProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final recoveryAsync = ref.watch(recoveryNotifierProvider);
    final recovery = recoveryAsync.value ?? const RecoveryState();

    // A sign-in that lands after the first frame (e.g. session restore)
    // retriggers the load once a patientId exists.
    ref.listen(authProvider, (prev, next) {
      if (prev?.patientId == null && next.patientId != null) {
        unawaited(ref.read(recoveryNotifierProvider.notifier).load());
      }
    });

    final isInitialLoading =
        recovery.sourceState == RecoverySourceState.loading;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 100.h),
            children: [
              _buildTopBar(auth),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.lg),
                    Text('RECOVERY', style: AppTextStyles.label),
                    SizedBox(height: AppSpacing.sm),
                    if (isInitialLoading)
                      _buildSkeleton()
                    else if (recovery.sourceState == RecoverySourceState.error)
                      _buildErrorCard()
                    else
                      ..._buildBody(recovery),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Loading (AppSkeletonLoader, Today pattern) ------------------------------

  Widget _buildSkeleton() {
    return Column(
      children: [
        AppSkeletonLoader(
          key: const Key('recovery_skeleton_header'),
          height: 60.h,
          borderRadius: AppSpacing.radiusMd,
        ),
        SizedBox(height: AppSpacing.lg),
        AppSkeletonLoader(height: 180.h, borderRadius: AppSpacing.radiusMd),
        SizedBox(height: AppSpacing.lg),
        AppSkeletonLoader(height: 140.h, borderRadius: AppSpacing.radiusMd),
      ],
    );
  }

  // -- Loaded body --------------------------------------------------------------

  List<Widget> _buildBody(RecoveryState recovery) {
    return [
      if (recovery.dayOfRecovery != null) ...[
        Text(
          'Day ${recovery.dayOfRecovery} of Recovery',
          style: AppTextStyles.heading2,
        ),
        SizedBox(height: AppSpacing.xs),
      ],
      _buildHeaderSubtitle(recovery),
      SizedBox(height: AppSpacing.xl),
      _buildAdherenceSection(recovery),
      SizedBox(height: AppSpacing.xl),
      _buildCareInstructionsSection(recovery),
    ];
  }

  /// Surgery type + surgery date from the case; each renders only when the
  /// server provides it. The clinician name is NOT exposed by any
  /// patient-accessible endpoint, so it is never rendered (honest absence).
  Widget _buildHeaderSubtitle(RecoveryState recovery) {
    final parts = <String>[
      if (recovery.surgeryType != null && recovery.surgeryType!.isNotEmpty)
        recovery.surgeryType!,
      if (recovery.surgeryDate != null)
        'Since ${DateFormat('MMM d, yyyy').format(recovery.surgeryDate!)}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join(' · '), style: AppTextStyles.bodyMedium);
  }

  // -- 7-day adherence (derived from real agenda slot states) -------------------

  Widget _buildAdherenceSection(RecoveryState recovery) {
    final percent = recovery.overallAdherencePercent;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.greyDivider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '7-Day Adherence',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (percent != null)
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          if (!recovery.hasAdherenceData)
            Text(
              'No doses scheduled in the last 7 days. '
              'Your adherence will appear here once you start logging.',
              key: const Key('recovery_adherence_empty'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.greyText,
              ),
            )
          else
            _buildChart(recovery.adherenceDays),
        ],
      ),
    );
  }

  Widget _buildChart(List<AdherenceDay> days) {
    return SizedBox(
      height: 140.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: _buildBar(day),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBar(AdherenceDay day) {
    final hasData = day.total > 0;
    final ratio = hasData ? day.taken / day.total : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasData)
          Text(
            '${((ratio) * 100).round()}',
            style: AppTextStyles.labelSmall.copyWith(fontSize: 9.sp),
          )
        else
          SizedBox(height: 12.h),
        SizedBox(height: 4.h),
        Container(
          key: Key(
            'recovery_bar_${DateFormat('yyyy-MM-dd').format(day.date)}',
          ),
          height: (hasData ? (ratio * 80).clamp(4.0, 80.0) : 4.0).h,
          decoration: BoxDecoration(
            color: hasData ? AppColors.primaryGreen : AppColors.greyDivider,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          DateFormat('E').format(day.date).substring(0, 1),
          style: AppTextStyles.labelSmall.copyWith(fontSize: 10.sp),
        ),
      ],
    );
  }

  // -- Care instructions (flat list of recommendation text) ---------------------

  Widget _buildCareInstructionsSection(RecoveryState recovery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CARE INSTRUCTIONS', style: AppTextStyles.label),
        SizedBox(height: AppSpacing.md),
        if (recovery.recommendations.isEmpty)
          Text(
            'Your care team has not added care instructions yet.',
            key: const Key('recovery_instructions_empty'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyText),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.greyDivider, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < recovery.recommendations.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i < recovery.recommendations.length - 1
                          ? AppSpacing.md
                          : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5.w,
                          height: 5.w,
                          margin: EdgeInsets.only(top: 6.h, right: 8.w),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            recovery.recommendations[i],
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // -- Error state (Today pattern: message + retry) -----------------------------

  Widget _buildErrorCard() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.greyDivider),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: AppColors.greyText,
              size: 40.sp,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              "We couldn't load your recovery plan. "
              'Check your connection and try again.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('recovery_retry'),
                  onPressed: _reload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Top bar (real patient name, no dead notification bell) -------------------

  Widget _buildTopBar(AuthState auth) {
    final fullName = auth.fullName?.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.lg,
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.remotecare, style: AppTextStyles.heading3),
                if (fullName != null && fullName.isNotEmpty)
                  Text(
                    fullName,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () => AppRoutes.navigateTo(context, AppRoutes.profile),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.primaryGreen,
                    size: AppSpacing.iconMd,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

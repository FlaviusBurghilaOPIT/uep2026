import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_skeleton_loader.dart';
import '../providers/medications_notifier.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    String? caseId = auth.caseId;
    if (caseId == null && auth.patientId != null) {
      try {
        final caseRes = await HttpApiService().get(
          '/patients/${auth.patientId}/case',
        );
        if (caseRes.statusCode == 200) {
          caseId = jsonDecode(caseRes.body)['id'];
        }
      } catch (_) {}
    }

    if (caseId != null) {
      await ref
          .read(medicationsNotifierProvider.notifier)
          .loadMedications(caseId);
    }
  }

  String _localizedFrequency(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context);
    switch (code.toUpperCase()) {
      case 'QD':
        return l10n.frequencyQD;
      case 'BID':
        return l10n.frequencyBID;
      case 'TID':
        return l10n.frequencyTID;
      case 'QID':
        return l10n.frequencyQID;
      case 'PRN':
        return l10n.frequencyPRN;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);
    final medicationsState = ref.watch(medicationsNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(auth),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.medicationsScreenTitle.toUpperCase(),
                        style: AppTextStyles.label,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 13.sp,
                            color: AppColors.greyText,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              l10n.medicationsCareTeamNote,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.greyText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      _buildBody(l10n, medicationsState),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, AsyncValue<List<Medication>> state) {
    return state.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            AppSkeletonLoader(height: 120.h, borderRadius: 12),
            SizedBox(height: AppSpacing.md),
            AppSkeletonLoader(height: 120.h, borderRadius: 12),
          ],
        ),
      ),
      error: (error, stack) => Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: Text(l10n.errorGeneric, style: AppTextStyles.bodyMedium),
        ),
      ),
      data: (medications) {
        if (medications.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: AppEmptyState(
              icon: Icons.medication_outlined,
              title: l10n.medicationsScreenTitle,
              message: l10n.medicationsEmptyState,
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < medications.length; i++) ...[
              _buildMedicationCard(l10n, medications[i]),
              if (i < medications.length - 1) SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMedicationCard(AppLocalizations l10n, Medication medication) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: AppColors.primaryGreen,
                  size: AppSpacing.iconLg,
                ),
              ),
              SizedBox(width: AppSpacing.hMd),
              Expanded(
                child: Text(
                  medication.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n.medCardDoseLabel(medication.dose),
            style: AppTextStyles.bodySmall,
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.medCardScheduleLabel(
              _localizedFrequency(context, medication.frequency),
            ),
            style: AppTextStyles.bodySmall,
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.medCardDurationLabel(medication.duration),
            style: AppTextStyles.bodySmall,
          ),
          if (medication.notes != null && medication.notes!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            SizedBox(height: AppSpacing.md),
            Text(
              l10n.medCardNotesHeader,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(medication.notes!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(AuthState auth) {
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
                Text(
                  '${auth.fullName ?? 'User'} · Post-op',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primaryGreen,
              size: AppSpacing.iconMd,
            ),
          ),
        ],
      ),
    );
  }
}

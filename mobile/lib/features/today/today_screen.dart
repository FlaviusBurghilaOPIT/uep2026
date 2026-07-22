import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/providers/app_providers.dart';
import '../../core/network/api_service.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _medications = [
    {
      'id': null,
      'name': 'Ibuprofen',
      'dosage': '400 mg · 3× daily',
      'time': '08:00',
      'status': 'pending',
      'hasWarning': false,
    },
    {
      'id': null,
      'name': 'Amoxicillin',
      'dosage': '500 mg · 2× daily',
      'time': '13:00',
      'status': 'pending',
      'hasWarning': true,
    },
    {
      'id': null,
      'name': 'Metoprolol',
      'dosage': '25 mg · 1× daily',
      'time': '20:00',
      'status': 'pending',
      'hasWarning': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    String? caseId = auth.caseId;
    if (caseId == null && auth.patientId != null) {
      try {
        final caseRes = await ApiService.get('/patients/${auth.patientId}/case');
        if (caseRes.statusCode == 200) {
          caseId = jsonDecode(caseRes.body)['id'];
        }
      } catch (_) {}
    }

    if (caseId != null) {
      setState(() => _isLoading = true);
      try {
        final res = await ApiService.get('/cases/$caseId/medications');
        if (res.statusCode == 200) {
          final List list = jsonDecode(res.body);
          if (list.isNotEmpty) {
            setState(() {
              _medications = list.map<Map<String, dynamic>>((m) => {
                'id': m['id'],
                'name': m['name'],
                'dosage': '${m['dose']} · ${m['schedule_text']}',
                'time': '08:00',
                'status': 'pending',
                'hasWarning': false,
              }).toList();
            });
          }
        }
      } catch (_) {} finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  int get _takenCount => _medications.where((m) => m['status'] == 'taken').length;

  Future<void> _updateStatus(int index, String status) async {
    setState(() {
      _medications[index]['status'] = status;
    });

    final medId = _medications[index]['id'];
    if (medId != null) {
      try {
        final remindersRes = await ApiService.get('/reminders');
        String? reminderId;
        if (remindersRes.statusCode == 200) {
          final List reminders = jsonDecode(remindersRes.body);
          final match = reminders.firstWhere(
            (r) => r['medication_id'] == medId,
            orElse: () => null,
          );
          if (match != null) {
            reminderId = match['id'];
          }
        }
        if (reminderId == null) {
          final createRes = await ApiService.post('/reminders', {
            'medication_id': medId,
            'scheduled_time': DateTime.now().toIso8601String(),
          });
          if (createRes.statusCode == 200) {
            reminderId = jsonDecode(createRes.body)['id'];
          }
        }
        if (reminderId != null) {
          await ApiService.post('/adherence/log?scheduled_reminder_id=$reminderId&status=$status', {});
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final firstName = auth.fullName?.split(' ').first ?? 'User';
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : (now.hour < 17 ? 'Good afternoon' : 'Good evening');

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context, auth),
                _buildGreetingCard(greeting, firstName),
                SizedBox(height: AppSpacing.lg),
                _buildFdaAlert(context),
                SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.todaysMedications, style: AppTextStyles.label),
                      if (_isLoading)
                        SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                for (int i = 0; i < _medications.length; i++) ...[
                  _buildMedCard(context, index: i),
                  if (i < _medications.length - 1) SizedBox(height: AppSpacing.md),
                ],
                SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16.sp, color: AppColors.greyLight),
                      SizedBox(width: 6.w),
                      Text(
                        'Next reminder: ${_medications.firstWhere((m) => m['status'] == 'pending', orElse: () => _medications.last)['name']} at ${_medications.firstWhere((m) => m['status'] == 'pending', orElse: () => _medications.last)['time']}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthNotifier auth) {
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
                Text('${auth.fullName ?? 'User'} · Post-op', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications — coming soon')),
              );
            },
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined, color: AppColors.black, size: AppSpacing.iconLg),
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => AppRoutes.navigateTo(context, AppRoutes.profile),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen, width: 1.5),
              ),
              child: Icon(Icons.person_outline, color: AppColors.primaryGreen, size: AppSpacing.iconMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(String greeting, String firstName) {
    final total = _medications.length;
    final progress = total > 0 ? _takenCount / total : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY · JUL ${DateTime.now().day}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '$greeting, $firstName',
              style: AppTextStyles.heading2.copyWith(color: AppColors.white),
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                      minHeight: 8.h,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.hMd),
                Text(
                  '$_takenCount/$total doses',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Day 19 post-surgery · Keep it up!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFdaAlert(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FDA detail — coming soon')),
          );
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: AppSpacing.iconLg),
              SizedBox(width: AppSpacing.hMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.fdaSafetyAlert,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14.sp),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'New drug interaction warning for Amoxicillin. Tap info to learn more.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedCard(BuildContext context, {required int index}) {
    final med = _medications[index];
    final String status = med['status'];
    final Color badgeBg;
    final Color badgeText;
    final String badgeLabel;

    switch (status) {
      case 'taken':
        badgeBg = AppColors.takenBg;
        badgeText = AppColors.takenText;
        badgeLabel = AppStrings.taken;
        break;
      case 'missed':
        badgeBg = AppColors.missedBg;
        badgeText = AppColors.missedText;
        badgeLabel = AppStrings.missed;
        break;
      case 'skipped':
        badgeBg = AppColors.inputFill;
        badgeText = AppColors.greyText;
        badgeLabel = AppStrings.skip;
        break;
      default:
        badgeBg = AppColors.pendingBg;
        badgeText = AppColors.pendingText;
        badgeLabel = AppStrings.pending;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: status == 'taken' ? AppColors.takenBg.withValues(alpha: 0.3) : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: status == 'taken'
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : AppColors.greyDivider,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: status == 'taken'
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    status == 'taken' ? Icons.check_circle_outline : Icons.medication_outlined,
                    color: AppColors.primaryGreen,
                    size: AppSpacing.iconLg,
                  ),
                ),
                SizedBox(width: AppSpacing.hMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              med['name'],
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppSpacing.hSm),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  badgeLabel,
                                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: badgeText),
                                ),
                                if (med['hasWarning'] == true) ...[
                                  SizedBox(width: 4.w),
                                  Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 12.sp),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(med['dosage'], style: AppTextStyles.bodySmall),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14.sp, color: AppColors.greyLight),
                          SizedBox(width: 4.w),
                          Text(med['time'], style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.info_outline, color: AppColors.greyLight, size: AppSpacing.iconMd),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MedAction(
                  icon: Icons.check_circle_outline,
                  label: AppStrings.taken,
                  color: AppColors.primaryGreen,
                  isActive: status == 'taken',
                  onTap: () => _updateStatus(index, status == 'taken' ? 'pending' : 'taken'),
                ),
                _MedAction(
                  icon: Icons.cancel_outlined,
                  label: AppStrings.missed,
                  color: AppColors.errorRed,
                  isActive: status == 'missed',
                  onTap: () => _updateStatus(index, status == 'missed' ? 'pending' : 'missed'),
                ),
                _MedAction(
                  icon: Icons.skip_next_outlined,
                  label: AppStrings.skip,
                  color: AppColors.greyText,
                  isActive: status == 'skipped',
                  onTap: () => _updateStatus(index, status == 'skipped' ? 'pending' : 'skipped'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _MedAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

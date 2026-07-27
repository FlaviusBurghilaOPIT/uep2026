import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/providers/app_providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/network/api_service.dart';
import '../checkin/checkin_card.dart';
import 'fda_warning_card.dart';
import 'providers/today_agenda_notifier.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isLoading = false;
  bool _dismissedCelebration = false;

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

  String _fdaSource = 'Official FDA Drug Safety Info';
  String? _fdaRetrievedAt;
  String _fdaMessage =
      'New drug interaction warning for Amoxicillin. Tap info to learn more.';

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _cardKeys = {};
  StreamSubscription<NotificationResponse>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _notificationSubscription = NotificationService
        .instance
        .notificationResponseStream
        .listen((response) {
          _handleNotificationResponse(response);
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final reminderId = NotificationService.parseReminderId(
      response.payload ?? '',
    );
    if (reminderId != null) {
      final key = _cardKeys[reminderId];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      final index = _medications.indexWhere((m) => m['id'] == reminderId);
      if (index != -1) {
        setState(() {
          _medications[index]['status'] = 'taken';
        });
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  l10n.doseStatusTaken,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    final api = ref.read(apiServiceProvider);
    try {
      final fdaRes = await api.get('/fda/drug/Amoxicillin');
      if (fdaRes.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(fdaRes.body);
        if (mounted) {
          setState(() {
            if (data['source'] != null) {
              _fdaSource = data['source'].toString();
            }
            if (data['summary'] != null) {
              _fdaMessage = data['summary'].toString();
            }
            if (data['retrieved_at'] != null) {
              _fdaRetrievedAt = data['retrieved_at'].toString();
            } else if (data['timestamp'] != null) {
              _fdaRetrievedAt = data['timestamp'].toString();
            }
          });
        }
      }
    } catch (_) {}

    final auth = ref.read(authProvider);
    String? caseId = auth.caseId;
    if (caseId == null && auth.patientId != null) {
      try {
        final caseRes = await api.get('/patients/${auth.patientId}/case');
        if (caseRes.statusCode == 200) {
          caseId = jsonDecode(caseRes.body)['id'];
        }
      } catch (_) {}
    }

    if (caseId != null) {
      setState(() => _isLoading = true);
      try {
        final res = await api.get('/cases/$caseId/medications');
        if (res.statusCode == 200) {
          final List list = jsonDecode(res.body);
          if (list.isNotEmpty) {
            setState(() {
              _medications = list
                  .map<Map<String, dynamic>>(
                    (m) => {
                      'id': m['id'],
                      'name': m['name'],
                      'dosage':
                          '${m['dose']} · ${_localizedFrequency(context, (m['frequency'] ?? m['schedule_text'] ?? 'QD') as String)}',
                      'time': '08:00',
                      'status': 'pending',
                      'hasWarning': false,
                    },
                  )
                  .toList();
            });
          }
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

  int get _takenCount =>
      _medications.where((m) => m['status'] == 'taken').length;

  bool get _allDosesCompleted =>
      _medications.isNotEmpty &&
      _medications.every((m) => m['status'] != 'pending');

  /// NOTE (WI 11 interim): the notifier is now the ONLY writer for adherence.
  /// This legacy card list is replaced entirely in WI 13; until then taps
  /// update local display state only and deliberately perform NO server write.
  Future<void> _updateStatus(int index, String newStatus) async {
    final previousStatus = _medications[index]['status'] as String;

    setState(() {
      _medications[index]['status'] = newStatus;
    });

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    if (newStatus == 'pending') {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final String statusDisplay = newStatus == 'taken'
        ? l10n.doseStatusTaken
        : (newStatus == 'skipped'
              ? l10n.doseStatusSkipped
              : l10n.doseStatusMissed);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.slateDark,
        content: Text(
          'Logged as $statusDisplay.',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryGreen,
          onPressed: () {
            if (mounted) {
              setState(() {
                _medications[index]['status'] = previousStatus;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final agendaState =
        ref.watch(todayAgendaNotifierProvider).valueOrNull ??
        const AgendaState();
    final firstName = auth.fullName?.split(' ').first ?? 'User';
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);
    final greeting = now.hour < 12
        ? l10n.greetingMorning
        : (now.hour < 17 ? l10n.greetingAfternoon : l10n.greetingEvening);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOfflineSyncBanner(context, agendaState),
                _buildTopBar(context, auth),
                _buildGreetingCard(greeting, firstName),
                if (_allDosesCompleted && !_dismissedCelebration)
                  _buildCelebratoryCard(),
                SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  child: const CheckInCard(),
                ),
                SizedBox(height: AppSpacing.lg),
                _buildFdaAlert(context),
                SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.todaysMedications,
                        style: AppTextStyles.label,
                      ),
                      if (_isLoading)
                        SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                for (int i = 0; i < _medications.length; i++) ...[
                  _buildMedCard(context, index: i),
                  if (i < _medications.length - 1)
                    SizedBox(height: AppSpacing.md),
                ],
                SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16.sp,
                        color: AppColors.greyLight,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Next reminder: ${_medications.firstWhere((m) => m['status'] == 'pending', orElse: () => _medications.last)['name']} at ${_medications.firstWhere((m) => m['status'] == 'pending', orElse: () => _medications.last)['time']}',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildOfflineSyncBanner(
    BuildContext context,
    AgendaState agendaState,
  ) {
    if (agendaState.offlineQueue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: AppColors.warningAmber.withValues(alpha: 0.15),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: AppColors.warningAmber,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Saved on your device. Will update care team when online.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebratoryCard() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.lightGreen.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primaryGreen, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.stars_rounded,
              color: AppColors.primaryGreen,
              size: 24.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'All doses for today completed! Thank you for updating your care team.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18.sp,
                color: AppColors.primaryGreen,
              ),
              onPressed: () {
                setState(() {
                  _dismissedCelebration = true;
                });
              },
            ),
          ],
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
                Text(
                  '${auth.fullName ?? 'User'} · Post-op',
                  style: AppTextStyles.bodySmall,
                ),
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
                  Icon(
                    Icons.notifications_outlined,
                    color: AppColors.black,
                    size: AppSpacing.iconLg,
                  ),
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
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
              child: Icon(
                Icons.person_outline,
                color: AppColors.primaryGreen,
                size: AppSpacing.iconMd,
              ),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
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
    return FdaWarningCard(
      source: _fdaSource,
      retrievedAt: _fdaRetrievedAt,
      message: _fdaMessage,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FDA detail — coming soon')),
        );
      },
    );
  }

  Widget _buildMedCard(BuildContext context, {required int index}) {
    final med = _medications[index];
    final medId = (med['id'] != null && med['id'].toString().isNotEmpty)
        ? med['id'].toString()
        : 'med_$index';
    final cardKey = _cardKeys.putIfAbsent(medId, () => GlobalKey());

    final String status = med['status'];
    final Color badgeBg;
    final Color badgeText;
    final String badgeLabel;
    final IconData? badgeIcon;
    final l10n = AppLocalizations.of(context);

    switch (status) {
      case 'taken':
        badgeBg = AppColors.takenBg;
        badgeText = AppColors.takenText;
        badgeLabel = l10n.doseStatusTaken;
        badgeIcon = Icons.check_circle;
        break;
      case 'missed':
        badgeBg = AppColors.missedBg;
        badgeText = AppColors.missedText;
        badgeLabel = l10n.doseStatusMissed;
        badgeIcon = Icons.close;
        break;
      case 'skipped':
        badgeBg = AppColors.inputFill;
        badgeText = AppColors.greyText;
        badgeLabel = l10n.doseStatusSkipped;
        badgeIcon = Icons.warning_amber_rounded;
        break;
      default:
        badgeBg = AppColors.pendingBg;
        badgeText = AppColors.pendingText;
        badgeLabel = AppStrings.pending;
        badgeIcon = null;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Container(
        key: cardKey,
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: status == 'taken'
              ? AppColors.takenBg.withValues(alpha: 0.3)
              : AppColors.white,
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
                    status == 'taken'
                        ? Icons.check_circle_outline
                        : Icons.medication_outlined,
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
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppSpacing.hSm),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            key: ValueKey('dose_status_badge_$medId'),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusRound,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (badgeIcon != null) ...[
                                  Icon(
                                    badgeIcon,
                                    color: badgeText,
                                    size: 12.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                ],
                                Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: badgeText,
                                  ),
                                ),
                                if (med['hasWarning'] == true) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.warningAmber,
                                    size: 12.sp,
                                  ),
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
                          Icon(
                            Icons.access_time_rounded,
                            size: 14.sp,
                            color: AppColors.greyLight,
                          ),
                          SizedBox(width: 4.w),
                          Text(med['time'], style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: AppColors.greyLight,
                  size: AppSpacing.iconMd,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _MedAction(
                    icon: Icons.check_circle_outline,
                    label: AppStrings.taken,
                    color: AppColors.primaryGreen,
                    isActive: status == 'taken',
                    onTap: () => _updateStatus(
                      index,
                      status == 'taken' ? 'pending' : 'taken',
                    ),
                  ),
                ),
                Expanded(
                  child: _MedAction(
                    icon: Icons.cancel_outlined,
                    label: AppStrings.missed,
                    color: AppColors.errorRed,
                    isActive: status == 'missed',
                    onTap: () => _updateStatus(
                      index,
                      status == 'missed' ? 'pending' : 'missed',
                    ),
                  ),
                ),
                Expanded(
                  child: _MedAction(
                    icon: Icons.skip_next_outlined,
                    label: AppStrings.skip,
                    color: AppColors.greyText,
                    isActive: status == 'skipped',
                    onTap: () => _updateStatus(
                      index,
                      status == 'skipped' ? 'pending' : 'skipped',
                    ),
                  ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

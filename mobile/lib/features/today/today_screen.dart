import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/settings/settings_opener.dart';
import '../../core/widgets/app_skeleton_loader.dart';
import '../checkin/checkin_card.dart';
import 'correction_sheet.dart';
import 'dose_format.dart';
import 'dose_group.dart';
import 'dose_slot_card.dart';
import 'fda_warning_card.dart';
import 'providers/fda_warning_provider.dart';
import 'providers/today_agenda_notifier.dart';
import 'side_effect_prompt_card.dart';

/// The clinical home screen (spec §7). Server truth in, intents out — every
/// dose write goes through [TodayAgendaNotifier]; this widget never talks to
/// `ApiService` directly and renders no fabricated data.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Testable clock seam for the time-of-day greeting/date line — defaults
  /// to [DateTime.now] in production.
  final DateTime Function() _clock;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _dismissedCelebration = false;
  final Set<DoseGroup> _expandedGroups = {};
  final Map<String, GlobalKey> _cardKeys = {};
  StreamSubscription<NotificationResponse>? _notificationSubscription;

  static const _terminal = {
    SlotState.taken,
    SlotState.skipped,
    SlotState.missed,
  };
  static const _pinnable = {SlotState.due, SlotState.overdue};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(todayAgendaNotifierProvider.notifier).start());
    });
    _notificationSubscription = NotificationService
        .instance
        .notificationResponseStream
        .listen(_handleNotificationResponse);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final slotId = NotificationService.parseReminderId(response.payload ?? '');
    if (slotId == null) return;
    final key = _cardKeys[slotId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    // A background interactive action may have changed server truth.
    unawaited(ref.read(todayAgendaNotifierProvider.notifier).loadAgenda());
  }

  Future<void> _logDose(AgendaSlot slot, DoseLogStatus status) async {
    final l10n = AppLocalizations.of(context);
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptics unavailable on this platform/host — non-fatal.
    }
    ref.read(todayAgendaNotifierProvider.notifier).logDose(slot, status);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.slateDark,
        content: Text(
          l10n.todayLoggedAs(localizedDoseStatus(l10n, status.name)),
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: l10n.todayLogUndo,
          textColor: AppColors.primaryGreen,
          onPressed: () => ref
              .read(todayAgendaNotifierProvider.notifier)
              .undoDoseLog(slot.slotId),
        ),
      ),
    );
  }

  void _openCorrection(AgendaSlot slot) {
    ref.read(todayAgendaNotifierProvider.notifier).trackCorrectionOpened(slot);
    CorrectionSheet.show(
      context,
      slot: slot,
      onCorrect: (status) {
        Navigator.of(context).pop();
        ref.read(todayAgendaNotifierProvider.notifier).correctLog(slot, status);
      },
      onKeep: () => Navigator.of(context).pop(),
    );
  }

  void _showFdaDetailSheet(FdaWarning warning) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(warning.source, style: AppTextStyles.label),
                SizedBox(height: AppSpacing.sm),
                Text(warning.message, style: AppTextStyles.bodyMedium),
                if (warning.retrievedAt != null) ...[
                  SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.fdaRetrievedTimestamp(warning.retrievedAt!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final agendaAsync = ref.watch(todayAgendaNotifierProvider);
    final agenda = agendaAsync.valueOrNull ?? const AgendaState();
    final l10n = AppLocalizations.of(context);

    ref.listen<AsyncValue<AgendaState>>(todayAgendaNotifierProvider, (
      previous,
      next,
    ) {
      final prevState = previous?.valueOrNull;
      final nextState = next.valueOrNull;
      if (nextState == null) return;

      // Rollback error snackbar (final write failure after retry).
      final nextRollback = nextState.rollbackErrorSlotId;
      if (nextRollback != null &&
          nextRollback != prevState?.rollbackErrorSlotId) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.todayLogRollbackError)));
        ref.read(todayAgendaNotifierProvider.notifier).acknowledgeRollback();
      }
    });

    final isInitialLoading =
        agenda.sourceState == AgendaSourceState.loading &&
        agenda.slots.isEmpty &&
        agenda.prn.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(todayAgendaNotifierProvider.notifier).loadAgenda(),
          child: isInitialLoading
              ? _buildSkeleton(auth, l10n)
              : _buildBody(auth, agenda, l10n),
        ),
      ),
    );
  }

  // -- Skeleton (loading, no cache) ------------------------------------------

  Widget _buildSkeleton(AuthNotifier auth, AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 100.h),
      children: [
        _buildTopBar(auth),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
          child: AppSkeletonLoader(
            key: const Key('today_skeleton_greeting'),
            height: 150.h,
            borderRadius: AppSpacing.radiusLg,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        for (int i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              0,
              AppSpacing.screenPaddingH,
              AppSpacing.md,
            ),
            child: AppSkeletonLoader(
              height: 120.h,
              borderRadius: AppSpacing.radiusMd,
            ),
          ),
      ],
    );
  }

  // -- Main body --------------------------------------------------------------

  Widget _buildBody(
    AuthNotifier auth,
    AgendaState agenda,
    AppLocalizations l10n,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 100.h),
      children: [
        _buildTopBar(auth),
        _buildGreetingCard(agenda, l10n),
        ..._buildBanners(agenda, l10n),
        if (agenda.c8PromptSlotId != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
              vertical: AppSpacing.sm,
            ),
            child: SideEffectPromptCard(slotId: agenda.c8PromptSlotId!),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: AppSpacing.sm,
          ),
          child: const CheckInCard(),
        ),
        _buildFdaSection(),
        if (agenda.sourceState == AgendaSourceState.error)
          _buildErrorCard(l10n)
        else if (agenda.sourceState == AgendaSourceState.empty)
          _buildEmptyState(l10n)
        else
          ..._buildSlotsSection(agenda, l10n),
      ],
    );
  }

  // -- Top bar (spec §7: "RemoteCare" + real fullName, avatar → /profile) ----

  Widget _buildTopBar(AuthNotifier auth) {
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
                Text('RemoteCare', style: AppTextStyles.heading3),
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

  // -- Greeting card (spec §7: real progress, real date, no fabricated data) -

  Widget _buildGreetingCard(AgendaState agenda, AppLocalizations l10n) {
    final auth = ref.watch(authProvider);
    final now = widget._clock();
    final greeting = now.hour < 12
        ? l10n.greetingMorning
        : (now.hour < 17 ? l10n.greetingAfternoon : l10n.greetingEvening);
    final trimmedName = auth.fullName?.trim();
    final firstName = (trimmedName != null && trimmedName.isNotEmpty)
        ? trimmedName.split(' ').first
        : null;
    final greetingLine = firstName == null
        ? '$greeting.'
        : '$greeting, $firstName';
    final locale = Localizations.localeOf(context).toString();
    final dateLine = DateFormat('EEEE, MMMM d', locale).format(now);

    final taken = agenda.slots.where((s) => s.state == SlotState.taken).length;
    final total = agenda.slots.length;

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
              dateLine.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              greetingLine,
              style: AppTextStyles.heading2.copyWith(color: AppColors.white),
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: total > 0 ? taken / total : 0.0,
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
                  l10n.todayProgressDoses(taken, total),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -- Banners region (max one per kind, spec §7) -----------------------------

  String _relativeTime(DateTime? syncedAt, AppLocalizations l10n) {
    if (syncedAt == null) return l10n.todayTimeJustNow;
    final diff = DateTime.now().difference(syncedAt);
    if (diff.inMinutes < 1) return l10n.todayTimeJustNow;
    if (diff.inMinutes < 60) return l10n.todayTimeMinutesAgo(diff.inMinutes);
    return l10n.todayTimeHoursAgo(diff.inHours);
  }

  List<Widget> _buildBanners(AgendaState agenda, AppLocalizations l10n) {
    final notifier = ref.read(todayAgendaNotifierProvider.notifier);
    final banners = <Widget>[];

    if (agenda.remindersOff) {
      banners.add(
        _TodayBanner(
          key: const Key('banner_reminders_off'),
          icon: Icons.notifications_off_outlined,
          color: AppColors.warningAmber,
          text: l10n.remindersOffBanner,
          actionLabel: l10n.todayOpenSettings,
          onAction: () =>
              ref.read(settingsOpenerProvider).openNotificationSettings(),
        ),
      );
    }
    if (agenda.planUpdated) {
      banners.add(
        _TodayBanner(
          key: const Key('banner_plan_updated'),
          icon: Icons.fact_check_outlined,
          color: AppColors.infoBlue,
          text: l10n.todayPlanUpdatedBanner,
          onDismiss: notifier.dismissPlanUpdated,
        ),
      );
    }
    if (agenda.sourceState == AgendaSourceState.stale) {
      banners.add(
        _TodayBanner(
          key: const Key('banner_stale'),
          icon: Icons.history,
          color: AppColors.greyText,
          text: l10n.todayStaleBanner(_relativeTime(agenda.lastSyncedAt, l10n)),
        ),
      );
    }
    if (agenda.offlineQueue.isNotEmpty) {
      banners.add(
        _TodayBanner(
          key: const Key('banner_offline'),
          icon: Icons.cloud_off_outlined,
          color: AppColors.warningAmber,
          text: l10n.todayOfflineBanner,
        ),
      );
    }
    if (agenda.timezoneAdjusted) {
      banners.add(
        _TodayBanner(
          key: const Key('banner_timezone'),
          icon: Icons.public,
          color: AppColors.infoBlue,
          text: l10n.todayTimezoneAdjusted,
          onDismiss: notifier.dismissTimezoneAdjusted,
        ),
      );
    }

    return [
      for (final banner in banners)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: 4.h,
          ),
          child: banner,
        ),
    ];
  }

  // -- FDA card (spec §7: only when real data for an on-plan med) ------------

  Widget _buildFdaSection() {
    final warning = ref.watch(fdaWarningProvider).valueOrNull;
    if (warning == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: FdaWarningCard(
        title: l10n.fdaSafetyAlertTitle,
        source: warning.source,
        retrievedAt: warning.retrievedAt,
        message: warning.message,
        onTap: () => _showFdaDetailSheet(warning),
      ),
    );
  }

  // -- Error / empty states ----------------------------------------------------

  Widget _buildErrorCard(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.lg,
      ),
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
              l10n.todayAgendaError,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('today_retry'),
                onPressed: () =>
                    ref.read(todayAgendaNotifierProvider.notifier).loadAgenda(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                child: Text(l10n.todayRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: AppColors.greyLight,
            size: 48.sp,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n.emptyPlanMessage,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            l10n.todayPullToRefreshHint,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // -- Dose slots: next-due pin, time-of-day groups, PRN, celebration --------

  List<Widget> _buildSlotsSection(AgendaState agenda, AppLocalizations l10n) {
    final widgets = <Widget>[];

    final allDone =
        agenda.slots.isNotEmpty &&
        agenda.slots.every((s) => _terminal.contains(s.state));
    if (allDone && !_dismissedCelebration) {
      widgets.add(_buildCelebrationCard(l10n));
    }

    final pinnedCandidates =
        agenda.slots.where((s) => _pinnable.contains(s.state)).toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final pinned = pinnedCandidates.isEmpty ? null : pinnedCandidates.first;
    final remaining = pinned == null
        ? agenda.slots
        : agenda.slots.where((s) => s.slotId != pinned.slotId).toList();

    if (pinned != null) {
      widgets.add(_sectionLabel(l10n.todayDueNow));
      widgets.add(_slotTile(pinned, agenda));
    }

    final sorted = [...remaining]
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final groups = <DoseGroup, List<AgendaSlot>>{};
    for (final slot in sorted) {
      groups
          .putIfAbsent(doseGroupFor(slot.scheduledTime.toLocal()), () => [])
          .add(slot);
    }

    for (final group in DoseGroup.values) {
      final slots = groups[group];
      if (slots == null || slots.isEmpty) continue;
      widgets.add(_sectionLabel(_groupLabel(group, l10n)));
      final expanded = _expandedGroups.contains(group) || slots.length <= 3;
      final visible = expanded ? slots : slots.take(3).toList();
      for (final slot in visible) {
        widgets.add(_slotTile(slot, agenda));
      }
      if (!expanded) {
        widgets.add(_collapsedGroupToggle(group, slots.length, l10n));
      }
    }

    if (agenda.prn.isNotEmpty) {
      widgets.add(_sectionLabel(l10n.todayPrnSection));
      for (final med in agenda.prn) {
        widgets.add(_prnTile(med, agenda, l10n));
      }
    }

    return widgets;
  }

  Widget _sectionLabel(String text) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.screenPaddingH,
      AppSpacing.md,
      AppSpacing.screenPaddingH,
      AppSpacing.sm,
    ),
    child: Text(text.toUpperCase(), style: AppTextStyles.label),
  );

  String _groupLabel(DoseGroup group, AppLocalizations l10n) => switch (group) {
    DoseGroup.morning => l10n.todayGroupMorning,
    DoseGroup.midday => l10n.todayGroupMidday,
    DoseGroup.evening => l10n.todayGroupEvening,
    DoseGroup.bedtime => l10n.todayGroupBedtime,
  };

  Widget _collapsedGroupToggle(
    DoseGroup group,
    int total,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label: '${_groupLabel(group, l10n)} · $total',
          child: SizedBox(
            height: 48,
            child: TextButton.icon(
              onPressed: () => setState(() => _expandedGroups.add(group)),
              icon: const Icon(Icons.expand_more),
              label: Text('+${total - 3}'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotTile(AgendaSlot slot, AgendaState agenda) {
    final cardKey = _cardKeys.putIfAbsent(slot.slotId, () => GlobalKey());
    final syncPending = agenda.offlineQueue.any((e) => e.slotId == slot.slotId);
    final writeInFlight = agenda.writeInFlightSlotIds.contains(slot.slotId);
    return Padding(
      key: cardKey,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        0,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      child: DoseSlotCard(
        slot: slot,
        syncPending: syncPending,
        writeInFlight: writeInFlight,
        onLog: (status) => _logDose(slot, status),
        onOpenCorrection: () => _openCorrection(slot),
      ),
    );
  }

  Widget _prnTile(
    PrnMedication med,
    AgendaState agenda,
    AppLocalizations l10n,
  ) {
    final writeInFlight = agenda.writeInFlightPrnIds.contains(med.medicationId);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        0,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      child: Container(
        key: Key('prn_${med.medicationId}'),
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
            Text(
              med.medicationName,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(formatDose(med.dose), style: AppTextStyles.bodySmall),
            SizedBox(height: AppSpacing.md),
            if (writeInFlight)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key('prn_log_${med.medicationId}'),
                  onPressed: () => ref
                      .read(todayAgendaNotifierProvider.notifier)
                      .logPrn(med, DoseLogStatus.taken),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.doseStatusTaken),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen),
                    foregroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- Celebration (spec §7/§9: ARB-localized, dismissible, no streaks) ------

  Widget _buildCelebrationCard(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        key: const Key('today_celebration'),
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
                l10n.todayCelebration,
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
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => setState(() => _dismissedCelebration = true),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single-kind banner (spec §7 banners region: max one per kind).
class _TodayBanner extends StatelessWidget {
  const _TodayBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSpacing.iconMd),
          SizedBox(width: AppSpacing.hSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.black,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: GestureDetector(
                      onTap: onAction,
                      child: Text(
                        actionLabel!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              iconSize: 18,
              color: color,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

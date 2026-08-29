import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/agenda_entities.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../widgets/dose_format.dart';

/// The core Today-screen dose slot (spec §7). Pure presentation — it emits
/// intents via [onLog] / [onOpenCorrection] and never talks to services.
class DoseSlotCard extends StatelessWidget {
  const DoseSlotCard({
    super.key,
    required this.slot,
    this.syncPending = false,
    this.writeInFlight = false,
    this.onLog,
    this.onOpenCorrection,
  });

  final AgendaSlot slot;
  final bool syncPending;
  final bool writeInFlight;
  final void Function(DoseLogStatus status)? onLog;
  final VoidCallback? onOpenCorrection;

  static const Set<SlotState> _actionable = {
    SlotState.upcoming,
    SlotState.due,
    SlotState.overdue,
  };

  bool get _isLogged =>
      slot.state == SlotState.taken || slot.state == SlotState.skipped;

  bool get _isActionable => _actionable.contains(slot.state);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final scheduledLocal = slot.scheduledTime.toLocal();
    final timeText = DateFormat.jm(locale).format(scheduledLocal);

    final badge = _BadgeSpec.forState(slot.state, l10n, timeText);

    return Card(
      key: Key('dose_slot_${slot.slotId}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.greyDivider, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: _isLogged ? onOpenCorrection : null,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // M-01: the descriptive block (name/dose/time/status/both-times)
              // is one merged Semantics unit; action buttons below stay
              // individually focusable so reading order is card, then
              // actions — never the whole card as one giant unreachable
              // button.
              Semantics(
                container: true,
                excludeSemantics: true,
                label: _semanticsLabel(l10n, timeText, badge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.medicationName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                formatDose(slot.dose),
                                style: AppTextStyles.bodySmall,
                              ),
                              SizedBox(height: 2.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14.sp,
                                    color: AppColors.greyLight,
                                  ),
                                  SizedBox(width: 4.w),
                                  // M-02: at large text scales this row must
                                  // not overflow horizontally.
                                  Flexible(
                                    child: Text(
                                      '$timeText · ${_pillForm(l10n)}',
                                      style: AppTextStyles.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.hSm),
                        _StateBadge(spec: badge),
                      ],
                    ),
                    if (syncPending) ...[
                      SizedBox(height: AppSpacing.sm),
                      _SyncPendingBadge(label: l10n.todaySyncPending),
                    ],
                    if (_isLogged && slot.loggedAt != null) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.todaySlotTimes(
                          timeText,
                          DateFormat.jm(
                            locale,
                          ).format(slot.loggedAt!.toLocal()),
                        ),
                        style: AppTextStyles.bodySmall,
                      ),
                      if (slot.previousStatus != null)
                        Text(
                          l10n.todayPreviouslyLogged(
                            localizedDoseStatus(l10n, slot.previousStatus!),
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.greyText,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              if (writeInFlight)
                const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else if (_isActionable)
                Column(
                  children: [
                    for (final (i, action) in _actions(l10n).indexed) ...[
                      if (i > 0) SizedBox(height: AppSpacing.sm),
                      _SlotActionRow(
                        key: Key(
                          'slot_action_${action.status.name}_${slot.slotId}',
                        ),
                        icon: action.icon,
                        label: action.label,
                        color: action.color,
                        onTap: () => onLog?.call(action.status),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// M-01 merged label: "{medName} {dose}, scheduled {time}, {state}.
  /// Actions: taken, skipped, missed." (only for actionable slots — logged/
  /// terminal slots describe themselves without a nonexistent action list).
  String _semanticsLabel(
    AppLocalizations l10n,
    String timeText,
    _BadgeSpec badge,
  ) {
    final base =
        '${slot.medicationName} ${formatDose(slot.dose)}, '
        'scheduled $timeText, ${badge.label}.';
    if (!_isActionable) return base;
    final actions = [
      l10n.doseStatusTaken,
      l10n.doseStatusSkipped,
      l10n.doseStatusMissed,
    ].map((s) => s.toLowerCase()).join(', ');
    return '$base Actions: $actions.';
  }

  String _pillForm(AppLocalizations l10n) {
    final medLower = '${slot.medicationName} ${slot.dose}'.toLowerCase();
    if (medLower.contains('liquid') ||
        medLower.contains('drops') ||
        medLower.contains('syrup') ||
        medLower.contains('ml')) {
      return l10n.pillFormLiquid;
    }
    if (medLower.contains('capsule') || medLower.contains('cap')) {
      return l10n.pillFormCapsule;
    }
    return l10n.pillFormTablet;
  }

  List<_ActionSpec> _actions(AppLocalizations l10n) => [
    _ActionSpec(
      status: DoseLogStatus.taken,
      icon: Icons.check_circle_outline,
      label: l10n.doseStatusTaken,
      color: AppColors.primaryGreen,
    ),
    _ActionSpec(
      status: DoseLogStatus.skipped,
      icon: Icons.skip_next_outlined,
      label: l10n.doseStatusSkipped,
      color: AppColors.greyText,
    ),
    _ActionSpec(
      status: DoseLogStatus.missed,
      icon: Icons.cancel_outlined,
      label: l10n.doseStatusMissed,
      color: AppColors.errorRed,
    ),
  ];
}

/// Maps a raw server status name to its localized label.
String localizedDoseStatus(AppLocalizations l10n, String statusName) {
  return switch (statusName) {
    'taken' => l10n.doseStatusTaken,
    'skipped' => l10n.doseStatusSkipped,
    'missed' => l10n.doseStatusMissed,
    _ => statusName,
  };
}

class _ActionSpec {
  const _ActionSpec({
    required this.status,
    required this.icon,
    required this.label,
    required this.color,
  });
  final DoseLogStatus status;
  final IconData icon;
  final String label;
  final Color color;
}

class _BadgeSpec {
  const _BadgeSpec({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  static _BadgeSpec forState(
    SlotState state,
    AppLocalizations l10n,
    String timeText,
  ) {
    return switch (state) {
      SlotState.upcoming => _BadgeSpec(
        icon: Icons.schedule,
        label: l10n.todayUpcoming,
        foreground: AppColors.greyText,
        background: AppColors.inputFill,
      ),
      SlotState.due => _BadgeSpec(
        icon: Icons.circle,
        label: l10n.todayDueNow,
        foreground: AppColors.deepTeal,
        background: AppColors.softCyan,
      ),
      SlotState.overdue => _BadgeSpec(
        icon: Icons.notification_important_outlined,
        label: l10n.todayScheduledFor(timeText),
        foreground: AppColors.pendingText,
        background: AppColors.pendingBg,
      ),
      SlotState.missed => _BadgeSpec(
        icon: Icons.cancel_outlined,
        label: l10n.todayScheduledFor(timeText),
        foreground: AppColors.greyText,
        background: AppColors.inputFill,
      ),
      SlotState.taken => _BadgeSpec(
        icon: Icons.check_circle,
        label: l10n.doseStatusTaken,
        foreground: AppColors.takenText,
        background: AppColors.takenBg,
      ),
      SlotState.skipped => _BadgeSpec(
        icon: Icons.warning_amber_rounded,
        label: l10n.doseStatusSkipped,
        foreground: AppColors.pendingText,
        background: AppColors.pendingBg,
      ),
    };
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.spec});

  final _BadgeSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, color: spec.foreground, size: 12.sp),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              spec.label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: spec.foreground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncPendingBadge extends StatelessWidget {
  const _SyncPendingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          color: AppColors.infoBlue,
          size: 14.sp,
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.infoBlue),
        ),
      ],
    );
  }
}

class _SlotActionRow extends StatelessWidget {
  const _SlotActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // M-02: no fixed card/action heights — a minimum keeps the ≥48dp
    // target at default text scale, but the button is free to grow at
    // large text scales instead of clipping its label.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: AppSpacing.iconMd),
          label: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}


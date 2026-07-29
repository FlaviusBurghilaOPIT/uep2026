import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/agenda_entities.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../widgets/dose_slot_card.dart' show localizedDoseStatus;

/// Correction sheet (C7): factual, never shaming. Offers exactly the two
/// statuses that are NOT currently logged, plus "Keep as is" at equal
/// visual weight (spec §7).
class CorrectionSheet extends StatelessWidget {
  const CorrectionSheet({
    super.key,
    required this.slot,
    required this.onCorrect,
    required this.onKeep,
  });

  final AgendaSlot slot;
  final void Function(DoseLogStatus status) onCorrect;
  final VoidCallback onKeep;

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AgendaSlot slot,
    required void Function(DoseLogStatus status) onCorrect,
    required VoidCallback onKeep,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          CorrectionSheet(slot: slot, onCorrect: onCorrect, onKeep: onKeep),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final loggedText = slot.loggedAt != null
        ? DateFormat.jm(locale).format(slot.loggedAt!.toLocal())
        : '';
    final currentStatus = localizedDoseStatus(l10n, slot.state.name);

    final options = DoseLogStatus.values
        .where((s) => s.name != slot.state.name)
        .toList();

    return SafeArea(
      // M-02: at large text scales the title + three ≥48dp options can
      // exceed the available sheet height — scroll instead of overflowing.
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.todayCorrectionTitle(currentStatus, loggedText),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              for (final (i, status) in options.indexed) ...[
                if (i > 0) SizedBox(height: AppSpacing.sm),
                _CorrectionOption(
                  key: Key('correction_option_${status.name}'),
                  label: localizedDoseStatus(l10n, status.name),
                  onTap: () => onCorrect(status),
                ),
              ],
              SizedBox(height: AppSpacing.sm),
              _CorrectionOption(
                key: const Key('correction_keep'),
                label: l10n.todayCorrectionKeep,
                onTap: onKeep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CorrectionOption extends StatelessWidget {
  const _CorrectionOption({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // M-02: no fixed heights — minimum keeps the ≥48dp target, free to
    // grow at large text scales.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.greyDivider),
            foregroundColor: AppColors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

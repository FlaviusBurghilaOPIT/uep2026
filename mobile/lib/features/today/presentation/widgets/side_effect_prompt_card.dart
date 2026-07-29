import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/today_agenda_notifier.dart';

/// C8 side-effect prompt (spec §7): one-tap, dismissible, non-blocking.
/// "Yes" reveals the emergency CTA — or the honest no-contact note when the
/// case has no emergency contact. "No, I'm okay" completes silently.
class SideEffectPromptCard extends ConsumerStatefulWidget {
  const SideEffectPromptCard({super.key, required this.slotId});

  final String slotId;

  @override
  ConsumerState<SideEffectPromptCard> createState() =>
      _SideEffectPromptCardState();
}

class _SideEffectPromptCardState extends ConsumerState<SideEffectPromptCard> {
  bool _closed = false;
  bool _answeredYes = false;
  bool _loading = false;
  String? _emergencyPhone;

  Future<void> _answer({required bool severeSymptoms}) async {
    if (!severeSymptoms) {
      await ref
          .read(todayAgendaNotifierProvider.notifier)
          .answerC8Prompt(severeSymptoms: false);
      if (mounted) setState(() => _closed = true);
      return;
    }
    setState(() => _loading = true);
    final phone = await ref
        .read(todayAgendaNotifierProvider.notifier)
        .answerC8Prompt(severeSymptoms: true);
    if (mounted) {
      setState(() {
        _loading = false;
        _answeredYes = true;
        _emergencyPhone = phone;
      });
    }
  }

  Future<void> _callEmergencyContact() async {
    final phone = _emergencyPhone;
    if (phone == null) return;
    ref.read(todayAgendaNotifierProvider.notifier).trackEmergencyCtaTapped();
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('SideEffectPromptCard: could not launch tel: link: $e');
    }
  }

  void _dismiss() {
    ref.read(todayAgendaNotifierProvider.notifier).dismissC8Prompt();
    setState(() => _closed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_closed) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('c8_prompt'),
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.todaySkipPrompt,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                key: const Key('c8_dismiss'),
                icon: const Icon(Icons.close),
                onPressed: _dismiss,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (_answeredYes) ...[
            SizedBox(height: AppSpacing.sm),
            if (_emergencyPhone != null)
              ConstrainedBox(
                key: const Key('c8_emergency_cta'),
                constraints: const BoxConstraints(minHeight: 48),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _callEmergencyContact,
                    icon: const Icon(Icons.phone),
                    label: Text(l10n.emergencyCallCta),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: AppSpacing.iconMd,
                    color: AppColors.greyText,
                  ),
                  SizedBox(width: AppSpacing.hSm),
                  Expanded(
                    child: Text(
                      l10n.todayNoEmergencyContact,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
          ] else ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    key: const Key('c8_yes'),
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton(
                      onPressed: () => _answer(severeSymptoms: true),
                      child: Text(l10n.todaySkipPromptYes),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.hMd),
                Expanded(
                  child: ConstrainedBox(
                    key: const Key('c8_no'),
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton(
                      onPressed: () => _answer(severeSymptoms: false),
                      child: Text(l10n.todaySkipPromptNo),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

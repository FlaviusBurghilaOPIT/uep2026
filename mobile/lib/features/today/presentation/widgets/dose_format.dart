import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';

/// M-08 dose formatting: `0.5 mg` — leading zero, single space before unit.

/// Normalizes a server dose string for display:
/// - inserts exactly one space between amount and unit (`400mg` → `400 mg`)
/// - adds a leading zero to fractional amounts (`.5 mg` → `0.5 mg`)
/// - passes through anything that does not look like an amount+unit
String formatDose(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  final match = RegExp(
    r'^([0-9]+(?:\.[0-9]+)?|\.[0-9]+)\s*([a-zA-Zµ]+)$',
  ).firstMatch(trimmed);
  if (match == null) return trimmed;

  var amount = match.group(1)!;
  if (amount.startsWith('.')) amount = '0$amount';
  return '$amount ${match.group(2)!}';
}

/// Medication dosage format types (VIS-03).
enum DosageForm {
  capsule,
  tablet,
  liquid;

  /// Dedicated visual icon glyph for this dosage format.
  IconData get icon => switch (this) {
    DosageForm.capsule => LucideIcons.pill,
    DosageForm.tablet => LucideIcons.tablets,
    DosageForm.liquid => LucideIcons.droplet,
  };

  /// Localized name for this dosage format.
  String localizedName(AppLocalizations l10n) => switch (this) {
    DosageForm.capsule => l10n.pillFormCapsule,
    DosageForm.tablet => l10n.pillFormTablet,
    DosageForm.liquid => l10n.pillFormLiquid,
  };
}

/// Detects the medication form from medication name and dose strings.
DosageForm detectDosageForm({String? medicationName, String? dose}) {
  final combined = '${medicationName ?? ''} ${dose ?? ''}'.toLowerCase();
  if (combined.contains('liquid') ||
      combined.contains('drop') ||
      combined.contains('syrup') ||
      combined.contains('ml') ||
      combined.contains('solution') ||
      combined.contains('suspension') ||
      combined.contains('elixir')) {
    return DosageForm.liquid;
  }
  if (combined.contains('capsule') ||
      combined.contains('cap') ||
      combined.contains('gelcap') ||
      combined.contains('softgel')) {
    return DosageForm.capsule;
  }
  return DosageForm.tablet;
}

/// A compact dosage form badge pairing an icon glyph with localized text.
class DoseFormatBadge extends StatelessWidget {
  const DoseFormatBadge({
    super.key,
    required this.form,
    this.style,
    this.iconSize,
    this.iconColor,
    this.spacing,
  });

  final DosageForm form;
  final TextStyle? style;
  final double? iconSize;
  final Color? iconColor;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = iconColor ?? AppColors.greyLight;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          form.icon,
          size: iconSize ?? 13.sp,
          color: color,
        ),
        SizedBox(width: spacing ?? 4.w),
        Flexible(
          child: Text(
            form.localizedName(l10n),
            style: style ?? AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

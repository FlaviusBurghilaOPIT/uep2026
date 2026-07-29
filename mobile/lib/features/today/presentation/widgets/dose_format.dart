/// M-08 dose formatting: `0.5 mg` — leading zero, single space before unit.
library;

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

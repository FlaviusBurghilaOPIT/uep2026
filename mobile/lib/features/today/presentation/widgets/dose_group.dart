/// Time-of-day buckets for grouping dose slots on Today (spec §7):
/// Morning / Midday / Evening / Bedtime, assigned by local scheduled hour.
library;

enum DoseGroup { morning, midday, evening, bedtime }

/// Buckets a device-local scheduled time. Boundaries:
/// morning 05:00–11:59 · midday 12:00–16:59 · evening 17:00–20:59 ·
/// bedtime 21:00–04:59.
DoseGroup doseGroupFor(DateTime localTime) {
  final hour = localTime.hour;
  if (hour >= 5 && hour < 12) return DoseGroup.morning;
  if (hour >= 12 && hour < 17) return DoseGroup.midday;
  if (hour >= 17 && hour < 21) return DoseGroup.evening;
  return DoseGroup.bedtime;
}

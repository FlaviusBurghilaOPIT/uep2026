import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import 'today_agenda_notifier.dart';

/// Real FDA warning data for a medication on the patient's plan (spec §7,
/// pending question E1). The card renders only when this returns non-null;
/// any failure is a silent omission — never a fabricated warning.
class FdaWarning {
  const FdaWarning({
    required this.source,
    required this.message,
    this.retrievedAt,
  });

  final String source;
  final String message;
  final String? retrievedAt;
}

/// Queries `GET /fda/drug/{name}` for each medication on the patient's
/// agenda (slots + PRN) and returns the first warning that comes back with
/// content. Null when no plan med has data or every query fails.
final fdaWarningProvider = FutureProvider<FdaWarning?>((ref) async {
  final agenda = ref.watch(todayAgendaNotifierProvider).value;
  if (agenda == null) return null;

  final planMedNames = <String>{
    ...agenda.slots.map((s) => s.medicationName),
    ...agenda.prn.map((p) => p.medicationName),
  }..removeWhere((name) => name.trim().isEmpty);
  if (planMedNames.isEmpty) return null;

  final api = ref.read(apiServiceProvider);
  for (final name in planMedNames) {
    try {
      final res = await api.get('/fda/drug/${Uri.encodeComponent(name)}');
      if (res.statusCode != 200) continue;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final summary = data['summary'] as String?;
      if (summary == null || summary.trim().isEmpty) continue;
      return FdaWarning(
        source: data['source']?.toString() ?? 'Official FDA Drug Safety Info',
        message: summary,
        retrievedAt: (data['retrieved_at'] ?? data['timestamp'])?.toString(),
      );
    } catch (e, st) {
      // Silent omission by design — logged for diagnosability, never
      // surfaced as a fabricated warning.
      debugPrint('fdaWarningProvider: query failed for $name: $e\n$st');
    }
  }
  return null;
});

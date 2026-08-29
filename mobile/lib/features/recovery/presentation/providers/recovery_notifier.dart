import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/// One day of adherence derived from the existing agenda endpoint (no
/// server-side aggregation exists — the raw slot states are server truth).
class AdherenceDay {
  const AdherenceDay({
    required this.date,
    required this.taken,
    required this.total,
  });

  final DateTime date;
  final int taken;
  final int total;
}

enum RecoverySourceState { loading, ready, error }

/// Server-truth snapshot for the Recovery screen. Nullable fields render
/// honest absence — nothing here is ever fabricated.
class RecoveryState {
  const RecoveryState({
    this.sourceState = RecoverySourceState.loading,
    this.surgeryType,
    this.surgeryDate,
    this.dayOfRecovery,
    this.doctorName,
    this.recommendations = const [],
    this.adherenceDays = const [],
  });

  final RecoverySourceState sourceState;
  final String? surgeryType;
  final DateTime? surgeryDate;

  /// 1-based day count since [surgeryDate]; null when the date is absent
  /// or in the future (never a fabricated number).
  final int? dayOfRecovery;
  final String? doctorName;
  final List<String> recommendations;
  final List<AdherenceDay> adherenceDays;

  bool get hasAdherenceData => adherenceDays.any((d) => d.total > 0);

  /// Taken/total across the whole 7-day window; null when no day has slots.
  int? get overallAdherencePercent {
    final taken = adherenceDays.fold<int>(0, (sum, d) => sum + d.taken);
    final total = adherenceDays.fold<int>(0, (sum, d) => sum + d.total);
    if (total == 0) return null;
    return ((taken / total) * 100).round();
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Loads the Recovery screen's server truth: the patient's case (surgery
/// type/date), the case's free-text recommendations, and the last 7 days of
/// agenda slots from which adherence is derived client-side (spec req 13–16).
class RecoveryNotifier extends AsyncNotifier<RecoveryState> {
  /// Testable clock seam — defaults to [DateTime.now] in production.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  @override
  RecoveryState build() => const RecoveryState();

  ApiService get _api => ref.read(apiServiceProvider);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final patientId = ref.read(authProvider).patientId;
      if (patientId == null) {
        state = AsyncValue.data(_error());
        return;
      }

      final caseRes = await _api.getPatientCase(patientId: patientId);
      if (caseRes.statusCode != 200) {
        state = AsyncValue.data(_error());
        return;
      }
      final caseJson = jsonDecode(caseRes.body) as Map<String, dynamic>;
      final caseId = caseJson['id'] as String;
      final surgeryDateRaw = caseJson['surgery_date'] as String?;
      final surgeryDate = surgeryDateRaw != null
          ? DateTime.tryParse(surgeryDateRaw)
          : null;

      final recRes = await _api.getCaseRecommendations(caseId: caseId);
      if (recRes.statusCode != 200) {
        state = AsyncValue.data(_error());
        return;
      }
      final recommendations = (jsonDecode(recRes.body) as List<dynamic>)
          .map((r) => ((r as Map<String, dynamic>)['text'] as String? ?? ''))
          .where((text) => text.trim().isNotEmpty)
          .toList();

      final today = _dateOnly(clock());
      final days = <AdherenceDay>[];
      for (var i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        days.add(await _fetchAdherenceDay(date));
      }

      state = AsyncValue.data(
        RecoveryState(
          sourceState: RecoverySourceState.ready,
          surgeryType: caseJson['surgery_type'] as String?,
          surgeryDate: surgeryDate,
          dayOfRecovery: _dayOfRecovery(surgeryDate, today),
          doctorName: (caseJson['doctor_name'] ??
                  caseJson['clinician_name'] ??
                  caseJson['doctorName']) as String?,
          recommendations: recommendations,
          adherenceDays: days,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(_error());
    }
  }

  /// One day's taken/total from `GET /patients/me/agenda?date=...`. A failed
  /// day fetch renders as no data for that day — never a fabricated zero
  /// presented as truth, and never a whole-screen error for one bad day.
  Future<AdherenceDay> _fetchAdherenceDay(DateTime date) async {
    try {
      final res = await _api.getPatientAgenda(date: _isoDate(date));
      if (res.statusCode != 200) {
        return AdherenceDay(date: date, taken: 0, total: 0);
      }
      final slots =
          (jsonDecode(res.body) as Map<String, dynamic>)['slots']
              as List<dynamic>? ??
          const [];
      final taken = slots
          .where((s) => (s as Map<String, dynamic>)['state'] == 'taken')
          .length;
      return AdherenceDay(date: date, taken: taken, total: slots.length);
    } catch (_) {
      return AdherenceDay(date: date, taken: 0, total: 0);
    }
  }

  static RecoveryState _error() =>
      const RecoveryState(sourceState: RecoverySourceState.error);

  static int? _dayOfRecovery(DateTime? surgeryDate, DateTime today) {
    if (surgeryDate == null) return null;
    final day = today.difference(_dateOnly(surgeryDate)).inDays + 1;
    return day >= 1 ? day : null;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _isoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

final recoveryNotifierProvider =
    AsyncNotifierProvider<RecoveryNotifier, RecoveryState>(
      RecoveryNotifier.new,
    );

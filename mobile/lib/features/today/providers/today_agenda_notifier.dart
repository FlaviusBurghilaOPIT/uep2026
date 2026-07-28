import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/telemetry/telemetry_service.dart';
import '../../../core/providers/shared_preferences_provider.dart';

part 'today_agenda_notifier.freezed.dart';

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/// Server-computed slot states (backend spec §6 E2) plus the client-only
/// [syncPending] marker which is derived from the offline queue, never sent
/// by the server.
enum SlotState { upcoming, due, overdue, missed, taken, skipped }

/// Writable log statuses (E1). A subset of what a slot can render.
enum DoseLogStatus { taken, skipped, missed }

/// Read-path freshness for the agenda (spec §6 state mapping).
enum AgendaSourceState { loading, fresh, stale, error, empty }

enum OfflineQueueKind { create, correct, adhoc }

SlotState slotStateFromName(String name) =>
    SlotState.values.asNameMap()[name] ?? SlotState.upcoming;

@freezed
abstract class AgendaSlot with _$AgendaSlot {
  const factory AgendaSlot({
    required String slotId,
    required String medicationId,
    required String medicationName,
    required String dose,
    String? notes,
    required DateTime scheduledTime,
    required SlotState state,
    DateTime? loggedAt,
    String? doseLogId,
    String? previousStatus,
  }) = _AgendaSlot;
}

@freezed
abstract class PrnMedication with _$PrnMedication {
  const factory PrnMedication({
    required String medicationId,
    required String medicationName,
    required String dose,
    String? notes,
  }) = _PrnMedication;
}

@freezed
abstract class OfflineQueueEntry with _$OfflineQueueEntry {
  const factory OfflineQueueEntry({
    required String idempotencyKey,
    required OfflineQueueKind kind,
    required DoseLogStatus status,
    required DateTime enqueuedAt,
    String? slotId,
    String? doseLogId,
    String? medicationId,
  }) = _OfflineQueueEntry;
}

Map<String, dynamic> offlineQueueEntryToJson(OfflineQueueEntry e) => {
  'idempotency_key': e.idempotencyKey,
  'kind': e.kind.name,
  'status': e.status.name,
  'enqueued_at': e.enqueuedAt.toIso8601String(),
  if (e.slotId != null) 'slot_id': e.slotId,
  if (e.doseLogId != null) 'dose_log_id': e.doseLogId,
  if (e.medicationId != null) 'medication_id': e.medicationId,
};

OfflineQueueEntry offlineQueueEntryFromJson(Map<String, dynamic> m) =>
    OfflineQueueEntry(
      idempotencyKey: m['idempotency_key'] as String,
      kind:
          OfflineQueueKind.values.asNameMap()[m['kind'] as String] ??
          OfflineQueueKind.create,
      status:
          DoseLogStatus.values.asNameMap()[m['status'] as String] ??
          DoseLogStatus.taken,
      enqueuedAt: DateTime.parse(m['enqueued_at'] as String),
      slotId: m['slot_id'] as String?,
      doseLogId: m['dose_log_id'] as String?,
      medicationId: m['medication_id'] as String?,
    );

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@freezed
abstract class AgendaState with _$AgendaState {
  const factory AgendaState({
    @Default([]) List<AgendaSlot> slots,
    @Default([]) List<PrnMedication> prn,
    @Default(AgendaSourceState.loading) AgendaSourceState sourceState,
    DateTime? lastSyncedAt,
    @Default([]) List<OfflineQueueEntry> offlineQueue,
    @Default({}) Set<String> writeInFlightSlotIds,
    @Default({}) Set<String> writeInFlightPrnIds,
    String? c8PromptSlotId,
    String? rollbackErrorSlotId,
    @Default(false) bool planUpdated,
    @Default(false) bool timezoneAdjusted,
    @Default(false) bool remindersOff,
  }) = _AgendaState;
}

// ---------------------------------------------------------------------------
// Notifier — the ONLY writer for adherence on the mobile app (spec §6).
// ---------------------------------------------------------------------------

class _StagedWrite {
  _StagedWrite({required this.slotBefore, required this.status});

  final AgendaSlot slotBefore;
  final DoseLogStatus status;
}

class TodayAgendaNotifier extends AsyncNotifier<AgendaState> {
  static const _cacheBodyKey = 'today_agenda_cache_body_v1';
  static const _cacheTimeKey = 'today_agenda_cache_time_v1';
  static const _queueKey = 'today_offline_queue_v1';

  final Map<String, Timer> _undoTimers = {};
  final Map<String, _StagedWrite> _staged = {};
  Timer? _emptyPollTimer;
  Timer? _queueRetryTimer;
  final Uuid _uuid = const Uuid();

  @visibleForTesting
  Duration undoWindow = const Duration(seconds: 5);

  @visibleForTesting
  Duration emptyPollInterval = const Duration(seconds: 60);

  @visibleForTesting
  Duration queueRetryInterval = const Duration(seconds: 30);

  @override
  AgendaState build() {
    ref.onDispose(() {
      for (final timer in _undoTimers.values) {
        timer.cancel();
      }
      _undoTimers.clear();
      _emptyPollTimer?.cancel();
      _queueRetryTimer?.cancel();
    });
    return const AgendaState();
  }

  ApiService get _api => ref.read(apiServiceProvider);
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  void _track(String name, Map<String, dynamic> properties) {
    unawaited(ref.read(telemetryServiceProvider).trackEvent(name, properties));
  }

  // -- Read -----------------------------------------------------------------

  String _todayLocalIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  /// Cold start: restore persisted queue, flush it (C4), restore the cached
  /// agenda for immediate render, then fetch fresh truth.
  Future<void> start() async {
    await _restoreQueue();
    await flushOfflineQueue();
    await _restoreCacheIntoState();
    await loadAgenda();
  }

  /// `GET /patients/me/agenda?date=...` (today, local) with spec §6 state mapping.
  Future<void> loadAgenda() async {
    try {
      final res = await _api.getPatientAgenda(date: _todayLocalIso());
      if (res.statusCode == 200) {
        await _applyFreshAgenda(res.body);
      } else {
        await _handleFetchFailure('http_${res.statusCode}');
      }
    } catch (e) {
      await _handleFetchFailure(e.runtimeType.toString());
    }
  }

  Future<void> _applyFreshAgenda(String body) async {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final slots = (json['slots'] as List<dynamic>)
        .map((m) => _slotFromJson(m as Map<String, dynamic>))
        .toList();
    final prn = (json['prn'] as List<dynamic>)
        .map((m) => _prnFromJson(m as Map<String, dynamic>))
        .toList();

    final current = state.value ?? const AgendaState();
    final isEmpty = slots.isEmpty && prn.isEmpty;

    // C6: plan-changed detection — the medication set differs from what we
    // last rendered (first load never counts as a change).
    final hadData = current.slots.isNotEmpty || current.prn.isNotEmpty;
    final previousMedIds = <String>{
      ...current.slots.map((s) => s.medicationId),
      ...current.prn.map((p) => p.medicationId),
    };
    final newMedIds = <String>{
      ...slots.map((s) => s.medicationId),
      ...prn.map((p) => p.medicationId),
    };
    final planChanged =
        hadData &&
        (previousMedIds.length != newMedIds.length ||
            !previousMedIds.containsAll(newMedIds));

    state = AsyncValue.data(
      current.copyWith(
        slots: slots,
        prn: prn,
        sourceState: isEmpty
            ? AgendaSourceState.empty
            : AgendaSourceState.fresh,
        lastSyncedAt: DateTime.now(),
        planUpdated: planChanged || current.planUpdated,
      ),
    );

    await _persistCache(body);
    _track('mobile.today.agenda_viewed', {
      'slot_count': slots.length,
      'has_prn': prn.isNotEmpty,
      'stale': false,
    });
    _syncEmptyPoll();

    // A successful fetch means connectivity is back — flush anything queued.
    await flushOfflineQueue();
  }

  Future<void> _handleFetchFailure(String errorClass) async {
    var current = state.value ?? const AgendaState();
    if (current.slots.isEmpty && current.prn.isEmpty) {
      // Maybe we have a persisted cache that was never restored.
      final restored = await _restoreCacheIntoState();
      current = state.value ?? current;
      if (!restored) {
        state = AsyncValue.data(
          current.copyWith(sourceState: AgendaSourceState.error),
        );
        _track('mobile.today.agenda_failed', {'error_class': errorClass});
        _syncEmptyPoll();
        return;
      }
    }
    state = AsyncValue.data(
      current.copyWith(sourceState: AgendaSourceState.stale),
    );
    _syncEmptyPoll();
  }

  // -- Cache (last-good response, persisted JSON for cold start) -------------

  Future<void> _persistCache(String body) async {
    await _prefs.setString(_cacheBodyKey, body);
    await _prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
  }

  Future<bool> _restoreCacheIntoState() async {
    final body = _prefs.getString(_cacheBodyKey);
    if (body == null) return false;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final slots = (json['slots'] as List<dynamic>)
          .map((m) => _slotFromJson(m as Map<String, dynamic>))
          .toList();
      final prn = (json['prn'] as List<dynamic>)
          .map((m) => _prnFromJson(m as Map<String, dynamic>))
          .toList();
      final timeRaw = _prefs.getString(_cacheTimeKey);
      final current = state.value ?? const AgendaState();
      state = AsyncValue.data(
        current.copyWith(
          slots: slots,
          prn: prn,
          lastSyncedAt: timeRaw != null ? DateTime.tryParse(timeRaw) : null,
        ),
      );
      return true;
    } catch (e, st) {
      debugPrint(
        'TodayAgendaNotifier: corrupt agenda cache, dropping: $e\n$st',
      );
      await _prefs.remove(_cacheBodyKey);
      await _prefs.remove(_cacheTimeKey);
      return false;
    }
  }

  // -- C9 empty-state poll (60s, only while empty) ----------------------------

  void _syncEmptyPoll() {
    final isEmpty = (state.value)?.sourceState == AgendaSourceState.empty;
    if (isEmpty && _emptyPollTimer == null) {
      _emptyPollTimer = Timer.periodic(emptyPollInterval, (_) {
        unawaited(loadAgenda());
      });
    } else if (!isEmpty) {
      _emptyPollTimer?.cancel();
      _emptyPollTimer = null;
    }
  }

  // -- JSON mapping ------------------------------------------------------------

  AgendaSlot _slotFromJson(Map<String, dynamic> m) => AgendaSlot(
    slotId: m['slot_id'] as String,
    medicationId: m['medication_id'] as String,
    medicationName: m['medication_name'] as String,
    dose: m['dose'] as String? ?? '',
    notes: m['notes'] as String?,
    scheduledTime: DateTime.parse(m['scheduled_time'] as String),
    state: slotStateFromName(m['state'] as String? ?? 'upcoming'),
    loggedAt: m['logged_at'] != null
        ? DateTime.parse(m['logged_at'] as String)
        : null,
    doseLogId: m['dose_log_id'] as String?,
    previousStatus: m['previous_status'] as String?,
  );

  PrnMedication _prnFromJson(Map<String, dynamic> m) => PrnMedication(
    medicationId: m['medication_id'] as String,
    medicationName: m['medication_name'] as String,
    dose: m['dose'] as String? ?? '',
    notes: m['notes'] as String?,
  );

  // -- Write — single path, per-slot lock (spec §6) ---------------------------

  AgendaSlot? _slotById(String slotId) {
    for (final slot in (state.value)?.slots ?? const <AgendaSlot>[]) {
      if (slot.slotId == slotId) return slot;
    }
    return null;
  }

  void _setSlot(AgendaSlot updated) {
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(
      current.copyWith(
        slots: [
          for (final slot in current.slots)
            if (slot.slotId == updated.slotId) updated else slot,
        ],
      ),
    );
  }

  void _markWriteInFlight(String slotId, bool inFlight) {
    final current = state.value ?? const AgendaState();
    final ids = Set<String>.from(current.writeInFlightSlotIds);
    if (inFlight) {
      ids.add(slotId);
    } else {
      ids.remove(slotId);
    }
    state = AsyncValue.data(current.copyWith(writeInFlightSlotIds: ids));
  }

  /// Log a dose against a scheduled slot. Double-taps while a write is
  /// staged/in flight are ignored (the screen gives haptic-only feedback).
  Future<void> logDose(AgendaSlot slot, DoseLogStatus status) async {
    final current = state.value ?? const AgendaState();
    if (current.writeInFlightSlotIds.contains(slot.slotId)) return;

    _track('mobile.today.dose_log_tapped', {
      'slot_state_before': slot.state.name,
      'action': status.name,
    });

    _staged[slot.slotId] = _StagedWrite(slotBefore: slot, status: status);
    _markWriteInFlight(slot.slotId, true);
    _setSlot(slot.copyWith(state: slotStateFromName(status.name)));

    _undoTimers[slot.slotId]?.cancel();
    _undoTimers[slot.slotId] = Timer(undoWindow, () {
      _undoTimers.remove(slot.slotId);
      unawaited(_commitStaged(slot.slotId));
    });
  }

  /// Undo within the window: revert locally, nothing reaches the server.
  void undoDoseLog(String slotId) {
    final staged = _staged.remove(slotId);
    _undoTimers.remove(slotId)?.cancel();
    if (staged == null) return;
    _setSlot(staged.slotBefore);
    _markWriteInFlight(slotId, false);
    _track('mobile.today.dose_log_undone', const {});
  }

  Future<void> _commitStaged(String slotId) async {
    final staged = _staged.remove(slotId);
    if (staged == null) return;

    try {
      final res = await _postLog(slotId, staged.status);
      if (_isCreated(res)) {
        _applyCreateCommit(slotId, staged.status, res.body);
      } else if (res.statusCode == 409) {
        _apply409(slotId, res.body);
      } else {
        // Server error — retry once, then roll back (spec §6).
        final retry = await _postLog(slotId, staged.status);
        if (_isCreated(retry)) {
          _applyCreateCommit(slotId, staged.status, retry.body);
        } else if (retry.statusCode == 409) {
          _apply409(slotId, retry.body);
        } else {
          _rollback(slotId, staged, 'http_${retry.statusCode}');
          return;
        }
      }
    } catch (e) {
      // Network failure — queue offline (C3/C4), slot shows sync-pending.
      _enqueue(
        OfflineQueueEntry(
          idempotencyKey: _uuid.v4(),
          kind: OfflineQueueKind.create,
          status: staged.status,
          enqueuedAt: DateTime.now(),
          slotId: slotId,
        ),
      );
    }
    _markWriteInFlight(slotId, false);
  }

  Future<dynamic> _postLog(String slotId, DoseLogStatus status) {
    return _api.logAdherence(scheduledReminderId: slotId, status: status.name);
  }

  bool _isCreated(dynamic res) =>
      res.statusCode == 200 || res.statusCode == 201;

  void _applyCreateCommit(String slotId, DoseLogStatus status, String body) {
    final slot = _slotById(slotId);
    if (slot == null) return;
    String? doseLogId;
    DateTime? loggedAt;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      doseLogId = json['id'] as String?;
      final loggedRaw = json['logged_at'] as String?;
      loggedAt = loggedRaw != null ? DateTime.tryParse(loggedRaw) : null;
    } catch (e, st) {
      debugPrint('TodayAgendaNotifier: unparseable log response: $e\n$st');
    }
    _setSlot(
      slot.copyWith(
        state: slotStateFromName(status.name),
        doseLogId: doseLogId ?? slot.doseLogId,
        loggedAt: loggedAt ?? slot.loggedAt,
      ),
    );
    _track('mobile.today.dose_log_committed', {
      'status': status.name,
      'was_offline': false,
    });
    if (status == DoseLogStatus.skipped) _setC8Prompt(slotId);
  }

  /// 409 — server truth wins: reconcile the slot to the existing log.
  void _apply409(String slotId, String body) {
    final slot = _slotById(slotId);
    if (slot == null) return;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final detail = json['detail'] as Map<String, dynamic>;
      final statusRaw = detail['status'] as String?;
      final loggedRaw = detail['logged_at'] as String?;
      _setSlot(
        slot.copyWith(
          state: statusRaw != null ? slotStateFromName(statusRaw) : slot.state,
          doseLogId: detail['id'] as String? ?? slot.doseLogId,
          loggedAt: loggedRaw != null
              ? DateTime.tryParse(loggedRaw) ?? slot.loggedAt
              : slot.loggedAt,
        ),
      );
      _track('mobile.today.dose_log_committed', {
        'status': statusRaw ?? slot.state.name,
        'was_offline': false,
      });
    } catch (e, st) {
      debugPrint('TodayAgendaNotifier: unparseable 409 detail: $e\n$st');
    }
  }

  void _rollback(String slotId, _StagedWrite staged, String errorClass) {
    _setSlot(staged.slotBefore);
    _markWriteInFlight(slotId, false);
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(current.copyWith(rollbackErrorSlotId: slotId));
    _track('mobile.today.dose_log_rolled_back', {'error_class': errorClass});
  }

  /// Screen acknowledges the rollback error snackbar.
  void acknowledgeRollback() {
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(current.copyWith(rollbackErrorSlotId: null));
  }

  void _setC8Prompt(String slotId) {
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(current.copyWith(c8PromptSlotId: slotId));
  }

  /// Screen dismisses the C8 side-effect prompt.
  void dismissC8Prompt() {
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(current.copyWith(c8PromptSlotId: null));
  }

  /// Screen dismisses the C6 plan-changed banner.
  void dismissPlanUpdated() {
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(current.copyWith(planUpdated: false));
  }

  /// WI 14 sets this from the OS notification-permission check (C1).
  void setRemindersOff(bool off) {
    final current = state.value ?? const AgendaState();
    if (current.remindersOff == off) return;
    state = AsyncValue.data(current.copyWith(remindersOff: off));
  }

  /// WI 14 sets this once when the notification re-anchor pass (app start /
  /// timezone-change proxy) detects the device's UTC offset shifted (C5).
  void setTimezoneAdjusted(bool adjusted) {
    final current = state.value ?? const AgendaState();
    if (current.timezoneAdjusted == adjusted) return;
    state = AsyncValue.data(current.copyWith(timezoneAdjusted: adjusted));
  }

  /// Screen dismisses the C5 timezone-adjusted banner.
  void dismissTimezoneAdjusted() {
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(current.copyWith(timezoneAdjusted: false));
  }

  /// C8 answer. Returns the emergency-contact phone when the patient taps
  /// "Yes" — null when no contact is on file (render the no-contact note)
  /// or when the answer was "No" (completes silently).
  Future<String?> answerC8Prompt({required bool severeSymptoms}) async {
    _track(
      severeSymptoms
          ? 'mobile.today.skip_sideeffect_yes'
          : 'mobile.today.skip_sideeffect_no',
      const {},
    );
    if (!severeSymptoms) {
      dismissC8Prompt();
      return null;
    }
    return _fetchEmergencyContactPhone();
  }

  /// D1: `GET /cases/{caseId}/emergency-contact` returns 200 with null
  /// fields when unset (404 only for an unknown case) — both map to the
  /// no-contact branch.
  Future<String?> _fetchEmergencyContactPhone() async {
    try {
      final auth = ref.read(authProvider);
      var caseId = auth.caseId;
      if (caseId == null && auth.patientId != null) {
        final caseRes = await _api.get('/patients/${auth.patientId}/case');
        if (caseRes.statusCode == 200) {
          caseId =
              (jsonDecode(caseRes.body) as Map<String, dynamic>)['id']
                  as String?;
        }
      }
      if (caseId == null) return null;
      final res = await _api.get('/cases/$caseId/emergency-contact');
      if (res.statusCode != 200) return null;
      final phone =
          (jsonDecode(res.body) as Map<String, dynamic>)['phone'] as String?;
      return (phone == null || phone.trim().isEmpty) ? null : phone;
    } catch (e, st) {
      debugPrint(
        'TodayAgendaNotifier: emergency contact fetch failed: $e\n$st',
      );
      return null;
    }
  }

  /// Telemetry for the emergency CTA tap (launch happens screen-side).
  void trackEmergencyCtaTapped() {
    _track('mobile.today.emergency_cta_tapped', const {});
  }

  /// Telemetry for a logged slot being tapped to open the correction sheet.
  void trackCorrectionOpened(AgendaSlot slot) {
    final loggedAt = slot.loggedAt;
    final age = loggedAt == null
        ? Duration.zero
        : DateTime.now().difference(loggedAt.toLocal());
    _track('mobile.today.correction_opened', {
      'slot_age_hours_bucket': age.inHours < 1
          ? '<1h'
          : age.inHours < 24
          ? '1-24h'
          : '>24h',
    });
  }

  void _enqueue(OfflineQueueEntry entry) {
    final current = state.value ?? const AgendaState();
    state = AsyncValue.data(
      current.copyWith(offlineQueue: [...current.offlineQueue, entry]),
    );
    unawaited(_persistQueue());
    _syncQueueRetry();
  }

  /// Correction (C7): PATCH an existing log. Previous value is preserved
  /// factually in [AgendaSlot.previousStatus]. Offline → queued correction.
  Future<void> correctLog(AgendaSlot slot, DoseLogStatus newStatus) async {
    final logId = slot.doseLogId;
    if (logId == null) return;
    final current = state.value ?? const AgendaState();
    if (current.writeInFlightSlotIds.contains(slot.slotId)) return;

    _markWriteInFlight(slot.slotId, true);
    _setSlot(
      slot.copyWith(
        state: slotStateFromName(newStatus.name),
        previousStatus: slot.state.name,
      ),
    );

    try {
      final res = await _api.correctAdherenceLog(
        logId: logId,
        status: newStatus.name,
      );
      if (res.statusCode == 200) {
        try {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final latest = _slotById(slot.slotId);
          if (latest != null) {
            _setSlot(
              latest.copyWith(
                state: slotStateFromName(
                  json['status'] as String? ?? newStatus.name,
                ),
                previousStatus:
                    json['previous_status'] as String? ?? latest.previousStatus,
              ),
            );
          }
        } catch (e, st) {
          debugPrint(
            'TodayAgendaNotifier: unparseable PATCH response: $e\n$st',
          );
        }
        _track('mobile.today.dose_log_corrected', const {});
      } else {
        _setSlot(slot);
        final latest = state.value ?? const AgendaState();
        state = AsyncValue.data(
          latest.copyWith(rollbackErrorSlotId: slot.slotId),
        );
        _track('mobile.today.dose_log_rolled_back', {
          'error_class': 'http_${res.statusCode}',
        });
      }
    } catch (e) {
      // Offline — queue the correction; flush order is creates-first.
      _enqueue(
        OfflineQueueEntry(
          idempotencyKey: _uuid.v4(),
          kind: OfflineQueueKind.correct,
          status: newStatus,
          enqueuedAt: DateTime.now(),
          slotId: slot.slotId,
          doseLogId: logId,
        ),
      );
    }
    _markWriteInFlight(slot.slotId, false);
  }

  // -- PRN ad-hoc logging (E1 log-adhoc) ----------------------------------------

  /// Log a PRN ("as needed") medication. One idempotency key per user
  /// action; offline retries reuse the same key (spec §6).
  Future<void> logPrn(PrnMedication medication, DoseLogStatus status) async {
    final current = state.value ?? const AgendaState();
    if (current.writeInFlightPrnIds.contains(medication.medicationId)) return;

    _track('mobile.today.dose_log_tapped', {
      'slot_state_before': 'prn',
      'action': status.name,
    });

    final key = _uuid.v4();
    _markPrnInFlight(medication.medicationId, true);
    try {
      final res = await _api.logAdhocAdherence(
        medicationId: medication.medicationId,
        status: status.name,
        idempotencyKey: key,
      );
      if (_isCreated(res)) {
        _applyAdhocCommit(res.body);
        _track('mobile.today.dose_log_committed', {
          'status': status.name,
          'was_offline': false,
        });
        if (status == DoseLogStatus.skipped) {
          final slot = _latestAdhocSlot(res.body);
          if (slot != null) _setC8Prompt(slot.slotId);
        }
      } else {
        final latest = state.value ?? const AgendaState();
        state = AsyncValue.data(
          latest.copyWith(rollbackErrorSlotId: medication.medicationId),
        );
        _track('mobile.today.dose_log_rolled_back', {
          'error_class': 'http_${res.statusCode}',
        });
      }
    } catch (e) {
      _enqueue(
        OfflineQueueEntry(
          idempotencyKey: key,
          kind: OfflineQueueKind.adhoc,
          status: status,
          enqueuedAt: DateTime.now(),
          medicationId: medication.medicationId,
        ),
      );
    }
    _markPrnInFlight(medication.medicationId, false);
  }

  void _markPrnInFlight(String medicationId, bool inFlight) {
    final current = state.value ?? const AgendaState();
    final ids = Set<String>.from(current.writeInFlightPrnIds);
    if (inFlight) {
      ids.add(medicationId);
    } else {
      ids.remove(medicationId);
    }
    state = AsyncValue.data(current.copyWith(writeInFlightPrnIds: ids));
  }

  AgendaSlot? _latestAdhocSlot(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final slotMap = json['slot'] is Map<String, dynamic>
          ? json['slot'] as Map<String, dynamic>
          : json;
      return _slotFromJson(slotMap);
    } catch (e, st) {
      debugPrint('TodayAgendaNotifier: unparseable ad-hoc response: $e\n$st');
      return null;
    }
  }

  void _applyAdhocCommit(String body) {
    final slot = _latestAdhocSlot(body);
    if (slot == null) return;
    final current = state.value ?? const AgendaState();
    if (current.slots.any((s) => s.slotId == slot.slotId)) {
      _setSlot(slot);
      return;
    }
    state = AsyncValue.data(current.copyWith(slots: [...current.slots, slot]));
  }

  // -- Offline queue (C4) ------------------------------------------------------

  Future<void> _restoreQueue() async {
    final raw = _prefs.getString(_queueKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((m) => offlineQueueEntryFromJson(m as Map<String, dynamic>))
          .toList();
      final current = state.value ?? const AgendaState();
      state = AsyncValue.data(current.copyWith(offlineQueue: list));
      _syncQueueRetry();
    } catch (e, st) {
      debugPrint(
        'TodayAgendaNotifier: corrupt offline queue, dropping: $e\n$st',
      );
      await _prefs.remove(_queueKey);
    }
  }

  Future<void> _persistQueue() async {
    final queue = (state.value)?.offlineQueue ?? const [];
    await _prefs.setString(
      _queueKey,
      jsonEncode(queue.map(offlineQueueEntryToJson).toList()),
    );
  }

  void _syncQueueRetry() {
    final hasEntries = ((state.value)?.offlineQueue.isNotEmpty ?? false);
    if (hasEntries && _queueRetryTimer == null) {
      _queueRetryTimer = Timer.periodic(queueRetryInterval, (_) {
        unawaited(flushOfflineQueue());
      });
    } else if (!hasEntries) {
      _queueRetryTimer?.cancel();
      _queueRetryTimer = null;
    }
  }

  /// Flushes the offline queue in order — creates (and ad-hoc creates)
  /// before corrections (spec §6). Per-entry 409 reconciles, never errors.
  Future<void> flushOfflineQueue() async {
    final current = state.value ?? const AgendaState();
    if (current.offlineQueue.isEmpty) return;

    final started = DateTime.now();
    final creates = current.offlineQueue
        .where((e) => e.kind != OfflineQueueKind.correct)
        .toList();
    final corrections = current.offlineQueue
        .where((e) => e.kind == OfflineQueueKind.correct)
        .toList();

    final remaining = <OfflineQueueEntry>[];
    var flushed = 0;

    for (final entry in [...creates, ...corrections]) {
      final done = await _flushEntry(entry);
      if (done) {
        flushed++;
      } else {
        remaining.add(entry);
      }
    }

    final latest = state.value ?? const AgendaState();
    state = AsyncValue.data(latest.copyWith(offlineQueue: remaining));
    await _persistQueue();
    _syncQueueRetry();

    if (flushed > 0) {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      _track('mobile.today.sync_flushed', {
        'entries_count': flushed,
        'duration_ms_bucket': elapsed < 1000
            ? '<1s'
            : elapsed < 5000
            ? '1-5s'
            : '>5s',
      });
    }
  }

  /// Returns true when the entry reached a terminal state (applied,
  /// reconciled, or safely droppable) and can leave the queue.
  Future<bool> _flushEntry(OfflineQueueEntry entry) async {
    try {
      switch (entry.kind) {
        case OfflineQueueKind.create:
          final res = await _api.logAdherence(
            scheduledReminderId: entry.slotId!,
            status: entry.status.name,
          );
          if (_isCreated(res)) {
            _applyCreateCommit(entry.slotId!, entry.status, res.body);
            _markOfflineCommitted(entry);
            return true;
          }
          if (res.statusCode == 409) {
            _apply409(entry.slotId!, res.body);
            return true;
          }
          return false;
        case OfflineQueueKind.adhoc:
          final res = await _api.logAdhocAdherence(
            medicationId: entry.medicationId!,
            status: entry.status.name,
            idempotencyKey: entry.idempotencyKey,
          );
          if (_isCreated(res)) {
            _applyAdhocCommit(res.body);
            _markOfflineCommitted(entry);
            return true;
          }
          return false;
        case OfflineQueueKind.correct:
          final res = await _api.correctAdherenceLog(
            logId: entry.doseLogId!,
            status: entry.status.name,
          );
          if (res.statusCode == 200) {
            final slotId = entry.slotId;
            final slot = slotId != null ? _slotById(slotId) : null;
            if (slot != null) {
              _setSlot(
                slot.copyWith(
                  state: slotStateFromName(entry.status.name),
                  previousStatus: slot.state.name,
                ),
              );
            }
            _track('mobile.today.dose_log_corrected', const {});
            _markOfflineCommitted(entry);
            return true;
          }
          // 400 (status unchanged — already applied) and 404 (log gone)
          // are terminal: drop the entry rather than retry forever.
          if (res.statusCode == 400 || res.statusCode == 404) {
            return true;
          }
          return false;
      }
    } catch (e) {
      return false; // still offline — keep the entry
    }
  }

  void _markOfflineCommitted(OfflineQueueEntry entry) {
    _track('mobile.today.dose_log_committed', {
      'status': entry.status.name,
      'was_offline': true,
    });
  }
}

final todayAgendaNotifierProvider =
    AsyncNotifierProvider<TodayAgendaNotifier, AgendaState>(
      TodayAgendaNotifier.new,
    );

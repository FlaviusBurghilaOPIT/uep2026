import 'package:freezed_annotation/freezed_annotation.dart';

part 'agenda_entities.freezed.dart';

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

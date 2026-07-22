import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/telemetry/telemetry_service.dart';

part 'today_agenda_notifier.freezed.dart';

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

enum DoseStatus { pending, taken, missed, skipped }

@freezed
class PendingDoseQueueItem with _$PendingDoseQueueItem {
  const factory PendingDoseQueueItem({
    required String reminderId,
    required DoseStatus status,
    required DateTime timestamp,
  }) = _PendingDoseQueueItem;
}

@freezed
class MedicationItem with _$MedicationItem {
  const factory MedicationItem({
    required String id,
    required String name,
    required String dose,
    required String scheduleText,
    required String duration,
    String? notes,
  }) = _MedicationItem;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@freezed
class AgendaState with _$AgendaState {
  const factory AgendaState({
    required AsyncValue<List<MedicationItem>> medications,
    required Map<String, DoseStatus> doseStatuses,
    @Default([]) List<PendingDoseQueueItem> offlineQueue,
  }) = _AgendaState;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TodayAgendaNotifier extends AsyncNotifier<AgendaState> {
  final Map<String, Timer> _pendingUndoTimers = {};

  @override
  AgendaState build() {
    ref.onDispose(() {
      for (final timer in _pendingUndoTimers.values) {
        timer.cancel();
      }
      _pendingUndoTimers.clear();
    });

    return const AgendaState(
      medications: AsyncValue.data([]),
      doseStatuses: {},
      offlineQueue: [],
    );
  }

  ApiService get _api => ref.read(apiServiceProvider);

  /// GET /cases/{caseId}/medications → populates [AgendaState.medications].
  Future<void> loadAgenda(String caseId) async {
    final current = state.valueOrNull ??
        const AgendaState(
          medications: AsyncValue.loading(),
          doseStatuses: {},
          offlineQueue: [],
        );

    state = AsyncValue.data(
      current.copyWith(medications: const AsyncValue.loading()),
    );

    try {
      final res = await _api.get('/cases/$caseId/medications');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final items = list.map((m) {
          final map = m as Map<String, dynamic>;
          return MedicationItem(
            id: map['id'] as String,
            name: map['name'] as String,
            dose: map['dose'] as String,
            scheduleText: (map['frequency'] as String?) ??
                (map['schedule_text'] as String? ?? 'QD'),
            duration: map['duration'] as String,
            notes: map['notes'] as String?,
          );
        }).toList();

        final updated = state.valueOrNull ?? current;
        state = AsyncValue.data(
          updated.copyWith(medications: AsyncValue.data(items)),
        );
        await _scheduleNotificationsForMedications(items);
        await flushOfflineQueue();
      } else {
        final updated = state.valueOrNull ?? current;
        state = AsyncValue.data(
          updated.copyWith(
            medications: AsyncValue.error(
              'Failed to load agenda (${res.statusCode})',
              StackTrace.current,
            ),
          ),
        );
      }
    } catch (e, st) {
      final updated = state.valueOrNull ?? current;
      state = AsyncValue.data(
        updated.copyWith(medications: AsyncValue.error(e, st)),
      );
    }
  }

  /// Stage a dose status change with a 5-second undo window.
  void stageDoseLog({
    required String reminderId,
    required DoseStatus status,
    Duration window = const Duration(seconds: 5),
    DoseStatus previousStatus = DoseStatus.pending,
  }) {
    _pendingUndoTimers[reminderId]?.cancel();

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          doseStatuses: {...current.doseStatuses, reminderId: status},
        ),
      );
    }

    _pendingUndoTimers[reminderId] = Timer(window, () {
      _pendingUndoTimers.remove(reminderId);
      commitDoseLog(reminderId: reminderId, status: status);
    });
  }

  /// Reverts a staged dose log back to previous status or pending.
  void undoDoseLog({
    required String reminderId,
    DoseStatus previousStatus = DoseStatus.pending,
  }) {
    _pendingUndoTimers[reminderId]?.cancel();
    _pendingUndoTimers.remove(reminderId);

    final current = state.valueOrNull;
    if (current != null) {
      final updatedStatuses = Map<String, DoseStatus>.from(current.doseStatuses);
      updatedStatuses[reminderId] = previousStatus;
      state = AsyncValue.data(
        current.copyWith(doseStatuses: updatedStatuses),
      );
    }

    try {
      ref.read(telemetryServiceProvider).trackEvent('mobile.today.dose_log_undone', {
        'reminder_id_hash': reminderId.hashCode.toString(),
        'status_enum': previousStatus.name,
      });
    } catch (_) {}
  }

  /// POST /adherence/log with {reminder_id, status}.
  Future<void> logDose({
    required String reminderId,
    required DoseStatus status,
  }) async {
    return commitDoseLog(reminderId: reminderId, status: status);
  }

  /// Commits the dose log to backend or queues offline.
  Future<void> commitDoseLog({
    required String reminderId,
    required DoseStatus status,
  }) async {
    _pendingUndoTimers[reminderId]?.cancel();
    _pendingUndoTimers.remove(reminderId);

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          doseStatuses: {...current.doseStatuses, reminderId: status},
        ),
      );
    }

    try {
      final res = await _api.post('/adherence/log', {
        'reminder_id': reminderId,
        'status': status.name,
      });

      final isSuccess = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 409;
      if (!isSuccess) {
        _queueOfflineLog(reminderId: reminderId, status: status);
      }

      try {
        ref.read(telemetryServiceProvider).trackEvent('mobile.today.dose_logged', {
          'reminder_id_hash': reminderId.hashCode.toString(),
          'status_enum': status.name,
          'is_offline': !isSuccess,
        });
      } catch (_) {}
    } catch (_) {
      _queueOfflineLog(reminderId: reminderId, status: status);
      try {
        ref.read(telemetryServiceProvider).trackEvent('mobile.today.dose_logged', {
          'reminder_id_hash': reminderId.hashCode.toString(),
          'status_enum': status.name,
          'is_offline': true,
        });
      } catch (_) {}
    }
  }

  void _queueOfflineLog({
    required String reminderId,
    required DoseStatus status,
  }) {
    final current = state.valueOrNull;
    if (current != null) {
      final newQueue = [
        ...current.offlineQueue.where((item) => item.reminderId != reminderId),
        PendingDoseQueueItem(
          reminderId: reminderId,
          status: status,
          timestamp: DateTime.now(),
        ),
      ];
      state = AsyncValue.data(current.copyWith(offlineQueue: newQueue));
    }
  }

  /// Flushes any pending offline logs to the server.
  Future<void> flushOfflineQueue() async {
    final current = state.valueOrNull;
    if (current == null || current.offlineQueue.isEmpty) return;

    final remaining = <PendingDoseQueueItem>[];

    for (final item in current.offlineQueue) {
      try {
        final res = await _api.post('/adherence/log', {
          'reminder_id': item.reminderId,
          'status': item.status.name,
        });

        final isSuccess = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 409;
        if (!isSuccess) {
          remaining.add(item);
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    final latest = state.valueOrNull;
    if (latest != null) {
      state = AsyncValue.data(latest.copyWith(offlineQueue: remaining));
    }
  }

  Future<void> _scheduleNotificationsForMedications(
      List<MedicationItem> items) async {
    try {
      await NotificationService.instance.cancelAll();
      final now = DateTime.now();
      for (final med in items) {
        final scheduleLower = med.scheduleText.toLowerCase();
        final List<TimeOfDay> times = [];
        if (scheduleLower.contains('3x') ||
            scheduleLower.contains('3 times') ||
            scheduleLower.contains('every 8 hours')) {
          times.addAll(const [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 14, minute: 0),
            TimeOfDay(hour: 20, minute: 0)
          ]);
        } else if (scheduleLower.contains('2x') ||
            scheduleLower.contains('2 times') ||
            scheduleLower.contains('every 12 hours')) {
          times.addAll(const [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 20, minute: 0)
          ]);
        } else {
          times.add(const TimeOfDay(hour: 8, minute: 0));
        }

        for (int i = 0; i < times.length; i++) {
          final timeOfDay = times[i];
          final scheduledDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            timeOfDay.hour,
            timeOfDay.minute,
          );
          await NotificationService.instance.scheduleMedicationReminder(
            reminderId: med.id,
            medicationId: med.id,
            medicationName: med.name,
            doseAmount: med.dose,
            scheduledTime: scheduledDateTime,
          );
        }
      }
    } catch (_) {}
  }
}

final todayAgendaNotifierProvider =
    AsyncNotifierProvider<TodayAgendaNotifier, AgendaState>(
  TodayAgendaNotifier.new,
);

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_service.dart';
import '../../../core/notifications/notification_service.dart';

part 'today_agenda_notifier.freezed.dart';

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

enum DoseStatus { pending, taken, missed, skipped }

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
  }) = _AgendaState;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TodayAgendaNotifier extends AsyncNotifier<AgendaState> {
  @override
  AgendaState build() => const AgendaState(
        medications: AsyncValue.data([]),
        doseStatuses: {},
      );

  ApiService get _api => ref.read(apiServiceProvider);

  /// GET /cases/{caseId}/medications → populates [AgendaState.medications].
  Future<void> loadAgenda(String caseId) async {
    final current = state.valueOrNull ??
        AgendaState(
          medications: const AsyncValue.loading(),
          doseStatuses: const {},
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
            scheduleText: map['schedule_text'] as String,
            duration: map['duration'] as String,
            notes: map['notes'] as String?,
          );
        }).toList();

        final updated = state.valueOrNull ?? current;
        state = AsyncValue.data(
          updated.copyWith(medications: AsyncValue.data(items)),
        );
        await _scheduleNotificationsForMedications(items);
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

  /// POST /adherence/log with {reminder_id, status}.
  /// Optimistically updates [AgendaState.doseStatuses] before the network call.
  Future<void> logDose({
    required String reminderId,
    required DoseStatus status,
  }) async {
    // Optimistic update
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          doseStatuses: {...current.doseStatuses, reminderId: status},
        ),
      );
    }

    try {
      await _api.post('/adherence/log', {
        'reminder_id': reminderId,
        'status': status.name,
      });
    } catch (e, st) {
      // Revert optimistic update on failure
      if (current != null) {
        state = AsyncValue.data(current);
      }
      Error.throwWithStackTrace(e, st);
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

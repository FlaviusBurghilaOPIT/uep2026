import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_service.dart';

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
}

final todayAgendaNotifierProvider =
    AsyncNotifierProvider<TodayAgendaNotifier, AgendaState>(
  TodayAgendaNotifier.new,
);

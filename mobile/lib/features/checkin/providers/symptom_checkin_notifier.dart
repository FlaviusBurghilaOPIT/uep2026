import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// State: [AsyncValue<bool>] — idle/loading/success/error.
class SymptomCheckinNotifier extends AsyncNotifier<bool> {
  @override
  bool build() => false;

  ApiService get _api => ref.read(apiServiceProvider);

  /// `POST /symptoms/checkin?case_id=&feeling=` — the canonical backend
  /// route (`backend/app/routers/checkins.py`, `/symptoms` prefix). [feeling]
  /// must be one of the `CheckInFeeling` enum values the mood picker already
  /// sends (`great` / `ok` / `not_great` / `bad`); query params, no JSON
  /// body — the endpoint declares no request-body model.
  ///
  /// Resolves [AsyncData(true)] on success, [AsyncError] on failure.
  Future<void> submit({required String caseId, required String feeling}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await _api.post(
        '/symptoms/checkin'
        '?case_id=${Uri.encodeQueryComponent(caseId)}'
        '&feeling=${Uri.encodeQueryComponent(feeling)}',
        const {},
      );
      if (res.statusCode == 200) {
        return true;
      }
      throw Exception('Check-in failed (${res.statusCode})');
    });
  }
}

final symptomCheckinNotifierProvider =
    AsyncNotifierProvider<SymptomCheckinNotifier, bool>(
      SymptomCheckinNotifier.new,
    );

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

  /// POST /checkins with {case_id, severity, notes, checked_in_at}.
  /// Resolves [AsyncData(true)] on success, [AsyncError] on failure.
  Future<void> submit({
    required String caseId,
    required String severity,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await _api.post('/checkins', {
        'case_id': caseId,
        'severity': severity,
        // ignore: use_null_aware_elements
        if (notes != null) 'notes': notes,
        'checked_in_at': DateTime.now().toIso8601String(),
      });
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

import 'package:http/http.dart' as http;

import '../entities/agenda_entities.dart';

/// Today repository interface — the test seam for the today feature (WI 05 /
/// spec R16). Abstracts the remote agenda/adherence API calls and local
/// cache/queue persistence.
abstract class TodayRepository {
  // --- Remote (agenda + adherence) ---

  /// `GET /patients/me/agenda?date=<YYYY-MM-DD>`
  Future<http.Response> fetchAgenda({required String date});

  /// `POST /adherence/log?scheduled_reminder_id=&status=`
  Future<http.Response> logDose({
    required String scheduledReminderId,
    required String status,
  });

  /// `POST /adherence/log-adhoc`
  Future<http.Response> logAdhocDose({
    required String medicationId,
    required String status,
    String? takenAt,
    required String idempotencyKey,
  });

  /// `PATCH /adherence/logs/{logId}`
  Future<http.Response> correctDoseLog({
    required String logId,
    required String status,
  });

  /// `GET /patients/{patientId}/case`
  Future<http.Response> fetchCase(String patientId);

  /// `GET /cases/{caseId}/emergency-contact`
  Future<http.Response> fetchEmergencyContact(String caseId);

  // --- Local (cache + offline queue) ---

  /// Reads the cached agenda body and timestamp.
  Future<({String? body, DateTime? time})> readCache();

  /// Persists the agenda body and timestamp.
  Future<void> writeCache(String body, DateTime time);

  /// Reads the persisted offline queue.
  Future<List<OfflineQueueEntry>> readOfflineQueue();

  /// Persists the offline queue.
  Future<void> writeOfflineQueue(List<OfflineQueueEntry> queue);
}

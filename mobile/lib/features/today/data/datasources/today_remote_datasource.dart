import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';

/// Remote datasource for today/agenda operations — wraps [ApiService] calls.
class TodayRemoteDatasource {
  final ApiService _api;

  TodayRemoteDatasource(this._api);

  Future<http.Response> fetchAgenda({required String date}) =>
      _api.getPatientAgenda(date: date);

  Future<http.Response> logDose({
    required String scheduledReminderId,
    required String status,
  }) => _api.logAdherence(
    scheduledReminderId: scheduledReminderId,
    status: status,
  );

  Future<http.Response> logAdhocDose({
    required String medicationId,
    required String status,
    String? takenAt,
    required String idempotencyKey,
  }) => _api.logAdhocAdherence(
    medicationId: medicationId,
    status: status,
    takenAt: takenAt,
    idempotencyKey: idempotencyKey,
  );

  Future<http.Response> correctDoseLog({
    required String logId,
    required String status,
  }) => _api.correctAdherenceLog(logId: logId, status: status);

  Future<http.Response> fetchCase(String patientId) =>
      _api.get('/patients/$patientId/case');

  Future<http.Response> fetchEmergencyContact(String caseId) =>
      _api.get('/cases/$caseId/emergency-contact');
}

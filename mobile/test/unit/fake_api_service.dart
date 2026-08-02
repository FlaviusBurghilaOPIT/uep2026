import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';

class FakeApiService implements ApiService {
  final Map<
    String,
    FutureOr<http.Response> Function(Map<String, dynamic>? body)
  >
  postHandlers = {};
  final Map<String, FutureOr<http.Response> Function()> getHandlers = {};

  /// WI 11 adherence-pipeline fakes. Handlers may throw to simulate a
  /// network failure (notifier treats a throw as offline).
  FutureOr<http.Response> Function(String date)? agendaHandler;
  FutureOr<http.Response> Function(String scheduledReminderId, String status)?
  adherenceLogHandler;
  FutureOr<http.Response> Function(Map<String, dynamic> body)? adhocLogHandler;
  FutureOr<http.Response> Function(String logId, Map<String, dynamic> body)?
  correctionHandler;

  /// WI 05 recovery fakes. Handlers may throw to simulate a network failure.
  FutureOr<http.Response> Function(String patientId)? caseHandler;
  FutureOr<http.Response> Function(String caseId)? recommendationsHandler;

  String? savedToken;
  final List<Map<String, dynamic>> requestsLog = [];

  /// Requests matching [pathPrefix] (and optionally [method]).
  List<Map<String, dynamic>> requestsTo(String pathPrefix, {String? method}) {
    return requestsLog
        .where(
          (r) =>
              (r['path'] as String).startsWith(pathPrefix) &&
              (method == null || r['method'] == method),
        )
        .toList();
  }

  @override
  Future<String?> getToken() async => savedToken;

  @override
  Future<void> setToken(String token) async {
    savedToken = token;
  }

  @override
  Future<void> clearToken() async {
    savedToken = null;
  }

  @override
  Future<http.Response> get(String path) async {
    requestsLog.add({'method': 'GET', 'path': path});
    if (getHandlers.containsKey(path)) {
      return await getHandlers[path]!();
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    requestsLog.add({'method': 'POST', 'path': path, 'body': body});
    if (postHandlers.containsKey(path)) {
      return await postHandlers[path]!(body);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> getPatientAgenda({required String date}) async {
    requestsLog.add({
      'method': 'GET',
      'path': '/patients/me/agenda?date=$date',
    });
    final handler = agendaHandler;
    if (handler != null) {
      return await handler(date);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> logAdherence({
    required String scheduledReminderId,
    required String status,
  }) async {
    requestsLog.add({
      'method': 'POST',
      'path':
          '/adherence/log?scheduled_reminder_id=$scheduledReminderId&status=$status',
    });
    final handler = adherenceLogHandler;
    if (handler != null) {
      return await handler(scheduledReminderId, status);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> logAdhocAdherence({
    required String medicationId,
    required String status,
    String? takenAt,
    required String idempotencyKey,
  }) async {
    final body = {
      'medication_id': medicationId,
      'status': status,
      'taken_at': takenAt,
      'idempotency_key': idempotencyKey,
    };
    requestsLog.add({
      'method': 'POST',
      'path': '/adherence/log-adhoc',
      'body': body,
    });
    final handler = adhocLogHandler;
    if (handler != null) {
      return await handler(body);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> correctAdherenceLog({
    required String logId,
    required String status,
  }) async {
    final body = {'status': status};
    requestsLog.add({
      'method': 'PATCH',
      'path': '/adherence/logs/$logId',
      'body': body,
    });
    final handler = correctionHandler;
    if (handler != null) {
      return await handler(logId, body);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> getPatientCase({required String patientId}) async {
    requestsLog.add({'method': 'GET', 'path': '/patients/$patientId/case'});
    final handler = caseHandler;
    if (handler != null) {
      return await handler(patientId);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> getCaseRecommendations({required String caseId}) async {
    requestsLog.add({'method': 'GET', 'path': '/cases/$caseId/recommendations'});
    final handler = recommendationsHandler;
    if (handler != null) {
      return await handler(caseId);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }
}

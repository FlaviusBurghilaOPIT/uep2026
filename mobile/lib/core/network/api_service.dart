import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

// ---------------------------------------------------------------------------
// Abstract interface — lets FakeApiService replace the real one in tests.
// ---------------------------------------------------------------------------

abstract class ApiService {
  Future<http.Response> get(String path);
  Future<http.Response> post(String path, Map<String, dynamic> body);
  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<void> clearToken();

  /// E2 · `GET /patients/me/agenda?date=<YYYY-MM-DD>` (backend spec §6).
  Future<http.Response> getPatientAgenda({required String date});

  /// E1 · `POST /adherence/log?scheduled_reminder_id=&status=` — the ONLY
  /// create path for scheduled dose logs. 201 on create; 409 with the
  /// existing-log detail body when already logged (callers reconcile).
  Future<http.Response> logAdherence({
    required String scheduledReminderId,
    required String status,
  });

  /// E1 · `POST /adherence/log-adhoc` — PRN logging. [idempotencyKey] is a
  /// client UUID per user action; retries MUST reuse the same key.
  Future<http.Response> logAdhocAdherence({
    required String medicationId,
    required String status,
    String? takenAt,
    required String idempotencyKey,
  });

  /// E1 · `PATCH /adherence/logs/{logId}` — correction.
  Future<http.Response> correctAdherenceLog({
    required String logId,
    required String status,
  });

  /// WI 05 · `GET /patients/{patientId}/case` — the patient's case
  /// (surgery type/date) for the Recovery screen.
  Future<http.Response> getPatientCase({required String patientId});

  /// WI 05 · `GET /cases/{caseId}/recommendations` — free-text care
  /// instructions for the Recovery screen.
  Future<http.Response> getCaseRecommendations({required String caseId});

  /// WI 06 · `PATCH /auth/me` — partial profile update; only non-null
  /// fields are sent so the backend preserves omitted values.
  Future<http.Response> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
  });

  /// WI 06 · `POST /auth/change-password` — [currentPassword] is required
  /// only when the user already has a password (`has_password` on /auth/me).
  Future<http.Response> changePassword({
    required String newPassword,
    String? currentPassword,
  });
}

// ---------------------------------------------------------------------------
// Concrete HTTP implementation (production).
// ---------------------------------------------------------------------------

class HttpApiService implements ApiService {
  static String get _baseUrl => AppConfig.baseUrl;

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Uri _buildUri(String path) {
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  @override
  Future<http.Response> get(String path) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http
        .get(_buildUri(path), headers: headers)
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http
        .post(
          _buildUri(path),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http
        .patch(
          _buildUri(path),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<http.Response> getPatientAgenda({required String date}) {
    return get('/patients/me/agenda?date=$date');
  }

  @override
  Future<http.Response> logAdherence({
    required String scheduledReminderId,
    required String status,
  }) {
    return post(
      '/adherence/log?scheduled_reminder_id=${Uri.encodeQueryComponent(scheduledReminderId)}&status=${Uri.encodeQueryComponent(status)}',
      const {},
    );
  }

  @override
  Future<http.Response> logAdhocAdherence({
    required String medicationId,
    required String status,
    String? takenAt,
    required String idempotencyKey,
  }) {
    return post('/adherence/log-adhoc', {
      'medication_id': medicationId,
      'status': status,
      'taken_at': takenAt,
      'idempotency_key': idempotencyKey,
    });
  }

  @override
  Future<http.Response> correctAdherenceLog({
    required String logId,
    required String status,
  }) {
    return _patch('/adherence/logs/$logId', {'status': status});
  }

  @override
  Future<http.Response> getPatientCase({required String patientId}) {
    return get('/patients/$patientId/case');
  }

  @override
  Future<http.Response> getCaseRecommendations({required String caseId}) {
    return get('/cases/$caseId/recommendations');
  }

  @override
  Future<http.Response> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
  }) {
    final body = <String, dynamic>{
      'full_name': ?fullName,
      'phone': ?phone,
      'date_of_birth': ?dateOfBirth,
    };
    return _patch('/auth/me', body);
  }

  @override
  Future<http.Response> changePassword({
    required String newPassword,
    String? currentPassword,
  }) {
    return post('/auth/change-password', {
      'new_password': newPassword,
      'current_password': ?currentPassword,
    });
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider — overridable in tests via ProviderScope overrides.
// ---------------------------------------------------------------------------

final apiServiceProvider = Provider<ApiService>((ref) => HttpApiService());

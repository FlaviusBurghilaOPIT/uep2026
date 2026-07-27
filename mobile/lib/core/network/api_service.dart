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

  @override
  Future<http.Response> get(String path) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.get(Uri.parse('$_baseUrl$path'), headers: headers);
  }

  @override
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
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
}

// ---------------------------------------------------------------------------
// Riverpod provider — overridable in tests via ProviderScope overrides.
// ---------------------------------------------------------------------------

final apiServiceProvider = Provider<ApiService>((ref) => HttpApiService());

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Abstract interface — lets FakeApiService replace the real one in tests.
// ---------------------------------------------------------------------------

abstract class ApiService {
  Future<http.Response> get(String path);
  Future<http.Response> post(String path, Map<String, dynamic> body);
  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<void> clearToken();
}

// ---------------------------------------------------------------------------
// Concrete HTTP implementation (production).
// ---------------------------------------------------------------------------

class HttpApiService implements ApiService {
  static String get _baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

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
}

// ---------------------------------------------------------------------------
// Riverpod provider — overridable in tests via ProviderScope overrides.
// ---------------------------------------------------------------------------

final apiServiceProvider = Provider<ApiService>((ref) => HttpApiService());

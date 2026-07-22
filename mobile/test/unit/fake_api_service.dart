import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';

class FakeApiService implements ApiService {
  final Map<String, http.Response Function(Map<String, dynamic>? body)> postHandlers = {};
  final Map<String, http.Response Function()> getHandlers = {};

  String? savedToken;
  final List<Map<String, dynamic>> requestsLog = [];

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
      return getHandlers[path]!();
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }

  @override
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    requestsLog.add({'method': 'POST', 'path': path, 'body': body});
    if (postHandlers.containsKey(path)) {
      return postHandlers[path]!(body);
    }
    return http.Response(jsonEncode({'detail': 'Not found'}), 404);
  }
}

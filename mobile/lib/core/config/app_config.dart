import 'dart:io';
import 'package:flutter/foundation.dart';

/// Application configuration and environment variables injection.
class AppConfig {
  AppConfig._();

  /// Pass at compile/run time via `--dart-define=API_BASE_URL=https://your-api.com`
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Resolves API Base URL dynamically:
  /// 1. Use [API_BASE_URL] if passed via `--dart-define`.
  /// 2. Use `10.0.2.2:8000` on Android emulator (host loopback alias).
  /// 3. Use `localhost:8000` on iOS simulator / Web.
  static String get baseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    if (kIsWeb || (!kIsWeb && Platform.isMacOS)) {
      return 'http://localhost:8000';
    }
    return 'http://192.168.86.227:8000';
  }
}

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
    String url;
    if (_envApiBaseUrl.isNotEmpty) {
      url = _envApiBaseUrl.trim();
    } else if (kReleaseMode) {
      throw StateError(
        'CRITICAL: API_BASE_URL must be provided via --dart-define=API_BASE_URL=https://... in release builds.',
      );
    } else if (!kIsWeb && Platform.isAndroid) {
      url = 'http://10.0.2.2:8000';
    } else {
      url = 'http://localhost:8000';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}

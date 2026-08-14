import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/auth_state.dart';

/// Local datasource for demo-auth prefs — wraps [SharedPreferences] keys
/// `isFirstTime`, `hasActiveSession`, `email` (spec R13).
class AuthLocalDatasource {
  final SharedPreferences _prefs;

  AuthLocalDatasource(this._prefs);

  DemoAuthState load() {
    return DemoAuthState(
      isFirstTime: _prefs.getBool('isFirstTime') ?? true,
      hasActiveSession: _prefs.getBool('hasActiveSession') ?? false,
      email: _prefs.getString('email'),
    );
  }

  Future<void> save({
    required bool isFirstTime,
    required bool hasActiveSession,
    String? email,
  }) async {
    await _prefs.setBool('isFirstTime', isFirstTime);
    await _prefs.setBool('hasActiveSession', hasActiveSession);
    if (email != null) {
      await _prefs.setString('email', email);
    }
  }

  Future<void> setEmail(String email) async {
    await _prefs.setString('email', email);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}

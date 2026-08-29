import 'dart:convert';

import '../../../../core/network/api_service.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

/// Remote datasource for auth operations — wraps [ApiService] calls to the
/// backend auth endpoints.
class AuthRemoteDatasource {
  final ApiService _api;

  AuthRemoteDatasource(this._api);

  /// `GET /auth/me`
  Future<AuthState?> fetchProfile() async {
    final res = await _api.get('/auth/me');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return AuthState(
        patientId: data['id'] as String?,
        email: data['email'] as String?,
        fullName: data['full_name'] as String?,
        phone: data['phone'] as String?,
        dateOfBirth: data['date_of_birth'] as String?,
        hasPassword: data['has_password'] as bool? ?? false,
        physicianName: data['physician_name'] as String? ??
            data['doctor_name'] as String? ??
            data['assigned_clinician'] as String?,
        isSignedIn: true,
      );
    }
    if (res.statusCode == 401) {
      return null;
    }
    return null;
  }

  /// `PATCH /auth/me` (WI 06) — partial profile update; only non-null
  /// fields are sent so the backend preserves omitted values.
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
  }) async {
    try {
      final res = await _api.updateProfile(
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// `POST /auth/change-password` (WI 06) — returns `null` on success or
  /// the backend `detail` message on failure (e.g. "Current password is
  /// incorrect") so callers can surface honest feedback.
  Future<String?> changePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    try {
      final res = await _api.changePassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      );
      if (res.statusCode == 200) return null;
      final data = jsonDecode(res.body);
      return data['detail'] as String? ?? 'Password change failed';
    } catch (_) {
      return 'Network error';
    }
  }

  /// `GET /patients/{patientId}/case`
  Future<({String? caseId, String? primaryCondition, String? physicianName})> fetchCase(
    String patientId,
  ) async {
    try {
      final res = await _api.get('/patients/$patientId/case');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (
          caseId: data['id'] as String?,
          primaryCondition: data['surgery_type'] as String?,
          physicianName: data['physician_name'] as String? ??
              data['doctor_name'] as String? ??
              data['assigned_clinician'] as String?,
        );
      }
    } catch (_) {}
    return (caseId: null, primaryCondition: null, physicianName: null);
  }

  /// `POST /auth/login` (email + password) — hybrid auth returning-login.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['access_token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// `POST /auth/patient/request-code`
  Future<bool> requestCode({required String email}) async {
    final res = await _api.post('/auth/patient/request-code', {'email': email});
    return res.statusCode == 200;
  }

  /// `POST /auth/patient/verify-code`
  Future<VerifyCodeResult?> verifyCode({
    required String email,
    required String code,
  }) async {
    final res = await _api.post('/auth/patient/verify-code', {
      'email': email,
      'code': code,
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return VerifyCodeResult(
        result: data['result'] as String,
        accessToken: data['access_token'] as String?,
        email: data['email'] as String?,
        fullName: data['full_name'] as String?,
        dateOfBirth: data['date_of_birth'] as String?,
      );
    }
    return null;
  }

  /// `POST /auth/complete-onboarding` — hybrid auth: [password] is hashed
  /// server-side when present; [dateOfBirth] is sent only when supplied so
  /// the backend preserves the intake value otherwise.
  Future<String?> completeOnboarding({
    required String email,
    required String inviteCode,
    String? dateOfBirth,
    String? fullName,
    required String phone,
    String? password,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'invite_code': inviteCode,
      'phone': phone,
    };
    // Optional fields are omitted (not sent as null) so the backend preserves
    // the intake values (DOB, name) and only hashes a password when one is
    // actually provided.
    if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
    if (fullName != null) body['full_name'] = fullName;
    if (password != null) body['password'] = password;
    final res = await _api.post('/auth/complete-onboarding', body);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['access_token'] as String?;
    }
    return null;
  }

  Future<String?> getToken() => _api.getToken();
  Future<void> setToken(String token) => _api.setToken(token);
  Future<void> clearToken() => _api.clearToken();
}

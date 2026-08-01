import '../entities/auth_state.dart';

/// Result of a verify-code call.
class VerifyCodeResult {
  /// `'authenticated'` or `'onboarding'`.
  final String result;
  final String? accessToken;
  final String? email;
  final String? fullName;

  /// Pre-set date of birth surfaced by the backend so onboarding can
  /// pre-fill it (editable). Optional: the backend may omit it.
  final String? dateOfBirth;

  const VerifyCodeResult({
    required this.result,
    this.accessToken,
    this.email,
    this.fullName,
    this.dateOfBirth,
  });
}

/// Auth repository interface — the test seam for the auth feature (WI 04 /
/// spec R16). Implemented in `data/` over a remote datasource (ApiService)
/// and a local datasource (SharedPreferences).
abstract class AuthRepository {
  // --- Remote (ApiService) ---

  /// `GET /auth/me` — returns the authenticated user's profile, or `null`
  /// on failure.
  Future<AuthState?> fetchProfile();

  /// `GET /patients/{patientId}/case` — returns case info to merge into
  /// [AuthState], or `null` on failure.
  Future<({String? caseId, String? primaryCondition})> fetchCase(
    String patientId,
  );

  /// `POST /auth/login` (email + password) — returns the access token on
  /// success, or `null` on failure (e.g. 401 invalid credentials).
  Future<String?> login({required String email, required String password});

  /// `POST /auth/patient/request-code` — returns `true` on success.
  Future<bool> requestCode({required String email});

  /// `POST /auth/patient/verify-code` — returns the parsed result, or
  /// `null` on failure.
  Future<VerifyCodeResult?> verifyCode({
    required String email,
    required String code,
  });

  /// `POST /auth/complete-onboarding` — returns the access token on
  /// success, or `null` on failure. [password] is optional (hybrid auth):
  /// when present the backend hashes it to `password_hash`; [dateOfBirth] and
  /// [fullName] are optional and only update the stored values when supplied
  /// (otherwise the intake values are preserved).
  Future<String?> completeOnboarding({
    required String email,
    required String inviteCode,
    String? dateOfBirth,
    String? fullName,
    required String phone,
    String? password,
  });

  // --- Token management ---

  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<void> clearToken();

  // --- Local (SharedPreferences) ---

  /// Loads the demo-auth prefs snapshot.
  Future<DemoAuthState> loadDemoAuth();

  /// Persists demo-auth prefs.
  Future<void> saveDemoAuth({
    required bool isFirstTime,
    required bool hasActiveSession,
    String? email,
  });

  /// Clears all demo-auth prefs.
  Future<void> clearDemoAuth();
}

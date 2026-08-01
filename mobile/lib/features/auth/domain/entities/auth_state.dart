import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

/// Immutable snapshot of the authenticated user's profile and session state.
///
/// Exposed by [AuthNotifier] and watched by screens across the app.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isSignedIn,
    @Default(false) bool isLoading,

    /// True until the boot-time JWT check ([AuthNotifier.checkAuthStatus])
    /// finishes. Boot routing waits for this to flip false before deciding
    /// main vs Welcome, so a stored-but-invalid token is never routed around.
    @Default(true) bool isInitializing,
    String? errorMessage,
    String? patientId,
    String? caseId,
    String? fullName,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? primaryCondition,
    String? inviteCode,
  }) = _AuthState;

  factory AuthState.fromJson(Map<String, dynamic> json) =>
      _$AuthStateFromJson(json);
}

/// Prefs-only demo auth state (first-run / OTP flow).
///
/// Persisted keys preserved per spec R13: `isFirstTime`, `hasActiveSession`,
/// `email`.
class DemoAuthState {
  final bool isFirstTime;
  final bool hasActiveSession;
  final String? email;

  DemoAuthState({
    required this.isFirstTime,
    required this.hasActiveSession,
    this.email,
  });
}

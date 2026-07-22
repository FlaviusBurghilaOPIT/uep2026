import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_service.dart';

part 'auth_notifier.freezed.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({
    required String userId,
    required String caseId,
    required String fullName,
    required String email,
    required String surgeryType,
  }) = _Authenticated;
  const factory AuthState.onboarding({
    required String email,
    required String fullName,
    required String surgeryType,
  }) = _Onboarding;
  const factory AuthState.error(String message) = _Error;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthStateNotifier extends AsyncNotifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();

  ApiService get _api => ref.read(apiServiceProvider);

  /// POST /auth/verify-invite
  /// Transitions to [AuthState.onboarding] on HTTP 200, [AuthState.error] on non-200.
  Future<void> verifyInvite(String email, String inviteCode) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/auth/verify-invite', {
        'email': email,
        'invite_code': inviteCode,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        state = AsyncValue.data(
          AuthState.onboarding(
            email: data['email'] as String? ?? email,
            fullName: data['full_name'] as String? ?? '',
            surgeryType: data['surgery_type'] as String? ?? '',
          ),
        );
      } else {
        final err = _parseError(res.body, 'Invalid invite code');
        state = AsyncValue.data(AuthState.error(err));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// POST /auth/complete-onboarding
  /// Saves JWT via [ApiService.setToken] and transitions to [AuthState.authenticated].
  Future<void> completeOnboarding({
    required String email,
    required String inviteCode,
    required String password,
    required String dateOfBirth,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/auth/complete-onboarding', {
        'email': email,
        'invite_code': inviteCode,
        'password': password,
        'date_of_birth': dateOfBirth,
        'phone': phone,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _api.setToken(data['access_token'] as String);
        state = AsyncValue.data(await _fetchAuthenticated());
      } else {
        final err = _parseError(res.body, 'Onboarding failed');
        state = AsyncValue.data(AuthState.error(err));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// POST /auth/login → GET /auth/me → GET /patients/{id}/case
  /// Transitions to [AuthState.authenticated].
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _api.setToken(data['access_token'] as String);
        state = AsyncValue.data(await _fetchAuthenticated());
      } else {
        final err = _parseError(res.body, 'Sign in failed');
        state = AsyncValue.data(AuthState.error(err));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clears token and returns to [AuthState.initial].
  Future<void> signOut() async {
    await _api.clearToken();
    state = const AsyncValue.data(AuthState.initial());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<AuthState> _fetchAuthenticated() async {
    final meRes = await _api.get('/auth/me');
    if (meRes.statusCode != 200) {
      return AuthState.error(_parseError(meRes.body, 'Failed to load profile'));
    }
    final me = jsonDecode(meRes.body) as Map<String, dynamic>;
    final userId = me['id'] as String;

    final caseRes = await _api.get('/patients/$userId/case');
    if (caseRes.statusCode != 200) {
      return AuthState.error(
        _parseError(caseRes.body, 'Failed to load case'),
      );
    }
    final caseData = jsonDecode(caseRes.body) as Map<String, dynamic>;

    return AuthState.authenticated(
      userId: userId,
      caseId: caseData['id'] as String,
      fullName: me['full_name'] as String? ?? '',
      email: me['email'] as String? ?? '',
      surgeryType: caseData['surgery_type'] as String? ?? '',
    );
  }

  String _parseError(String body, String fallback) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['detail'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);

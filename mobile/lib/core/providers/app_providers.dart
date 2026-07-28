import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/api_service.dart';

part 'app_providers.freezed.dart';
part 'app_providers.g.dart';

// ---------------------------------------------------------------------------
// Auth state — immutable snapshot exposed by [AuthNotifier].
// ---------------------------------------------------------------------------

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isSignedIn,
    @Default(false) bool isLoading,
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
}

// ---------------------------------------------------------------------------
// Auth notifier — preserves the existing public method/behavior API
// (checkAuthStatus, fetchProfile, requestCode, verifyCode,
// completeOnboarding, setSignUpInfo, signOut). Screens read state through
// `ref.watch(authProvider)` and invoke methods through
// `ref.read(authProvider.notifier)`.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class AuthNotifier extends Notifier<AuthState> {
  ApiService get _api => ref.read(apiServiceProvider);

  @override
  AuthState build() {
    // Mirrors the old constructor side-effect: kick off a session check as
    // soon as the provider is created (fire-and-forget).
    checkAuthStatus();
    return const AuthState();
  }

  Future<void> checkAuthStatus() async {
    final token = await _api.getToken();
    if (token != null && token.isNotEmpty) {
      final success = await fetchProfile();
      if (!success) {
        await _api.clearToken();
        state = state.copyWith(isSignedIn: false);
      }
    }
  }

  Future<bool> fetchProfile() async {
    try {
      final res = await _api.get('/auth/me');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final patientId = data['id'] as String?;
        var next = state.copyWith(
          patientId: patientId,
          email: data['email'] as String?,
          fullName: data['full_name'] as String?,
          phone: data['phone'] as String?,
          dateOfBirth: data['date_of_birth'] as String?,
          isSignedIn: true,
        );

        if (patientId != null) {
          final caseRes = await _api.get('/patients/$patientId/case');
          if (caseRes.statusCode == 200) {
            final caseData = jsonDecode(caseRes.body);
            next = next.copyWith(
              caseId: caseData['id'] as String?,
              primaryCondition: caseData['surgery_type'] as String?,
            );
          }
        }
        state = next;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> requestCode({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.post('/auth/patient/request-code', {
        'email': email,
      });
      if (res.statusCode == 200) {
        state = state.copyWith(email: email);
        return true;
      } else {
        final err = jsonDecode(res.body);
        state = state.copyWith(
          errorMessage: (err['detail'] as String?) ?? 'Failed to send code',
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  /// Returns 'onboarding', 'authenticated', or null on failure (see
  /// [AuthState.errorMessage]).
  Future<String?> verifyCode({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.post('/auth/patient/verify-code', {
        'email': email,
        'code': code,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['result'] as String;
        if (result == 'authenticated') {
          final token = data['access_token'];
          await _api.setToken(token);
          await fetchProfile();
        } else {
          state = state.copyWith(
            email: data['email'] as String?,
            fullName: data['full_name'] as String?,
            inviteCode: code,
          );
        }
        return result;
      } else {
        final err = jsonDecode(res.body);
        state = state.copyWith(
          errorMessage: (err['detail'] as String?) ?? 'Invalid or expired code',
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return null;
  }

  Future<bool> completeOnboarding({
    required String email,
    required String inviteCode,
    required String dateOfBirth,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.post('/auth/complete-onboarding', {
        'email': email,
        'invite_code': inviteCode,
        'date_of_birth': dateOfBirth,
        'phone': phone,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['access_token'];
        await _api.setToken(token);
        await fetchProfile();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final err = jsonDecode(res.body);
        state = state.copyWith(
          errorMessage:
              (err['detail'] as String?) ?? 'Failed to complete onboarding',
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  void setSignUpInfo({
    required String fullName,
    required String email,
    required String phone,
  }) {
    state = state.copyWith(fullName: fullName, email: email, phone: phone);
  }

  Future<void> signOut() async {
    await _api.clearToken();
    state = const AuthState();
  }
}

// ---------------------------------------------------------------------------
// Navigation state — tracks the selected bottom-nav tab.
// ---------------------------------------------------------------------------

@freezed
abstract class NavigationState with _$NavigationState {
  const factory NavigationState({@Default(0) int currentIndex}) =
      _NavigationState;
}

@Riverpod(keepAlive: true)
class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() => const NavigationState();

  int get currentIndex => state.currentIndex;

  void setTab(int index, {bool notify = true}) {
    if (index < 0 || index > 4 || state.currentIndex == index) return;
    state = NavigationState(currentIndex: index);
  }
}

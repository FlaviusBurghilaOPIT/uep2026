import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

/// Repository provider — overridable in tests via [AuthRepository] mock.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final api = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepositoryImpl(
    remote: AuthRemoteDatasource(api),
    local: AuthLocalDatasource(prefs),
  );
}

/// Remote auth notifier — preserves the existing public method/behavior API
/// (checkAuthStatus, fetchProfile, requestCode, verifyCode,
/// completeOnboarding, setSignUpInfo, signOut). Screens read state through
/// `ref.watch(authProvider)` and invoke methods through
/// `ref.read(authProvider.notifier)`.
@Riverpod(keepAlive: true)
class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    checkAuthStatus();
    return const AuthState();
  }

  /// Boot-time JWT check: a stored token is validated against `GET /auth/me`.
  /// Valid -> [AuthState.isSignedIn] true; absent/invalid (401) -> token
  /// cleared and signed-out. Always clears [AuthState.isInitializing] so boot
  /// routing can decide main vs Welcome on the REAL JWT (not demo prefs).
  Future<void> checkAuthStatus() async {
    try {
      final token = await _repo.getToken();
      if (token != null && token.isNotEmpty) {
        final success = await fetchProfile();
        if (!success) {
          await _repo.clearToken();
          state = state.copyWith(isSignedIn: false);
        }
      }
    } finally {
      state = state.copyWith(isInitializing: false);
    }
  }

  /// Hybrid auth returning-login: `POST /auth/login` (email + password).
  /// On success stores the JWT, loads the profile, and returns true.
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _repo.login(email: email, password: password);
      if (token != null) {
        await _repo.setToken(token);
        await fetchProfile();
        return state.isSignedIn;
      } else {
        state = state.copyWith(errorMessage: 'Invalid email or password');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  Future<bool> fetchProfile() async {
    try {
      final profile = await _repo.fetchProfile();
      if (profile != null) {
        var next = state.copyWith(
          patientId: profile.patientId,
          email: profile.email,
          fullName: profile.fullName,
          phone: profile.phone,
          dateOfBirth: profile.dateOfBirth,
          isSignedIn: true,
        );

        if (profile.patientId != null) {
          final caseInfo = await _repo.fetchCase(profile.patientId!);
          next = next.copyWith(
            caseId: caseInfo.caseId,
            primaryCondition: caseInfo.primaryCondition,
          );
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
      final success = await _repo.requestCode(email: email);
      if (success) {
        state = state.copyWith(email: email);
        return true;
      } else {
        state = state.copyWith(errorMessage: 'Failed to send code');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  /// Returns 'onboarding', 'authenticated', or null on failure.
  Future<String?> verifyCode({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repo.verifyCode(email: email, code: code);
      if (result != null) {
        if (result.result == 'authenticated') {
          if (result.accessToken != null) {
            await _repo.setToken(result.accessToken!);
          }
          await fetchProfile();
        } else {
          // First-run onboarding: pre-fill name + DOB from the backend so the
          // patient confirms/edits rather than re-typing clinic-held data.
          state = state.copyWith(
            email: result.email,
            fullName: result.fullName,
            dateOfBirth: result.dateOfBirth,
            inviteCode: code,
          );
        }
        return result.result;
      } else {
        state = state.copyWith(errorMessage: 'Invalid or expired code');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return null;
  }

  /// First-run onboarding completion: `POST /auth/complete-onboarding`.
  /// [password] (hybrid auth) is hashed server-side when present;
  /// [dateOfBirth] and [fullName] are optional and only update the stored
  /// values when given (otherwise the intake values are preserved).
  Future<bool> completeOnboarding({
    required String email,
    required String inviteCode,
    String? dateOfBirth,
    String? fullName,
    required String phone,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _repo.completeOnboarding(
        email: email,
        inviteCode: inviteCode,
        dateOfBirth: dateOfBirth,
        fullName: fullName,
        phone: phone,
        password: password,
      );
      if (token != null) {
        await _repo.setToken(token);
        await fetchProfile();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(errorMessage: 'Failed to complete onboarding');
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
    await _repo.clearToken();
    state = const AuthState();
  }
}

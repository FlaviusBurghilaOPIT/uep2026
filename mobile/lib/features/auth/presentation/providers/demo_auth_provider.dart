import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_provider.dart';

export '../../domain/entities/auth_state.dart' show DemoAuthState;

part 'demo_auth_provider.g.dart';

/// Prefs-only demo auth flow (first-run / OTP). Persisted keys preserved per
/// spec R13: `isFirstTime`, `hasActiveSession`, `email`.
@Riverpod(keepAlive: true)
class DemoAuthNotifier extends AsyncNotifier<DemoAuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<DemoAuthState> build() async {
    return _repo.loadDemoAuth();
  }

  Future<void> completeProfileSetup(String email) async {
    await _repo.saveDemoAuth(
      isFirstTime: false,
      hasActiveSession: true,
      email: email,
    );
    state = AsyncValue.data(
      DemoAuthState(isFirstTime: false, hasActiveSession: true, email: email),
    );
  }

  Future<void> triggerOtp(String email) async {
    await _repo.saveDemoAuth(
      isFirstTime: state.value?.isFirstTime ?? false,
      hasActiveSession: false,
      email: email,
    );
    final currentState = state.value;
    state = AsyncValue.data(
      DemoAuthState(
        isFirstTime: currentState?.isFirstTime ?? false,
        hasActiveSession: false,
        email: email,
      ),
    );
  }

  Future<void> completeOtpLogin() async {
    await _repo.saveDemoAuth(isFirstTime: false, hasActiveSession: true);
    final reloaded = await _repo.loadDemoAuth();
    state = AsyncValue.data(reloaded);
  }

  Future<void> simulateSessionExpiry() async {
    await _repo.saveDemoAuth(isFirstTime: false, hasActiveSession: false);
    final reloaded = await _repo.loadDemoAuth();
    state = AsyncValue.data(reloaded);
  }

  Future<void> resetApp() async {
    await _repo.clearDemoAuth();
    state = AsyncValue.data(
      DemoAuthState(isFirstTime: true, hasActiveSession: false, email: null),
    );
  }
}

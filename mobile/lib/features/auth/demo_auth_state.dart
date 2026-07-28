import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers/shared_preferences_provider.dart';

// Backward-compat re-export: this file historically defined
// `sharedPreferencesProvider`; it now lives in core (spec R8). Existing
// importers (notably tests) still resolve it through this library.
export '../../core/providers/shared_preferences_provider.dart';

part 'demo_auth_state.g.dart';

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

/// Prefs-only demo auth flow (first-run / OTP). Persisted keys preserved per
/// spec R13: `isFirstTime`, `hasActiveSession`, `email`.
@Riverpod(keepAlive: true)
class DemoAuthNotifier extends AsyncNotifier<DemoAuthState> {
  @override
  Future<DemoAuthState> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final hasActiveSession = prefs.getBool('hasActiveSession') ?? false;
    final email = prefs.getString('email');

    return DemoAuthState(
      isFirstTime: isFirstTime,
      hasActiveSession: hasActiveSession,
      email: email,
    );
  }

  Future<void> completeProfileSetup(String email) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('isFirstTime', false);
    await prefs.setBool('hasActiveSession', true);
    await prefs.setString('email', email);

    state = AsyncValue.data(
      DemoAuthState(isFirstTime: false, hasActiveSession: true, email: email),
    );
  }

  Future<void> triggerOtp(String email) async {
    // Mock triggering OTP, just saves email to state so OtpScreen knows it.
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('email', email);
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
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('isFirstTime', false);
    await prefs.setBool('hasActiveSession', true);
    final email = prefs.getString('email');
    state = AsyncValue.data(
      DemoAuthState(isFirstTime: false, hasActiveSession: true, email: email),
    );
  }

  Future<void> simulateSessionExpiry() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasActiveSession', false);
    final email = prefs.getString('email');
    state = AsyncValue.data(
      DemoAuthState(isFirstTime: false, hasActiveSession: false, email: email),
    );
  }

  Future<void> resetApp() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.clear();
    state = AsyncValue.data(
      DemoAuthState(isFirstTime: true, hasActiveSession: false, email: null),
    );
  }
}

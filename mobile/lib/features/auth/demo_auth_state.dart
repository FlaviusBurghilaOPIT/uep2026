import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

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

class DemoAuthNotifier extends StateNotifier<AsyncValue<DemoAuthState>> {
  final Ref _ref;

  DemoAuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      final hasActiveSession = prefs.getBool('hasActiveSession') ?? false;
      final email = prefs.getString('email');
      
      state = AsyncValue.data(DemoAuthState(
        isFirstTime: isFirstTime,
        hasActiveSession: hasActiveSession,
        email: email,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeSignup() async {
    // Legacy method, unused now.
  }

  Future<void> completeProfileSetup(String email) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool('isFirstTime', false);
    await prefs.setBool('hasActiveSession', true);
    await prefs.setString('email', email);
    
    state = AsyncValue.data(DemoAuthState(
      isFirstTime: false,
      hasActiveSession: true,
      email: email,
    ));
  }

  Future<void> triggerOtp(String email) async {
    // Mock triggering OTP, just saves email to state so OtpScreen knows it.
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString('email', email);
    final currentState = state.valueOrNull;
    state = AsyncValue.data(DemoAuthState(
      isFirstTime: currentState?.isFirstTime ?? false,
      hasActiveSession: false,
      email: email,
    ));
  }

  Future<void> completeOtpLogin() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool('isFirstTime', false);
    await prefs.setBool('hasActiveSession', true);
    final email = prefs.getString('email');
    state = AsyncValue.data(DemoAuthState(
      isFirstTime: false,
      hasActiveSession: true,
      email: email,
    ));
  }

  Future<void> simulateSessionExpiry() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasActiveSession', false);
    final email = prefs.getString('email');
    state = AsyncValue.data(DemoAuthState(
      isFirstTime: false,
      hasActiveSession: false,
      email: email,
    ));
  }

  Future<void> resetApp() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.clear();
    state = AsyncValue.data(DemoAuthState(
      isFirstTime: true,
      hasActiveSession: false,
      email: null,
    ));
  }
}

final demoAuthProvider =
    StateNotifierProvider<DemoAuthNotifier, AsyncValue<DemoAuthState>>((ref) {
  return DemoAuthNotifier(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/features/auth/demo_auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoAuthNotifier', () {
    test('initial state when SharedPreferences is empty defaults to first time', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(demoAuthProvider);
      expect(state.value, isNotNull);
      expect(state.value!.isFirstTime, isTrue);
      expect(state.value!.hasActiveSession, isFalse);
      expect(state.value!.email, isNull);
    });

    test('initial state loads values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'isFirstTime': false,
        'hasActiveSession': true,
        'email': 'existing@example.com',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(demoAuthProvider);
      expect(state.value, isNotNull);
      expect(state.value!.isFirstTime, isFalse);
      expect(state.value!.hasActiveSession, isTrue);
      expect(state.value!.email, 'existing@example.com');
    });

    test('completeProfileSetup sets flags and email in state and prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoAuthProvider.notifier);
      await notifier.completeProfileSetup('jane@example.com');

      final state = container.read(demoAuthProvider);
      expect(state.value!.isFirstTime, isFalse);
      expect(state.value!.hasActiveSession, isTrue);
      expect(state.value!.email, 'jane@example.com');

      expect(prefs.getBool('isFirstTime'), isFalse);
      expect(prefs.getBool('hasActiveSession'), isTrue);
      expect(prefs.getString('email'), 'jane@example.com');
    });

    test('triggerOtp saves email and sets active session to false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoAuthProvider.notifier);
      await notifier.triggerOtp('otp@example.com');

      final state = container.read(demoAuthProvider);
      expect(state.value!.hasActiveSession, isFalse);
      expect(state.value!.email, 'otp@example.com');

      expect(prefs.getString('email'), 'otp@example.com');
    });

    test('completeOtpLogin sets isFirstTime=false and hasActiveSession=true in state and prefs', () async {
      SharedPreferences.setMockInitialValues({'email': 'otp@example.com', 'isFirstTime': true});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoAuthProvider.notifier);
      await notifier.completeOtpLogin();

      final state = container.read(demoAuthProvider);
      expect(state.value!.isFirstTime, isFalse);
      expect(state.value!.hasActiveSession, isTrue);
      expect(state.value!.email, 'otp@example.com');

      expect(prefs.getBool('isFirstTime'), isFalse);
      expect(prefs.getBool('hasActiveSession'), isTrue);
    });

    test('resetApp clears SharedPreferences and resets state', () async {
      SharedPreferences.setMockInitialValues({
        'isFirstTime': false,
        'hasActiveSession': true,
        'email': 'active@example.com',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(demoAuthProvider.notifier);
      await notifier.resetApp();

      final state = container.read(demoAuthProvider);
      expect(state.value!.isFirstTime, isTrue);
      expect(state.value!.hasActiveSession, isFalse);
      expect(state.value!.email, isNull);

      expect(prefs.getBool('isFirstTime'), isNull);
      expect(prefs.getBool('hasActiveSession'), isNull);
      expect(prefs.getString('email'), isNull);
    });
  });
}

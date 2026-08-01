import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('requestCode success returns true and stores email', () async {
    fakeApi.postHandlers['/auth/patient/request-code'] = (body) {
      return http.Response(
        jsonEncode({'message': 'If that email exists, a code was sent.'}),
        200,
      );
    };

    final auth = container.read(authProvider.notifier);
    final success = await auth.requestCode(email: 'jane@example.com');

    expect(success, true);
    expect(container.read(authProvider).email, 'jane@example.com');
  });

  test(
    'verifyCode for a new patient returns onboarding and stores profile fields',
    () async {
      fakeApi.postHandlers['/auth/patient/verify-code'] = (body) {
        return http.Response(
          jsonEncode({
            'result': 'onboarding',
            'email': 'jane@example.com',
            'full_name': 'Jane Doe',
          }),
          200,
        );
      };

      final auth = container.read(authProvider.notifier);
      final result = await auth.verifyCode(
        email: 'jane@example.com',
        code: '123456',
      );

      expect(result, 'onboarding');
      final state = container.read(authProvider);
      expect(state.fullName, 'Jane Doe');
      expect(state.inviteCode, '123456');
    },
  );

  test(
    'verifyCode for a returning patient returns authenticated and stores token',
    () async {
      fakeApi.postHandlers['/auth/patient/verify-code'] = (body) {
        return http.Response(
          jsonEncode({'result': 'authenticated', 'access_token': 'jwt_1'}),
          200,
        );
      };
      fakeApi.getHandlers['/auth/me'] = () {
        return http.Response(
          jsonEncode({
            'id': 'user_1',
            'email': 'jane@example.com',
            'full_name': 'Jane Doe',
          }),
          200,
        );
      };
      fakeApi.getHandlers['/patients/user_1/case'] = () {
        return http.Response(
          jsonEncode({'id': 'case_1', 'surgery_type': 'Knee Replacement'}),
          200,
        );
      };

      final auth = container.read(authProvider.notifier);
      final result = await auth.verifyCode(
        email: 'jane@example.com',
        code: '123456',
      );

      expect(result, 'authenticated');
      expect(fakeApi.savedToken, 'jwt_1');
      expect(container.read(authProvider).isSignedIn, true);
    },
  );

  test(
    'verifyCode with wrong code returns null and sets errorMessage',
    () async {
      fakeApi.postHandlers['/auth/patient/verify-code'] = (body) {
        return http.Response(
          jsonEncode({'detail': 'Invalid or expired code'}),
          400,
        );
      };

      final auth = container.read(authProvider.notifier);
      final result = await auth.verifyCode(
        email: 'jane@example.com',
        code: '000000',
      );

      expect(result, null);
      expect(
        container.read(authProvider).errorMessage,
        'Invalid or expired code',
      );
    },
  );

  test(
    'completeOnboarding sends the hybrid-auth password and patient edits',
    () async {
      Map<String, dynamic>? captured;
      fakeApi.postHandlers['/auth/complete-onboarding'] = (body) {
        captured = body;
        return http.Response(jsonEncode({'access_token': 'jwt_2'}), 200);
      };
      fakeApi.getHandlers['/auth/me'] = () {
        return http.Response(
          jsonEncode({
            'id': 'user_2',
            'email': 'jane@example.com',
            'full_name': 'Jane Doe',
          }),
          200,
        );
      };
      fakeApi.getHandlers['/patients/user_2/case'] = () {
        return http.Response(
          jsonEncode({'id': 'case_2', 'surgery_type': 'Knee Replacement'}),
          200,
        );
      };

      final auth = container.read(authProvider.notifier);
      final success = await auth.completeOnboarding(
        email: 'jane@example.com',
        inviteCode: '123456',
        dateOfBirth: '1990-01-01',
        fullName: 'Jane Smith',
        phone: '1234567890',
        password: 'secret123',
      );

      expect(success, true);
      expect(fakeApi.savedToken, 'jwt_2');
      // Hybrid auth: the password is forwarded so the backend can hash it.
      expect(captured?['password'], 'secret123');
      // Patient edits (DOB + name) + patient-provided phone are persisted.
      expect(captured?['date_of_birth'], '1990-01-01');
      expect(captured?['full_name'], 'Jane Smith');
      expect(captured?['phone'], '1234567890');
      expect(captured?['invite_code'], '123456');
    },
  );

  test(
    'completeOnboarding omits date_of_birth when not supplied (preserve intake)',
    () async {
      Map<String, dynamic>? captured;
      fakeApi.postHandlers['/auth/complete-onboarding'] = (body) {
        captured = body;
        return http.Response(jsonEncode({'access_token': 'jwt_3'}), 200);
      };
      fakeApi.getHandlers['/auth/me'] = () => http.Response(
        jsonEncode({'id': 'user_3', 'email': 'jane@example.com'}),
        200,
      );

      final auth = container.read(authProvider.notifier);
      final success = await auth.completeOnboarding(
        email: 'jane@example.com',
        inviteCode: '123456',
        phone: '1234567890',
        password: 'secret123',
      );

      expect(success, true);
      // Unchanged/absent optional fields are omitted so the backend preserves
      // the intake values.
      expect(captured?.containsKey('date_of_birth'), false);
      expect(captured?.containsKey('full_name'), false);
    },
  );

  test('login success stores token, loads profile, and signs in', () async {
    fakeApi.postHandlers['/auth/login'] = (body) {
      expect(body?['email'], 'jane@example.com');
      expect(body?['password'], 'secret123');
      return http.Response(
        jsonEncode({'access_token': 'jwt_login', 'token_type': 'bearer'}),
        200,
      );
    };
    fakeApi.getHandlers['/auth/me'] = () => http.Response(
      jsonEncode({
        'id': 'user_9',
        'email': 'jane@example.com',
        'full_name': 'Jane Doe',
      }),
      200,
    );
    fakeApi.getHandlers['/patients/user_9/case'] = () => http.Response(
      jsonEncode({'id': 'case_9', 'surgery_type': 'Knee Replacement'}),
      200,
    );

    final auth = container.read(authProvider.notifier);
    final success = await auth.login(
      email: 'jane@example.com',
      password: 'secret123',
    );

    expect(success, true);
    expect(fakeApi.savedToken, 'jwt_login');
    expect(container.read(authProvider).isSignedIn, true);
  });

  test('login failure (401) returns false and sets errorMessage', () async {
    fakeApi.postHandlers['/auth/login'] = (body) {
      return http.Response(jsonEncode({'detail': 'Invalid credentials'}), 401);
    };

    final auth = container.read(authProvider.notifier);
    final success = await auth.login(
      email: 'jane@example.com',
      password: 'wrong',
    );

    expect(success, false);
    expect(container.read(authProvider).isSignedIn, false);
    expect(container.read(authProvider).errorMessage, isNotNull);
  });

  test(
    'verifyCode onboarding surfaces the backend date_of_birth for pre-fill',
    () async {
      fakeApi.postHandlers['/auth/patient/verify-code'] = (body) {
        return http.Response(
          jsonEncode({
            'result': 'onboarding',
            'email': 'jane@example.com',
            'full_name': 'Jane Doe',
            'date_of_birth': '1988-03-14',
          }),
          200,
        );
      };

      final auth = container.read(authProvider.notifier);
      final result = await auth.verifyCode(
        email: 'jane@example.com',
        code: '123456',
      );

      expect(result, 'onboarding');
      expect(container.read(authProvider).dateOfBirth, '1988-03-14');
      expect(container.read(authProvider).fullName, 'Jane Doe');
    },
  );

  test(
    'checkAuthStatus with a valid stored token signs in and clears initializing',
    () async {
      fakeApi.savedToken = 'jwt_stored';
      fakeApi.getHandlers['/auth/me'] = () => http.Response(
        jsonEncode({'id': 'user_5', 'email': 'jane@example.com'}),
        200,
      );

      final auth = container.read(authProvider.notifier);
      await auth.checkAuthStatus();

      final state = container.read(authProvider);
      expect(state.isInitializing, false);
      expect(state.isSignedIn, true);
    },
  );

  test(
    'checkAuthStatus with an invalid stored token (401) clears it and signs out',
    () async {
      fakeApi.savedToken = 'jwt_expired';
      fakeApi.getHandlers['/auth/me'] = () =>
          http.Response(jsonEncode({'detail': 'Not authenticated'}), 401);

      final auth = container.read(authProvider.notifier);
      await auth.checkAuthStatus();

      final state = container.read(authProvider);
      expect(state.isInitializing, false);
      expect(state.isSignedIn, false);
      expect(fakeApi.savedToken, isNull);
    },
  );

  test(
    'checkAuthStatus with no stored token clears initializing only',
    () async {
      final auth = container.read(authProvider.notifier);
      await auth.checkAuthStatus();

      final state = container.read(authProvider);
      expect(state.isInitializing, false);
      expect(state.isSignedIn, false);
    },
  );
}

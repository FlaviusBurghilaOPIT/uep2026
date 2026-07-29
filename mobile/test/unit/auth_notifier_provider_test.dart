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

  test('completeOnboarding no longer sends a password field', () async {
    fakeApi.postHandlers['/auth/complete-onboarding'] = (body) {
      expect(body?.containsKey('password'), false);
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
      phone: '1234567890',
    );

    expect(success, true);
    expect(fakeApi.savedToken, 'jwt_2');
  });
}

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/auth/providers/auth_notifier.dart';

import 'fake_api_service.dart';

void main() {
  late FakeApiService fakeApi;
  late ProviderContainer container;

  setUp(() {
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('verifyInvite success -> AuthState.onboarding', () async {
    fakeApi.postHandlers['/auth/verify-invite'] = (body) {
      if (body?['email'] == 'test@example.com' && body?['invite_code'] == 'VALID123') {
        return http.Response(
          jsonEncode({
            'email': 'test@example.com',
            'full_name': 'Jane Doe',
            'surgery_type': 'Knee Replacement',
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'detail': 'Invalid invite code'}), 400);
    };

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.verifyInvite('test@example.com', 'VALID123');

    final state = container.read(authNotifierProvider).value;
    expect(
      state,
      const AuthState.onboarding(
        email: 'test@example.com',
        fullName: 'Jane Doe',
        surgeryType: 'Knee Replacement',
      ),
    );
  });

  test('verifyInvite with wrong code -> AuthState.error("Invalid invite code")', () async {
    fakeApi.postHandlers['/auth/verify-invite'] = (body) {
      return http.Response(jsonEncode({'detail': 'Invalid invite code'}), 400);
    };

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.verifyInvite('test@example.com', 'WRONG');

    final state = container.read(authNotifierProvider).value;
    expect(state, const AuthState.error('Invalid invite code'));
  });

  test('completeOnboarding success -> AuthState.authenticated', () async {
    fakeApi.postHandlers['/auth/complete-onboarding'] = (body) {
      return http.Response(jsonEncode({'access_token': 'jwt_token_123'}), 200);
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
        jsonEncode({
          'id': 'case_1',
          'patient_id': 'user_1',
          'surgery_type': 'Knee Replacement',
        }),
        200,
      );
    };

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.completeOnboarding(
      email: 'jane@example.com',
      inviteCode: 'VALID123',
      password: 'password123',
      dateOfBirth: '1990-01-01',
      phone: '1234567890',
    );

    expect(fakeApi.savedToken, 'jwt_token_123');
    final state = container.read(authNotifierProvider).value;
    expect(
      state,
      const AuthState.authenticated(
        userId: 'user_1',
        caseId: 'case_1',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        surgeryType: 'Knee Replacement',
      ),
    );
  });

  test('signIn success -> AuthState.authenticated with userId populated', () async {
    fakeApi.postHandlers['/auth/login'] = (body) {
      return http.Response(jsonEncode({'access_token': 'jwt_token_456'}), 200);
    };
    fakeApi.getHandlers['/auth/me'] = () {
      return http.Response(
        jsonEncode({
          'id': 'user_2',
          'email': 'john@example.com',
          'full_name': 'John Smith',
        }),
        200,
      );
    };
    fakeApi.getHandlers['/patients/user_2/case'] = () {
      return http.Response(
        jsonEncode({
          'id': 'case_2',
          'patient_id': 'user_2',
          'surgery_type': 'Hip Replacement',
        }),
        200,
      );
    };

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.signIn('john@example.com', 'password123');

    expect(fakeApi.savedToken, 'jwt_token_456');
    final state = container.read(authNotifierProvider).value;
    expect(
      state,
      const AuthState.authenticated(
        userId: 'user_2',
        caseId: 'case_2',
        fullName: 'John Smith',
        email: 'john@example.com',
        surgeryType: 'Hip Replacement',
      ),
    );
  });
}

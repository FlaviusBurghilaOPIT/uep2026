import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/notifications/notification_service.dart';
import 'package:remotecare/core/notifications/push_notification_service.dart';

import 'fake_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late PushNotificationService pushService;

  setUp(() {
    fakeApi = FakeApiService();
    pushService = PushNotificationService(
      apiService: fakeApi,
      notificationService: NotificationService.instance,
    );
  });

  group('PushNotificationService Tests', () {
    test('registerDeviceToken sends POST request to /notifications/register-token', () async {
      fakeApi.postHandlers['/notifications/register-token'] = (body) {
        expect(body?['token'], 'apns_token_abc123');
        expect(body?['platform'], 'ios');
        return http.Response('{"status": "registered"}', 200);
      };

      final success = await pushService.registerDeviceToken('apns_token_abc123', 'ios');

      expect(success, isTrue);
      expect(pushService.registeredToken, 'apns_token_abc123');
      expect(pushService.registeredPlatform, 'ios');
      expect(fakeApi.requestsLog.length, 1);
      expect(fakeApi.requestsLog.first['path'], '/notifications/register-token');
    });

    test('registerDeviceToken handles empty inputs gracefully', () async {
      final successEmptyToken = await pushService.registerDeviceToken('', 'android');
      final successEmptyPlatform = await pushService.registerDeviceToken('token123', '');

      expect(successEmptyToken, isFalse);
      expect(successEmptyPlatform, isFalse);
      expect(fakeApi.requestsLog, isEmpty);
    });

    test('registerDeviceToken returns false when server responds with non-200 code', () async {
      fakeApi.postHandlers['/notifications/register-token'] = (body) {
        return http.Response('{"detail": "Internal error"}', 500);
      };

      final success = await pushService.registerDeviceToken('fcm_token_xyz', 'android');

      expect(success, isFalse);
      expect(pushService.registeredToken, isNull);
    });

    test('handleRemoteMessage processes take_dose action payload', () async {
      bool adherenceLogged = false;
      fakeApi.postHandlers['/adherence/log'] = (body) {
        expect(body?['reminder_id'], 'rem_789');
        expect(body?['status'], 'taken');
        adherenceLogged = true;
        return http.Response('{"status": "logged"}', 200);
      };

      final payload = {
        'action': 'take_dose',
        'reminder_id': 'rem_789',
      };

      await pushService.handleRemoteMessage(payload);

      expect(adherenceLogged, isTrue);
    });

    test('syncPushFallback does not trigger remote registration when permissions granted in foreground', () async {
      final success = await pushService.syncPushFallback(
        token: 'token_123',
        platform: 'ios',
        isLocalPermissionGranted: true,
        isAppInBackground: false,
      );

      expect(success, isTrue);
      expect(pushService.isFallbackActive, isFalse);
      expect(fakeApi.requestsLog, isEmpty);
    });

    test('syncPushFallback triggers remote push fallback when local permissions are restricted', () async {
      fakeApi.postHandlers['/notifications/register-token'] = (body) {
        return http.Response('{"status": "registered"}', 200);
      };

      final success = await pushService.syncPushFallback(
        token: 'token_restricted_perm',
        platform: 'android',
        isLocalPermissionGranted: false,
        isAppInBackground: false,
      );

      expect(success, isTrue);
      expect(pushService.isFallbackActive, isTrue);
      expect(pushService.registeredToken, 'token_restricted_perm');
      expect(fakeApi.requestsLog.length, 1);
    });

    test('syncPushFallback triggers remote push fallback when app is in background', () async {
      fakeApi.postHandlers['/notifications/register-token'] = (body) {
        return http.Response('{"status": "registered"}', 200);
      };

      final success = await pushService.syncPushFallback(
        token: 'token_bg_mode',
        platform: 'ios',
        isLocalPermissionGranted: true,
        isAppInBackground: true,
      );

      expect(success, isTrue);
      expect(pushService.isFallbackActive, isTrue);
      expect(pushService.registeredToken, 'token_bg_mode');
    });

    test('NotificationService integration delegates to PushNotificationService correctly', () async {
      fakeApi.postHandlers['/notifications/register-token'] = (body) {
        return http.Response('{"status": "registered"}', 200);
      };

      final notificationService = NotificationService.instance;
      notificationService.setPushNotificationService(pushService);

      final result = await notificationService.checkAndSyncPushFallback(
        deviceToken: 'token_integ',
        platform: 'ios',
        isPermissionGranted: false,
      );

      expect(result, isTrue);
      expect(pushService.isFallbackActive, isTrue);
      expect(pushService.registeredToken, 'token_integ');
    });
  });
}

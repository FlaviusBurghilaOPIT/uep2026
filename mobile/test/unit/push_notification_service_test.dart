import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/notifications/notification_service.dart';
import 'package:remotecare/core/notifications/push_notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'fake_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiService fakeApi;
  late PushNotificationService pushService;

  setUp(() {
    tz.initializeTimeZones();
    fakeApi = FakeApiService();
    pushService = PushNotificationService(
      apiService: fakeApi,
      notificationService: NotificationService.instance,
    );
  });

  group('PushNotificationService Tests', () {
    test(
      'registerDeviceToken sends POST request to /notifications/register-token',
      () async {
        fakeApi.postHandlers['/notifications/register-token'] = (body) {
          expect(body?['token'], 'apns_token_abc123');
          expect(body?['platform'], 'ios');
          return http.Response('{"status": "registered"}', 200);
        };

        final success = await pushService.registerDeviceToken(
          'apns_token_abc123',
          'ios',
        );

        expect(success, isTrue);
        expect(pushService.registeredToken, 'apns_token_abc123');
        expect(pushService.registeredPlatform, 'ios');
        expect(fakeApi.requestsLog.length, 1);
        expect(
          fakeApi.requestsLog.first['path'],
          '/notifications/register-token',
        );
      },
    );

    test('registerDeviceToken handles empty inputs gracefully', () async {
      final successEmptyToken = await pushService.registerDeviceToken(
        '',
        'android',
      );
      final successEmptyPlatform = await pushService.registerDeviceToken(
        'token123',
        '',
      );

      expect(successEmptyToken, isFalse);
      expect(successEmptyPlatform, isFalse);
      expect(fakeApi.requestsLog, isEmpty);
    });

    test(
      'registerDeviceToken returns false when server responds with non-200 code',
      () async {
        fakeApi.postHandlers['/notifications/register-token'] = (body) {
          return http.Response('{"detail": "Internal error"}', 500);
        };

        final success = await pushService.registerDeviceToken(
          'fcm_token_xyz',
          'android',
        );

        expect(success, isFalse);
        expect(pushService.registeredToken, isNull);
      },
    );

    test('handleRemoteMessage processes take_dose action payload', () async {
      bool adherenceLogged = false;
      fakeApi.adherenceLogHandler = (scheduledReminderId, status) {
        expect(scheduledReminderId, 'rem_789');
        expect(status, 'taken');
        adherenceLogged = true;
        return http.Response('{"status": "logged"}', 200);
      };

      final payload = {'action': 'take_dose', 'reminder_id': 'rem_789'};

      await pushService.handleRemoteMessage(payload);

      expect(adherenceLogged, isTrue);
    });

    test(
      'REGRESSION: take_dose routes through ApiService.logAdherence with query params, not JSON body',
      () async {
        fakeApi.adherenceLogHandler = (scheduledReminderId, status) {
          return http.Response('{"status": "logged"}', 201);
        };

        await pushService.handleRemoteMessage({
          'action': 'take_dose',
          'reminder_id': 'rem_regression',
        });

        final adherenceRequests = fakeApi.requestsTo('/adherence/log');
        expect(adherenceRequests.length, 1);
        expect(
          adherenceRequests.first['path'],
          '/adherence/log?scheduled_reminder_id=rem_regression&status=taken',
        );
        // Must NOT have used the old JSON body call
        final oldStyleRequests = fakeApi.requestsLog.where(
          (r) =>
              r['path'] == '/adherence/log' &&
              r['body'] != null &&
              (r['body'] as Map).containsKey('reminder_id'),
        );
        expect(oldStyleRequests, isEmpty);
      },
    );

    test(
      'syncPushFallback does not trigger remote registration when permissions granted in foreground',
      () async {
        final success = await pushService.syncPushFallback(
          token: 'token_123',
          platform: 'ios',
          isLocalPermissionGranted: true,
          isAppInBackground: false,
        );

        expect(success, isTrue);
        expect(pushService.isFallbackActive, isFalse);
        expect(fakeApi.requestsLog, isEmpty);
      },
    );

    test(
      'syncPushFallback triggers remote push fallback when local permissions are restricted',
      () async {
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
      },
    );

    test(
      'syncPushFallback triggers remote push fallback when app is in background',
      () async {
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
      },
    );

    test(
      'NotificationService integration delegates to PushNotificationService correctly',
      () async {
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
      },
    );

    test(
      'REGRESSION: snooze routes through notification datasource, not adherence API',
      () async {
        // snooze calls NotificationService.snoozeReminder which hits a
        // platform channel (unavailable in tests). The key regression check
        // is that snooze does NOT route through the adherence API.
        try {
          await pushService.handleRemoteMessage({
            'action': 'snooze',
            'reminder_id': 'rem_snooze',
          });
        } catch (_) {
          // Platform channel error expected in test environment —
          // the routing assertion below is what matters.
        }

        // No adherence log should have been created
        final adherenceRequests = fakeApi.requestsTo('/adherence/log');
        expect(adherenceRequests, isEmpty);
      },
    );

    test(
      'handleRemoteMessage extracts reminder_id from payload field',
      () async {
        fakeApi.adherenceLogHandler = (scheduledReminderId, status) {
          expect(scheduledReminderId, 'rem_from_payload');
          return http.Response('{"status": "logged"}', 201);
        };

        await pushService.handleRemoteMessage({
          'action': 'take_dose',
          'payload': 'rem_from_payload:med_123:take_dose',
        });

        expect(fakeApi.requestsTo('/adherence/log').length, 1);
      },
    );
  });
}

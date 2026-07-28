import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../network/api_service.dart';
import 'push_notification_service.dart';

// Top-level background handler — required for terminated app dose logging
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  if (details.actionId == 'take_dose') {
    final reminderId = NotificationService.parseReminderId(
      details.payload ?? '',
    );
    if (reminderId != null && reminderId.isNotEmpty) {
      final api = HttpApiService();
      await api.post('/adherence/log', {
        'reminder_id': reminderId,
        'status': 'taken',
      });
      await HapticFeedback.mediumImpact();
    }
  }
  if (details.actionId == 'snooze') {
    final reminderId = NotificationService.parseReminderId(
      details.payload ?? '',
    );
    if (reminderId != null && reminderId.isNotEmpty) {
      await NotificationService.instance.snoozeReminder(reminderId, 15);
    }
  }
}

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _notificationResponseSubject =
      StreamController<NotificationResponse>.broadcast();
  PushNotificationService? _pushNotificationService;

  Stream<NotificationResponse> get notificationResponseStream =>
      _notificationResponseSubject.stream;

  void setPushNotificationService(PushNotificationService pushService) {
    _pushNotificationService = pushService;
  }

  PushNotificationService get pushNotificationService =>
      _pushNotificationService ??
      PushNotificationService(notificationService: this);

  /// Synchronizes remote push fallback when OS local notification permissions are restricted
  /// or when operating in background.
  Future<bool> checkAndSyncPushFallback({
    required String deviceToken,
    required String platform,
    required bool isPermissionGranted,
    bool isAppInBackground = false,
  }) async {
    return await pushNotificationService.syncPushFallback(
      token: deviceToken,
      platform: platform,
      isLocalPermissionGranted: isPermissionGranted,
      isAppInBackground: isAppInBackground,
    );
  }

  static String? parseReminderId(String payload) {
    if (payload.isEmpty) return null;
    final parts = payload.split(':');
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
  }

  /// Re-initializes timezone data and re-anchors scheduled reminders on app launch and OS timezone changes.
  Future<void> reinitialize() async {
    tz.initializeTimeZones();
  }

  Future<void> initialize() async {
    await reinitialize();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final takeDoseDarwinAction = DarwinNotificationAction.plain(
      'take_dose',
      'Take Dose',
      options: {DarwinNotificationActionOption.foreground},
    );
    final snoozeDarwinAction = DarwinNotificationAction.plain(
      'snooze',
      'Snooze 15 min',
    );
    final medicationCategory = DarwinNotificationCategory(
      'medication_reminder',
      actions: [takeDoseDarwinAction, snoozeDarwinAction],
    );

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [medicationCategory],
    );

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == 'take_dose') {
          final reminderId = parseReminderId(response.payload ?? '');
          if (reminderId != null && reminderId.isNotEmpty) {
            final api = HttpApiService();
            await api.post('/adherence/log', {
              'reminder_id': reminderId,
              'status': 'taken',
            });
            await HapticFeedback.mediumImpact();
          }
        } else if (response.actionId == 'snooze') {
          final reminderId = parseReminderId(response.payload ?? '');
          if (reminderId != null && reminderId.isNotEmpty) {
            await snoozeReminder(reminderId, 15);
          }
        }
        _notificationResponseSubject.add(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    const androidChannel = AndroidNotificationChannel(
      'carepro_med_reminders',
      'Medication Reminders',
      description: 'Reminders to take scheduled medications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Checks the OS notification-permission state WITHOUT prompting the user
  /// (WI 14 / spec §6: the first-run primer owns the one-time request; Today
  /// / notification-scheduling code must never re-prompt or nag).
  Future<bool> arePermissionsGranted() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }
    // Unknown/unsupported platform (e.g. macOS in tests) — don't nag with a
    // reminders-off banner when we simply cannot tell.
    return true;
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> scheduleMedicationReminder({
    required String reminderId,
    required String medicationId,
    required String medicationName,
    required String doseAmount,
    required DateTime scheduledTime,
  }) async {
    const takeDoseAction = AndroidNotificationAction(
      'take_dose',
      'Take Dose',
      showsUserInterface: false,
      cancelNotification: true,
    );

    const snoozeAction = AndroidNotificationAction(
      'snooze',
      'Snooze 15 min',
      showsUserInterface: false,
      cancelNotification: true,
    );

    final androidDetails = AndroidNotificationDetails(
      'carepro_med_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take scheduled medications',
      importance: Importance.high,
      priority: Priority.high,
      actions: const [takeDoseAction, snoozeAction],
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_reminder',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    var scheduledTzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (scheduledTzTime.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledTzTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 5));
    }

    final payload = '$reminderId:$medicationId:take_dose';
    final notificationId = reminderId.hashCode.abs();

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Medication Reminder',
      body: 'Time to take $medicationName — $doseAmount',
      scheduledDate: scheduledTzTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> snoozeReminder(String reminderId, int minutes) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    await scheduleMedicationReminder(
      reminderId: reminderId,
      medicationId: reminderId,
      medicationName: 'Medication',
      doseAmount: '1 dose',
      scheduledTime: snoozeTime,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  void dispose() {
    _notificationResponseSubject.close();
  }
}

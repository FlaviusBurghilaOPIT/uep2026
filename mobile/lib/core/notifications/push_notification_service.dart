import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_service.dart';
import 'notification_service.dart';

/// PushNotificationService manages remote APNS/FCM device push token registration
/// with backend `POST /notifications/register-token` and processes remote push messages.
///
/// It integrates with [NotificationService] to automatically fall back to remote
/// push when OS local notification permissions are restricted or when the app is in the background.
class PushNotificationService {
  final ApiService _apiService;
  final NotificationService _notificationService;

  String? _registeredToken;
  String? _registeredPlatform;
  bool _isFallbackActive = false;

  PushNotificationService({
    ApiService? apiService,
    NotificationService? notificationService,
  })  : _apiService = apiService ?? HttpApiService(),
        _notificationService = notificationService ?? NotificationService.instance;

  /// Currently registered device push token.
  String? get registeredToken => _registeredToken;

  /// Currently registered device platform (e.g. 'apns', 'fcm', 'ios', 'android').
  String? get registeredPlatform => _registeredPlatform;

  /// Indicates whether the remote push fallback channel is currently active.
  bool get isFallbackActive => _isFallbackActive;

  /// Registers remote APNS/FCM device push token with backend `POST /notifications/register-token`.
  ///
  /// Returns `true` if registration succeeded (HTTP 200 or 201), `false` otherwise.
  Future<bool> registerDeviceToken(String token, String platform) async {
    if (token.trim().isEmpty || platform.trim().isEmpty) return false;
    try {
      final response = await _apiService.post('/notifications/register-token', {
        'token': token,
        'platform': platform,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _registeredToken = token;
        _registeredPlatform = platform;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('PushNotificationService: Token registration failed: $e');
      return false;
    }
  }

  /// Processes an incoming remote push notification payload.
  ///
  /// Handles dose logging, snooze actions, and optional local notification fallback displays.
  Future<void> handleRemoteMessage(Map<String, dynamic> payload) async {
    final reminderId = payload['reminder_id'] as String? ??
        NotificationService.parseReminderId(payload['payload'] as String? ?? '');
    final action = payload['action'] as String?;

    if (action == 'take_dose' && reminderId != null && reminderId.isNotEmpty) {
      await _apiService.post('/adherence/log', {
        'reminder_id': reminderId,
        'status': 'taken',
      });
    } else if (action == 'snooze' && reminderId != null && reminderId.isNotEmpty) {
      final minutes = payload['snooze_minutes'] as int? ?? 15;
      await _notificationService.snoozeReminder(reminderId, minutes);
    }

    final showLocal = payload['show_local'] == true || payload['show_local'] == 'true';
    if (showLocal && reminderId != null && reminderId.isNotEmpty) {
      final medicationId = payload['medication_id'] as String? ?? reminderId;
      final medicationName = payload['medication_name'] as String? ?? 'Medication';
      final doseAmount = payload['dose_amount'] as String? ?? '1 dose';
      await _notificationService.scheduleMedicationReminder(
        reminderId: reminderId,
        medicationId: medicationId,
        medicationName: medicationName,
        doseAmount: doseAmount,
        scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
      );
    }
  }

  /// Checks OS local notification permission status and app lifecycle state.
  ///
  /// Automatically registers remote push token with backend as a fallback whenever
  /// local permissions are restricted/denied or when the app is running in the background.
  Future<bool> syncPushFallback({
    required String token,
    required String platform,
    required bool isLocalPermissionGranted,
    bool isAppInBackground = false,
  }) async {
    final needsFallback = !isLocalPermissionGranted || isAppInBackground;
    if (needsFallback) {
      _isFallbackActive = true;
      return await registerDeviceToken(token, platform);
    } else {
      _isFallbackActive = false;
      return true;
    }
  }
}

/// Provider for accessing [PushNotificationService].
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    apiService: ref.watch(apiServiceProvider),
    notificationService: NotificationService.instance,
  );
});

/// Push-notification datasource interface (WI 03 / spec R20).
///
/// Abstracts the remote push capability so it can be mocked in tests:
/// device-token registration, remote message handling, and the
/// permission/background fallback logic.
abstract class PushDatasource {
  /// Registers the device push token with the backend
  /// (`POST /notifications/register-token`, body `{token, platform}`).
  ///
  /// Returns `true` if registration succeeded.
  Future<bool> registerDeviceToken(String token, String platform);

  /// Processes an incoming remote push notification payload.
  ///
  /// Handles `take_dose` (routes through [ApiService.logAdherence]),
  /// `snooze` (routes through the local-notification datasource), and
  /// `show_local` (schedules a local fallback reminder).
  Future<void> handleRemoteMessage(Map<String, dynamic> payload);

  /// Checks OS local notification permission and app lifecycle state,
  /// registering the remote push token as a fallback when local
  /// permissions are restricted or the app is in the background.
  Future<bool> syncPushFallback({
    required String token,
    required String platform,
    required bool isLocalPermissionGranted,
    bool isAppInBackground = false,
  });
}

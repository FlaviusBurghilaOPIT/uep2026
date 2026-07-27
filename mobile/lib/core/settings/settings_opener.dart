import 'package:app_settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seam for deep-linking to OS settings (C1 reminders-off banner).
/// Injectable so widget tests can verify the deep link without platform
/// channels.
abstract class SettingsOpener {
  Future<void> openNotificationSettings();
}

class AppSettingsOpener implements SettingsOpener {
  const AppSettingsOpener();

  @override
  Future<void> openNotificationSettings() {
    return AppSettings.openAppSettings(type: AppSettingsType.notification);
  }
}

final settingsOpenerProvider = Provider<SettingsOpener>(
  (ref) => const AppSettingsOpener(),
);

/// Shared_preferences keys for the Profile notification toggles (WI 06 /
/// spec Req 25). Preferences are client-side only — no notification-
/// preference endpoint exists (spec Technical Decision 5).
class NotificationPrefsKeys {
  NotificationPrefsKeys._();

  static const medReminders = 'profile_notif_med_reminders_v1';
  static const dailyCheckin = 'profile_notif_daily_checkin_v1';
}

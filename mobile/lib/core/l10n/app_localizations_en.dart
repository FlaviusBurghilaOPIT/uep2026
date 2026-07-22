// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Remote CarePro';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get onboardingTitle => 'You\'ve been invited';

  @override
  String get onboardingSubtitle =>
      'Enter your email and the code your clinician sent you.';

  @override
  String get inviteCodeLabel => 'Invitation code';

  @override
  String get verifyButton => 'Verify Code';

  @override
  String get completeSetupButton => 'Complete Setup';

  @override
  String get todayTitle => 'Today';

  @override
  String medicationCardTitle(String medicationName) {
    return 'Take $medicationName';
  }

  @override
  String doseAmount(String doseAmount) {
    return '$doseAmount dose';
  }

  @override
  String scheduledAt(String scheduledTime) {
    return 'Scheduled at $scheduledTime';
  }

  @override
  String get doseStatusTaken => 'Taken';

  @override
  String get doseStatusMissed => 'Missed';

  @override
  String get doseStatusSkipped => 'Skipped';

  @override
  String get takeDoseButton => 'Take Dose';

  @override
  String get skipDoseButton => 'Skip';

  @override
  String get missedDoseButton => 'Missed';

  @override
  String get checkinTitle => 'Daily Check-in';

  @override
  String get symptomQuestion => 'How are you feeling today?';

  @override
  String get severityMild => 'Mild';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severitySevere => 'Severe';

  @override
  String get submitCheckinButton => 'Submit';

  @override
  String get checkinGreatOption => 'Feeling Great 🙂';

  @override
  String get checkinOkOption => 'Feeling Ok 😐';

  @override
  String get checkinNotGreatOption => 'Not Feeling Great 😟';

  @override
  String get checkinBadOption => 'Feeling Unwell 😣';

  @override
  String get checkinSuccessBanner =>
      'Daily check-in logged. Thank you for updating your care team.';

  @override
  String get assistantTitle => 'AI Assistant';

  @override
  String get assistantGuardrailBanner =>
      'AI Assistant • Informational only, never diagnostic';

  @override
  String get typeMessagePlaceholder => 'Type your question...';

  @override
  String get chipMedicationSideEffects => 'Medication side effects';

  @override
  String get chipWoundCareTips => 'Wound care tips';

  @override
  String get chipPhysioTargets => 'Physio targets';

  @override
  String get chipEmergencyContact => 'Emergency contact';

  @override
  String get profileTitle => 'Profile';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italian';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languageGerman => 'German';

  @override
  String get signOutButton => 'Sign Out';

  @override
  String get notificationReminderTitle => 'Medication Reminder';

  @override
  String notificationReminderBody(String medicationName, String doseAmount) {
    return 'Time to take $medicationName — $doseAmount';
  }

  @override
  String get notificationActionTake => 'Take Dose';

  @override
  String get notificationActionSnooze => 'Snooze 15 min';

  @override
  String get notificationPermissionRationale =>
      'Enable notifications to receive medication reminders at the right time.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No connection. Please check your internet.';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get navTabToday => 'Today';

  @override
  String get navTabMedications => 'Medications';

  @override
  String get navTabRecovery => 'Recovery';

  @override
  String get navTabAssistant => 'Assistant';

  @override
  String get navTabProfile => 'Profile';

  @override
  String get medicationsScreenTitle => 'Medications';

  @override
  String medCardDoseLabel(String dose) {
    return 'Dose: $dose';
  }

  @override
  String medCardScheduleLabel(String schedule) {
    return 'Schedule: $schedule';
  }

  @override
  String medCardDurationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get medCardNotesHeader => 'Clinician Instructions:';

  @override
  String get medCardReadOnlyBadge => '🔒 Prescribed by Care Team — Read Only';

  @override
  String get medicationsEmptyState =>
      'No active medications on your care plan yet.';
}

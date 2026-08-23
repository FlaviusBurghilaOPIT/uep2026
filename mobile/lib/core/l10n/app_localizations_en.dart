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
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

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
  String get assistantTitle => 'Care Team Assistant';

  @override
  String get assistantGuardrailBanner =>
      'Care Team Assistant • Informational only, never diagnostic';

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
  String get emergencyCallCta => 'Call Emergency Contact';

  @override
  String emergencyCallCtaWithPhone(String phone) {
    return 'Call Emergency Contact ($phone)';
  }

  @override
  String get emergencyWarningTitle =>
      'I Cannot Advise on Dose Changes or Urgent Symptoms';

  @override
  String get fdaSafetyAlertTitle => 'Official FDA Drug Safety Info';

  @override
  String get fdaSourceLive => '📋 Source: Official FDA Drug Safety Info';

  @override
  String get fdaSourceFixture => '📋 Source: Regulatory Cache';

  @override
  String fdaRetrievedTimestamp(String date) {
    return 'Retrieved: $date';
  }

  @override
  String get fdaWarningMessage =>
      'New drug interaction warning for Amoxicillin. Tap info to learn more.';

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

  @override
  String get frequencyQD => 'Once daily';

  @override
  String get frequencyBID => 'Twice daily';

  @override
  String get frequencyTID => 'Three times daily';

  @override
  String get frequencyQID => 'Four times daily';

  @override
  String get frequencyPRN => 'As needed';

  @override
  String get authEmailLoginTitle => 'Login';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authRequiredError => 'Required';

  @override
  String get authInvalidEmailError => 'Enter a valid email';

  @override
  String get authSendOtpButton => 'Send OTP';

  @override
  String authErrorSendingOtp(String error) {
    return 'Error sending OTP: $error';
  }

  @override
  String get authEnterInvitationCodeTitle => 'Enter Invitation Code';

  @override
  String get authWelcomeTitle => 'Welcome!';

  @override
  String get authInvitationCodeSubtitle =>
      'Please enter your invitation code to continue.';

  @override
  String get authInvitationCodeLabel => 'Invitation Code';

  @override
  String get authInvalidInvitationCodeError =>
      'Please enter a valid invitation code';

  @override
  String get authContinueButton => 'Continue';

  @override
  String get authEnterOtpTitle => 'Enter OTP';

  @override
  String get authVerifyIdentityTitle => 'Verify Identity';

  @override
  String authOtpSentToEmail(String email) {
    return 'Please enter the 6-digit code sent to $email.';
  }

  @override
  String get authOtpSentToEmailFallback =>
      'Please enter the 6-digit code sent to your email.';

  @override
  String get authOtpCodeLabel => 'OTP Code';

  @override
  String get authOtpCodeLengthError => 'Code must be exactly 6 digits';

  @override
  String get authOtpCodeNumericError => 'Code must be numeric';

  @override
  String get authVerifyAndLogInButton => 'Verify and Log In';

  @override
  String get authProfileSetupTitle => 'Profile Setup';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authSurnameLabel => 'Surname';

  @override
  String get authAgeLabel => 'Age';

  @override
  String get authInvalidAgeError => 'Enter a valid positive integer';

  @override
  String get authSaveAndEnterAppButton => 'Save and Enter App';

  @override
  String get authSelectDobError => 'Please select your date of birth';

  @override
  String get okButton => 'OK';

  @override
  String get authCompleteProfileSetupSubtitle =>
      'Complete your patient profile setup';

  @override
  String get todayAgendaError =>
      'We couldn\'t load your care plan. Check your connection and try again.';

  @override
  String get todayRetry => 'Retry';

  @override
  String todayStaleBanner(String relativeTime) {
    return 'Updated $relativeTime — syncing latest plan…';
  }

  @override
  String get todayOfflineBanner =>
      'Log saved on your device. We will update your care team once you are back online.';

  @override
  String get todayPlanUpdatedBanner =>
      'Your care team updated your prescribed medications.';

  @override
  String get todayTimezoneAdjusted =>
      'Your reminder times have adjusted to your current time zone.';

  @override
  String get todayLogUndo => 'Undo';

  @override
  String todayLoggedAs(String status) {
    return 'Logged as $status.';
  }

  @override
  String get todayLogRollbackError =>
      'We couldn\'t save that log. Your dose shows as unlogged — tap to try again.';

  @override
  String todayCorrectionTitle(String status, String time) {
    return 'Logged as $status at $time. Change what happened?';
  }

  @override
  String get todayCorrectionKeep => 'Keep as is';

  @override
  String get todaySkipPrompt =>
      'Are you experiencing severe or troubling symptoms?';

  @override
  String get todaySkipPromptYes => 'Yes';

  @override
  String get todaySkipPromptNo => 'No, I\'m okay';

  @override
  String get todayNoEmergencyContact =>
      'No emergency contact on file — contact your clinic.';

  @override
  String get todayGroupMorning => 'Morning';

  @override
  String get todayGroupMidday => 'Midday';

  @override
  String get todayGroupEvening => 'Evening';

  @override
  String get todayGroupBedtime => 'Bedtime';

  @override
  String get todayPrnSection => 'As needed';

  @override
  String get todayDueNow => 'Due now';

  @override
  String get todayUpcoming => 'Upcoming';

  @override
  String todayScheduledFor(String time) {
    return 'Scheduled $time';
  }

  @override
  String todaySlotTimes(String scheduledTime, String loggedTime) {
    return 'Scheduled for $scheduledTime — Logged at $loggedTime.';
  }

  @override
  String todayPreviouslyLogged(String status) {
    return 'Previously: $status';
  }

  @override
  String get todaySyncPending => 'Saved on device';

  @override
  String todayCelebrationNext(String weekday, String time) {
    return 'Next dose: $weekday at $time';
  }

  @override
  String get todayCelebration =>
      'All doses for today completed! Thank you for updating your care team.';

  @override
  String todayProgressDoses(int taken, int total) {
    return '$taken/$total doses';
  }

  @override
  String get todayPullToRefreshHint => 'Pull down to check again.';

  @override
  String get todayOpenSettings => 'Open Settings';

  @override
  String get remindersOffBanner =>
      'Reminders are turned off. You can log doses manually — or turn reminders on in Settings.';

  @override
  String get emptyPlanMessage =>
      'Your care team is preparing your care plan. No action is needed from you right now.';

  @override
  String get checkinErrorRetry =>
      'We couldn\'t save your check-in. Tap to try again.';

  @override
  String get todayTimeJustNow => 'just now';

  @override
  String todayTimeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String todayTimeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get emergencyBannerTitle => 'Emergency Red Flag Warning';

  @override
  String get emergencyCall911 => 'Call Emergency (911)';

  @override
  String emergencyCallClinic(String phone) {
    return 'Call Care Team ($phone)';
  }

  @override
  String get emergencyCallClinicFallback => 'Call Care Team';

  @override
  String get pillFormCapsule => 'Capsule';

  @override
  String get pillFormTablet => 'Tablet';

  @override
  String get pillFormLiquid => 'Liquid';
}

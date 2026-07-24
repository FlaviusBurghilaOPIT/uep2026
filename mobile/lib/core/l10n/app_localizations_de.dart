// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Remote CarePro';

  @override
  String get loginTitle => 'Willkommen zurück';

  @override
  String get loginEmailLabel => 'E-Mail-Adresse';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get onboardingTitle => 'Sie wurden eingeladen';

  @override
  String get onboardingSubtitle =>
      'Geben Sie Ihre E-Mail und den Code Ihres Arztes ein.';

  @override
  String get inviteCodeLabel => 'Einladungscode';

  @override
  String get verifyButton => 'Code überprüfen';

  @override
  String get completeSetupButton => 'Einrichtung abschließen';

  @override
  String get todayTitle => 'Heute';

  @override
  String get greetingMorning => 'Guten Morgen';

  @override
  String get greetingAfternoon => 'Guten Tag';

  @override
  String get greetingEvening => 'Guten Abend';

  @override
  String medicationCardTitle(String medicationName) {
    return 'Nimm $medicationName';
  }

  @override
  String doseAmount(String doseAmount) {
    return '$doseAmount Dosis';
  }

  @override
  String scheduledAt(String scheduledTime) {
    return 'Geplant um $scheduledTime';
  }

  @override
  String get doseStatusTaken => 'Eingenommen';

  @override
  String get doseStatusMissed => 'Verpasst';

  @override
  String get doseStatusSkipped => 'Übersprungen';

  @override
  String get takeDoseButton => 'Dosis einnehmen';

  @override
  String get skipDoseButton => 'Überspringen';

  @override
  String get missedDoseButton => 'Verpasst';

  @override
  String get checkinTitle => 'Täglicher Check-in';

  @override
  String get symptomQuestion => 'Wie fühlen Sie sich heute?';

  @override
  String get severityMild => 'Leicht';

  @override
  String get severityModerate => 'Mäßig';

  @override
  String get severitySevere => 'Schwer';

  @override
  String get submitCheckinButton => 'Absenden';

  @override
  String get checkinGreatOption => 'Fühle mich großartig 🙂';

  @override
  String get checkinOkOption => 'Fühle mich okay 😐';

  @override
  String get checkinNotGreatOption => 'Fühle mich nicht gut 😟';

  @override
  String get checkinBadOption => 'Fühle mich schlecht 😣';

  @override
  String get checkinSuccessBanner =>
      'Täglicher Check-in gespeichert. Danke, dass Sie Ihr Behandlungsteam informiert haben.';

  @override
  String get assistantTitle => 'Pflegeteam-Assistent';

  @override
  String get assistantGuardrailBanner =>
      'Pflegeteam-Assistent • Nur zur Information, nie diagnostisch';

  @override
  String get typeMessagePlaceholder => 'Schreiben Sie Ihre Frage...';

  @override
  String get chipMedicationSideEffects => 'Nebenwirkungen von Medikamenten';

  @override
  String get chipWoundCareTips => 'Tipps zur Wundversorgung';

  @override
  String get chipPhysioTargets => 'Physiotherapie-Ziele';

  @override
  String get chipEmergencyContact => 'Notfallkontakt';

  @override
  String get emergencyCallCta => 'Notfallkontakt anrufen';

  @override
  String emergencyCallCtaWithPhone(String phone) {
    return 'Notfallkontakt anrufen ($phone)';
  }

  @override
  String get emergencyWarningTitle =>
      'Ich kann nicht zu Dosisänderungen oder dringenden Symptomen beraten';

  @override
  String get fdaSafetyAlertTitle =>
      'Offizielle FDA-Arzneimittelsicherheitsinformationen';

  @override
  String get fdaSourceLive => '📋 Quelle: Offizielle FDA-Informationen';

  @override
  String get fdaSourceFixture => '📋 Quelle: Regulatorischer Cache';

  @override
  String fdaRetrievedTimestamp(String date) {
    return 'Abgerufen: $date';
  }

  @override
  String get fdaWarningMessage =>
      'Neue Warnung zu Wechselwirkungen für Amoxicillin. Tippen Sie auf Info, um mehr zu erfahren.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get languageSectionTitle => 'Sprache';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageItalian => 'Italienisch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get signOutButton => 'Abmelden';

  @override
  String get notificationReminderTitle => 'Medikamentenerinnerung';

  @override
  String notificationReminderBody(String medicationName, String doseAmount) {
    return 'Zeit für $medicationName — $doseAmount';
  }

  @override
  String get notificationActionTake => 'Dosis einnehmen';

  @override
  String get notificationActionSnooze => '15 Min. schlummern';

  @override
  String get notificationPermissionRationale =>
      'Aktivieren Sie Benachrichtigungen, um Medikamentenerinnerungen pünktlich zu erhalten.';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get errorNetwork =>
      'Keine Verbindung. Bitte überprüfen Sie Ihr Internet.';

  @override
  String get loadingLabel => 'Wird geladen...';

  @override
  String get navTabToday => 'Heute';

  @override
  String get navTabMedications => 'Medikamente';

  @override
  String get navTabRecovery => 'Genesung';

  @override
  String get navTabAssistant => 'Assistent';

  @override
  String get navTabProfile => 'Profil';

  @override
  String get medicationsScreenTitle => 'Medikamente';

  @override
  String medCardDoseLabel(String dose) {
    return 'Dosis: $dose';
  }

  @override
  String medCardScheduleLabel(String schedule) {
    return 'Zeitplan: $schedule';
  }

  @override
  String medCardDurationLabel(String duration) {
    return 'Dauer: $duration';
  }

  @override
  String get medCardNotesHeader => 'Anweisungen des Arztes:';

  @override
  String get medCardReadOnlyBadge =>
      '🔒 Verschrieben vom Behandlungsteam — Nur lesen';

  @override
  String get medicationsEmptyState =>
      'Noch keine aktiven Medikamente in Ihrem Behandlungsplan.';

  @override
  String get frequencyQD => 'Einmal täglich';

  @override
  String get frequencyBID => 'Zweimal täglich';

  @override
  String get frequencyTID => 'Dreimal täglich';

  @override
  String get frequencyQID => 'Viermal täglich';

  @override
  String get frequencyPRN => 'Bei Bedarf';

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
}

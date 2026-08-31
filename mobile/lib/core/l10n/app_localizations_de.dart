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
      'Check-in erhalten • Behandlungsteam aktualisiert';

  @override
  String checkinSuccessBannerWithPhysician(String physician) {
    return 'Check-in erhalten • Behandlungsteam von $physician aktualisiert';
  }

  @override
  String get assistantTitle => 'Pflegeteam-Assistent';

  @override
  String get assistantGuardrailBanner =>
      'Pflegeteam-Assistent • Nur zur Information, nie diagnostisch';

  @override
  String get typeMessagePlaceholder => 'Schreiben Sie Ihre Frage...';

  @override
  String get chipSwellingNormal => 'Ist eine leichte Schwellung normal?';

  @override
  String get chipShowering => 'Wann kann ich duschen?';

  @override
  String get chipMedicationInstructions => 'Medikamentenanweisungen';

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
  String get authErrorSendingOtp =>
      'Bestätigungscode konnte nicht gesendet werden. Bitte Verbindung prüfen und erneut versuchen.';

  @override
  String get authEnterInvitationCodeTitle => 'Enter Invitation Code';

  @override
  String get authWelcomeTitle => 'Welcome!';

  @override
  String get authNewPatientClinicInvitation =>
      'Neuer Patient? Klinikeinladung eingeben';

  @override
  String get authSignInWithOneTimeCode => 'Mit Einmalcode anmelden';

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
  String get authResendCode => 'Code erneut senden';

  @override
  String authResendCodeCountdown(int seconds) {
    return 'Code erneut senden in ${seconds}s';
  }

  @override
  String authCodeResentSnackbar(String email) {
    return 'Code erneut an $email gesendet';
  }

  @override
  String get authCodeResentSnackbarFallback => 'Code erneut gesendet';

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
      'Wir konnten Ihren Behandlungsplan nicht laden. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get todayRetry => 'Erneut versuchen';

  @override
  String todayStaleBanner(String relativeTime) {
    return 'Aktualisiert $relativeTime — neueste Version wird synchronisiert…';
  }

  @override
  String get todayOfflineBanner =>
      'Protokoll auf Ihrem Gerät gespeichert. Wir informieren Ihr Pflegeteam, sobald Sie wieder online sind.';

  @override
  String get todayPlanUpdatedBanner =>
      'Ihr Pflegeteam hat Ihre verschriebenen Medikamente aktualisiert.';

  @override
  String get todayTimezoneAdjusted =>
      'Ihre Erinnerungszeiten wurden an Ihre aktuelle Zeitzone angepasst.';

  @override
  String get todayLogUndo => 'Rückgängig';

  @override
  String todayLoggedAs(String status) {
    return 'Eingetragen als $status.';
  }

  @override
  String get todayLogRollbackError =>
      'Wir konnten diesen Eintrag nicht speichern. Ihre Dosis gilt als nicht eingetragen — tippen Sie, um es erneut zu versuchen.';

  @override
  String todayCorrectionTitle(String status, String time) {
    return 'Eingetragen als $status um $time. Korrigieren, was passiert ist?';
  }

  @override
  String get todayCorrectionKeep => 'So belassen';

  @override
  String get todaySkipPrompt =>
      'Haben Sie starke oder beunruhigende Beschwerden?';

  @override
  String get todaySkipPromptYes => 'Ja';

  @override
  String get todaySkipPromptNo => 'Nein, mir geht es gut';

  @override
  String get todayNoEmergencyContact =>
      'Kein Notfallkontakt hinterlegt — wenden Sie sich an Ihre Klinik.';

  @override
  String get todayGroupMorning => 'Morgens';

  @override
  String get todayGroupMidday => 'Mittags';

  @override
  String get todayGroupEvening => 'Abends';

  @override
  String get todayGroupBedtime => 'Zur Nacht';

  @override
  String get todayPrnSection => 'Bei Bedarf';

  @override
  String get todayDueNow => 'Jetzt fällig';

  @override
  String get todayUpcoming => 'Bevorstehend';

  @override
  String todayScheduledFor(String time) {
    return 'Geplant $time';
  }

  @override
  String todaySlotTimes(String scheduledTime, String loggedTime) {
    return 'Geplant für $scheduledTime — Eingetragen um $loggedTime.';
  }

  @override
  String todayPreviouslyLogged(String status) {
    return 'Zuvor: $status';
  }

  @override
  String get todaySyncPending => 'Auf dem Gerät gespeichert';

  @override
  String todayCelebrationNext(String weekday, String time) {
    return 'Nächste Dosis: $weekday um $time';
  }

  @override
  String get todayCelebration =>
      'Alle Dosen für heute erledigt! Danke, dass Sie Ihr Pflegeteam auf dem Laufenden halten.';

  @override
  String todayProgressDoses(int taken, int total) {
    return '$taken/$total Dosen';
  }

  @override
  String get todayPullToRefreshHint => 'Zum Aktualisieren nach unten ziehen.';

  @override
  String get todayOpenSettings => 'Einstellungen öffnen';

  @override
  String get remindersOffBanner =>
      'Erinnerungen sind ausgeschaltet. Sie können Dosen manuell eintragen — oder Erinnerungen in den Einstellungen aktivieren.';

  @override
  String get emptyPlanMessage =>
      'Ihr Pflegeteam bereitet Ihren Behandlungsplan vor. Sie müssen im Moment nichts tun.';

  @override
  String get checkinErrorRetry =>
      'Wir konnten Ihren Check-in nicht speichern. Tippen Sie, um es erneut zu versuchen.';

  @override
  String get todayTimeJustNow => 'gerade eben';

  @override
  String todayTimeMinutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String todayTimeHoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String get emergencyBannerTitle => 'Rote Notfallwarnung';

  @override
  String get emergencyCall911 => 'Notruf wählen (112)';

  @override
  String emergencyCallClinic(String phone) {
    return 'Pflegeteam anrufen ($phone)';
  }

  @override
  String get emergencyCallClinicFallback => 'Pflegeteam anrufen';

  @override
  String get pillFormCapsule => 'Kapsel';

  @override
  String get pillFormTablet => 'Tablette';

  @override
  String get pillFormLiquid => 'Flüssig';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Remote CarePro';

  @override
  String get loginTitle => 'Bentornato';

  @override
  String get loginEmailLabel => 'Indirizzo e-mail';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginButton => 'Accedi';

  @override
  String get onboardingTitle => 'Sei stato invitato';

  @override
  String get onboardingSubtitle =>
      'Inserisci la tua e-mail e il codice inviato dal tuo medico.';

  @override
  String get inviteCodeLabel => 'Codice di invito';

  @override
  String get verifyButton => 'Verifica codice';

  @override
  String get completeSetupButton => 'Completa configurazione';

  @override
  String get todayTitle => 'Oggi';

  @override
  String get greetingMorning => 'Buongiorno';

  @override
  String get greetingAfternoon => 'Buon pomeriggio';

  @override
  String get greetingEvening => 'Buona sera';

  @override
  String medicationCardTitle(String medicationName) {
    return 'Prendi $medicationName';
  }

  @override
  String doseAmount(String doseAmount) {
    return 'Dose $doseAmount';
  }

  @override
  String scheduledAt(String scheduledTime) {
    return 'Programmato alle $scheduledTime';
  }

  @override
  String get doseStatusTaken => 'Assunto';

  @override
  String get doseStatusMissed => 'Mancato';

  @override
  String get doseStatusSkipped => 'Saltato';

  @override
  String get takeDoseButton => 'Prendi dose';

  @override
  String get skipDoseButton => 'Salta';

  @override
  String get missedDoseButton => 'Mancato';

  @override
  String get checkinTitle => 'Check-in giornaliero';

  @override
  String get symptomQuestion => 'Come ti senti oggi?';

  @override
  String get severityMild => 'Lieve';

  @override
  String get severityModerate => 'Moderato';

  @override
  String get severitySevere => 'Grave';

  @override
  String get submitCheckinButton => 'Invia';

  @override
  String get checkinGreatOption => 'Mi sento benissimo 🙂';

  @override
  String get checkinOkOption => 'Mi sento ok 😐';

  @override
  String get checkinNotGreatOption => 'Non mi sento benissimo 😟';

  @override
  String get checkinBadOption => 'Mi sento male 😣';

  @override
  String get checkinSuccessBanner =>
      'Check-in ricevuto • Team medico aggiornato';

  @override
  String checkinSuccessBannerWithPhysician(String physician) {
    return 'Check-in ricevuto • Team medico di $physician aggiornato';
  }

  @override
  String get assistantTitle => 'Assistente del Team Medico';

  @override
  String get assistantGuardrailBanner =>
      'Assistente del Team Medico • Solo informativo, mai diagnostico';

  @override
  String get typeMessagePlaceholder => 'Scrivi la tua domanda...';

  @override
  String get chipSwellingNormal => 'Un lieve gonfiore è normale?';

  @override
  String get chipShowering => 'Quando posso fare la doccia?';

  @override
  String get chipMedicationInstructions => 'Istruzioni sui farmaci';

  @override
  String get emergencyCallCta => 'Chiama il contatto di emergenza';

  @override
  String emergencyCallCtaWithPhone(String phone) {
    return 'Chiama il contatto di emergenza ($phone)';
  }

  @override
  String get emergencyWarningTitle =>
      'Non posso fornire consulenza su modifiche di dosaggio o sintomi urgenti';

  @override
  String get fdaSafetyAlertTitle =>
      'Informazioni ufficiali sulla sicurezza dei farmaci FDA';

  @override
  String get fdaSourceLive => '📋 Fonte: Informazioni ufficiali FDA';

  @override
  String get fdaSourceFixture => '📋 Fonte: Cache regolatoria';

  @override
  String fdaRetrievedTimestamp(String date) {
    return 'Recuperato: $date';
  }

  @override
  String get fdaWarningMessage =>
      'Nuovo avviso di interazione tra farmaci per Amoxicillina. Tocca per saperne di più.';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get languageSectionTitle => 'Lingua';

  @override
  String get languageEnglish => 'Inglese';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageSpanish => 'Spagnolo';

  @override
  String get languageFrench => 'Francese';

  @override
  String get languageGerman => 'Tedesco';

  @override
  String get signOutButton => 'Disconnetti';

  @override
  String get notificationReminderTitle => 'Reminder del farmaco';

  @override
  String notificationReminderBody(String medicationName, String doseAmount) {
    return 'Ora di prendere $medicationName — $doseAmount';
  }

  @override
  String get notificationActionTake => 'Prendi dose';

  @override
  String get notificationActionSnooze => 'Posticipa 15 min';

  @override
  String get notificationPermissionRationale =>
      'Attiva le notifiche per ricevere i promemoria dei farmaci al momento giusto.';

  @override
  String get errorGeneric => 'Si è verificato un errore. Riprova.';

  @override
  String get errorNetwork => 'Nessuna connessione. Controlla internet.';

  @override
  String get loadingLabel => 'Caricamento...';

  @override
  String get navTabToday => 'Oggi';

  @override
  String get navTabMedications => 'Farmaci';

  @override
  String get navTabRecovery => 'Recupero';

  @override
  String get navTabAssistant => 'Assistente';

  @override
  String get navTabProfile => 'Profilo';

  @override
  String get medicationsScreenTitle => 'Farmaci';

  @override
  String medCardDoseLabel(String dose) {
    return 'Dose: $dose';
  }

  @override
  String medCardScheduleLabel(String schedule) {
    return 'Programma: $schedule';
  }

  @override
  String medCardDurationLabel(String duration) {
    return 'Durata: $duration';
  }

  @override
  String get medCardNotesHeader => 'Istruzioni del medico:';

  @override
  String get medCardReadOnlyBadge =>
      '🔒 Prescritto dal team medico — Sola lettura';

  @override
  String get medicationsEmptyState =>
      'Nessun farmaco attivo nel tuo piano di cura al momento.';

  @override
  String get frequencyQD => 'Una volta al giorno';

  @override
  String get frequencyBID => 'Due volte al giorno';

  @override
  String get frequencyTID => 'Tre volte al giorno';

  @override
  String get frequencyQID => 'Quattro volte al giorno';

  @override
  String get frequencyPRN => 'Al bisogno';

  @override
  String get authEmailLoginTitle => 'Accedi';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authRequiredError => 'Obbligatorio';

  @override
  String get authInvalidEmailError => 'Inserisci un\'e-mail valida';

  @override
  String get authSendOtpButton => 'Invia OTP';

  @override
  String get authErrorSendingOtp => 'Errore durante l\'invio dell\'OTP: null';

  @override
  String get authEnterInvitationCodeTitle => 'Inserisci il codice di invito';

  @override
  String get authWelcomeTitle => 'Benvenuto!';

  @override
  String get authNewPatientClinicInvitation =>
      'New Patient? Enter Clinic Invitation';

  @override
  String get authSignInWithOneTimeCode => 'Sign in with One-Time Code';

  @override
  String get authClinicianSignIn => 'Clinician Sign In';

  @override
  String get authInvitationCodeSubtitle =>
      'Inserisci il tuo codice di invito per continuare.';

  @override
  String get authInvitationCodeLabel => 'Codice di invito';

  @override
  String get authInvalidInvitationCodeError =>
      'Inserisci un codice di invito valido';

  @override
  String get authContinueButton => 'Continua';

  @override
  String get authEnterOtpTitle => 'Inserisci OTP';

  @override
  String get authVerifyIdentityTitle => 'Verifica identità';

  @override
  String authOtpSentToEmail(String email) {
    return 'Inserisci il codice di 6 cifre inviato a $email.';
  }

  @override
  String get authOtpSentToEmailFallback =>
      'Inserisci il codice di 6 cifre inviato alla tua e-mail.';

  @override
  String get authOtpCodeLabel => 'Codice OTP';

  @override
  String get authOtpCodeLengthError =>
      'Il codice deve avere esattamente 6 cifre';

  @override
  String get authOtpCodeNumericError => 'Il codice deve essere numerico';

  @override
  String get authVerifyAndLogInButton => 'Verifica e Accedi';

  @override
  String get authResendCode => 'Reinvia codice';

  @override
  String authResendCodeCountdown(int seconds) {
    return 'Reinvia codice tra ${seconds}s';
  }

  @override
  String authCodeResentSnackbar(String email) {
    return 'Codice reinviato a $email';
  }

  @override
  String get authCodeResentSnackbarFallback => 'Codice reinviato';

  @override
  String get authProfileSetupTitle => 'Configurazione profilo';

  @override
  String get authNameLabel => 'Nome';

  @override
  String get authSurnameLabel => 'Cognome';

  @override
  String get authAgeLabel => 'Età';

  @override
  String get authInvalidAgeError =>
      'Inserisci un numero intero positivo valido';

  @override
  String get authSaveAndEnterAppButton => 'Salva ed entra';

  @override
  String get authSelectDobError => 'Seleziona la tua data di nascita';

  @override
  String get okButton => 'OK';

  @override
  String get authCompleteProfileSetupSubtitle =>
      'Completa la configurazione del tuo profilo paziente';

  @override
  String get todayAgendaError =>
      'Non siamo riusciti a caricare il tuo piano di cura. Controlla la connessione e riprova.';

  @override
  String get todayRetry => 'Riprova';

  @override
  String todayStaleBanner(String relativeTime) {
    return 'Aggiornato $relativeTime — sincronizzazione dell\'ultimo piano…';
  }

  @override
  String get todayOfflineBanner =>
      'Registrazione salvata sul tuo dispositivo. Avviseremo il tuo team di cura quando sarai di nuovo online.';

  @override
  String get todayPlanUpdatedBanner =>
      'Il tuo team di cura ha aggiornato i tuoi farmaci prescritti.';

  @override
  String get todayTimezoneAdjusted =>
      'Gli orari dei promemoria sono stati adattati al tuo fuso orario attuale.';

  @override
  String get todayLogUndo => 'Annulla';

  @override
  String todayLoggedAs(String status) {
    return 'Registrato come $status.';
  }

  @override
  String get todayLogRollbackError =>
      'Non siamo riusciti a salvare la registrazione. La dose risulta non registrata — tocca per riprovare.';

  @override
  String todayCorrectionTitle(String status, String time) {
    return 'Registrato come $status alle $time. Vuoi correggere cosa è successo?';
  }

  @override
  String get todayCorrectionKeep => 'Lascia così';

  @override
  String get todaySkipPrompt => 'Hai sintomi gravi o preoccupanti?';

  @override
  String get todaySkipPromptYes => 'Sì';

  @override
  String get todaySkipPromptNo => 'No, sto bene';

  @override
  String get todayNoEmergencyContact =>
      'Nessun contatto di emergenza registrato — contatta la tua clinica.';

  @override
  String get todayGroupMorning => 'Mattina';

  @override
  String get todayGroupMidday => 'Mezzogiorno';

  @override
  String get todayGroupEvening => 'Sera';

  @override
  String get todayGroupBedtime => 'Notte';

  @override
  String get todayPrnSection => 'Al bisogno';

  @override
  String get todayDueNow => 'Da prendere ora';

  @override
  String get todayUpcoming => 'In arrivo';

  @override
  String todayScheduledFor(String time) {
    return 'Programmata $time';
  }

  @override
  String todaySlotTimes(String scheduledTime, String loggedTime) {
    return 'Programmata per $scheduledTime — Registrata alle $loggedTime.';
  }

  @override
  String todayPreviouslyLogged(String status) {
    return 'Precedente: $status';
  }

  @override
  String get todaySyncPending => 'Salvato sul dispositivo';

  @override
  String todayCelebrationNext(String weekday, String time) {
    return 'Prossima dose: $weekday alle $time';
  }

  @override
  String get todayCelebration =>
      'Tutte le dosi di oggi completate! Grazie per aver aggiornato il tuo team di cura.';

  @override
  String todayProgressDoses(int taken, int total) {
    return '$taken/$total dosi';
  }

  @override
  String get todayPullToRefreshHint =>
      'Scorri verso il basso per controllare di nuovo.';

  @override
  String get todayOpenSettings => 'Apri Impostazioni';

  @override
  String get remindersOffBanner =>
      'I promemoria sono disattivati. Puoi registrare le dosi manualmente — oppure attivare i promemoria nelle Impostazioni.';

  @override
  String get emptyPlanMessage =>
      'Il tuo team di cura sta preparando il tuo piano. Non devi fare nulla per ora.';

  @override
  String get checkinErrorRetry =>
      'Non siamo riusciti a salvare il tuo check-in. Tocca per riprovare.';

  @override
  String get todayTimeJustNow => 'proprio ora';

  @override
  String todayTimeMinutesAgo(int count) {
    return '$count min fa';
  }

  @override
  String todayTimeHoursAgo(int count) {
    return '$count h fa';
  }

  @override
  String get emergencyBannerTitle => 'Avviso di Emergenza Rosso';

  @override
  String get emergencyCall911 => 'Chiama Emergenza (112)';

  @override
  String emergencyCallClinic(String phone) {
    return 'Chiama Reparto ($phone)';
  }

  @override
  String get emergencyCallClinicFallback => 'Chiama Reparto';

  @override
  String get pillFormCapsule => 'Capsula';

  @override
  String get pillFormTablet => 'Compressa';

  @override
  String get pillFormLiquid => 'Liquido';
}

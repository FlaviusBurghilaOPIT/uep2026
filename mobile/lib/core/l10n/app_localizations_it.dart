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
      'Check-in giornaliero registrato. Grazie per aver aggiornato il tuo team medico.';

  @override
  String get assistantTitle => 'Assistente AI';

  @override
  String get assistantGuardrailBanner =>
      'Assistente AI • Solo informativo, mai diagnostico';

  @override
  String get typeMessagePlaceholder => 'Scrivi la tua domanda...';

  @override
  String get chipMedicationSideEffects => 'Effetti collaterali dei farmaci';

  @override
  String get chipWoundCareTips => 'Consigli per la cura delle ferite';

  @override
  String get chipPhysioTargets => 'Obiettivi di fisioterapia';

  @override
  String get chipEmergencyContact => 'Contatto di emergenza';

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
}

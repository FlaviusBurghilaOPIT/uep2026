// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Remote CarePro';

  @override
  String get loginTitle => 'Bon retour';

  @override
  String get loginEmailLabel => 'Adresse e-mail';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get onboardingTitle => 'Vous avez été invité(e)';

  @override
  String get onboardingSubtitle =>
      'Entrez votre e-mail et le code envoyé par votre médecin.';

  @override
  String get inviteCodeLabel => 'Code d\'invitation';

  @override
  String get verifyButton => 'Vérifier le code';

  @override
  String get completeSetupButton => 'Terminer la configuration';

  @override
  String get todayTitle => 'Aujourd\'hui';

  @override
  String medicationCardTitle(String medicationName) {
    return 'Prendre $medicationName';
  }

  @override
  String doseAmount(String doseAmount) {
    return 'Dose $doseAmount';
  }

  @override
  String scheduledAt(String scheduledTime) {
    return 'Prévu à $scheduledTime';
  }

  @override
  String get doseStatusTaken => 'Pris';

  @override
  String get doseStatusMissed => 'Manqué';

  @override
  String get doseStatusSkipped => 'Ignoré';

  @override
  String get takeDoseButton => 'Prendre la dose';

  @override
  String get skipDoseButton => 'Ignorer';

  @override
  String get missedDoseButton => 'Manqué';

  @override
  String get checkinTitle => 'Suivi quotidien';

  @override
  String get symptomQuestion => 'Comment vous sentez-vous aujourd\'hui ?';

  @override
  String get severityMild => 'Léger';

  @override
  String get severityModerate => 'Modéré';

  @override
  String get severitySevere => 'Sévère';

  @override
  String get submitCheckinButton => 'Soumettre';

  @override
  String get assistantTitle => 'Assistant IA';

  @override
  String get assistantGuardrailBanner =>
      'Assistant IA • Informations uniquement, jamais de diagnostic';

  @override
  String get typeMessagePlaceholder => 'Écrivez votre question...';

  @override
  String get chipMedicationSideEffects => 'Effets secondaires des médicaments';

  @override
  String get chipWoundCareTips => 'Conseils de soins des plaies';

  @override
  String get chipPhysioTargets => 'Objectifs de physiothérapie';

  @override
  String get chipEmergencyContact => 'Contact d\'urgence';

  @override
  String get profileTitle => 'Profil';

  @override
  String get languageSectionTitle => 'Langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageItalian => 'Italien';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get signOutButton => 'Se déconnecter';

  @override
  String get notificationReminderTitle => 'Rappel de médicament';

  @override
  String notificationReminderBody(String medicationName, String doseAmount) {
    return 'Heure de prendre $medicationName — $doseAmount';
  }

  @override
  String get notificationActionTake => 'Prendre la dose';

  @override
  String get notificationActionSnooze => 'Répéter 15 min';

  @override
  String get errorGeneric => 'Un problème est survenu. Veuillez réessayer.';

  @override
  String get errorNetwork => 'Pas de connexion. Vérifiez votre accès internet.';

  @override
  String get loadingLabel => 'Chargement...';
}

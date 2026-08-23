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
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

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
  String get checkinGreatOption => 'Je me sens très bien 🙂';

  @override
  String get checkinOkOption => 'Je me sens correct 😐';

  @override
  String get checkinNotGreatOption => 'Je ne me sens pas très bien 😟';

  @override
  String get checkinBadOption => 'Je me sens mal 😣';

  @override
  String get checkinSuccessBanner =>
      'Suivi quotidien enregistré. Merci d\'avoir informé votre équipe soignante.';

  @override
  String get assistantTitle => 'Assistant de l\'Équipe Soignante';

  @override
  String get assistantGuardrailBanner =>
      'Assistant de l\'Équipe Soignante • Informations uniquement, jamais de diagnostic';

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
  String get emergencyCallCta => 'Appeler le contact d\'urgence';

  @override
  String emergencyCallCtaWithPhone(String phone) {
    return 'Appeler le contact d\'urgence ($phone)';
  }

  @override
  String get emergencyWarningTitle =>
      'Je ne peux pas donner de conseils sur les changements de dose ou les symptômes urgents';

  @override
  String get fdaSafetyAlertTitle =>
      'Informations officielles de sécurité des médicaments de la FDA';

  @override
  String get fdaSourceLive => '📋 Source : Informations officielles de la FDA';

  @override
  String get fdaSourceFixture => '📋 Source : Cache réglementaire';

  @override
  String fdaRetrievedTimestamp(String date) {
    return 'Récupéré : $date';
  }

  @override
  String get fdaWarningMessage =>
      'Nouvelle alerte d\'interaction médicamenteuse pour l\'Amoxicilline. Appuyez sur info pour en savoir plus.';

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
  String get notificationPermissionRationale =>
      'Activez les notifications pour recevoir des rappels de médicaments au bon moment.';

  @override
  String get errorGeneric => 'Un problème est survenu. Veuillez réessayer.';

  @override
  String get errorNetwork => 'Pas de connexion. Vérifiez votre accès internet.';

  @override
  String get loadingLabel => 'Chargement...';

  @override
  String get navTabToday => 'Aujourd\'hui';

  @override
  String get navTabMedications => 'Médicaments';

  @override
  String get navTabRecovery => 'Rétablissement';

  @override
  String get navTabAssistant => 'Assistant';

  @override
  String get navTabProfile => 'Profil';

  @override
  String get medicationsScreenTitle => 'Médicaments';

  @override
  String medCardDoseLabel(String dose) {
    return 'Dose : $dose';
  }

  @override
  String medCardScheduleLabel(String schedule) {
    return 'Horaire : $schedule';
  }

  @override
  String medCardDurationLabel(String duration) {
    return 'Durée : $duration';
  }

  @override
  String get medCardNotesHeader => 'Instructions du médecin :';

  @override
  String get medCardReadOnlyBadge =>
      '🔒 Prescrit par l\'équipe soignante — Lecture seule';

  @override
  String get medicationsEmptyState =>
      'Aucun médicament actif dans votre plan de soins pour le moment.';

  @override
  String get frequencyQD => 'Une fois par jour';

  @override
  String get frequencyBID => 'Deux fois par jour';

  @override
  String get frequencyTID => 'Trois fois par jour';

  @override
  String get frequencyQID => 'Quatre fois par jour';

  @override
  String get frequencyPRN => 'Au besoin';

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
      'Nous n\'avons pas pu charger votre plan de soins. Vérifiez votre connexion et réessayez.';

  @override
  String get todayRetry => 'Réessayer';

  @override
  String todayStaleBanner(String relativeTime) {
    return 'Mis à jour $relativeTime — synchronisation du dernier plan…';
  }

  @override
  String get todayOfflineBanner =>
      'Enregistrement sauvegardé sur votre appareil. Nous informerons votre équipe soignante lorsque vous serez de nouveau en ligne.';

  @override
  String get todayPlanUpdatedBanner =>
      'Votre équipe soignante a mis à jour vos médicaments prescrits.';

  @override
  String get todayTimezoneAdjusted =>
      'Les horaires de vos rappels ont été adaptés à votre fuseau horaire actuel.';

  @override
  String get todayLogUndo => 'Annuler';

  @override
  String todayLoggedAs(String status) {
    return 'Enregistré comme $status.';
  }

  @override
  String get todayLogRollbackError =>
      'Nous n\'avons pas pu enregistrer ce suivi. Votre dose apparaît comme non enregistrée — touchez pour réessayer.';

  @override
  String todayCorrectionTitle(String status, String time) {
    return 'Enregistré comme $status à $time. Corriger ce qui s\'est passé ?';
  }

  @override
  String get todayCorrectionKeep => 'Garder tel quel';

  @override
  String get todaySkipPrompt =>
      'Ressentez-vous des symptômes graves ou inquiétants ?';

  @override
  String get todaySkipPromptYes => 'Oui';

  @override
  String get todaySkipPromptNo => 'Non, ça va';

  @override
  String get todayNoEmergencyContact =>
      'Aucun contact d\'urgence enregistré — contactez votre clinique.';

  @override
  String get todayGroupMorning => 'Matin';

  @override
  String get todayGroupMidday => 'Midi';

  @override
  String get todayGroupEvening => 'Soir';

  @override
  String get todayGroupBedtime => 'Coucher';

  @override
  String get todayPrnSection => 'Si besoin';

  @override
  String get todayDueNow => 'À prendre maintenant';

  @override
  String get todayUpcoming => 'À venir';

  @override
  String todayScheduledFor(String time) {
    return 'Prévu $time';
  }

  @override
  String todaySlotTimes(String scheduledTime, String loggedTime) {
    return 'Prévu pour $scheduledTime — Enregistré à $loggedTime.';
  }

  @override
  String todayPreviouslyLogged(String status) {
    return 'Précédent : $status';
  }

  @override
  String get todaySyncPending => 'Enregistré sur l\'appareil';

  @override
  String todayCelebrationNext(String weekday, String time) {
    return 'Prochaine dose : $weekday à $time';
  }

  @override
  String get todayCelebration =>
      'Toutes les doses du jour sont terminées ! Merci de tenir votre équipe soignante informée.';

  @override
  String todayProgressDoses(int taken, int total) {
    return '$taken/$total doses';
  }

  @override
  String get todayPullToRefreshHint =>
      'Tirez vers le bas pour vérifier à nouveau.';

  @override
  String get todayOpenSettings => 'Ouvrir les réglages';

  @override
  String get remindersOffBanner =>
      'Les rappels sont désactivés. Vous pouvez enregistrer vos doses manuellement — ou activer les rappels dans les réglages.';

  @override
  String get emptyPlanMessage =>
      'Votre équipe soignante prépare votre plan de soins. Vous n\'avez rien à faire pour le moment.';

  @override
  String get checkinErrorRetry =>
      'Nous n\'avons pas pu enregistrer votre bilan. Touchez pour réessayer.';

  @override
  String get todayTimeJustNow => 'à l\'instant';

  @override
  String todayTimeMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String todayTimeHoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String get emergencyBannerTitle => 'Alerte d\'Urgence Rouge';

  @override
  String get emergencyCall911 => 'Appeler les Urgences (15)';

  @override
  String emergencyCallClinic(String phone) {
    return 'Appeler l\'Équipe ($phone)';
  }

  @override
  String get emergencyCallClinicFallback => 'Appeler l\'Équipe';

  @override
  String get pillFormCapsule => 'Gélule';

  @override
  String get pillFormTablet => 'Comprimé';

  @override
  String get pillFormLiquid => 'Liquide';
}

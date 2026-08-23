// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Remote CarePro';

  @override
  String get loginTitle => 'Bienvenido de nuevo';

  @override
  String get loginEmailLabel => 'Correo electrónico';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get onboardingTitle => 'Has sido invitado';

  @override
  String get onboardingSubtitle =>
      'Ingresa tu correo y el código enviado por tu médico.';

  @override
  String get inviteCodeLabel => 'Código de invitación';

  @override
  String get verifyButton => 'Verificar código';

  @override
  String get completeSetupButton => 'Completar configuración';

  @override
  String get todayTitle => 'Hoy';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String medicationCardTitle(String medicationName) {
    return 'Toma $medicationName';
  }

  @override
  String doseAmount(String doseAmount) {
    return 'Dosis $doseAmount';
  }

  @override
  String scheduledAt(String scheduledTime) {
    return 'Programado a las $scheduledTime';
  }

  @override
  String get doseStatusTaken => 'Tomado';

  @override
  String get doseStatusMissed => 'Omitido';

  @override
  String get doseStatusSkipped => 'Saltado';

  @override
  String get takeDoseButton => 'Tomar dosis';

  @override
  String get skipDoseButton => 'Saltar';

  @override
  String get missedDoseButton => 'Omitido';

  @override
  String get checkinTitle => 'Control diario';

  @override
  String get symptomQuestion => '¿Cómo te sientes hoy?';

  @override
  String get severityMild => 'Leve';

  @override
  String get severityModerate => 'Moderado';

  @override
  String get severitySevere => 'Grave';

  @override
  String get submitCheckinButton => 'Enviar';

  @override
  String get checkinGreatOption => 'Me siento genial 🙂';

  @override
  String get checkinOkOption => 'Me siento bien 😐';

  @override
  String get checkinNotGreatOption => 'No me siento muy bien 😟';

  @override
  String get checkinBadOption => 'Me siento mal 😣';

  @override
  String get checkinSuccessBanner =>
      'Control diario registrado. Gracias por actualizar a tu equipo médico.';

  @override
  String get assistantTitle => 'Asistente del Equipo Médico';

  @override
  String get assistantGuardrailBanner =>
      'Asistente del Equipo Médico • Solo informativo, nunca diagnóstico';

  @override
  String get typeMessagePlaceholder => 'Escribe tu pregunta...';

  @override
  String get chipMedicationSideEffects => 'Efectos secundarios de medicamentos';

  @override
  String get chipWoundCareTips => 'Consejos para el cuidado de heridas';

  @override
  String get chipPhysioTargets => 'Objetivos de fisioterapia';

  @override
  String get chipEmergencyContact => 'Contacto de emergencia';

  @override
  String get emergencyCallCta => 'Llamar al contacto de emergencia';

  @override
  String emergencyCallCtaWithPhone(String phone) {
    return 'Llamar al contacto de emergencia ($phone)';
  }

  @override
  String get emergencyWarningTitle =>
      'No puedo asesorar sobre cambios de dosis o síntomas urgentes';

  @override
  String get fdaSafetyAlertTitle =>
      'Información oficial de seguridad de medicamentos de la FDA';

  @override
  String get fdaSourceLive => '📋 Fuente: Información oficial de la FDA';

  @override
  String get fdaSourceFixture => '📋 Fuente: Caché reglamentario';

  @override
  String fdaRetrievedTimestamp(String date) {
    return 'Obtenido: $date';
  }

  @override
  String get fdaWarningMessage =>
      'Nueva advertencia de interacción de medicamentos para Amoxicilina. Toca para saber más.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get signOutButton => 'Cerrar sesión';

  @override
  String get notificationReminderTitle => 'Recordatorio de medicamento';

  @override
  String notificationReminderBody(String medicationName, String doseAmount) {
    return 'Hora de tomar $medicationName — $doseAmount';
  }

  @override
  String get notificationActionTake => 'Tomar dosis';

  @override
  String get notificationActionSnooze => 'Posponer 15 min';

  @override
  String get notificationPermissionRationale =>
      'Active las notificaciones para recibir recordatorios de medicamentos a tiempo.';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorNetwork => 'Sin conexión. Comprueba tu internet.';

  @override
  String get loadingLabel => 'Cargando...';

  @override
  String get navTabToday => 'Hoy';

  @override
  String get navTabMedications => 'Medicamentos';

  @override
  String get navTabRecovery => 'Recuperación';

  @override
  String get navTabAssistant => 'Asistente';

  @override
  String get navTabProfile => 'Perfil';

  @override
  String get medicationsScreenTitle => 'Medicamentos';

  @override
  String medCardDoseLabel(String dose) {
    return 'Dosis: $dose';
  }

  @override
  String medCardScheduleLabel(String schedule) {
    return 'Horario: $schedule';
  }

  @override
  String medCardDurationLabel(String duration) {
    return 'Duración: $duration';
  }

  @override
  String get medCardNotesHeader => 'Instrucciones del médico:';

  @override
  String get medCardReadOnlyBadge =>
      '🔒 Recetado por el equipo médico — Solo lectura';

  @override
  String get medicationsEmptyState =>
      'Aún no hay medicamentos activos en tu plan de cuidado.';

  @override
  String get frequencyQD => 'Una vez al día';

  @override
  String get frequencyBID => 'Dos veces al día';

  @override
  String get frequencyTID => 'Tres veces al día';

  @override
  String get frequencyQID => 'Cuatro veces al día';

  @override
  String get frequencyPRN => 'Según sea necesario';

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
      'No pudimos cargar tu plan de cuidados. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get todayRetry => 'Reintentar';

  @override
  String todayStaleBanner(String relativeTime) {
    return 'Actualizado $relativeTime — sincronizando el plan más reciente…';
  }

  @override
  String get todayOfflineBanner =>
      'Registro guardado en tu dispositivo. Avisaremos a tu equipo de cuidados cuando vuelvas a estar en línea.';

  @override
  String get todayPlanUpdatedBanner =>
      'Tu equipo de cuidados actualizó tus medicamentos recetados.';

  @override
  String get todayTimezoneAdjusted =>
      'Los horarios de tus recordatorios se ajustaron a tu zona horaria actual.';

  @override
  String get todayLogUndo => 'Deshacer';

  @override
  String todayLoggedAs(String status) {
    return 'Registrado como $status.';
  }

  @override
  String get todayLogRollbackError =>
      'No pudimos guardar ese registro. Tu dosis aparece como no registrada — toca para intentarlo de nuevo.';

  @override
  String todayCorrectionTitle(String status, String time) {
    return 'Registrado como $status a las $time. ¿Quieres corregir lo que pasó?';
  }

  @override
  String get todayCorrectionKeep => 'Dejar como está';

  @override
  String get todaySkipPrompt => '¿Tienes síntomas graves o preocupantes?';

  @override
  String get todaySkipPromptYes => 'Sí';

  @override
  String get todaySkipPromptNo => 'No, estoy bien';

  @override
  String get todayNoEmergencyContact =>
      'No hay contacto de emergencia registrado — contacta a tu clínica.';

  @override
  String get todayGroupMorning => 'Mañana';

  @override
  String get todayGroupMidday => 'Mediodía';

  @override
  String get todayGroupEvening => 'Tarde';

  @override
  String get todayGroupBedtime => 'Noche';

  @override
  String get todayPrnSection => 'Según sea necesario';

  @override
  String get todayDueNow => 'Toca ahora';

  @override
  String get todayUpcoming => 'Próximo';

  @override
  String todayScheduledFor(String time) {
    return 'Programada $time';
  }

  @override
  String todaySlotTimes(String scheduledTime, String loggedTime) {
    return 'Programada para $scheduledTime — Registrada a las $loggedTime.';
  }

  @override
  String todayPreviouslyLogged(String status) {
    return 'Anterior: $status';
  }

  @override
  String get todaySyncPending => 'Guardado en el dispositivo';

  @override
  String todayCelebrationNext(String weekday, String time) {
    return 'Próxima dosis: $weekday a las $time';
  }

  @override
  String get todayCelebration =>
      '¡Todas las dosis de hoy completadas! Gracias por mantener informado a tu equipo de cuidados.';

  @override
  String todayProgressDoses(int taken, int total) {
    return '$taken/$total dosis';
  }

  @override
  String get todayPullToRefreshHint =>
      'Desliza hacia abajo para comprobar de nuevo.';

  @override
  String get todayOpenSettings => 'Abrir Ajustes';

  @override
  String get remindersOffBanner =>
      'Los recordatorios están desactivados. Puedes registrar dosis manualmente — o activar los recordatorios en Ajustes.';

  @override
  String get emptyPlanMessage =>
      'Tu equipo de cuidados está preparando tu plan. No necesitas hacer nada por ahora.';

  @override
  String get checkinErrorRetry =>
      'No pudimos guardar tu registro diario. Toca para intentarlo de nuevo.';

  @override
  String get todayTimeJustNow => 'ahora mismo';

  @override
  String todayTimeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String todayTimeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String get emergencyBannerTitle => 'Aviso de Emergencia Rojo';

  @override
  String get emergencyCall911 => 'Llamar a Emergencias (911)';

  @override
  String emergencyCallClinic(String phone) {
    return 'Llamar al Equipo ($phone)';
  }

  @override
  String get emergencyCallClinicFallback => 'Llamar al Equipo';

  @override
  String get pillFormCapsule => 'Cápsula';

  @override
  String get pillFormTablet => 'Comprimido';

  @override
  String get pillFormLiquid => 'Líquido';
}

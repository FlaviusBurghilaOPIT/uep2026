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
  String get assistantTitle => 'Asistente IA';

  @override
  String get assistantGuardrailBanner =>
      'Asistente IA • Solo informativo, nunca diagnóstico';

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
}

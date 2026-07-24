import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote CarePro'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and the code your clinician sent you.'**
  String get onboardingSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get inviteCodeLabel;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyButton;

  /// No description provided for @completeSetupButton.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetupButton;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @medicationCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Take {medicationName}'**
  String medicationCardTitle(String medicationName);

  /// No description provided for @doseAmount.
  ///
  /// In en, this message translates to:
  /// **'{doseAmount} dose'**
  String doseAmount(String doseAmount);

  /// No description provided for @scheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at {scheduledTime}'**
  String scheduledAt(String scheduledTime);

  /// No description provided for @doseStatusTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get doseStatusTaken;

  /// No description provided for @doseStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get doseStatusMissed;

  /// No description provided for @doseStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get doseStatusSkipped;

  /// No description provided for @takeDoseButton.
  ///
  /// In en, this message translates to:
  /// **'Take Dose'**
  String get takeDoseButton;

  /// No description provided for @skipDoseButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipDoseButton;

  /// No description provided for @missedDoseButton.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missedDoseButton;

  /// No description provided for @checkinTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get checkinTitle;

  /// No description provided for @symptomQuestion.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get symptomQuestion;

  /// No description provided for @severityMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severityMild;

  /// No description provided for @severityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severitySevere;

  /// No description provided for @submitCheckinButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitCheckinButton;

  /// No description provided for @checkinGreatOption.
  ///
  /// In en, this message translates to:
  /// **'Feeling Great 🙂'**
  String get checkinGreatOption;

  /// No description provided for @checkinOkOption.
  ///
  /// In en, this message translates to:
  /// **'Feeling Ok 😐'**
  String get checkinOkOption;

  /// No description provided for @checkinNotGreatOption.
  ///
  /// In en, this message translates to:
  /// **'Not Feeling Great 😟'**
  String get checkinNotGreatOption;

  /// No description provided for @checkinBadOption.
  ///
  /// In en, this message translates to:
  /// **'Feeling Unwell 😣'**
  String get checkinBadOption;

  /// No description provided for @checkinSuccessBanner.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in logged. Thank you for updating your care team.'**
  String get checkinSuccessBanner;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Care Team Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantGuardrailBanner.
  ///
  /// In en, this message translates to:
  /// **'Care Team Assistant • Informational only, never diagnostic'**
  String get assistantGuardrailBanner;

  /// No description provided for @typeMessagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your question...'**
  String get typeMessagePlaceholder;

  /// No description provided for @chipMedicationSideEffects.
  ///
  /// In en, this message translates to:
  /// **'Medication side effects'**
  String get chipMedicationSideEffects;

  /// No description provided for @chipWoundCareTips.
  ///
  /// In en, this message translates to:
  /// **'Wound care tips'**
  String get chipWoundCareTips;

  /// No description provided for @chipPhysioTargets.
  ///
  /// In en, this message translates to:
  /// **'Physio targets'**
  String get chipPhysioTargets;

  /// No description provided for @chipEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get chipEmergencyContact;

  /// No description provided for @emergencyCallCta.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency Contact'**
  String get emergencyCallCta;

  /// No description provided for @emergencyCallCtaWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency Contact ({phone})'**
  String emergencyCallCtaWithPhone(String phone);

  /// No description provided for @emergencyWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'I Cannot Advise on Dose Changes or Urgent Symptoms'**
  String get emergencyWarningTitle;

  /// No description provided for @fdaSafetyAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Official FDA Drug Safety Info'**
  String get fdaSafetyAlertTitle;

  /// No description provided for @fdaSourceLive.
  ///
  /// In en, this message translates to:
  /// **'📋 Source: Official FDA Drug Safety Info'**
  String get fdaSourceLive;

  /// No description provided for @fdaSourceFixture.
  ///
  /// In en, this message translates to:
  /// **'📋 Source: Regulatory Cache'**
  String get fdaSourceFixture;

  /// No description provided for @fdaRetrievedTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Retrieved: {date}'**
  String fdaRetrievedTimestamp(String date);

  /// No description provided for @fdaWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'New drug interaction warning for Amoxicillin. Tap info to learn more.'**
  String get fdaWarningMessage;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalian;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutButton;

  /// No description provided for @notificationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminder'**
  String get notificationReminderTitle;

  /// No description provided for @notificationReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time to take {medicationName} — {doseAmount}'**
  String notificationReminderBody(String medicationName, String doseAmount);

  /// No description provided for @notificationActionTake.
  ///
  /// In en, this message translates to:
  /// **'Take Dose'**
  String get notificationActionTake;

  /// No description provided for @notificationActionSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze 15 min'**
  String get notificationActionSnooze;

  /// No description provided for @notificationPermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive medication reminders at the right time.'**
  String get notificationPermissionRationale;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please check your internet.'**
  String get errorNetwork;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @navTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navTabToday;

  /// No description provided for @navTabMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get navTabMedications;

  /// No description provided for @navTabRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get navTabRecovery;

  /// No description provided for @navTabAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navTabAssistant;

  /// No description provided for @navTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navTabProfile;

  /// No description provided for @medicationsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsScreenTitle;

  /// No description provided for @medCardDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose: {dose}'**
  String medCardDoseLabel(String dose);

  /// No description provided for @medCardScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule: {schedule}'**
  String medCardScheduleLabel(String schedule);

  /// No description provided for @medCardDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String medCardDurationLabel(String duration);

  /// No description provided for @medCardNotesHeader.
  ///
  /// In en, this message translates to:
  /// **'Clinician Instructions:'**
  String get medCardNotesHeader;

  /// No description provided for @medCardReadOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'🔒 Prescribed by Care Team — Read Only'**
  String get medCardReadOnlyBadge;

  /// No description provided for @medicationsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No active medications on your care plan yet.'**
  String get medicationsEmptyState;

  /// No description provided for @frequencyQD.
  ///
  /// In en, this message translates to:
  /// **'Once daily'**
  String get frequencyQD;

  /// No description provided for @frequencyBID.
  ///
  /// In en, this message translates to:
  /// **'Twice daily'**
  String get frequencyBID;

  /// No description provided for @frequencyTID.
  ///
  /// In en, this message translates to:
  /// **'Three times daily'**
  String get frequencyTID;

  /// No description provided for @frequencyQID.
  ///
  /// In en, this message translates to:
  /// **'Four times daily'**
  String get frequencyQID;

  /// No description provided for @frequencyPRN.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get frequencyPRN;

  /// No description provided for @authEmailLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authEmailLoginTitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get authRequiredError;

  /// No description provided for @authInvalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authInvalidEmailError;

  /// No description provided for @authSendOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get authSendOtpButton;

  /// No description provided for @authErrorSendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Error sending OTP: {error}'**
  String authErrorSendingOtp(String error);

  /// No description provided for @authEnterInvitationCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Invitation Code'**
  String get authEnterInvitationCodeTitle;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get authWelcomeTitle;

  /// No description provided for @authInvitationCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your invitation code to continue.'**
  String get authInvitationCodeSubtitle;

  /// No description provided for @authInvitationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code'**
  String get authInvitationCodeLabel;

  /// No description provided for @authInvalidInvitationCodeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid invitation code'**
  String get authInvalidInvitationCodeError;

  /// No description provided for @authContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinueButton;

  /// No description provided for @authEnterOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get authEnterOtpTitle;

  /// No description provided for @authVerifyIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get authVerifyIdentityTitle;

  /// No description provided for @authOtpSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code sent to {email}.'**
  String authOtpSentToEmail(String email);

  /// No description provided for @authOtpSentToEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code sent to your email.'**
  String get authOtpSentToEmailFallback;

  /// No description provided for @authOtpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get authOtpCodeLabel;

  /// No description provided for @authOtpCodeLengthError.
  ///
  /// In en, this message translates to:
  /// **'Code must be exactly 6 digits'**
  String get authOtpCodeLengthError;

  /// No description provided for @authOtpCodeNumericError.
  ///
  /// In en, this message translates to:
  /// **'Code must be numeric'**
  String get authOtpCodeNumericError;

  /// No description provided for @authVerifyAndLogInButton.
  ///
  /// In en, this message translates to:
  /// **'Verify and Log In'**
  String get authVerifyAndLogInButton;

  /// No description provided for @authProfileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Setup'**
  String get authProfileSetupTitle;

  /// No description provided for @authNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authNameLabel;

  /// No description provided for @authSurnameLabel.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get authSurnameLabel;

  /// No description provided for @authAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get authAgeLabel;

  /// No description provided for @authInvalidAgeError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive integer'**
  String get authInvalidAgeError;

  /// No description provided for @authSaveAndEnterAppButton.
  ///
  /// In en, this message translates to:
  /// **'Save and Enter App'**
  String get authSaveAndEnterAppButton;

  /// No description provided for @authSelectDobError.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get authSelectDobError;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @authCompleteProfileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your patient profile setup'**
  String get authCompleteProfileSetupSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

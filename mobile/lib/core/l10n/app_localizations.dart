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
  /// **'Enter your email and the code your care team sent you.'**
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
  /// **'Check-in received • Care team updated'**
  String get checkinSuccessBanner;

  /// No description provided for @checkinSuccessBannerWithPhysician.
  ///
  /// In en, this message translates to:
  /// **'Check-in received • {physician}\'s care team updated'**
  String checkinSuccessBannerWithPhysician(String physician);

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

  /// No description provided for @chipSwellingNormal.
  ///
  /// In en, this message translates to:
  /// **'Is mild swelling normal?'**
  String get chipSwellingNormal;

  /// No description provided for @chipShowering.
  ///
  /// In en, this message translates to:
  /// **'When can I shower?'**
  String get chipShowering;

  /// No description provided for @chipMedicationInstructions.
  ///
  /// In en, this message translates to:
  /// **'Medication instructions'**
  String get chipMedicationInstructions;

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
  /// **'Care Team Instructions:'**
  String get medCardNotesHeader;

  /// No description provided for @medicationsCareTeamNote.
  ///
  /// In en, this message translates to:
  /// **'Prescribed by your care team — read-only'**
  String get medicationsCareTeamNote;

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
  /// **'Unable to send verification code. Check your connection and try again.'**
  String get authErrorSendingOtp;

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

  /// No description provided for @authNewPatientClinicInvitation.
  ///
  /// In en, this message translates to:
  /// **'New Patient? Enter Clinic Invitation'**
  String get authNewPatientClinicInvitation;

  /// No description provided for @authSignInWithOneTimeCode.
  ///
  /// In en, this message translates to:
  /// **'Sign in with One-Time Code'**
  String get authSignInWithOneTimeCode;

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

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get authResendCode;

  /// No description provided for @authResendCodeCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend Code in {seconds}s'**
  String authResendCodeCountdown(int seconds);

  /// No description provided for @authCodeResentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Code resent to {email}'**
  String authCodeResentSnackbar(String email);

  /// No description provided for @authCodeResentSnackbarFallback.
  ///
  /// In en, this message translates to:
  /// **'Code resent'**
  String get authCodeResentSnackbarFallback;

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

  /// No description provided for @todayAgendaError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your care plan. Check your connection and try again.'**
  String get todayAgendaError;

  /// No description provided for @todayRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get todayRetry;

  /// No description provided for @todayStaleBanner.
  ///
  /// In en, this message translates to:
  /// **'Updated {relativeTime} — syncing latest plan…'**
  String todayStaleBanner(String relativeTime);

  /// No description provided for @todayOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Will sync automatically once reconnected.'**
  String get todayOfflineBanner;

  /// No description provided for @todayPlanUpdatedBanner.
  ///
  /// In en, this message translates to:
  /// **'Your care team updated your prescribed medications.'**
  String get todayPlanUpdatedBanner;

  /// No description provided for @todayTimezoneAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Your reminder times have adjusted to your current time zone.'**
  String get todayTimezoneAdjusted;

  /// No description provided for @todayLogUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get todayLogUndo;

  /// No description provided for @todayLoggedAs.
  ///
  /// In en, this message translates to:
  /// **'Logged as {status}.'**
  String todayLoggedAs(String status);

  /// No description provided for @todayLogRollbackError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that log. Your dose shows as unlogged — tap to try again.'**
  String get todayLogRollbackError;

  /// No description provided for @todayCorrectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Logged as {status} at {time}. Change what happened?'**
  String todayCorrectionTitle(String status, String time);

  /// No description provided for @todayCorrectionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep as is'**
  String get todayCorrectionKeep;

  /// No description provided for @todaySkipPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you experiencing severe or troubling symptoms?'**
  String get todaySkipPrompt;

  /// No description provided for @todaySkipPromptYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get todaySkipPromptYes;

  /// No description provided for @todaySkipPromptNo.
  ///
  /// In en, this message translates to:
  /// **'No, I\'m okay'**
  String get todaySkipPromptNo;

  /// No description provided for @todayNoEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'No emergency contact on file — contact your clinic.'**
  String get todayNoEmergencyContact;

  /// No description provided for @todayGroupMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get todayGroupMorning;

  /// No description provided for @todayGroupMidday.
  ///
  /// In en, this message translates to:
  /// **'Midday'**
  String get todayGroupMidday;

  /// No description provided for @todayGroupEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get todayGroupEvening;

  /// No description provided for @todayGroupBedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get todayGroupBedtime;

  /// No description provided for @todayPrnSection.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get todayPrnSection;

  /// No description provided for @todayDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get todayDueNow;

  /// No description provided for @todayUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get todayUpcoming;

  /// No description provided for @todayScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {time}'**
  String todayScheduledFor(String time);

  /// No description provided for @todaySlotTimes.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {scheduledTime} — Logged at {loggedTime}.'**
  String todaySlotTimes(String scheduledTime, String loggedTime);

  /// No description provided for @todayPreviouslyLogged.
  ///
  /// In en, this message translates to:
  /// **'Previously: {status}'**
  String todayPreviouslyLogged(String status);

  /// No description provided for @todaySyncPending.
  ///
  /// In en, this message translates to:
  /// **'Saved on device'**
  String get todaySyncPending;

  /// No description provided for @todayCelebrationNext.
  ///
  /// In en, this message translates to:
  /// **'Next dose: {weekday} at {time}'**
  String todayCelebrationNext(String weekday, String time);

  /// No description provided for @todayCelebration.
  ///
  /// In en, this message translates to:
  /// **'All doses for today completed! Thank you for updating your care team.'**
  String get todayCelebration;

  /// No description provided for @todayProgressDoses.
  ///
  /// In en, this message translates to:
  /// **'{taken}/{total} doses'**
  String todayProgressDoses(int taken, int total);

  /// No description provided for @todayPullToRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Pull down to check again.'**
  String get todayPullToRefreshHint;

  /// No description provided for @todayOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get todayOpenSettings;

  /// No description provided for @remindersOffBanner.
  ///
  /// In en, this message translates to:
  /// **'Reminders are turned off. You can log doses manually — or turn reminders on in Settings.'**
  String get remindersOffBanner;

  /// No description provided for @emptyPlanMessage.
  ///
  /// In en, this message translates to:
  /// **'Your care team is preparing your care plan. No action is needed from you right now.'**
  String get emptyPlanMessage;

  /// No description provided for @checkinErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your check-in. Tap to try again.'**
  String get checkinErrorRetry;

  /// No description provided for @todayTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get todayTimeJustNow;

  /// No description provided for @todayTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String todayTimeMinutesAgo(int count);

  /// No description provided for @todayTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String todayTimeHoursAgo(int count);

  /// No description provided for @emergencyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Red Flag Warning'**
  String get emergencyBannerTitle;

  /// No description provided for @emergencyCall911.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency (911)'**
  String get emergencyCall911;

  /// No description provided for @emergencyCallClinic.
  ///
  /// In en, this message translates to:
  /// **'Call Care Team ({phone})'**
  String emergencyCallClinic(String phone);

  /// No description provided for @emergencyCallClinicFallback.
  ///
  /// In en, this message translates to:
  /// **'Call Care Team'**
  String get emergencyCallClinicFallback;

  /// No description provided for @pillFormCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get pillFormCapsule;

  /// No description provided for @pillFormTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get pillFormTablet;

  /// No description provided for @pillFormLiquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get pillFormLiquid;
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

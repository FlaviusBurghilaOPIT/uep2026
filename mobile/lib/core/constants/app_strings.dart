class AppStrings {
  AppStrings._();

  static const String appName = 'RemoteCare Pro';
  static const String appTagline =
      'Your post-surgery recovery, always in your pocket';

  static const String signInToAccount = 'Sign in to your account';
  static const String createAccount = 'Create account';
  static const String termsPrefix = 'By continuing you agree to our ';
  static const String terms = 'Terms';
  static const String and = ' and ';
  static const String privacyPolicy = 'Privacy Policy';

  static const String carousel1Title = 'Clinician-prescribed regimen';
  static const String carousel1Body =
      'Your medications come directly from your doctor — no manual entry, no guesswork.';
  static const String carousel2Title = 'Smart medication reminders';
  static const String carousel2Body =
      'Never miss a dose. Get timely reminders and log your medications in two taps.';
  static const String carousel3Title = 'AI-powered recovery assistant';
  static const String carousel3Body =
      'Ask questions about your recovery anytime. Context-aware, never diagnostic.';
  static const String carousel4Title = 'Progress tracking';
  static const String carousel4Body =
      'Track your recovery journey day by day. Your clinician monitors your progress remotely.';

  static const String hipaaAware = 'Secure Clinic Account';
  static const String awsBedrock = 'Care Team Assistant';
  static const String cognitoAuth = 'Secure Clinic Account';

  static const String welcomeBack = 'Welcome back';
  static const String signInSubtitle =
      'Sign in to continue your recovery journey';
  static const String email = 'EMAIL';
  static const String emailHint = 'sarah.mitchell@email.com';
  static const String password = 'PASSWORD';
  static const String passwordHint = 'Enter your password';
  static const String forgotPassword = 'Forgot password?';
  static const String signIn = 'Sign In';
  static const String orSignInWith = 'or sign in with';
  static const String noAccountYet = 'No account yet? ';
  static const String createOne = 'Create one';

  static const String createYourAccount = 'Create your account';
  static const String setupCredentials =
      'Set up your RemoteCare credentials';
  static const String fullName = 'FULL NAME';
  static const String fullNameHint = 'Sarah Mitchell';
  static const String emailAddress = 'EMAIL ADDRESS';
  static const String emailAddressHint = 'you@email.com';
  static const String phoneNumber = 'PHONE NUMBER';
  static const String phoneHint = '+1 (555) 000-0000';
  static const String passwordMinHint = 'Min. 8 characters';
  static const String continueText = 'Continue';

  static const String verifyEmail = 'Verify your email';
  static const String verificationSent =
      'We sent a 6-digit code to your email address';
  static const String enterCode = 'Enter verification code';
  static const String didntReceiveCode = "Didn't receive a code? ";
  static const String resendCode = 'Resend code';
  static const String verifyAndContinue = 'Verify & Continue';

  static const String yourHealthProfile = 'Your health profile';
  static const String personalizeExperience =
      'Help us personalize your experience';
  static const String dateOfBirth = 'DATE OF BIRTH';
  static const String dateHint = 'MM / DD / YYYY';
  static const String primaryCondition = 'PRIMARY CONDITION';
  static const String completeSetup = 'Complete Setup';
  static const String healthInfoEncrypted =
      'Your health information is encrypted and never shared without your consent. Compliant with secure clinic standards.';

  static const List<String> conditions = [
    'Post-surgical recovery',
    'Diabetes',
    'Hypertension',
    'COPD',
    'Heart failure',
    'Other',
  ];

  static const String cognitoSecurityPrefix =
      'Authentication secured by ';
  static const String cognitoSecurityBold = 'Secure Clinic Account';
  static const String cognitoSecuritySuffix =
      ', your credentials never touch our servers.';

  static const String remotecare = 'RemoteCare';
  static const String todaysMedications = "TODAY'S MEDICATIONS";
  static const String taken = 'Taken';
  static const String pending = 'Pending';
  static const String missed = 'Missed';
  static const String skip = 'Skip';
  static const String fdaSafetyAlert = 'Official FDA Drug Safety Info';
  static const String fdaSourceLive = '📋 Source: Official FDA Drug Safety Info';
  static const String fdaSourceFixture = '📋 Source: Regulatory Cache';
  static String fdaRetrievedTimestamp(String date) => 'Retrieved: $date';

  static const String navToday = 'Today';
  static const String navCheckIn = 'Check-In';
  static const String navAssistant = 'Assistant';
  static const String navRecovery = 'Recovery';

  static const String checkInTitle = 'Daily Check-In';
  static const String checkInSubtitle =
      'How are you feeling today?';
  static const String assistantTitle = 'Recovery Assistant';
  static const String assistantSubtitle =
      'Ask me anything about your recovery';
  static const String recoveryTitle = 'Recovery Progress';
  static const String recoverySubtitle =
      'Track your journey back to health';
}

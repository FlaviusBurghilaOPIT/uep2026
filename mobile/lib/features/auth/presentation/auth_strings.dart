/// UI copy for the hybrid auth + onboarding flow (WI 04).
///
/// Kept inside the auth feature so the new screens stay self-contained.
/// The two-method Welcome presentation and the first-run create-password
/// step follow the spec defaults (password primary; create-password
/// immediately after code verification, first-run only).
class AuthStrings {
  AuthStrings._();

  // --- Welcome (patient-facing auth) ---
  static const String welcomeTitle = 'Welcome back';
  static const String welcomeSubtitle =
      'Sign in to continue your recovery journey';
  static const String emailLabel = 'EMAIL';
  static const String emailHint = 'you@email.com';
  static const String passwordLabel = 'PASSWORD';
  static const String passwordHint = '••••••••';
  static const String signInButton = 'Sign In';
  static const String clinicianSignInButton = 'Sign In';
  static const String clinicInvitationButton =
      'Login with OTP code';
  static const String codeSignInLink = 'Sign in with One-Time Code';
  static const String invalidCredentials = 'Invalid email or password';

  // --- Request code (code fallback entry) ---
  static const String requestCodeTitle = 'Verify your email';
  static const String requestCodeSubtitle =
      'We\'ll email you a one-time code to sign in';
  static const String sendCodeButton = 'Send code';

  // --- Verify code ---
  static const String verifyCodeTitle = 'Enter the code';
  static String verifyCodeSubtitle(String email) =>
      'We sent a 6-digit code to $email';
  static const String codeLabel = 'VERIFICATION CODE';
  static const String codeHint = '000000';
  static const String verifyAndContinueButton = 'Verify & Continue';
  static const String resendCode = 'Resend Code';
  static String resendCodeCountdown(int seconds) => 'Resend Code in ${seconds}s';

  // --- Create password (first-run, immediately after code verification) ---
  static const String createPasswordTitle = 'Create a password';
  static const String createPasswordSubtitle =
      'Set a password so you can sign in faster next time';
  static const String confirmPasswordLabel = 'CONFIRM PASSWORD';
  static const String passwordMinLengthError =
      'Password must be at least 8 characters';
  static const String passwordMismatchError = 'Passwords do not match';
  static const String continueButton = 'Continue';

  // --- Onboarding profile (pre-filled editable name + DOB, patient phone) ---
  static const String profileTitle = 'Your health profile';
  static const String profileSubtitle = 'Confirm or correct your details';
  static const String fullNameLabel = 'FULL NAME';
  static const String fullNameHint = 'Your full name';
  static const String dateOfBirthLabel = 'DATE OF BIRTH';
  static const String dateOfBirthHint = 'MM / DD / YYYY';
  static const String phoneLabel = 'PHONE NUMBER';
  static const String phoneHint = '+1 (555) 000-0000';
  static const String completeSetupButton = 'Complete Setup';

  // --- Shared validation ---
  static const String requiredError = 'Required';
  static const String invalidEmailError = 'Enter a valid email';
  static const String invalidCodeError = 'Code must be 6 digits';
}

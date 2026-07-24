import 'package:flutter/material.dart';
import '../../features/auth/boot_screen.dart';
import '../../features/auth/invitation_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/auth/email_login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/main/main_shell_page.dart';
import '../../features/profile/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String boot = '/boot';
  static const String invitation = '/invitation';
  static const String profileSetup = '/profile-setup';
  static const String emailLogin = '/email-login';
  static const String otp = '/otp';
  
  static const String main = '/main';
  static const String profile = '/profile';

  // Legacy route constants for backward compatibility
  static const String onboarding = invitation;
  static const String login = emailLogin;
  static const String signupStep2 = profileSetup;
  static const String signupStep3 = profileSetup;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case boot:
        return _buildRoute(const BootScreen(), settings);
      case invitation:
        return _buildRoute(const InvitationScreen(), settings);
      case profileSetup:
        return _buildRoute(const ProfileSetupScreen(), settings);
      case emailLogin:
        return _buildRoute(const EmailLoginScreen(), settings);
      case otp:
        return _buildRoute(const OtpScreen(), settings);
      case main:
        return _buildRoute(const MainShellPage(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      default:
        return _buildRoute(const BootScreen(), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  static void navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  static void navigateAndReplace(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  static void navigateAndClearStack(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }
}

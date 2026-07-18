import 'package:flutter/material.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_step1_screen.dart';
import '../../features/auth/signup_step2_screen.dart';
import '../../features/auth/signup_step3_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/main/main_shell_page.dart';
import '../../features/profile/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String login      = '/login';
  static const String signupStep1 = '/signup/step1';
  static const String signupStep2 = '/signup/step2';
  static const String signupStep3 = '/signup/step3';
  static const String forgotPassword = '/forgot-password';
  static const String main       = '/main';
  static const String profile    = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case signupStep1:
        return _buildRoute(const SignupStep1Screen(), settings);
      case signupStep2:
        return _buildRoute(const SignupStep2Screen(), settings);
      case signupStep3:
        return _buildRoute(const SignupStep3Screen(), settings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
      case main:
        return _buildRoute(const MainShellPage(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      default:
        return _buildRoute(const OnboardingScreen(), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
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

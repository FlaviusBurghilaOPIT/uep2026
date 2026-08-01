import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';

/// Boot routing (WI 04, spec Req 3): decides main vs Welcome from the REAL
/// JWT, not demo prefs. [AuthNotifier.checkAuthStatus] validates any stored
/// token against `GET /auth/me`; this screen waits for that check
/// ([AuthState.isInitializing]) to finish, then routes:
/// - valid token (isSignedIn) -> main app (Today),
/// - absent/invalid token (401) -> Welcome (two-method sign-in).
class BootScreen extends ConsumerStatefulWidget {
  const BootScreen({super.key});

  @override
  ConsumerState<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends ConsumerState<BootScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  void _route() {
    if (!mounted || _navigated) return;
    final state = ref.read(authProvider);
    if (state.isInitializing) return; // wait for the JWT check to finish

    _navigated = true;
    if (state.isSignedIn) {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-route once the async JWT check flips isInitializing -> false.
    ref.listen(authProvider, (_, _) => _route());

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

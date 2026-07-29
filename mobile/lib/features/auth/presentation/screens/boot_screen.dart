import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/app_routes.dart';
import '../providers/demo_auth_provider.dart';

class BootScreen extends ConsumerStatefulWidget {
  const BootScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends ConsumerState<BootScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRoute();
    });
  }

  void _checkAuthAndRoute() {
    if (!mounted) return;
    final authState = ref.read(demoAuthProvider);

    authState.when(
      data: (state) {
        if (state.isFirstTime) {
          AppRoutes.navigateAndReplace(context, AppRoutes.invitation);
        } else if (!state.hasActiveSession) {
          AppRoutes.navigateAndReplace(context, AppRoutes.emailLogin);
        } else {
          AppRoutes.navigateAndReplace(context, AppRoutes.main);
        }
      },
      loading: () {}, // Wait
      error: (err, st) {
        // Fallback to invitation on error for safety
        AppRoutes.navigateAndReplace(context, AppRoutes.invitation);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes in case data isn't ready on mount
    ref.listen<AsyncValue<DemoAuthState>>(demoAuthProvider, (
      previous,
      next,
    ) {
      if (!next.isLoading) {
        _checkAuthAndRoute();
      }
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

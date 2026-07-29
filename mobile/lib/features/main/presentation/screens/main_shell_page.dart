import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/main_bottom_nav.dart';
import '../../../today/presentation/screens/today_screen.dart';
import '../../../medications/presentation/screens/medications_screen.dart';
import '../../../recovery/presentation/screens/recovery_screen.dart';
import '../../../assistant/presentation/screens/assistant_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  static const List<Widget> _pages = [
    TodayScreen(),
    MedicationsScreen(),
    RecoveryScreen(),
    AssistantScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider).currentIndex;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/main_bottom_nav.dart';
import '../today/today_screen.dart';
import '../medications/medications_screen.dart';
import '../recovery/recovery_screen.dart';
import '../assistant/assistant_screen.dart';
import '../profile/profile_screen.dart';

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

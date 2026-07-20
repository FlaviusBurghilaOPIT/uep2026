import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/shared_widgets/main_bottom_nav.dart';
import '../today/today_screen.dart';
import '../checkin/checkin_screen.dart';
import '../assistant/assistant_screen.dart';
import '../recovery/recovery_screen.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  static const List<Widget> _pages = [
    TodayScreen(),
    CheckInScreen(),
    AssistantScreen(),
    RecoveryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}

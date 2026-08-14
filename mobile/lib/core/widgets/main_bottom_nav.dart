import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';

class _NavItem {
  const _NavItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class MainBottomNav extends ConsumerWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider).currentIndex;
    final l10n = AppLocalizations.of(context);

    final List<_NavItem> navItems = [
      _NavItem(
        key: 'today',
        label: l10n.navTabToday,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _NavItem(
        key: 'medications',
        label: l10n.navTabMedications,
        icon: Icons.medication_outlined,
        activeIcon: Icons.medication_rounded,
      ),
      _NavItem(
        key: 'recovery',
        label: l10n.navTabRecovery,
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite_rounded,
      ),
      _NavItem(
        key: 'assistant',
        label: l10n.navTabAssistant,
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
      ),
      _NavItem(
        key: 'profile',
        label: l10n.navTabProfile,
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final bool isActive = currentIndex == index;
              final item = navItems[index];

              return Expanded(
                child: GestureDetector(
                  key: Key('navTab_${item.key}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(navigationProvider.notifier).setTab(index);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          key: ValueKey('${item.key}_$isActive'),
                          color: isActive
                              ? AppColors.primaryGreen
                              : AppColors.greyLight,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primaryGreen
                              : AppColors.greyLight,
                          fontSize: 11.sp,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 5.w : 0,
                        height: isActive ? 5.w : 0,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

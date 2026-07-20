import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/navigation_provider.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentIndex;

    final List<Map<String, String>> navItems = [
      {
        'label': 'Today',
        'icon': 'assets/images/Home.png',
        'icon_active': 'assets/images/HomeGreen.png',
      },
      {
        'label': 'Check-In',
        'icon': 'assets/images/CheckIn.png',
        'icon_active': 'assets/images/CheckIngreen.png',
      },
      {
        'label': 'Assistant',
        'icon': 'assets/images/Assistant.png',
        'icon_active': 'assets/images/AssistantGreen.png',
      },
      {
        'label': 'Recovery',
        'icon': 'assets/images/Recovery.png',
        'icon_active': 'assets/images/RecoveryGreen.png',
      },
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.read<NavigationProvider>().setTab(index);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Image.asset(
                          isActive ? item['icon_active']! : item['icon']!,
                          key: ValueKey('${item['label']}_$isActive'),
                          width: 24.w,
                          height: 24.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item['label']!,
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

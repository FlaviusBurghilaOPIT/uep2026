import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/shared_widgets/app_button.dart';
import '../../core/navigation/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'title': AppStrings.carousel1Title,
      'body': AppStrings.carousel1Body,
      'icon': Icons.medication_outlined,
    },
    {
      'title': AppStrings.carousel2Title,
      'body': AppStrings.carousel2Body,
      'icon': Icons.alarm_outlined,
    },
    {
      'title': AppStrings.carousel3Title,
      'body': AppStrings.carousel3Body,
      'icon': Icons.smart_toy_outlined,
    },
    {
      'title': AppStrings.carousel4Title,
      'body': AppStrings.carousel4Body,
      'icon': Icons.show_chart_outlined,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeroSection(),
            SizedBox(height: AppSpacing.xl),

            _buildCarousel(),
            SizedBox(height: AppSpacing.lg),

            _buildDotIndicators(),
            SizedBox(height: AppSpacing.xl),

            _buildTrustBadges(),

            const Spacer(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
              child: Column(
                children: [
                  AppButton(
                    text: AppStrings.signInToAccount,
                    onPressed: () => AppRoutes.navigateTo(context, AppRoutes.login),
                  ),
                  SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: AppStrings.createAccount,
                    isOutlined: true,
                    onPressed: () => AppRoutes.navigateTo(context, AppRoutes.signupStep1),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.bodySmall,
                      children: [
                        const TextSpan(text: AppStrings.termsPrefix),
                        TextSpan(
                          text: AppStrings.terms,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryGreen,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryGreen,
                          ),
                        ),
                        const TextSpan(text: AppStrings.and),
                        TextSpan(
                          text: AppStrings.privacyPolicy,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryGreen,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_outlined,
              color: AppColors.white,
              size: 32.sp,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.appName,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.white,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              AppStrings.appTagline,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 220.h,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: _carouselItems.length,
        itemBuilder: (context, index) {
          final item = _carouselItems[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.greyDivider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: AppColors.primaryGreen,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    item['title']!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    item['body']!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_carouselItems.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: _currentPage == index ? 20.w : 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primaryGreen
                : AppColors.greyDivider,
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }

  Widget _buildTrustBadges() {
    final badges = [
      {'icon': Icons.shield_outlined, 'text': AppStrings.hipaaAware},
      {'icon': Icons.cloud_outlined, 'text': AppStrings.awsBedrock},
      {'icon': Icons.lock_outline, 'text': AppStrings.cognitoAuth},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: badges.map((badge) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                badge['icon'] as IconData,
                size: 14.sp,
                color: AppColors.greyLight,
              ),
              SizedBox(width: 4.w),
              Text(
                badge['text'] as String,
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

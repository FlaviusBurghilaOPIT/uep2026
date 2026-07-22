import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/navigation/app_routes.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _medReminders = true;
  bool _dailyCheckin = true;
  bool _fdaAlerts = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.fullName ?? 'Sarah Mitchell';
    final email = auth.email ?? 'sarah.mitchell@email.com';
    final initials = name.split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              _buildHeader(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.xl),
                    _buildProfileHeader(initials, name, email),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection('PERSONAL INFORMATION', [
                      _infoRow('Full name', name),
                      _infoRow('Email', email),
                      _infoRow('Phone', auth.phone ?? '+1 (555) 248-3901'),
                      _infoRow('Date of birth', auth.dateOfBirth ?? 'Mar 14, 1988'),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection('TREATMENT PLAN', [
                      _infoRow('Condition', auth.primaryCondition ?? 'Post-surgical recovery'),
                      _infoRow('Procedure', 'Knee Arthroscopy'),
                      _infoRow('Surgery date', 'Jun 18, 2025'),
                      _infoRow('Clinician', 'Dr. Claire Moreau'),
                      _infoRow('Invite code', 'RC-4827-XK'),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection('NOTIFICATIONS', [
                      _toggleRow('Medication reminders', _medReminders, (v) => setState(() => _medReminders = v)),
                      _toggleRow('Daily check-in', _dailyCheckin, (v) => setState(() => _dailyCheckin = v)),
                      _toggleRow('FDA safety alerts', _fdaAlerts, (v) => setState(() => _fdaAlerts = v)),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSection('SECURITY', [
                      _arrowRow('Change password', Icons.lock_outline),
                      _arrowRow('Two-factor authentication', Icons.security_outlined),
                      _arrowRow('Connected devices', Icons.devices_outlined),
                    ]),
                    SizedBox(height: AppSpacing.xl),
                    _buildSignOutButton(),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.lg,
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.remotecare, style: AppTextStyles.heading3),
                Text(
                  'Sarah Mitchell \u00B7 Post-op',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined, color: AppColors.black, size: AppSpacing.iconLg),
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
            child: Icon(Icons.person_outline, color: AppColors.primaryGreen, size: AppSpacing.iconMd),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: AppColors.black, size: AppSpacing.iconMd),
            ),
          ),
          SizedBox(width: AppSpacing.hMd),
          Text('Profile & Settings', style: AppTextStyles.heading3),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String initials, String name, String email) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.hMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heading3.copyWith(color: AppColors.white),
                ),
                SizedBox(height: 2.h),
                Text(
                  email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Patient - Active',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.greyDivider, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(height: 1, indent: 16.w, endIndent: 16.w, color: AppColors.greyDivider),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _arrowRow(String label, IconData icon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, color: AppColors.greyText, size: AppSpacing.iconLg),
            SizedBox(width: AppSpacing.hMd),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
            Icon(Icons.chevron_right, color: AppColors.greyLight, size: AppSpacing.iconMd),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: () async {
          await ref.read(authProvider).signOut();
          if (mounted) {
            AppRoutes.navigateAndClearStack(context, AppRoutes.onboarding);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorRed,
          side: const BorderSide(color: AppColors.errorRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: AppSpacing.iconMd),
            SizedBox(width: AppSpacing.hSm),
            Text('Sign Out', style: AppTextStyles.buttonTextOutlined.copyWith(color: AppColors.errorRed)),
          ],
        ),
      ),
    );
  }
}

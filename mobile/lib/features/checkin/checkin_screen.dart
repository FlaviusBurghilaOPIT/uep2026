import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  int? _painLevel;
  int? _energyLevel;
  String? _selectedMood;
  final Set<String> _selectedEffects = {};
  bool _submitted = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _moods = const [
    {'label': 'Good', 'emoji': '😊', 'value': 'great'},
    {'label': 'Okay', 'emoji': '🙂', 'value': 'ok'},
    {'label': 'Low', 'emoji': '🙁', 'value': 'not_great'},
    {'label': 'Rough', 'emoji': '😣', 'value': 'bad'},
  ];

  final List<String> _sideEffects = [
    'Nausea', 'Dizziness', 'Fatigue', 'Headache', 'Rash', 'None',
  ];

  bool get _isComplete => _painLevel != null && _energyLevel != null && _selectedMood != null;

  Future<void> _submit() async {
    if (!_isComplete) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    String? caseId = auth.caseId;
    if (caseId == null && auth.patientId != null) {
      try {
        final caseRes = await ApiService.get('/patients/${auth.patientId}/case');
        if (caseRes.statusCode == 200) {
          caseId = jsonDecode(caseRes.body)['id'];
        }
      } catch (_) {}
    }

    final selectedMoodMap = _moods.firstWhere(
      (m) => m['label'] == _selectedMood,
      orElse: () => {'value': 'ok'},
    );
    final feeling = selectedMoodMap['value']!;

    if (caseId != null) {
      try {
        await ApiService.post('/symptoms/checkin?case_id=$caseId&feeling=$feeling', {});
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    }
  }

  void _reset() {
    setState(() {
      _painLevel = null;
      _energyLevel = null;
      _selectedMood = null;
      _selectedEffects.clear();
      _submitted = false;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessView();

    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(auth),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.xl),
                    Text('DAILY CHECK-IN', style: AppTextStyles.label),
                    SizedBox(height: AppSpacing.sm),
                    Text('How are you feeling today?', style: AppTextStyles.heading2),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Mon, Jul ${DateTime.now().day} \u00B7 Takes ~1 min',
                      style: AppTextStyles.bodySmall,
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _buildNumberScale(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Pain level',
                      value: _painLevel,
                      labels: const ['None', 'Severe'],
                      accentColor: AppColors.errorRed,
                      onTap: (i) => setState(() => _painLevel = i),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _buildNumberScale(
                      icon: Icons.bolt_outlined,
                      title: 'Energy level',
                      value: _energyLevel,
                      labels: const ['Exhausted', 'Great'],
                      accentColor: AppColors.primaryGreen,
                      onTap: (i) => setState(() => _energyLevel = i),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _buildMoodSection(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSideEffectsSection(),
                    SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: (_isComplete && !_isSubmitting) ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isComplete
                              ? AppColors.primaryGreen
                              : AppColors.greyDivider,
                          foregroundColor: _isComplete
                              ? AppColors.white
                              : AppColors.greyLight,
                          disabledBackgroundColor: AppColors.greyDivider,
                          disabledForegroundColor: AppColors.greyLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Submit Check-In',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _isComplete ? AppColors.white : AppColors.greyLight,
                                ),
                              ),
                      ),
                    ),
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

  Widget _buildTopBar(AuthProvider auth) {
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
                Text('${auth.fullName ?? 'User'} \u00B7 Post-op',
                    style: AppTextStyles.bodySmall),
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

  Widget _buildNumberScale({
    required IconData icon,
    required String title,
    required int? value,
    required List<String> labels,
    required Color accentColor,
    required ValueChanged<int> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: AppSpacing.iconLg),
            SizedBox(width: AppSpacing.hSm),
            Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (value != null)
              Text(
                '$value/5',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final isSelected = value == (i + 1);
            return GestureDetector(
              onTap: () => onTap(i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : AppColors.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? accentColor : AppColors.greyDivider,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.greyText,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Text(l, style: AppTextStyles.labelSmall)).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_outline, color: AppColors.primaryGreen, size: AppSpacing.iconLg),
            SizedBox(width: AppSpacing.hSm),
            Text('Overall mood', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 2.2,
          children: _moods.map((mood) {
            final isSelected = _selectedMood == mood['label'];
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood['label']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : AppColors.greyDivider,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mood['emoji']!, style: TextStyle(fontSize: 20.sp)),
                      SizedBox(width: 6.w),
                      Text(
                        mood['label']!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.white : AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSideEffectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Any side effects?', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _sideEffects.map((effect) {
            final isSelected = _selectedEffects.contains(effect);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (effect == 'None') {
                    _selectedEffects.clear();
                    _selectedEffects.add('None');
                  } else {
                    _selectedEffects.remove('None');
                    if (isSelected) {
                      _selectedEffects.remove(effect);
                    } else {
                      _selectedEffects.add(effect);
                    }
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : AppColors.greyDivider,
                    width: 1,
                  ),
                ),
                child: Text(
                  effect,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.white : AppColors.greyText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: const BoxDecoration(
                    color: AppColors.lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: AppColors.primaryGreen, size: 48.sp),
                ),
                SizedBox(height: AppSpacing.xxl),
                Text('Check-in Complete', style: AppTextStyles.heading2),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Your responses have been recorded and sent to your clinician. See you tomorrow!',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xl),
                GestureDetector(
                  onTap: _reset,
                  child: Text(
                    'Reset',
                    style: AppTextStyles.linkText.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

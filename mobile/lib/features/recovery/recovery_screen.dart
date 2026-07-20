import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  int? _expandedInstruction;

  final List<Map<String, dynamic>> _milestones = [
    {'title': 'Surgery', 'date': 'Jun 18', 'completed': true},
    {'title': 'Discharge', 'date': 'Jun 28', 'completed': true},
    {'title': 'Wound check', 'date': 'Jun 27', 'completed': true},
    {'title': 'Physio start', 'date': 'Jul 4', 'completed': false},
    {'title': 'Follow-up', 'date': 'Jul 18', 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.lg),
                    Text('RECOVERY', style: AppTextStyles.label),
                    SizedBox(height: AppSpacing.sm),
                    Text('Day 19 of Recovery', style: AppTextStyles.heading2),
                    SizedBox(height: AppSpacing.xs),
                    Text('Knee Arthroscopy \u00B7 Dr. Claire Moreau', style: AppTextStyles.bodyMedium),
                    SizedBox(height: AppSpacing.xl),
                    _buildAdherenceChart(),
                    SizedBox(height: AppSpacing.xl),
                    _buildMilestonesSection(),
                    SizedBox(height: AppSpacing.xl),
                    _buildCareInstructionsSection(),
                    SizedBox(height: AppSpacing.xl),
                    _buildWarningBox(),
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
                  '${AppStrings.checkInSubtitle.split(' ')[0]} Mitchell \u00B7 Post-op',
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

  Widget _buildAdherenceChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.greyDivider, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('7-Day Adherence', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '81%',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 120.h,
            child: CustomPaint(
              size: Size(double.infinity, 120.h),
              painter: _ChartPainter(),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d, style: AppTextStyles.labelSmall.copyWith(fontSize: 10.sp)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen, size: AppSpacing.iconLg),
            SizedBox(width: AppSpacing.hSm),
            Text('Recovery Milestones', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        for (int i = 0; i < _milestones.length; i++)
          _buildMilestoneItem(_milestones[i], i < _milestones.length - 1),
      ],
    );
  }

  Widget _buildMilestoneItem(Map<String, dynamic> m, bool showLine) {
    final completed = m['completed'] as bool;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24.w,
            child: Column(
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    color: completed ? AppColors.primaryGreen : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed ? AppColors.primaryGreen : AppColors.greyDivider,
                      width: 2,
                    ),
                  ),
                  child: completed
                      ? Icon(Icons.check, color: AppColors.white, size: 10.sp)
                      : null,
                ),
                if (showLine)
                  Expanded(
                    child: Container(width: 2.w, color: AppColors.greyDivider),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.hMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    m['title'],
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      color: completed ? AppColors.black : AppColors.greyText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    m['date'],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: completed ? AppColors.primaryGreen : AppColors.greyLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareInstructionsSection() {
    final instructions = [
      {
        'title': 'Activity Restrictions',
        'icon': Icons.directions_walk_outlined,
        'iconColor': AppColors.infoBlue,
        'items': [
          'Light walking 10\u201315 min, 3\u00D7 daily',
          'No lifting over 2 kg until Jul 18',
          'Avoid stairs more than 2 flights',
          'No driving for 4 more weeks',
        ],
      },
      {
        'title': 'Wound Care',
        'icon': Icons.favorite_outline,
        'iconColor': AppColors.errorRed,
        'items': [
          'Keep wound clean and dry',
          'Change dressing daily',
          'Report any redness or discharge',
        ],
      },
      {
        'title': 'Physiotherapy',
        'icon': Icons.bolt_outlined,
        'iconColor': AppColors.primaryGreen,
        'items': [
          'Begin gentle range-of-motion exercises',
          'Follow physiotherapist schedule',
          'Ice for 15 min after exercises',
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CARE INSTRUCTIONS', style: AppTextStyles.label),
        SizedBox(height: AppSpacing.md),
        for (int i = 0; i < instructions.length; i++)
          _buildInstructionCard(instructions[i], i),
      ],
    );
  }

  Widget _buildInstructionCard(Map<String, dynamic> inst, int index) {
    final isExpanded = _expandedInstruction == index;
    final items = (inst['items'] as List<String>);

    return GestureDetector(
      onTap: () => setState(() => _expandedInstruction = isExpanded ? null : index),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.greyDivider, width: 0.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: (inst['iconColor'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      inst['icon'] as IconData,
                      color: inst['iconColor'] as Color,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                  SizedBox(width: AppSpacing.hMd),
                  Expanded(
                    child: Text(
                      inst['title'],
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.chevron_right,
                    color: AppColors.greyLight,
                    size: AppSpacing.iconMd,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Divider(height: 1, indent: 52.w, color: AppColors.greyDivider),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5.w,
                          height: 5.w,
                          margin: EdgeInsets.only(top: 6.h, right: 8.w),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(item, style: AppTextStyles.bodySmall),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: AppSpacing.iconLg),
              SizedBox(width: AppSpacing.hSm),
              Text(
                'Seek Care Immediately If:',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _warningBullet('Fever > 38.5\u00B0C'),
          _warningBullet('Severe swelling'),
          _warningBullet('Unusual discharge'),
          _warningBullet('Chest pain or shortness of breath'),
        ],
      ),
    );
  }

  Widget _warningBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            margin: EdgeInsets.only(top: 6.h, right: 8.w),
            decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.black)),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [90.0, 85.0, 88.0, 82.0, 78.0, 60.0, 81.0];
    final w = size.width;
    final h = size.height;
    final stepX = w / (values.length - 1);

    final linePaint = Paint()
      ..color = AppColors.primaryGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryGreen.withValues(alpha: 0.3),
          AppColors.primaryGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = h - (values[i] / 100.0) * h;
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final dotPaint = Paint()..color = AppColors.primaryGreen;
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

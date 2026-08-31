import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/constants/app_colors.dart';
import 'package:remotecare/core/widgets/step_progress_bar.dart';

Widget _buildTestApp(Widget child, {bool disableAnimations = false}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StepProgressBar', () {
    testWidgets('renders step counter text and correct number of segments', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const StepProgressBar(
            currentStep: 2,
            totalSteps: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('uses AnimatedContainer with 240ms duration and easeOutCubic curve by default', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const StepProgressBar(
            currentStep: 1,
            totalSteps: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).toList();
      expect(animatedContainers.length, 3);
      for (final ac in animatedContainers) {
        expect(ac.duration, const Duration(milliseconds: 240));
        expect(ac.curve, Curves.easeOutCubic);
      }

      final decoration1 = animatedContainers[0].decoration as BoxDecoration;
      final decoration2 = animatedContainers[1].decoration as BoxDecoration;
      final decoration3 = animatedContainers[2].decoration as BoxDecoration;

      expect(decoration1.color, AppColors.primaryGreen);
      expect(decoration2.color, AppColors.greyDivider);
      expect(decoration3.color, AppColors.greyDivider);
    });

    testWidgets('uses Duration.zero when disableAnimations is true', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const StepProgressBar(
            currentStep: 2,
            totalSteps: 3,
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).toList();
      expect(animatedContainers.length, 3);
      for (final ac in animatedContainers) {
        expect(ac.duration, Duration.zero);
        expect(ac.curve, Curves.easeOutCubic);
      }
    });
  });
}

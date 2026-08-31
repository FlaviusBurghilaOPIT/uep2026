import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/features/today/presentation/widgets/celebration_ring_card.dart';

Widget wrapCelebration({
  required VoidCallback onDismiss,
  bool disableAnimations = false,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: SingleChildScrollView(
            child: CelebrationRingCard(onDismiss: onDismiss),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CelebrationRingCard', () {
    testWidgets('renders animated ring signature moment and handles dismiss with exit animation', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrapCelebration(onDismiss: () => dismissed = true));
      await tester.pump();

      expect(find.byKey(const Key('today_celebration')), findsOneWidget);
      expect(find.byKey(const Key('ring_closure_celebration')), findsOneWidget);
      expect(find.textContaining("All doses for today completed!"), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));

      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);

      final sizeTransitionFinder = find.byType(SizeTransition);
      expect(sizeTransitionFinder, findsOneWidget);
      final sizeTransition = tester.widget<SizeTransition>(sizeTransitionFinder);
      expect(sizeTransition.axisAlignment, -1.0);

      final fadeTransitionFinder = find.descendant(
        of: sizeTransitionFinder,
        matching: find.byType(FadeTransition),
      );
      expect(fadeTransitionFinder, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pump();
      expect(dismissed, isFalse);

      await tester.pump(const Duration(milliseconds: 90));
      expect(dismissed, isFalse);

      await tester.pump(const Duration(milliseconds: 100));
      expect(dismissed, isTrue);
    });

    testWidgets('dismisses immediately when disableAnimations is true', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrapCelebration(
        onDismiss: () => dismissed = true,
        disableAnimations: true,
      ));
      await tester.pump();

      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      expect(dismissed, isTrue);
    });
  });
}

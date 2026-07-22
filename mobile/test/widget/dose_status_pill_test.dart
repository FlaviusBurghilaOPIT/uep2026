import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/today/today_screen.dart';

import '../unit/fake_api_service.dart';

Widget buildTestWidget(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dose status pill dual icon + text indicators', () {
    late FakeApiService fakeApi;

    setUp(() {
      fakeApi = FakeApiService();
    });

    Future<void> pumpTodayScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
          child: buildTestWidget(const TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapAction(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Finder badgeFinder(int index) =>
        find.byKey(ValueKey('dose_status_badge_med_$index'));

    testWidgets('Taken pill renders check icon and "Taken" text', (
      tester,
    ) async {
      await pumpTodayScreen(tester);

      await tapAction(
        tester,
        find.widgetWithText(GestureDetector, 'Taken').first,
      );

      final badge = badgeFinder(0);
      expect(
        find.descendant(of: badge, matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: badge, matching: find.text('Taken')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Skipped pill renders warning triangle icon and "Skipped" text',
      (tester) async {
        await pumpTodayScreen(tester);

        await tapAction(
          tester,
          find.widgetWithText(GestureDetector, 'Skip').first,
        );

        final badge = badgeFinder(0);
        expect(
          find.descendant(
            of: badge,
            matching: find.byIcon(Icons.warning_amber_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: badge, matching: find.text('Skipped')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Missed pill renders cross icon and "Missed" text', (
      tester,
    ) async {
      await pumpTodayScreen(tester);

      await tapAction(
        tester,
        find.widgetWithText(GestureDetector, 'Missed').first,
      );

      final badge = badgeFinder(0);
      expect(
        find.descendant(of: badge, matching: find.byIcon(Icons.close)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: badge, matching: find.text('Missed')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Taken, Skipped, and Missed pills use pairwise-distinct icons and labels '
      '(distinguishable without relying on color)',
      (tester) async {
        await pumpTodayScreen(tester);

        await tapAction(
          tester,
          find.widgetWithText(GestureDetector, 'Taken').first,
        );
        await tapAction(
          tester,
          find.widgetWithText(GestureDetector, 'Skip').at(1),
        );
        await tapAction(
          tester,
          find.widgetWithText(GestureDetector, 'Missed').at(2),
        );

        expect(
          find.descendant(
            of: badgeFinder(0),
            matching: find.byIcon(Icons.check_circle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: badgeFinder(1),
            matching: find.byIcon(Icons.warning_amber_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: badgeFinder(2),
            matching: find.byIcon(Icons.close),
          ),
          findsOneWidget,
        );

        // Distinct IconData per status means the three pills remain
        // distinguishable from one another when rendered without color
        // (e.g. grayscale/monochrome), satisfying WCAG 1.4.1 non-color cues.
        final icons = <IconData>{
          Icons.check_circle,
          Icons.warning_amber_rounded,
          Icons.close,
        };
        expect(icons.length, 3);

        expect(
          find.descendant(of: badgeFinder(0), matching: find.text('Taken')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: badgeFinder(1), matching: find.text('Skipped')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: badgeFinder(2), matching: find.text('Missed')),
          findsOneWidget,
        );
      },
    );

    testWidgets('dose action tap targets remain >= 48x48dp after pill change', (
      tester,
    ) async {
      await pumpTodayScreen(tester);

      final actionFinder = find.widgetWithText(GestureDetector, 'Taken').first;
      await tester.ensureVisible(actionFinder);
      await tester.pumpAndSettle();
      final size = tester.getSize(actionFinder);

      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });
}

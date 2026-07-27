import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/features/today/fda_warning_card.dart';

// The former "TodayScreen FDA Source Badge Integration Tests" group here
// exercised the hardcoded-Amoxicillin fallback the WI 13 rewrite deletes
// (spec §7/§9: the FDA card now queries per-plan medications via
// `fdaWarningProvider`, never a hardcoded name). That integration coverage
// is superseded by `test/widget/today_screen_test.dart` (screen states) and
// the `fdaWarningProvider`-level coverage; this file keeps only the
// presentational `FdaWarningCard` unit coverage, which is unaffected.

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

  group('FdaWarningCard Widget Tests', () {
    testWidgets(
      'renders Official FDA Drug Safety Info source badge and retrieved timestamp',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestWidget(
            const Scaffold(
              body: FdaWarningCard(
                source: 'Official FDA Drug Safety Info',
                retrievedAt: '2026-07-22',
                message: 'Live FDA Warning test text',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('📋 Source: Official FDA Drug Safety Info'),
          findsOneWidget,
        );
        expect(find.text('Retrieved: 2026-07-22'), findsOneWidget);
        expect(find.text('Live FDA Warning test text'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Regulatory Cache source badge and timestamp when source is fixture',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestWidget(
            const Scaffold(
              body: FdaWarningCard(
                source: 'fixture',
                retrievedAt: '2026-07-22',
                message: 'Cached FDA Warning test text',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('📋 Source: Regulatory Cache'), findsOneWidget);
        expect(find.text('Retrieved: 2026-07-22'), findsOneWidget);
        expect(find.text('Cached FDA Warning test text'), findsOneWidget);
      },
    );
  });
}

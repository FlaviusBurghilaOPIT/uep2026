import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/features/today/presentation/widgets/celebration_ring_card.dart';

Widget wrapCelebration({required VoidCallback onDismiss}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CelebrationRingCard(onDismiss: onDismiss),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CelebrationRingCard', () {
    testWidgets('renders animated ring signature moment and handles dismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrapCelebration(onDismiss: () => dismissed = true));
      await tester.pump();

      expect(find.byKey(const Key('today_celebration')), findsOneWidget);
      expect(find.byKey(const Key('ring_closure_celebration')), findsOneWidget);
      expect(find.textContaining("All doses for today completed!"), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));

      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      expect(dismissed, isTrue);
    });
  });
}

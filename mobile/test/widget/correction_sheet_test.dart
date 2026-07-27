import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/features/today/correction_sheet.dart';
import 'package:remotecare/features/today/providers/today_agenda_notifier.dart';

AgendaSlot loggedSlot({SlotState state = SlotState.taken, DateTime? loggedAt}) {
  return AgendaSlot(
    slotId: 'rem-1',
    medicationId: 'med-1',
    medicationName: 'Ibuprofen',
    dose: '400 mg',
    scheduledTime: DateTime.parse('2026-07-26T08:00:00Z'),
    state: state,
    loggedAt: loggedAt ?? DateTime.parse('2026-07-26T08:42:00Z'),
    doseLogId: 'log-1',
  );
}

Widget wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CorrectionSheet', () {
    testWidgets('shows factual title and exactly the two OTHER statuses plus '
        'Keep as is at equal weight', (tester) async {
      await tester.pumpWidget(
        wrap(
          CorrectionSheet(
            slot: loggedSlot(state: SlotState.taken),
            onCorrect: (_) {},
            onKeep: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Logged as Taken at'), findsOneWidget);
      expect(find.textContaining('Change what happened?'), findsOneWidget);

      // Logged as Taken → options are Skipped and Missed, NOT Taken.
      expect(
        find.byKey(const Key('correction_option_skipped')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('correction_option_missed')), findsOneWidget);
      expect(find.byKey(const Key('correction_option_taken')), findsNothing);

      final keep = find.byKey(const Key('correction_keep'));
      expect(keep, findsOneWidget);
      expect(find.text('Keep as is'), findsOneWidget);

      // Equal visual weight: all three options are the same size and ≥48dp.
      final sizes = [
        tester.getSize(find.byKey(const Key('correction_option_skipped'))),
        tester.getSize(find.byKey(const Key('correction_option_missed'))),
        tester.getSize(keep),
      ];
      for (final size in sizes) {
        expect(size.height, greaterThanOrEqualTo(48.0));
      }
      expect(sizes[0].height, sizes[1].height);
      expect(sizes[1].height, sizes[2].height);
    });

    testWidgets('logged as skipped → offers Taken and Missed', (tester) async {
      await tester.pumpWidget(
        wrap(
          CorrectionSheet(
            slot: loggedSlot(state: SlotState.skipped),
            onCorrect: (_) {},
            onKeep: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Logged as Skipped at'), findsOneWidget);
      expect(find.byKey(const Key('correction_option_taken')), findsOneWidget);
      expect(find.byKey(const Key('correction_option_missed')), findsOneWidget);
      expect(find.byKey(const Key('correction_option_skipped')), findsNothing);
    });

    testWidgets('tapping an option fires onCorrect with that status; Keep '
        'fires onKeep', (tester) async {
      DoseLogStatus? corrected;
      var kept = 0;

      await tester.pumpWidget(
        wrap(
          CorrectionSheet(
            slot: loggedSlot(state: SlotState.taken),
            onCorrect: (s) => corrected = s,
            onKeep: () => kept++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('correction_option_skipped')));
      expect(corrected, DoseLogStatus.skipped);

      await tester.tap(find.byKey(const Key('correction_keep')));
      expect(kept, 1);
    });
  });
}

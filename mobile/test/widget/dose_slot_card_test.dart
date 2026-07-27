import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/features/today/dose_slot_card.dart';
import 'package:remotecare/features/today/providers/today_agenda_notifier.dart';

AgendaSlot buildSlot({
  String slotId = 'rem-1',
  SlotState state = SlotState.due,
  String medicationName = 'Ibuprofen',
  String dose = '400 mg',
  DateTime? scheduledTime,
  DateTime? loggedAt,
  String? doseLogId,
  String? previousStatus,
}) {
  return AgendaSlot(
    slotId: slotId,
    medicationId: 'med-1',
    medicationName: medicationName,
    dose: dose,
    scheduledTime: scheduledTime ?? DateTime.parse('2026-07-26T08:00:00Z'),
    state: state,
    loggedAt: loggedAt,
    doseLogId: doseLogId,
    previousStatus: previousStatus,
  );
}

Widget wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DoseSlotCard', () {
    testWidgets('due slot: Due now badge + three 48dp action rows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = 0;
      await tester.pumpWidget(
        wrap(DoseSlotCard(slot: buildSlot(), onLog: (_) => tapped++)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofen'), findsOneWidget);
      expect(find.text('400 mg'), findsOneWidget);
      expect(find.text('Due now'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsWidgets);

      for (final label in ['Taken', 'Skipped', 'Missed']) {
        final action = find.byKey(
          Key('slot_action_${label.toLowerCase()}_rem-1'),
        );
        expect(action, findsOneWidget, reason: '$label action row exists');
        expect(
          tester.getSize(action).height,
          greaterThanOrEqualTo(48.0),
          reason: '$label action is at least 48dp tall',
        );
      }

      await tester.tap(find.byKey(const Key('slot_action_taken_rem-1')));
      expect(tapped, 1);
    });

    testWidgets('taken slot: both times shown, no action rows, tap opens '
        'correction', (tester) async {
      var correctionOpened = 0;
      final slot = buildSlot(
        state: SlotState.taken,
        loggedAt: DateTime.parse('2026-07-26T08:42:00Z'),
        doseLogId: 'log-1',
      );

      await tester.pumpWidget(
        wrap(
          DoseSlotCard(slot: slot, onOpenCorrection: () => correctionOpened++),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Taken'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('Scheduled for'), findsOneWidget);
      expect(find.textContaining('Logged at'), findsOneWidget);
      expect(find.byKey(const Key('slot_action_taken_rem-1')), findsNothing);

      await tester.tap(find.byKey(const Key('dose_slot_rem-1')));
      expect(correctionOpened, 1);
    });

    testWidgets('missed slot: grey factual badge with scheduled time, no '
        'actions', (tester) async {
      await tester.pumpWidget(
        wrap(DoseSlotCard(slot: buildSlot(state: SlotState.missed))),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Scheduled'), findsOneWidget);
      expect(find.byKey(const Key('slot_action_taken_rem-1')), findsNothing);
    });

    testWidgets('writeInFlight replaces actions with an inline spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(DoseSlotCard(slot: buildSlot(), writeInFlight: true)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('slot_action_taken_rem-1')), findsNothing);
    });

    testWidgets('syncPending shows cloud icon + Saved on device badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DoseSlotCard(
            slot: buildSlot(state: SlotState.taken, doseLogId: null),
            syncPending: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.text('Saved on device'), findsOneWidget);
    });

    testWidgets('previous correction value is visible in slot detail', (
      tester,
    ) async {
      final slot = buildSlot(
        state: SlotState.skipped,
        loggedAt: DateTime.parse('2026-07-26T08:42:00Z'),
        doseLogId: 'log-1',
        previousStatus: 'taken',
      );

      await tester.pumpWidget(wrap(DoseSlotCard(slot: slot)));
      await tester.pumpAndSettle();

      expect(find.text('Previously: Taken'), findsOneWidget);
    });

    testWidgets('med name wraps up to 2 lines (Tall Man preserved)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DoseSlotCard(
            slot: buildSlot(
              medicationName: 'predniSOLONE acetate ophthalmic suspension',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(
        find.text('predniSOLONE acetate ophthalmic suspension'),
      );
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group('DoseSlotCard accessibility (WI 15)', () {
    testWidgets('M-01: descriptive block is one merged Semantics unit; action '
        'buttons stay individually reachable', (tester) async {
      await tester.pumpWidget(wrap(DoseSlotCard(slot: buildSlot())));
      await tester.pumpAndSettle();

      final mergedFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.contains('Ibuprofen') ?? false),
      );
      final merged = tester.widget<Semantics>(mergedFinder);
      final label = merged.properties.label!;
      expect(label, contains('Ibuprofen'));
      expect(label, contains('400 mg'));
      expect(label, contains('scheduled'));
      expect(label, contains('Due now'));
      expect(label, contains('Actions: taken, skipped, missed.'));
      expect(merged.excludeSemantics, isTrue);

      // Actions are structurally OUTSIDE the excluded/merged descriptive
      // block — they remain their own focusable, tappable nodes, not
      // swallowed into the card's single announcement.
      final actionKey = const Key('slot_action_taken_rem-1');
      expect(
        find.descendant(of: mergedFinder, matching: find.byKey(actionKey)),
        findsNothing,
      );
      expect(find.byKey(actionKey), findsOneWidget);
    });

    testWidgets('M-01: logged slot label describes state without a nonexistent '
        'action list', (tester) async {
      await tester.pumpWidget(
        wrap(
          DoseSlotCard(
            slot: buildSlot(
              state: SlotState.taken,
              loggedAt: DateTime.parse('2026-07-26T08:42:00Z'),
              doseLogId: 'log-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final merged = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere(
            (s) => s.properties.label?.contains('Ibuprofen') ?? false,
          );
      expect(merged.properties.label, isNot(contains('Actions:')));
    });

    testWidgets('M-02: 200% text scale — no overflow, actions remain ≥48dp', (
      tester,
    ) async {
      // MaterialApp builds its own root MediaQuery from the test view, so
      // the override must go through `builder` (inside that scope) rather
      // than wrapping MaterialApp itself.
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: DoseSlotCard(slot: buildSlot()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final action = find.byKey(const Key('slot_action_taken_rem-1'));
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48.0));
    });

    testWidgets(
      'M-03: every status badge uses a distinct icon — distinguishable in '
      'grayscale, never color-only',
      (tester) async {
        final iconsByState = <SlotState, IconData>{};
        for (final state in SlotState.values) {
          await tester.pumpWidget(
            wrap(DoseSlotCard(slot: buildSlot(state: state))),
          );
          await tester.pumpAndSettle();

          final icons = tester
              .widgetList<Icon>(
                find.descendant(
                  of: find.byKey(const Key('dose_slot_rem-1')),
                  matching: find.byType(Icon),
                ),
              )
              .map((i) => i.icon)
              .toList();
          // icons[0] is always the "scheduled time" clock icon; icons[1] is
          // the state badge's icon (any action-row icons follow after it).
          expect(icons.length, greaterThanOrEqualTo(2));
          iconsByState[state] = icons[1]!;
        }

        // Pairwise distinct across all 6 states (M-03 grayscale requirement).
        expect(iconsByState.values.toSet().length, SlotState.values.length);
      },
    );
  });
}

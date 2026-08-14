import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Today hardening ARB keys (spec §8) exist in all 5 locales', () {
    final locales = AppLocalizations.supportedLocales;

    test('supported locales are exactly de/en/es/fr/it', () {
      expect(
        locales.map((l) => l.languageCode),
        unorderedEquals(['de', 'en', 'es', 'fr', 'it']),
      );
    });

    for (final locale in locales) {
      test(
        '${locale.languageCode}: all new keys resolve to non-empty strings',
        () {
          final l10n = lookupAppLocalizations(locale);
          final values = <String>[
            l10n.todayAgendaError,
            l10n.todayRetry,
            l10n.todayStaleBanner('2h ago'),
            l10n.todayOfflineBanner,
            l10n.todayPlanUpdatedBanner,
            l10n.todayTimezoneAdjusted,
            l10n.todayLogUndo,
            l10n.todayLoggedAs('Taken'),
            l10n.todayLogRollbackError,
            l10n.todayCorrectionTitle('Taken', '8:42 AM'),
            l10n.todayCorrectionKeep,
            l10n.todaySkipPrompt,
            l10n.todaySkipPromptYes,
            l10n.todaySkipPromptNo,
            l10n.todayNoEmergencyContact,
            l10n.todayGroupMorning,
            l10n.todayGroupMidday,
            l10n.todayGroupEvening,
            l10n.todayGroupBedtime,
            l10n.todayPrnSection,
            l10n.todayDueNow,
            l10n.todayUpcoming,
            l10n.todayScheduledFor('8:00 AM'),
            l10n.todaySlotTimes('8:00 AM', '8:42 AM'),
            l10n.todayPreviouslyLogged('Taken'),
            l10n.todaySyncPending,
            l10n.todayCelebrationNext('Monday', '8:00 AM'),
            l10n.todayCelebration,
            l10n.todayProgressDoses(2, 3),
            l10n.todayPullToRefreshHint,
            l10n.todayOpenSettings,
            l10n.remindersOffBanner,
            l10n.emptyPlanMessage,
            l10n.checkinErrorRetry,
          ];
          for (final value in values) {
            expect(value.trim(), isNotEmpty);
          }
          // Placeholders actually interpolate.
          expect(
            l10n.todaySlotTimes('8:00 AM', '8:42 AM'),
            contains('8:42 AM'),
          );
          expect(l10n.todayProgressDoses(2, 3), contains('2'));
          expect(l10n.todayProgressDoses(2, 3), contains('3'));
        },
      );
    }
  });
}

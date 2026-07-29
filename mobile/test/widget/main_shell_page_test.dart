import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/main/main_shell_page.dart';
import 'package:remotecare/features/today/today_screen.dart';
import 'package:remotecare/features/medications/medications_screen.dart';
import 'package:remotecare/features/recovery/recovery_screen.dart';
import 'package:remotecare/features/assistant/assistant_screen.dart';
import 'package:remotecare/features/profile/profile_screen.dart';

import '../unit/fake_api_service.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: MainShellPage(),
  );
}

Widget buildTestApp(SharedPreferences prefs, FakeApiService fakeApi) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      apiServiceProvider.overrideWithValue(fakeApi),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: _buildMaterialApp,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeApiService fakeApi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeApi = FakeApiService();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(prefs, fakeApi));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders exactly 5 tabs in order: Today, Medications, Recovery, Assistant, Profile',
    (tester) async {
      await pumpShell(tester);

      final navTabOrder = [
        'navTab_today',
        'navTab_medications',
        'navTab_recovery',
        'navTab_assistant',
        'navTab_profile',
      ];

      for (final key in navTabOrder) {
        expect(find.byKey(Key(key)), findsOneWidget);
      }

      final labels = [
        'Today',
        'Medications',
        'Recovery',
        'Assistant',
        'Profile',
      ];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }

      // Confirm left-to-right order matches the required sequence.
      final positions = navTabOrder
          .map((key) => tester.getCenter(find.byKey(Key(key))).dx)
          .toList();
      final sorted = [...positions]..sort();
      expect(positions, sorted);

      // Today (index 0) is the default landing tab.
      expect(find.byType(TodayScreen), findsOneWidget);
    },
  );

  testWidgets(
    'IndexedStack keeps every tab mounted and preserves state across switches',
    (tester) async {
      await pumpShell(tester);

      // All 5 screens are mounted simultaneously by IndexedStack (offstage
      // tabs are wrapped in Visibility, not removed — skipOffstage: false
      // makes the finder see them too).
      expect(find.byType(TodayScreen, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(MedicationsScreen, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(RecoveryScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(AssistantScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsOneWidget);

      final todayStateBefore = tester.state(
        find.byType(TodayScreen, skipOffstage: false),
      );

      await tester.tap(find.byKey(const Key('navTab_medications')));
      await tester.pumpAndSettle();
      expect(find.byType(MedicationsScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('navTab_today')));
      await tester.pumpAndSettle();

      final todayStateAfter = tester.state(find.byType(TodayScreen));
      expect(identical(todayStateBefore, todayStateAfter), isTrue);
    },
  );
}

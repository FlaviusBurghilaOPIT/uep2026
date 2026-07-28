import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/l10n/locale_notifier.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/profile/profile_screen.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return Consumer(
    builder: (context, ref, child) {
      final locale = ref.watch(localeProvider);
      return MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const ProfileScreen(),
      );
    },
  );
}

Widget buildTestApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: _buildMaterialApp,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Default locale is English and renders English labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(await SharedPreferences.getInstance()));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Italian'), findsOneWidget);
  });

  testWidgets(
    'Tap Italian in ProfileScreen locale picker switches locale to Italian',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(await SharedPreferences.getInstance()));
      await tester.pumpAndSettle();

      final italianFinder = find.text('Italian');
      await tester.ensureVisible(italianFinder);
      await tester.tap(italianFinder);
      await tester.pumpAndSettle();

      expect(find.text('Profilo'), findsOneWidget);
      expect(find.text('Inglese'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
    },
  );

  testWidgets(
    'Tap German in ProfileScreen locale picker switches locale to German',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(await SharedPreferences.getInstance()));
      await tester.pumpAndSettle();

      final germanFinder = find.text('German');
      await tester.ensureVisible(germanFinder);
      await tester.tap(germanFinder);
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
    },
  );
}

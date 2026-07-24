import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/navigation/app_routes.dart';
import 'package:remotecare/features/auth/boot_screen.dart';
import 'package:remotecare/features/auth/demo_auth_state.dart';

Widget buildTestApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => const MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: BootScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BootScreen routes to InvitationScreen on first time user', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Enter Invitation Code'), findsOneWidget);
  });

  testWidgets('BootScreen routes to EmailLoginScreen when not first time and no active session', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'isFirstTime': false,
      'hasActiveSession': false,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('BootScreen routes to MainShellPage when active session exists', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'isFirstTime': false,
      'hasActiveSession': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
  });
}

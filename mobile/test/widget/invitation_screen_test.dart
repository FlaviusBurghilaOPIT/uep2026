import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/navigation/app_routes.dart';
import 'package:remotecare/features/auth/invitation_screen.dart';
import 'package:remotecare/core/l10n/app_localizations.dart';

Widget buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    onGenerateRoute: AppRoutes.onGenerateRoute,
    home: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => child,
    ),
  );
}

void main() {
  testWidgets('invitation screen displays UI and navigates on submit', (tester) async {
    await tester.pumpWidget(buildTestApp(const InvitationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Enter Invitation Code'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'INV123');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verification that we have navigated
    expect(find.text('Enter Invitation Code'), findsNothing);
  });

  testWidgets('shows validation error when invitation code is empty or whitespace', (tester) async {
    await tester.pumpWidget(buildTestApp(const InvitationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid invitation code'), findsOneWidget);
    expect(find.text('Enter Invitation Code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid invitation code'), findsOneWidget);
    expect(find.text('Enter Invitation Code'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/navigation/app_routes.dart';
import 'package:remotecare/features/auth/invitation_screen.dart';

Widget buildTestApp(Widget child) {
  return MaterialApp(
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
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'INV123');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verification that we have navigated (e.g., check that ProfileSetupScreen is present)
    // Assuming ProfileSetupScreen has some identifying text or you can check for the absence of the InvitationScreen
    expect(find.text('Enter Invitation Code'), findsNothing);
  });
}

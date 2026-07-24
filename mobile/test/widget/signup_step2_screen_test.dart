import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/auth/signup_step2_screen.dart';

import '../unit/fake_api_service.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(home: SignupStep2Screen());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup step 2 has no password field', (tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: _buildMaterialApp,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PASSWORD'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget); // phone only
  });
}

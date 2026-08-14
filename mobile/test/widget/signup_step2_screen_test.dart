import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/screens/signup_step2_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(home: SignupStep2Screen());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup step 2 has no password field', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeApi = FakeApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(fakeApi),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
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

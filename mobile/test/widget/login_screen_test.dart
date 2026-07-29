import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/constants/app_strings.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/shared_preferences_provider.dart';
import 'package:remotecare/features/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_api_service.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(home: LoginScreen());
}

Widget buildTestApp(FakeApiService fakeApi, SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(fakeApi),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      builder: _buildMaterialApp,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'email stage has no password field, sending a code moves to the code stage',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeApi = FakeApiService();
      fakeApi.postHandlers['/auth/patient/request-code'] = (body) {
        return http.Response(jsonEncode({'message': 'sent'}), 200);
      };

      await tester.pumpWidget(buildTestApp(fakeApi, prefs));
      await tester.pumpAndSettle();

      expect(find.text('PASSWORD'), findsNothing);

      await tester.enterText(
        find.byType(TextFormField).first,
        'jane@example.com',
      );
      await tester.tap(find.text(AppStrings.signIn));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.verifyEmail), findsOneWidget);
      expect(fakeApi.requestsLog.first['path'], '/auth/patient/request-code');
    },
  );
}

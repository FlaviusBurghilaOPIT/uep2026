import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() => runApp(
      const ProviderScope(
        child: RemoteCareApp(),
      ),
    );

class RemoteCareApp extends StatelessWidget {
  const RemoteCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: 'RemoteCare Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.onboarding,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

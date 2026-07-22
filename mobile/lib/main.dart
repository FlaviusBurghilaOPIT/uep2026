import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_notifier.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';

import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(
    const ProviderScope(
      child: RemoteCareApp(),
    ),
  );
}

class RemoteCareApp extends ConsumerWidget {
  const RemoteCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: 'RemoteCare Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        initialRoute: AppRoutes.onboarding,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

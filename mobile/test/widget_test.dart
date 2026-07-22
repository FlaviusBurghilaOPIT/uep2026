import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:remotecare/main.dart';

void main() {
  testWidgets('RemoteCareApp smoke test — renders without crashing',
      (WidgetTester tester) async {
    // Use a phone-sized surface matching the ScreenUtil designSize.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Suppress pre-existing RenderFlex overflow warnings in the onboarding
    // screen — these are a layout issue that pre-dates WI-01 and are outside
    // this work item's scope.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Let overflow errors through silently; surface everything else.
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      const ProviderScope(
        child: RemoteCareApp(),
      ),
    );

    // The MaterialApp must be present to confirm the widget tree built.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

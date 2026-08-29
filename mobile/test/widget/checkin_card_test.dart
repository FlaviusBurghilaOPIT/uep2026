import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/l10n/app_localizations.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/auth/domain/entities/auth_state.dart';
import 'package:remotecare/features/auth/presentation/providers/auth_provider.dart';
import 'package:remotecare/features/checkin/presentation/widgets/checkin_card.dart';

import '../unit/fake_api_service.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

Widget wrapCheckIn(
  Widget child, {
  required FakeApiService fakeApi,
  String caseId = 'case-123',
  AuthState? authState,
}) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(fakeApi),
      authProvider.overrideWith(
        () => _TestAuthNotifier(
          authState ??
              AuthState(
                patientId: 'pat-123',
                caseId: caseId,
                isSignedIn: true,
                isInitializing: false,
              ),
        ),
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CheckInCard', () {
    late FakeApiService fakeApi;

    setUp(() {
      fakeApi = FakeApiService();
      fakeApi.getHandlers['/cases/case-123/emergency-contact'] = () {
        return http.Response(jsonEncode({'phone': '+1 (555) 987-6543'}), 200);
      };
      fakeApi.postHandlers['/symptoms/checkin?case_id=case-123&feeling=great'] = (body) {
        return http.Response(jsonEncode({'id': 'chk-1'}), 200);
      };
      fakeApi.postHandlers['/symptoms/checkin?case_id=case-123&feeling=ok'] = (body) {
        return http.Response(jsonEncode({'id': 'chk-ok'}), 200);
      };
      fakeApi.postHandlers['/symptoms/checkin?case_id=case-123&feeling=not_great'] = (body) {
        return http.Response(jsonEncode({'id': 'chk-ng'}), 200);
      };
      fakeApi.postHandlers['/symptoms/checkin?case_id=case-123&feeling=bad'] = (body) {
        return http.Response(jsonEncode({'id': 'chk-2'}), 200);
      };
    });

    testWidgets('renders 4 mood options and title', (tester) async {
      await tester.pumpWidget(wrapCheckIn(const CheckInCard(), fakeApi: fakeApi));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkin_card')), findsOneWidget);
      expect(find.text('DAILY CHECK-IN'), findsOneWidget);
      expect(find.text('Feeling Great 🙂'), findsOneWidget);
      expect(find.text('Feeling Ok 😐'), findsOneWidget);
      expect(find.text('Not Feeling Great 😟'), findsOneWidget);
      expect(find.text('Feeling Unwell 😣'), findsOneWidget);

      expect(find.byKey(const Key('checkin_chip_great')), findsOneWidget);
      expect(find.byKey(const Key('checkin_chip_ok')), findsOneWidget);
      expect(find.byKey(const Key('checkin_chip_not_great')), findsOneWidget);
      expect(find.byKey(const Key('checkin_chip_bad')), findsOneWidget);
    });

    testWidgets(
      'selecting great shows default telemetry confirmation banner when physician is null',
      (tester) async {
        await tester.pumpWidget(wrapCheckIn(const CheckInCard(), fakeApi: fakeApi));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Feeling Great 🙂'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('checkin_success')), findsOneWidget);
        expect(
          find.text('Check-in received • Care team updated'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('emergency_red_flag_banner')), findsNothing);
      },
    );

    testWidgets('selecting ok submits ok and shows success banner', (tester) async {
      await tester.pumpWidget(wrapCheckIn(const CheckInCard(), fakeApi: fakeApi));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Feeling Ok 😐'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkin_success')), findsOneWidget);
      expect(find.byKey(const Key('emergency_red_flag_banner')), findsNothing);
    });

    testWidgets('selecting not_great submits not_great and shows success banner', (tester) async {
      await tester.pumpWidget(wrapCheckIn(const CheckInCard(), fakeApi: fakeApi));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not Feeling Great 😟'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkin_success')), findsOneWidget);
      expect(find.byKey(const Key('emergency_red_flag_banner')), findsNothing);
    });

    testWidgets(
      'selecting great shows physician telemetry confirmation banner when physicianName is in AuthState',
      (tester) async {
        final authWithDoctor = const AuthState(
          patientId: 'pat-123',
          caseId: 'case-123',
          physicianName: 'Dr. Miller',
          isSignedIn: true,
          isInitializing: false,
        );

        await tester.pumpWidget(
          wrapCheckIn(
            const CheckInCard(),
            fakeApi: fakeApi,
            authState: authWithDoctor,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Feeling Great 🙂'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('checkin_success')), findsOneWidget);
        expect(
          find.text("Check-in received • Dr. Miller's care team updated"),
          findsOneWidget,
        );
        expect(find.byKey(const Key('emergency_red_flag_banner')), findsNothing);
      },
    );

    testWidgets(
      'selecting great shows physician telemetry confirmation banner when physicianName is passed as prop',
      (tester) async {
        await tester.pumpWidget(
          wrapCheckIn(
            const CheckInCard(physicianName: 'Dr. Miller'),
            fakeApi: fakeApi,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Feeling Great 🙂'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('checkin_success')), findsOneWidget);
        expect(
          find.text("Check-in received • Dr. Miller's care team updated"),
          findsOneWidget,
        );
      },
    );

    testWidgets('selecting bad reveals emergency red flag banner with 911 and clinic CTAs', (tester) async {
      await tester.pumpWidget(wrapCheckIn(const CheckInCard(), fakeApi: fakeApi));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Feeling Unwell 😣'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emergency_red_flag_banner')), findsOneWidget);
      expect(find.byKey(const Key('emergency_dial_911_button')), findsOneWidget);
      expect(find.byKey(const Key('emergency_dial_clinic_button')), findsOneWidget);
      expect(find.text('Emergency Red Flag Warning'), findsOneWidget);
      expect(find.text('Call Emergency (911)'), findsOneWidget);
    });
  });
}

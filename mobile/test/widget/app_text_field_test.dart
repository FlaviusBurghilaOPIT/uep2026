import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/widgets/app_text_field.dart';

Widget _buildTestApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTextField', () {
    testWidgets('defaults to TextCapitalization.none and autocorrect: false', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppTextField(
            label: 'Test Label',
            hintText: 'Test Hint',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byType(TextField),
      );
      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );

      expect(textField.textCapitalization, TextCapitalization.none);
      expect(textField.autocorrect, isFalse);
      expect(editableText.textCapitalization, TextCapitalization.none);
      expect(editableText.autocorrect, isFalse);
    });

    testWidgets('enforces no capitalization and no autocorrect when keyboardType is emailAddress', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppTextField(
            label: 'Email',
            hintText: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.words,
            autocorrect: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byType(TextField),
      );
      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );

      expect(textField.keyboardType, TextInputType.emailAddress);
      expect(textField.textCapitalization, TextCapitalization.none);
      expect(textField.autocorrect, isFalse);
      expect(editableText.keyboardType, TextInputType.emailAddress);
      expect(editableText.textCapitalization, TextCapitalization.none);
      expect(editableText.autocorrect, isFalse);
    });
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/utils/e164_phone_formatter.dart';

void main() {
  group('E164PhoneInputFormatter', () {
    const formatter = E164PhoneInputFormatter();

    test('empty string remains empty', () {
      const input = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '');
      expect(result.selection.baseOffset, 0);
    });

    test('plus only returns plus with cursor at 1', () {
      const input = TextEditingValue(
        text: '+',
        selection: TextSelection.collapsed(offset: 1),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '+');
      expect(result.selection.baseOffset, 1);
    });

    test('typing digits without plus adds leading plus and formats', () {
      const input = TextEditingValue(
        text: '15552483901',
        selection: TextSelection.collapsed(offset: 11),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '+1 555 248 3901');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('formats Italian numbers (+39) with E.164 telecommunication mask', () {
      const input = TextEditingValue(
        text: '+393331234567',
        selection: TextSelection.collapsed(offset: 13),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '+39 333 123 4567');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('formats 3-digit country code numbers', () {
      const input = TextEditingValue(
        text: '+351912345678',
        selection: TextSelection.collapsed(offset: 13),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '+351 912 345 678');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('enforces ITU-T E.164 maximum of 15 digits', () {
      const input = TextEditingValue(
        text: '+12345678901234567890',
        selection: TextSelection.collapsed(offset: 21),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      final digits = result.text.replaceAll(RegExp(r'[^\d]'), '');
      expect(digits.length, 15);
    });

    test('filters out non-digit characters', () {
      const input = TextEditingValue(
        text: '+39 (333) abc-1234567',
        selection: TextSelection.collapsed(offset: 21),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '+39 333 123 4567');
    });

    test('preserves cursor position when editing in the middle', () {
      const oldVal = TextEditingValue(
        text: '+1 555 123 4567',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newVal = TextEditingValue(
        text: '+1 5559 123 4567',
        selection: TextSelection.collapsed(offset: 7),
      );
      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text.startsWith('+1 555'), true);
      expect(result.selection.baseOffset, greaterThan(0));
    });
  });
}

import 'package:flutter/services.dart';

/// Formats telephone input according to standard ITU-T E.164 telecommunication specifications:
/// - Enforces leading '+' for international E.164 numbers.
/// - Only permits digits (0-9) and standard grouping spaces.
/// - Limits the total number of digits to a maximum of 15 (E.164 standard limit).
/// - Calculates and preserves cursor positioning to avoid jumping to index 0 on edit/focus.
class E164PhoneInputFormatter extends TextInputFormatter {
  const E164PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final hasPlus = text.startsWith('+') || text.contains('+');
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // ITU-T E.164 specifies max 15 digits in an international telephone number.
    final clampedDigits = digitsOnly.length > 15
        ? digitsOnly.substring(0, 15)
        : digitsOnly;

    if (clampedDigits.isEmpty) {
      if (hasPlus) {
        return const TextEditingValue(
          text: '+',
          selection: TextSelection.collapsed(offset: 1),
        );
      }
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatE164(clampedDigits);

    // Calculate cursor offset based on the number of digits before previous cursor
    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.baseOffset && i < newValue.text.length; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    int newOffset = 0;
    int countedDigits = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        countedDigits++;
        if (countedDigits == digitsBeforeCursor) {
          newOffset = i + 1;
          break;
        }
      }
    }

    if (digitsBeforeCursor == 0) {
      newOffset = formatted.startsWith('+') ? 1 : 0;
    } else if (countedDigits < digitsBeforeCursor ||
        newValue.selection.baseOffset >= newValue.text.length) {
      newOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newOffset.clamp(0, formatted.length),
      ),
    );
  }

  static String _formatE164(String digits) {
    final buffer = StringBuffer('+');

    // 1-digit country codes: +1 (US/CA/NANP), +7 (KZ/RU)
    if ((digits.startsWith('1') || digits.startsWith('7')) && digits.length > 1) {
      final cc = digits.substring(0, 1);
      buffer.write('$cc ');
      final rest = digits.substring(1);
      _appendGroupedRest(buffer, rest);
      return buffer.toString().trimRight();
    }

    // 3-digit country code prefixes
    final is3DigitCc = digits.length >= 3 &&
        (_is3DigitCountryCode(digits.substring(0, 3)));

    if (is3DigitCc) {
      final cc = digits.substring(0, 3);
      buffer.write('$cc ');
      final rest = digits.substring(3);
      _appendGroupedRest(buffer, rest);
      return buffer.toString().trimRight();
    }

    // 2-digit country codes (e.g. +39 IT, +44 UK, +49 DE, +33 FR, +34 ES)
    if (digits.length >= 2) {
      final cc = digits.substring(0, 2);
      buffer.write('$cc ');
      final rest = digits.substring(2);
      _appendGroupedRest(buffer, rest);
      return buffer.toString().trimRight();
    }

    // Single digit input without known grouping yet
    buffer.write(digits);
    return buffer.toString();
  }

  static void _appendGroupedRest(StringBuffer buffer, String rest) {
    if (rest.isEmpty) return;
    if (rest.length <= 3) {
      buffer.write(rest);
    } else if (rest.length <= 6) {
      buffer.write('${rest.substring(0, 3)} ${rest.substring(3)}');
    } else if (rest.length <= 10) {
      buffer.write(
        '${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}',
      );
    } else {
      buffer.write(
        '${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6, 10)} ${rest.substring(10)}',
      );
    }
  }

  static bool _is3DigitCountryCode(String prefix) {
    final code = int.tryParse(prefix);
    if (code == null) return false;
    // Known ITU-T 3-digit country code ranges
    return (code >= 350 && code <= 359) ||
        (code >= 370 && code <= 379) ||
        (code >= 380 && code <= 389) ||
        (code >= 420 && code <= 429) ||
        (code >= 500 && code <= 509) ||
        (code >= 590 && code <= 599) ||
        (code >= 670 && code <= 699) ||
        (code >= 850 && code <= 859) ||
        (code >= 880 && code <= 889) ||
        (code >= 960 && code <= 999);
  }
}

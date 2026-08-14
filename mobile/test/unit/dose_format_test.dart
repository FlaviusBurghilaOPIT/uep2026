import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/features/today/presentation/widgets/dose_format.dart';

void main() {
  group('formatDose (M-08)', () {
    test('inserts a space before the unit', () {
      expect(formatDose('400mg'), '400 mg');
      expect(formatDose('500mg'), '500 mg');
      expect(formatDose('25mcg'), '25 mcg');
    });

    test('keeps an already formatted dose unchanged', () {
      expect(formatDose('400 mg'), '400 mg');
    });

    test('adds a leading zero to fractional doses', () {
      expect(formatDose('.5mg'), '0.5 mg');
      expect(formatDose('.5 mg'), '0.5 mg');
      expect(formatDose('0.5mg'), '0.5 mg');
    });

    test('passes through non-numeric doses untouched', () {
      expect(formatDose('1 puff'), '1 puff');
      expect(formatDose(''), '');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  group('DosageForm & detectDosageForm (VIS-03)', () {
    test('icons map correctly to Lucide glyphs', () {
      expect(DosageForm.capsule.icon, LucideIcons.pill);
      expect(DosageForm.tablet.icon, LucideIcons.tablets);
      expect(DosageForm.liquid.icon, LucideIcons.droplet);
    });

    test('detects capsule formats', () {
      expect(
        detectDosageForm(medicationName: 'Amoxicillin Capsule'),
        DosageForm.capsule,
      );
      expect(
        detectDosageForm(medicationName: 'Celebrex', dose: '200 mg cap'),
        DosageForm.capsule,
      );
      expect(
        detectDosageForm(medicationName: 'Vitamin D softgel cap'),
        DosageForm.capsule,
      );
    });

    test('detects liquid formats', () {
      expect(
        detectDosageForm(medicationName: 'Paracetamol syrup'),
        DosageForm.liquid,
      );
      expect(
        detectDosageForm(medicationName: 'Morphine', dose: '10 ml'),
        DosageForm.liquid,
      );
      expect(
        detectDosageForm(medicationName: 'Prednisolone eye drops'),
        DosageForm.liquid,
      );
      expect(
        detectDosageForm(medicationName: 'Oral solution'),
        DosageForm.liquid,
      );
      expect(
        detectDosageForm(medicationName: 'Amoxicillin oral suspension'),
        DosageForm.liquid,
      );
    });

    test('defaults to tablet format', () {
      expect(
        detectDosageForm(medicationName: 'Ibuprofen', dose: '400 mg'),
        DosageForm.tablet,
      );
      expect(
        detectDosageForm(medicationName: 'Aspirin tablet'),
        DosageForm.tablet,
      );
    });
  });
}

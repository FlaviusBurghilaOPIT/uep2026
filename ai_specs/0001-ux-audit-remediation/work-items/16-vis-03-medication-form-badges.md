---
type: Work Item
title: VIS-03 Medication Dosage Form Icon Glyphs
parent: ../spec.md
---

## What to build
Add dedicated visual icon glyphs for Capsule, Tablet, and Liquid medication dosage formats beside text badges in `DoseSlotCard` / `DoseFormat` (`A02`) to enhance glanceability and aesthetic-usability.

## Required context
- Target file: `mobile/lib/features/today/presentation/widgets/dose_format.dart`
- Target file: `mobile/lib/features/today/presentation/widgets/dose_slot_card.dart`
- Icons: `lucide_icons_flutter` or Material `Icons.medication`, `Icons.water_drop`

## Acceptance criteria
- [x] Capsule medications render with capsule icon glyph.
- [x] Tablet medications render with tablet/pill icon glyph.
- [x] Liquid/drops render with drop/liquid icon glyph.
- [x] Icons pair cleanly with localized format text badges.

## Covers
- User Stories: US1
- Requirements: Requirement 16
- Interview Ledger: L16

## Blocked by
None - ready to start

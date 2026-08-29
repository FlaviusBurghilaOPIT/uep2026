---
type: Work Item
title: FORM-01 Pinned Sticky Emergency Red Flag Direct-Dial Banner
parent: ../spec.md
---

## What to build
Pin a sticky Emergency Red Flag banner with 1-tap direct dial (`tel:911` / Clinic emergency hotline) above the fold in `CheckInCard` (`A03`) whenever a patient selects "Feeling Unwell" / 'bad' to satisfy Gulf of Evaluation and acute patient safety requirements.

## Required context
- Target file: `mobile/lib/features/checkin/presentation/widgets/checkin_card.dart`
- Emergency phone lookup seam: `/cases/{caseId}/emergency-contact` and `url_launcher`

## Acceptance criteria
- [x] Selecting "Unwell" ('bad') immediately displays the Red Flag emergency banner above the fold.
- [x] Banner contains prominent 1-tap direct dial button invoking `url_launcher` with `tel:` URI scheme.
- [x] Emergency contact phone number defaults to clinic hotline or 911 if no custom case number is assigned.
- [x] Emergency banner remains sticky and visible during symptom detail entry.

## Covers
- User Stories: US2
- Requirements: Requirement 5
- Interview Ledger: L5

## Blocked by
None - ready to start

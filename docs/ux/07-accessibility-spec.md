# Remote CarePro — Cross-Platform Accessibility & Cognitive-Load Specification

**Document ID:** `docs/ux/07-accessibility-spec.md`  
**Generated Date:** 2026-07-22  
**Role:** Lead Product, UX, and Technical-Design Agent  
**Status:** Approved Accessibility & Cognitive-Load Specification

---

## 1. Executive Summary & Governance Standards

Remote CarePro serves post-surgery patients (who may experience pain, motor tremors, fatigue, low vision, or cognitive overload) and busy clinicians (who require high-speed, error-free keyboard navigation). 

This specification establishes non-negotiable accessibility and cognitive-load engineering standards across the **Flutter Patient Mobile App** and the **React Clinician Web Dashboard**, aligned with **WCAG 2.2 Level AA** standards.

---

## 2. Mobile Accessibility & Cognitive Specification (Flutter)

---

### Standard M-01: Screen-Reader Labels & Reading Order

* **Affected App & Component**: `mobile/lib/features/today/today_screen.dart` (Medication Timecards).
* **User Impact**: Screen reader users (VoiceOver/TalkBack) encounter fragmented reading of dosage cards, reading buttons out of logical sequence.
* **Severity**: `Critical`
* **Exact Remediation**: Wrap medication timecards in Flutter `Semantics` widgets with structured `label`, `hint`, and `mergeWithAncestor: true` so the entire card reads as a single cohesive sentence before action buttons are focused.
* **Implementation Guidance (Flutter)**:
  ```dart
  Semantics(
    mergeWithAncestor: true,
    label: '${medication.name} ${medication.dose}, scheduled for ${medication.scheduledTimeText}. Status: ${medication.statusText}.',
    hint: 'Double tap to open prescription details',
    child: MedicationCardWidget(...),
  )
  ```
* **Test Procedure**: Enable VoiceOver (iOS) or TalkBack (Android). Swipe linearly through `TodayScreen`.
* **Definition of Done**: Screen reader speaks medication name, dose, due time, and status in a single sentence before advancing to action buttons.

---

### Standard M-02: Dynamic Text Scaling (200%)

* **Affected App & Component**: `mobile/lib/features/today/today_screen.dart`, `mobile/lib/features/checkin/checkin_screen.dart`.
* **User Impact**: Low-vision patients using 200% OS font scaling experience text truncation or `A RenderFlex overflowed by X pixels` crash boxes.
* **Severity**: `High`
* **Exact Remediation**: Remove fixed pixel container heights (`height: 60`). Wrap text containers in `Expanded` or `SingleChildScrollView` and allow multi-line wrapping with `maxLines: null`.
* **Implementation Guidance (Flutter)**:
  ```dart
  // Replace Container(height: 50) with:
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    child: Text(
      medication.name,
      style: Theme.of(context).textTheme.titleMedium,
      softWrap: true,
      maxLines: null,
    ),
  )
  ```
* **Test Procedure**: Set iOS/Android system text size to maximum (200%). Inspect all 12 mobile screens.
* **Definition of Done**: All text wraps cleanly without visual clipping or `RenderFlex` overflow errors.

---

### Standard M-03: Contrast & Non-Colour Status Cues

* **Affected App & Component**: `mobile/lib/features/today/today_screen.dart` (Status Badges).
* **User Impact**: Colorblind patients cannot distinguish green (Taken), amber (Skipped), and red (Missed) status pills.
* **Severity**: `Critical`
* **Exact Remediation**: Maintain $\ge 4.5:1$ text contrast against pill backgrounds AND pair every status color with a distinct icon (Checkmark for Taken, Warning Triangle for Skipped, Cross for Missed) and explicit text label.
* **Implementation Guidance (Flutter)**:
  ```dart
  Row(
    children: [
      Icon(status.icon, color: status.foregroundColor, size: 18),
      const SizedBox(width: 6),
      Text(status.labelText, style: TextStyle(color: status.foregroundColor)),
    ],
  )
  ```
* **Test Procedure**: Run app through SimDaltonism (Protanopia/Deuteranopia/Tritanopia simulator) or grayscale display mode.
* **Definition of Done**: Statuses are 100% distinguishable in monochrome/grayscale mode.

---

### Standard M-04: Minimum Touch Target Area (48×48dp)

* **Affected App & Component**: `mobile/lib/features/today/today_screen.dart` (Action Pills), `mobile/lib/features/checkin/checkin_screen.dart`.
* **User Impact**: Patients with tremors or hand weakness struggle to tap small buttons, causing missed logs or frustration.
* **Severity**: `High`
* **Exact Remediation**: Ensure every interactive target (buttons, checkboxes, tab items) has a minimum touch hitbox of $48 \times 48\text{dp}$.
* **Implementation Guidance (Flutter)**:
  ```dart
  ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
    child: ElevatedButton(...),
  )
  ```
* **Test Procedure**: Inspect interactive elements with Flutter Widget Inspector touch target overlay.
* **Definition of Done**: Zero interactive elements measure under $48 \times 48\text{dp}$.

---

### Standard M-05: Haptic & Motion Alternatives

* **Affected App & Component**: `mobile/lib/features/today/today_screen.dart` (Log Confirmation).
* **User Impact**: Deaf or non-haptic users miss confirmation cues; vestibular-disorder patients suffer nausea from interface animations.
* **Severity**: `Medium`
* **Exact Remediation**: Pair haptic vibrations (`HapticFeedback.lightImpact()`) with persistent visual toast confirmations; wrap motion transitions to respect `MediaQuery.of(context).disableAnimations`.
* **Implementation Guidance (Flutter)**:
  ```dart
  if (!MediaQuery.of(context).disableAnimations) {
    // Run subtle card transition
  }
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(...);
  ```
* **Test Procedure**: Enable "Reduce Motion" in system settings and tap "Taken".
* **Definition of Done**: Dose logging triggers visual toast + haptics, and interface animations disable when "Reduce Motion" is active.

---

### Standard M-06: One-Handed Thumb-Zone Layout

* **Affected App & Component**: `mobile/lib/features/today/today_screen.dart`, `mobile/lib/features/main/main_shell_page.dart`.
* **User Impact**: Bedridden patients holding their phone with one hand cannot reach high-altitude top buttons.
* **Severity**: `High`
* **Exact Remediation**: Position high-frequency primary action buttons (1-tap "Taken", Check-in options) and navigation bar within the natural thumb reach zone (bottom 60% of viewport).
* **Implementation Guidance (Flutter)**:
  ```dart
  // Primary dose logging cards placed in scrollable body above bottom navigation bar
  ```
* **Test Procedure**: Perform reachability audit using standard one-handed thumb reach templates.
* **Definition of Done**: 1-tap "Taken" button and check-in options reside entirely within bottom 60% of viewport.

---

### Standard M-07: Plain-Language & Low-Cognitive Load Content

* **Affected App & Component**: All mobile screens (`mobile/lib/features/`).
* **User Impact**: Patients experiencing post-surgery cognitive fatigue or low literacy misunderstand prescription acronyms.
* **Severity**: `High`
* **Exact Remediation**: Enforce Flesch-Kincaid Grade 8 maximum reading level; replace medical jargon (e.g. *"TID PC"*) with plain language (e.g. *"Take 3 times a day with meals"*).
* **Implementation Guidance (Flutter)**: Consume centralized localization strings from `docs/ux/06-content-system.md`.
* **Test Procedure**: Run mobile strings through automated Flesch-Kincaid readability scanner.
* **Definition of Done**: 100% of patient-facing mobile strings pass Grade 8 reading level test.

---

### Standard M-08: Standardized Medication & Dose Formatting

* **Affected App & Component**: `mobile/lib/features/today/`, `mobile/lib/features/medications/`.
* **User Impact**: Ambiguous dosage numbers (e.g. `.5 mg` vs `0.5 mg`) or look-alike drug names lead to double dosing or safety errors.
* **Severity**: `Critical`
* **Exact Remediation**: Format dosage quantities with leading zeros (`0.5 mg`, never `.5 mg`), explicit unit spacing (`400 mg`), and apply Tall Man lettering for look-alike drugs.
* **Implementation Guidance (Flutter)**:
  ```dart
  class MedicationFormatter {
    static String formatDose(num dose, String unit) {
      final formattedNum = dose < 1 ? '0.$dose' : '$dose';
      return '$formattedNum $unit';
    }
  }
  ```
* **Test Procedure**: Unit test suite verifying dosage string outputs.
* **Definition of Done**: Zero leading decimal points without a zero, space between quantity and unit enforced.

---

## 3. Web Accessibility & Focus Specification (React)

---

### Standard W-01: Keyboard Navigation & Visible Focus Rings

* **Affected App & Component**: `web/src/pages/PatientsPage.tsx`, `web/src/components/NavBar.tsx`.
* **User Impact**: Keyboard-only clinicians cannot identify which button or row currently has focus.
* **Severity**: `Critical`
* **Exact Remediation**: Apply high-contrast 2px solid indigo focus ring (`outline: 2px solid #4338ca; outline-offset: 2px;`) to all focused interactive elements. Never disable focus rings (`outline: none`).
* **Implementation Guidance (React / CSS)**:
  ```css
  :focus-visible {
    outline: 2px solid #4338ca !important;
    outline-offset: 2px !important;
  }
  ```
* **Test Procedure**: Navigate entire web dashboard using `Tab`, `Shift+Tab`, `Enter`, `Space` without touching mouse.
* **Definition of Done**: 100% of interactive controls display a visible, high-contrast focus ring when focused.

---

### Standard W-02: Semantic Forms & Field Error Announcements

* **Affected App & Component**: `web/src/pages/CreatePatientPage.tsx`, `web/src/pages/MedicationsPage.tsx`.
* **User Impact**: Screen readers fail to announce form field labels or validation error messages on submit.
* **Severity**: `High`
* **Exact Remediation**: Connect every `<input>` to a `<label htmlFor="...">`, use `aria-invalid="true"` and `aria-describedby="error-id"` when errors occur.
* **Implementation Guidance (React)**:
  ```tsx
  <div>
    <label htmlFor="patient-email">Patient Email *</label>
    <input
      id="patient-email"
      type="email"
      aria-invalid={!!errors.email}
      aria-describedby={errors.email ? "email-error" : undefined}
    />
    {errors.email && (
      <span id="email-error" role="alert" className="error-text">
        {errors.email}
      </span>
    )}
  </div>
  ```
* **Test Procedure**: Run axe-core automated scanner and test form submission with VoiceOver.
* **Definition of Done**: Zero axe-core form errors; screen reader announces field validation errors immediately on submit.

---

### Standard W-03: Semantic Data Tables & Accessible Charts

* **Affected App & Component**: `web/src/pages/PatientsPage.tsx`, `web/src/pages/MedicationsListPage.tsx`.
* **User Impact**: Screen reader users cannot navigate unstructured grid layouts or interpret visual symptom graphs.
* **Severity**: `High`
* **Exact Remediation**: Use HTML `<table>`, `<thead>`, `<tbody>`, `<th scope="col">` elements for roster data; provide `aria-label` text descriptions for trend charts.
* **Implementation Guidance (React)**:
  ```tsx
  <table role="table" aria-label="Patient Roster">
    <thead>
      <tr>
        <th scope="col">Patient Name</th>
        <th scope="col">Adherence</th>
        <th scope="col">Status</th>
      </tr>
    </thead>
    <tbody>...</tbody>
  </table>
  ```
* **Test Procedure**: Perform VoiceOver table navigation shortcut test (`Control+Option+Arrows`).
* **Definition of Done**: Roster renders as a semantic HTML table and charts provide full text equivalents.

---

### Standard W-04: Modal Focus Trapping & Management

* **Affected App & Component**: `web/src/pages/RecommendationsPage.tsx` (Drawer / Modal).
* **User Impact**: Opening a modal leaves focus on background elements; closing a modal loses focus completely.
* **Severity**: `Critical`
* **Exact Remediation**: Trap focus inside modal container when active, focus first interactive field on open, return focus to trigger button on close, dismiss modal on `Escape`.
* **Implementation Guidance (React)**:
  ```tsx
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);
  ```
* **Test Procedure**: Open modal using keyboard, press `Tab` repeatedly, press `Escape`.
* **Definition of Done**: Focus remains trapped in modal, `Escape` closes modal, focus restores to trigger button.

---

### Standard W-05: Accessible Labels for Icon-Only Buttons

* **Affected App & Component**: `web/src/components/NavBar.tsx`, `web/src/pages/PatientsPage.tsx`.
* **User Impact**: Screen readers read icon buttons (e.g. trash icon, phone icon) as *"unlabeled button"*.
* **Severity**: `High`
* **Exact Remediation**: Add explicit `aria-label="..."` or visually hidden text (`<span className="sr-only">...</span>`) to all icon-only buttons.
* **Implementation Guidance (React)**:
  ```tsx
  <button type="button" aria-label="Call Patient Emergency Contact">
    <PhoneIcon aria-hidden="true" />
  </button>
  ```
* **Test Procedure**: Inspect VoiceOver Rotor $\rightarrow$ Buttons list.
* **Definition of Done**: Zero unlabeled buttons present in screen reader rotor list.

---

### Standard W-06: Responsive Reflow Down to 320px Viewport

* **Affected App & Component**: `web/src/App.tsx`, `web/src/pages/PatientsPage.tsx`.
* **User Impact**: Clinicians using small tablets or 400% zoom experience horizontal scrolling or overlapping text.
* **Severity**: `Medium`
* **Exact Remediation**: Implement CSS flex/grid responsive reflows down to 320px viewport width without horizontal scrollbars (WCAG 2.2 Reflow).
* **Implementation Guidance (React / CSS)**:
  ```css
  @media (max-width: 768px) {
    .patient-grid {
      grid-template-columns: 1fr;
    }
  }
  ```
* **Test Procedure**: Resize Chrome DevTools viewport to 320px width at 400% zoom.
* **Definition of Done**: Page reflows cleanly in single column without horizontal scrollbars or content loss.

---

## 4. Compliance Audit Summary Matrix

| Standard ID | Platform | Domain Area | Target Standard | Severity | Primary Remediation |
|---|---|---|---|---|---|
| **M-01** | Mobile | Screen Reader | WCAG 1.3.1 | Critical | `Semantics` card merging + hints |
| **M-02** | Mobile | Text Scaling | WCAG 1.4.4 | High | Dynamic line wrapping, remove fixed heights |
| **M-03** | Mobile | Color Contrast | WCAG 1.4.1 | Critical | Color + Icon + Text triple status cues |
| **M-04** | Mobile | Touch Targets | WCAG 2.5.8 | High | Minimum $48 \times 48\text{dp}$ hitboxes |
| **M-05** | Mobile | Haptics & Motion| WCAG 2.3.3 | Medium | Visual toasts + respect `disableAnimations` |
| **M-06** | Mobile | One-Handed Ergonomics| Cognitive/Motor | High | Action buttons in bottom 60% thumb zone |
| **M-07** | Mobile | Reading Level | WCAG 3.1.5 | High | Plain-language Grade 8 reading level |
| **M-08** | Mobile | Drug Formatting | Patient Safety | Critical | Leading zeros, dose spacing, Tall Man caps |
| **W-01** | Web | Visible Focus | WCAG 2.4.7 | Critical | 2px solid indigo focus ring (`:focus-visible`)|
| **W-02** | Web | Semantic Forms | WCAG 3.3.2 | High | `<label htmlFor>` + `aria-invalid` |
| **W-03** | Web | Accessible Tables| WCAG 1.3.1 | High | Semantic `<table>` headers + chart text |
| **W-04** | Web | Modal Trapping | WCAG 2.4.3 | Critical | Focus trap + `Escape` key handler |
| **W-05** | Web | Icon Buttons | WCAG 4.1.2 | High | `aria-label` on all icon controls |
| **W-06** | Web | Viewport Reflow | WCAG 1.4.10 | Medium | 320px responsive reflow without scrollbars |

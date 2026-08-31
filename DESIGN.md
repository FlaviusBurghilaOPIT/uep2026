---
name: RemoteCare Pro
description: Intelligent post-operative remote patient monitoring & clinical safety platform
colors:
  # Web Primary (Sky Blue)
  primary-50: "#f0f9ff"
  primary-100: "#e0f2fe"
  primary-500: "#0ea5e9"
  primary-600: "#0284c7"
  primary-700: "#0369a1"
  primary-800: "#075985"
  # Mobile Primary (Deep Teal)
  deep-teal: "#0D9488"
  clinical-emerald: "#059669"
  primary-green: "#1B7D5A"
  dark-green: "#0E5C3F"
  teal-grad-end: "#3DAF8F"
  soft-cyan: "#F0FDF4"
  light-green: "#E8F5F0"
  mint-green: "#F0F7F4"
  # Neutral Slate
  slate-900: "#0f172a"
  slate-800: "#1e293b"
  slate-700: "#334155"
  slate-600: "#475569"
  slate-500: "#64748b"
  slate-400: "#94a3b8"
  slate-300: "#cbd5e1"
  slate-200: "#e2e8f0"
  slate-100: "#f1f5f9"
  slate-50: "#f8fafc"
  surface-white: "#ffffff"
  # Mobile Neutrals
  grey-text: "#6B7280"
  grey-light: "#9CA3AF"
  grey-divider: "#E5E7EB"
  input-fill: "#F3F4F6"
  card-bg: "#F9FAFB"
  # Clinical Severity — Critical
  critical-bg: "#fef2f2"
  critical-border: "#f87171"
  critical-text: "#991b1b"
  critical-accent: "#ef4444"
  error-red: "#DC2626"
  # Clinical Severity — Moderate
  moderate-bg: "#fffbeb"
  moderate-border: "#fbbf24"
  moderate-text: "#92400e"
  moderate-accent: "#f59e0b"
  # Clinical Severity — Stable
  stable-bg: "#f0fdf4"
  stable-border: "#86efac"
  stable-text: "#15803d"
  stable-accent: "#10b981"
  # Medication Status
  taken-bg: "#DCFCE7"
  taken-text: "#166534"
  pending-bg: "#FEF9C3"
  pending-text: "#854D0E"
  missed-bg: "#FEE2E2"
  missed-text: "#991B1B"
  # Specialty
  info-blue: "#3B82F6"
  purple-accent: "#7c3aed"
typography:
  display:
    fontFamily: "Outfit, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "clamp(2rem, 4vw + 1rem, 3.25rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.025em"
  heading1:
    fontFamily: "Outfit, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "1.75rem"
    fontWeight: 700
    lineHeight: 1.2
  heading2:
    fontFamily: "Outfit, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 700
    lineHeight: 1.25
  heading3:
    fontFamily: "Outfit, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
  body-small:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "0.05em"
rounded:
  xs: "4px"
  sm: "6px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  2xl: "24px"
  pill: "9999px"
spacing:
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  6: "24px"
  8: "32px"
  12: "48px"
  16: "64px"
components:
  button-primary-web:
    backgroundColor: "{colors.primary-600}"
    textColor: "{colors.surface-white}"
    rounded: "{rounded.md}"
    padding: "14px 28px"
  button-primary-web-hover:
    backgroundColor: "{colors.primary-700}"
  button-secondary-web:
    backgroundColor: "{colors.slate-100}"
    textColor: "{colors.slate-700}"
    rounded: "{rounded.md}"
    padding: "14px 28px"
  button-primary-mobile:
    backgroundColor: "{colors.primary-green}"
    textColor: "{colors.surface-white}"
    rounded: "{rounded.xl}"
    height: "56px"
  button-outlined-mobile:
    backgroundColor: "transparent"
    textColor: "{colors.primary-green}"
    rounded: "{rounded.xl}"
    height: "56px"
  card-web:
    backgroundColor: "{colors.surface-white}"
    rounded: "{rounded.lg}"
    padding: "20px"
  card-mobile:
    backgroundColor: "{colors.surface-white}"
    rounded: "{rounded.lg}"
    padding: "16px"
  input-web:
    backgroundColor: "{colors.surface-white}"
    textColor: "{colors.slate-900}"
    rounded: "{rounded.md}"
    padding: "10px 12px"
  input-mobile:
    backgroundColor: "{colors.input-fill}"
    textColor: "{colors.slate-900}"
    rounded: "{rounded.lg}"
    padding: "16px 16px"
  nav-sidebar:
    backgroundColor: "{colors.slate-900}"
    textColor: "{colors.slate-400}"
    width: "260px"
  badge-critical:
    backgroundColor: "{colors.critical-bg}"
    textColor: "{colors.critical-text}"
    rounded: "{rounded.sm}"
    padding: "4px 10px"
  badge-moderate:
    backgroundColor: "{colors.moderate-bg}"
    textColor: "{colors.moderate-text}"
    rounded: "{rounded.sm}"
    padding: "4px 10px"
  badge-stable:
    backgroundColor: "{colors.stable-bg}"
    textColor: "{colors.stable-text}"
    rounded: "{rounded.sm}"
    padding: "4px 10px"
---

# Design System: RemoteCare Pro

## Overview

**Creative North Star: "The Recovery Ward"**

RemoteCare Pro's design system is the digital equivalent of a well-run post-operative floor: warm, monitored, reassuring. Every surface prioritizes clinical clarity and patient confidence. The system is deliberately bifocal — the clinician web portal uses a disciplined operations aesthetic (dark slate navigation, sky-blue primary, severity-striped triage cards), while the patient mobile companion uses a softer recovery palette (teal/emerald gradients, rounded forms, celebration animations). Both share the same information hierarchy principle: normal states recede, exceptions surface.

The visual density shifts by audience. Clinicians operate in a data-rich environment where scan speed matters — compact typography, tabular data, severity color-coding. Patients operate in a reassurance environment where confidence and simplicity matter — generous spacing, clear medication timelines, one-tap actions, and haptic confirmation. Despite these different densities, the system maintains a unified tonal palette (slate neutrals, clinical severity colors) and a shared commitment to flat-by-default elevation.

**Key Characteristics:**
- **Bifocal design language:** Operations-grade precision for clinicians, recovery-grade warmth for patients
- **Exception-driven visual hierarchy:** Normal states are quiet; severity states are unmissable
- **Flat and tonal depth model:** Background fills and subtle borders create separation; shadows appear only on hover or elevation change
- **Clinical and steady component feel:** Components communicate state clearly without competing for attention; interactions are tactile but restrained
- **Dual typography pairing:** Outfit (display/headings) + Inter (body/labels) — modern clinical warmth with maximum legibility
- **Three-tier clinical severity palette:** Red/Amber/Green severity colors are consistent across both surfaces

## Colors

A clinical-grade palette where severity is semantic and brand is contextual. The web surface leads with sky-blue; the mobile surface leads with deep teal. Both share the same neutral slate ramp and the same red/amber/green clinical severity vocabulary.

### Primary

- **Sky Clinical Blue** (#0284c7, `--primary-600`): The web surface's primary interactive color. Used for CTAs, links, focus outlines, active nav highlights, and brand icon glow. Its ramp spans from near-white (#f0f9ff) to deep navy (#075985).
- **Deep Teal** (#0D9488): The mobile surface's primary interactive color. Used for focused input borders, active tab icons, link text, and outlined button strokes. Derived from a teal seed via Material 3 `ColorScheme.fromSeed`.
- **Clinical Emerald** (#059669): The mobile celebration accent. Reserved for the 600ms ring-closure animation, success confirmations, and high-confidence recovery signals.
- **Primary Green** (#1B7D5A): The mobile surface's primary action button color. Used for filled CTAs, adherence chart bars, and brand accent badges.

### Neutral

- **Slate 900** (#0f172a): Primary text color (both surfaces), web sidebar background, mobile snackbar background. The darkest value in the system.
- **Slate 700** (#334155): Body text color on web, form labels, card borders. Readable against white and slate-50 backgrounds.
- **Slate 500** (#64748b): Muted text, subtitles, placeholder icons, helper copy. The midpoint between readable and recessive.
- **Slate 200** (#e2e8f0): Card borders, divider lines, table cell separators. The primary structural stroke color on web.
- **Slate 50** (#f8fafc): Page background on web, alternating table rows, card header fills.
- **Grey Text** (#6B7280): Mobile secondary body text, subtitles, inactive icons. Equivalent to slate-500 in the mobile palette.
- **Grey Divider** (#E5E7EB): Mobile card borders, horizontal dividers, unselected progress segments.
- **Input Fill** (#F3F4F6): Mobile text field background fill, OTP cell background, inactive badge background.

### Named Rules

**The Severity Is Semantic Rule.** Red means clinical danger or error. Amber means warning, moderate risk, or attention required. Green means stable, complete, or confirmed. These three hues are never decorative — they always carry clinical meaning. No component may use `#ef4444`, `#f59e0b`, or `#10b981` (or their tonal variants) for brand expression or visual interest.

**The Surface-Appropriate Primary Rule.** Web surfaces use sky-blue (#0284c7) as their primary interactive color. Mobile surfaces use deep teal (#0D9488) or primary green (#1B7D5A). Neither primary appears on the other's surface except in shared severity contexts.

## Typography

**Display Font:** Outfit (with system sans-serif fallback)
**Body Font:** Inter (with system sans-serif fallback)
**Web System Font:** -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif

**Character:** Outfit provides modern geometric warmth for headings — open counters, even stroke weight, contemporary without being trendy. Inter provides maximum legibility for body text and data — tabular figures, clear small sizes, neutral enough to recede behind the content it carries. On the web surface, the system font stack replaces both in production for performance; Outfit + Inter are the mobile's canonical pairing.

### Hierarchy

- **Display** (Outfit 700, `clamp(2rem, 4vw + 1rem, 3.25rem)` web / 32sp mobile, line-height 1.1–1.15): Landing page hero headline and mobile display titles. Tracked tight at -0.025em on web.
- **Heading 1** (Outfit 700, 28sp mobile / 24–26px web, line-height 1.2): Page primary titles, section headers.
- **Heading 2** (Outfit 700, 24sp mobile / 20–22px web, line-height 1.25): Card titles, dialog headers, stat values.
- **Heading 3** (Outfit 600, 20sp mobile / 17–18px web, line-height 1.3): Sub-section headers, metric labels.
- **Body** (Inter 400, 16sp mobile / 16px web, line-height 1.5): Paragraph text, descriptions, input values. Max measure 66ch on web.
- **Body Small** (Inter 400, 14sp mobile / 14px web, line-height 1.5): Table cells, standard buttons, card body text.
- **Label** (Inter 600, 12sp mobile / 12px web, line-height 1.4, letter-spacing 0.05em): Form labels, badge text, uppercase category headers. Often set in ALL CAPS with 1.2 tracking on mobile.

### Named Rules

**The Measure Rule.** Body text on the web never exceeds 66ch (`--measure: 66ch`). Readable lines prevent the clinical dashboard from feeling like a spreadsheet.

**The Tabular Figures Rule.** All numeric data — OTP codes, countdown timers, adherence percentages, stat values — uses `font-feature-settings: 'tnum'` (Inter) or `FontFeature.tabularFigures()` (Flutter) so digits align vertically in columns and counters don't shift layout on update.

## Layout

### Web Surface

The clinician portal uses a fixed 260px left sidebar navigation with a full-height dark background (`--slate-900`). The main content area fills the remaining viewport width with 32px page padding. Cards, tables, and forms use a fluid single-column or responsive grid layout.

Breakpoints are implicit (no formal token system), but the sidebar collapses to a mobile drawer below approximately 768px. Content containers rarely exceed ~1200px effective width.

The 8-point spacing scale (`--space-1` through `--space-16`) provides rhythm: 4px micro-gaps, 8px icon-text pairs, 16px card gaps, 24px section spacing, 32px page gutters, 48–64px section breaks.

### Mobile Surface

The mobile app targets iPhone X / 11 Pro baseline (375×812 design size) via `flutter_screenutil`, with all dimensions expressed in responsive units (`.w`, `.h`, `.r`, `.sp`).

Screen-level horizontal padding is 24w. Vertical screen gutter is 16h. Cards use 16w or 20w internal padding. The vertical spacing scale mirrors the 8-point web grid: xs(4), sm(8), md(12), lg(16), xl(24), xxl(32), xxxl(48).

A 5-tab bottom navigation bar (70h tall) anchors the mobile shell. Interactive elements maintain a minimum 48dp×48dp touch target.

## Elevation & Depth

Flat and tonal. Both surfaces default to zero-elevation components. Depth is communicated primarily through background fill changes and 1px border strokes rather than cast shadows.

Shadows exist but are deliberately inconspicuous:

### Shadow Vocabulary

- **Ambient Card** (`0 1px 2px rgba(15,23,42,0.05)` web / `alpha: 0.03, blur: 8, offset: 0,2` mobile): The default card shadow — barely visible, just enough to lift white cards from slate-50 backgrounds. Present at rest on web; present at rest on mobile.
- **Standard Elevation** (`0 4px 6px -1px rgba(15,23,42,0.08)` web): Form cards, login card, modal cards. Slightly more pronounced but still ambient.
- **Hover Lift** (`0 6px 16px rgba(15,23,42,0.08)` web): Cards on hover. Combined with `translateY(-2px)` to create a physical "picked up" sensation.
- **Modal Float** (`0 20px 25px -5px rgba(15,23,42,0.15)` web): Resolution dialog, modal overlays. The heaviest shadow in the system.
- **Brand Glow** (`0 2px 4px rgba(2,132,199,0.2)` web): Primary CTA buttons and brand icon. A tinted blue glow rather than a neutral shadow.
- **Bottom Nav Shadow** (`alpha: 0.06, blur: 16, offset: 0,-4` mobile): The only upward-casting shadow. Creates the bottom navigation bar's "shelf" above content.
- **Celebration Glow** (`clinicalEmerald alpha: 0.08, blur: 12, offset: 0,4` mobile): The emerald-tinted glow beneath the day-complete ring-closure celebration card.
- **Emergency Alert Glow** (`0 0 8px rgba(239,68,68,0.4)` web): Live triage critical alert pulse. The only shadow that demands attention.

### Named Rules

**The Flat-By-Default Rule.** Components start at elevation zero. Shadows appear only as a response to state change (hover, focus, modal open) or to separate fixed chrome from scrollable content (bottom nav, sidebar). A card that looks lifted at rest is overdesigned.

## Shapes

The system uses a consistent radius hierarchy that scales with component importance:

- **Micro** (4px / xs): Skeleton loading placeholders, inline code blocks, time pills
- **Small** (6px / sm): Badges, pill buttons, language switcher, search inputs
- **Standard** (8px / md): Text inputs, primary buttons (web), dropdown selects, tabs
- **Card** (12px / lg): Content cards, feature cards, triage cards, table containers, input fields (mobile)
- **Large** (16px / xl): Login card, modal dialogs, AI summary drawer, primary buttons (mobile), chat bubbles
- **Hero** (24px / 2xl): Onboarding hero containers, large rounded features
- **Circle** (50% / 50r): Avatars, status indicator dots
- **Pill** (9999px): Progress bars, count badges, telemetry pills, condition chips

The mobile surface uses asymmetric radii for directional components: chat bubbles have a small (4r) corner at the tail and full (16r) corners elsewhere. The onboarding hero uses bottom-only rounding (32r) to create a curtain effect.

### Named Rules

**The Radius Scales With Permanence Rule.** Ephemeral elements (badges, chips) use small radii. Persistent containers (cards, modals) use large radii. The exception is pill-shaped elements (progress bars, status badges), which use 9999px to signal self-contained data rather than interactive surface.

## Components

### Buttons

Clinical and steady. Buttons communicate available actions without visual competition. The tactile `scale(0.97)` active press on web and `scale(0.97)` on mobile provides physical feedback without animation drama.

- **Shape:** Gently curved edges — 8px radius on web, 16r radius on mobile
- **Primary (web):** Sky-blue background (#0284c7), white text, 600 weight, 14px 28px padding. Blue glow shadow (`rgba(2,132,199,0.3)`). Hover darkens to #0369a1.
- **Primary (mobile):** Primary green background (#1B7D5A), white text, 600 weight, full-width 56dp height. No shadow at rest, `elevation: 0`.
- **Secondary (web):** Slate-100 background, slate-700 text, 1px slate-300 border. Hover fills to slate-200.
- **Outlined (mobile):** Transparent background, primary green text, 1.5px primary green border, 56dp height.
- **Hover / Focus:** Web buttons transition background, shadow, and transform over 140ms with `ease-out`. All interactive elements show a 2px solid primary focus ring with 2px offset on `:focus-visible`.
- **Loading:** Web uses an inline spinner (16px border ring). Mobile uses a centered 24w CircularProgressIndicator with 2.5 stroke width.

### Cards / Containers

- **Corner Style:** 12px radius on both surfaces
- **Background:** White (#ffffff) on both surfaces. Mobile inactive cards use #F9FAFB.
- **Shadow Strategy:** Ambient card shadow at rest (barely visible). Hover lift on web with translateY(-2px). No hover state on mobile.
- **Border:** 1px solid slate-200 (#e2e8f0) on web. 1px solid grey-divider (#E5E7EB) on mobile.
- **Internal Padding:** 20px on web, 16w on mobile
- **Triage Cards (web):** Standard card styling plus a 4px left border in severity color (red #ef4444, amber #f59e0b, green not used — stable patients don't need a card).

### Inputs / Fields

- **Web Style:** White background, 1px solid slate-300 (#cbd5e1) border, 8px radius, 10px 12px padding. System font at 14px.
- **Mobile Style:** Filled input-fill (#F3F4F6) background, no visible border at rest, 12r radius, 16w horizontal / 18h vertical padding. Inter at 15sp.
- **Focus (web):** Border shifts to primary-600 (#0284c7), focus ring `0 0 0 3px rgba(2,132,199,0.15)`.
- **Focus (mobile):** 1.5px border appears in deep-teal (#0D9488).
- **Error:** Web shows red text (#b91c1c) and red border. Mobile uses 1.5px error-red (#DC2626) border.
- **Disabled:** Reduced opacity, pointer-events none.

### Navigation

- **Web Sidebar:** Fixed 260px width, slate-900 (#0f172a) background, 1px slate-800 right border. Active link gets a 3px sky-400 (#38bdf8) left border and a subtle blue gradient fill. Inactive links are slate-400 with opacity transition. Section headers are 10px uppercase with 0.08em tracking.
- **Mobile Bottom Nav:** White background, 70h height, 5 tab destinations. Active tab shows primary-green icon and a 5w circular dot indicator. Top shadow separates nav from content. Tab switch uses 200ms AnimatedSwitcher.

### Severity Badges

A three-tier system shared across both surfaces:
- **Critical / Red:** Light red background (#fef2f2), dark red text (#991b1b), red border (#f87171). Used for missed doses, critical triage, errors.
- **Moderate / Amber:** Light amber background (#fffbeb / #FEF9C3), dark amber text (#92400e / #854D0E), amber border (#fbbf24). Used for warnings, overdue items, FDA alerts.
- **Stable / Green:** Light green background (#f0fdf4 / #DCFCE7), dark green text (#15803d / #166534), green border (#86efac). Used for taken doses, stable patients, successful actions.

### Segmented Frequency Selector (Web — Signature Component)

A 5-column grid for medication frequency selection (QD/BID/TID/QID/PRN). Slate-50 container background with 10px radius. Individual segments are 7px radius buttons with two-line content (code + description). Active segment fills with primary-600 (#0284c7) and white text with 0.25 blue shadow. Tactile press at scale(0.95).

### Celebration Ring Card (Mobile — Signature Component)

A 600ms arc-sweep animation (easeInOutCubic) that fills a circular progress ring in clinical emerald (#059669) when all daily doses are logged. Accompanied by an icon morph from `check` to `sparkles` and an emerald glow shadow. The card is dismissible with a 180ms size/fade exit transition.

## Do's and Don'ts

### Do:

- **Do** use the severity color system (red/amber/green) exclusively for clinical meaning — never for brand expression or visual variety.
- **Do** maintain the 8-point spacing grid on both surfaces. When in doubt, use the next value up from the scale (4→8→12→16→24→32→48→64).
- **Do** use tabular figures (`font-feature-settings: 'tnum'`) for all numeric data, countdowns, and aligned columns.
- **Do** provide a 2px solid primary-color focus ring with 2px offset on every interactive element for keyboard navigation.
- **Do** gate all motion behind `prefers-reduced-motion` (web) and `MediaQuery.disableAnimations` (mobile). Every animation must have a static fallback.
- **Do** use the tactile `scale(0.97)` active press on buttons and interactive cards. It's the system's signature micro-interaction.
- **Do** keep body text under 66ch measure on the web surface.

### Don't:

- **Don't** mix web-primary (#0284c7) and mobile-primary (#0D9488 / #1B7D5A) on the same surface. Each surface has its own primary.
- **Don't** use shadows for visual hierarchy at rest. Depth comes from background fill and border contrast. Shadows respond to state.
- **Don't** add elevation to mobile cards beyond the ambient `alpha: 0.03` tier. The mobile surface is deliberately flat.
- **Don't** introduce new font families. The system uses Outfit + Inter on mobile and the system font stack on web. No decorative typefaces.
- **Don't** use border-radius values outside the established scale (4/6/8/12/16/24/9999px). No arbitrary radii.
- **Don't** create triage or severity indicators in colors outside the red/amber/green vocabulary. No blue or purple severity.
- **Don't** fabricate testimonials, clinical outcomes data, or regulatory certifications that don't exist in the evidence on hand.

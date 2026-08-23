# Design System

## Design Direction
- **Personality**: Clinical authority, high-trust precision, calm focus, instant legibility.
- **Signature Moment**: The **"Day Complete" Ring Closure & Recovery Sparkle** — 100% progress sweep with haptic pulse (`HapticFeedback.mediumImpact()`) and reassuring recovery closure ("All doses completed for Day X. Rest well and heal.").
- **Visual Aesthetic**: Tailored slate/sky palette (`#0f172a`, `#0284c7`, `#38bdf8`), crisp borders (`#e2e8f0`), tinted functional status badges, and subtle depth elevation shadows.

## Typography
- **Primary Typeface**: Modern System Sans (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`) for instantaneous render with 0ms FOUT/FOIT.
- **Modular Scale (Fluid clamp)**:
  - Hero Heading (Display): `clamp(2rem, 4vw + 1rem, 3.25rem)` (32px - 52px), weight 800, line-height 1.15, letter-spacing -0.025em.
  - Section Heading (H2): `clamp(1.5rem, 2.5vw + 0.5rem, 2.25rem)` (24px - 36px), weight 700, line-height 1.25, letter-spacing -0.02em.
  - Card / Subheading (H3): `1.25rem` (20px), weight 600, line-height 1.35.
  - Body Text: `1rem` (16px, min size for high legibility), weight 400, line-height 1.6, color `#334155`.
  - Small / Badge / Meta: `0.875rem` (14px) / `0.75rem` (12px), weight 500, line-height 1.4.
- **Measure (Line Length)**: Strict 45–75 characters (~66ch optimal) across all marketing and clinical narrative blocks.
- **Loading Strategy**: Zero external webfont network hops (uses system font stack), zero render blocking, <1KB font CSS payload.

## Tokens

### Spacing Scale (8-point grid with 4px half-step)
- `space-1`: `4px` (subtle gaps, icon margins)
- `space-2`: `8px` (compact padding, badge margins)
- `space-3`: `12px` (input padding, compact grid gap)
- `space-4`: `16px` (standard card padding, element gap)
- `space-6`: `24px` (section inner margins, container padding)
- `space-8`: `32px` (card separation, sub-section spacing)
- `space-12`: `48px` (large section margins)
- `space-16`: `64px` (hero & page section dividers)

### Color Palette (WCAG AAA/AA Compliant)
- **Brand Primary**:
  - Primary Base: `#0284c7` (Sky 600, 4.5:1 contrast against white)
  - Primary Hover: `#0369a1` (Sky 700)
  - Primary Light: `#e0f2fe` (Sky 100)
- **Neutral / Slate (Tinted Grays, not dead black #000)**:
  - Slate 900 (Deep Navy / Header): `#0f172a`
  - Slate 800 (Sidebar / Dark Card): `#1e293b`
  - Slate 700 (High-Contrast Text): `#334155`
  - Slate 500 (Muted / Subtitles): `#64748b`
  - Slate 200 (Borders): `#e2e8f0`
  - Slate 50 (Background): `#f8fafc`
  - Surface White: `#ffffff`
- **Clinical Functional Alerts**:
  - Critical / Red: Text `#b91c1c` (Red 700), Background `#fef2f2` (Red 50), Border `#fca5a5`
  - Moderate / Amber: Text `#b45309` (Amber 700), Background `#fffbeb` (Amber 50), Border `#fcd34d`
  - Stable / Green: Text `#15803d` (Green 700), Background `#f0fdf4` (Green 50), Border `#86efac`

### Elevation & Shadows
- `shadow-sm`: `0 1px 2px 0 rgba(15, 23, 42, 0.05)`
- `shadow-md`: `0 4px 6px -1px rgba(15, 23, 42, 0.08), 0 2px 4px -2px rgba(15, 23, 42, 0.05)`
- `shadow-lg`: `0 10px 15px -3px rgba(15, 23, 42, 0.08), 0 4px 6px -4px rgba(15, 23, 42, 0.04)`
- `shadow-glow`: `0 0 20px rgba(2, 132, 199, 0.25)`

## Components
| Component | Decision | Status |
|---|---|---|
| **Landing Hero** | Two-column responsive hero with high-contrast headline, one-liner, live demo CTA, trust badges, and interactive triage preview card | Built |
| **Interactive Triage Preview** | Live mock exception cards demonstrating 1-click resolution, simulated adherence telemetries, and instant audio/visual cues | Built |
| **Feature Grid** | 3-column benefit cards highlighting Bedrock AI guardrails, closed-loop adherence, and live FDA safety integration | Built |
| **How It Works Timeline** | 3-step numbered progression (1: Clinician Prescribes, 2: Patient Receives & Logs, 3: Real-Time Triage) | Built |
| **Quick Demo Login Modal / Card** | 1-click authentication bypass with demo clinician credentials prefilled | Built |
| **Navigation Bar** | Sticky header with brand icon, language switcher, direct demo launch button, and clean portal navigation | Built |
| **Mobile Dose Slot Card** | Optimistic 1-tap Taken/Skipped actions, time-slot grouping, pill form icons, and 5s undo snackbar | Built |
| **Mobile AI Safety Pill** | Pinned clinical badge affirming Amazon Bedrock safety guardrails and non-diagnostic boundary | Built |
| **Mobile Emergency Red Flag Banner** | 1-tap 911 / clinic direct dial banner above symptom intake | Built |
| **Recovery Progress Ring** | Animated SVG/Canvas circular sweep with daily completion sparkle and haptic feedback | Built |

## UX & Performance Audit Findings (Nielsen Heuristics, Norman Gulfs, Core Web Vitals)
| Issue / Metric | Heuristic / Domain | Severity (0-4) | Target / Fix | Status |
|---|---|---|---|---|
| **PERF-01**: Input response latency during network writes | Performance (INP) | 3 (Major) | **INP < 100ms** via optimistic state update + background sync queue | Done |
| **PERF-02**: Initial page load & script execution time | Performance (LCP) | 3 (Major) | **LCP < 1.2s** via code splitting (`React.lazy`), 0ms system font stack | Done |
| **PERF-03**: Layout jumping during data fetch | Performance (CLS) | 2 (Minor) | **CLS < 0.01** via bounding box skeleton loaders (`AppSkeletonLoader`) | Done |
| **UX-01**: Acute symptoms lack clear emergency escalation banner | H10: Help / H5: Prevention | 4 (Catastrophe) | Pin Emergency Banner with 1-tap direct dial (911 / Clinic Direct) | Done |
| **UX-02**: Ambiguous dose write status on slow network | H1: Visibility of Status | 3 (Major) | Optimistic state update with 100ms micro-pulse + 5s non-blocking Undo snackbar | Done |
| **UX-03**: Post-op patient OTP entry fatigue | H5: Prevention / H7: Efficiency | 3 (Major) | Implement clipboard auto-paste, segmented 6-digit input, auto-submit | Done |
| **UX-04**: Clinicians must drill into single patient cases to triage | H7: Flexibility & Efficiency | 3 (Major) | Unified high-density Triage Dashboard matrix with 1-click quick-outreach modal | Done |
| **UX-05**: Generic text-only medication cards | H2: Match Real World | 3 (Major) | Add visual pill form icons (Capsule, Tablet, Liquid) and plain-English timing tags | Done |
| **UX-06**: Raw technical error messages during offline / sync drops | H9: Help Users Recover | 3 (Major) | User-friendly copy: *"Saved locally. Will sync automatically when reconnected."* | Done |
| **UX-07**: Excessive disclaimer repetition inside AI chat bubbles | H8: Aesthetic & Minimalist | 2 (Minor) | Persistent top clinical guardrail pill; keep conversation bubbles clean | Done |
| **ND-01**: Accidental dose skip during scroll | Norman Slip | 3 (Major) | Prefer 5s Undo snackbar + easy slot tap correction over modal warning dialogs | Done |
| **ND-02**: Typos & invalid frequencies in prescription form | Norman Constraint | 3 (Major) | Constrain Rx time slots to validated clinical slots (08:00, 12:00, 18:00, 21:00) | Done |
| **ND-03**: Patient anxiety over symptom submission | Norman Evaluation | 2 (Minor) | Explicit confirmation: *"Telemetry Received • Dr. Miller's care team alerted"* | Done |

## Microinteraction Inventory
| Interaction | Trigger / Rules / Feedback / Loops | Fix | Status |
|---|---|---|---|
| **Dose Logging (Taken/Skipped)** | Tap `[Log Taken]` → Optimistic Riverpod state mutation in <10ms; write SQLite queue; non-blocking API call. Direct feedback: Button scales 0.96, morphs to solid green checkmark with 120ms spring, `HapticFeedback.lightImpact()`, progress ring advances. Loops: 5s Undo snackbar. | Add SpringAnimation + HapticImpact + Riverpod Optimistic Notifier | Done |
| **Signature Moment: Ring Closure** | Last dose of the day logged (100% adherence) → Progress ring sweeps closed, emerald confetti glow, `HapticFeedback.mediumImpact()`. Message: *"All doses completed for Day X. Rest well and heal."* | CustomPainter ProgressRing with AnimatedBuilder + Haptic feedback | Done |
| **AI Assistant Streaming** | Query submit → SSE connection. Sub-200ms pulsating typing bubble → token typewriter effect → smooth physics auto-scroll. Loops: Inline retry on network drop. | StreamSubscription listener + ScrollController animateTo | Done |
| **Symptom Mood Selection** | Tap feeling pill (Great/OK/Not Great/Bad) → 100ms scale pop + active border. Expands structured notes in 150ms. Severe feeling immediately reveals Emergency Red Flag banner. | AnimatedContainer + crossFade to symptom options | Done |
| **Clinician Triage Resolve (Web)** | Click `[Resolve Alert]` → Dialog with mandatory note (>10 chars). Submitting flashes green checkmark; row smoothly transitions out in 200ms; toast confirms with `[Undo]`. | Dialog with form validation + toast notification with undo handler | Done |
| **CTA Hover & Click** | Hover: translateY(-2px) + shadow-lg; Click: active scale(0.98); instant transition | Add smooth 150ms cubic-bezier transition to all primary and secondary buttons | Done |
| **Language Switcher** | Click: Immediate re-render in EN / ES / IT with active border indicator | LanguageProvider React context with localStorage persistence | Done |

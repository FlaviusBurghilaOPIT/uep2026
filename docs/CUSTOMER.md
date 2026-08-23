# Customer Profile & Jobs to Be Done (JTBD)

## Job Statement

> **Primary Job (Post-Surgical Patient)**:  
> *"When I am discharged home following a surgical procedure, I want to execute my prescribed medication regimen accurately and verify unexpected symptoms instantly, so I can recover safely and comfortably without complications, anxiety, or hospital readmission."*

> **Supporting Job (Surgical & Clinical Care Team)**:  
> *"When my post-op patients leave the facility, I want automated visibility into their daily protocol adherence and immediate triage alerts for high-risk adverse events, so I can intervene early without hours of manual follow-up."*

---

## Job Dimensions & Underdelivery Notes

### 1. Functional Dimension
- **Core Expectation**: Log scheduled doses in 1 tap at the exact scheduled slot, receive timely contextual reminder notifications, and ask questions about drug interactions or side effects.
- **Where App Underdelivers**:
  - Ambiguous loading and offline sync states when logging doses on weak Wi-Fi/cellular connectivity.
  - Lack of distinct visual drug form/color identifiers on dose cards to prevent medication confusion.
  - Manual 6-digit OTP code entry post-discharge creates high friction when the patient is groggy or fatigued.

### 2. Emotional Dimension
- **Core Expectation**: Relieve post-discharge vulnerability, eliminate fear of accidental double-dosing or missed critical antibiotics, and receive calming, authoritative reassurance on recovery progress.
- **Where App Underdelivers**:
  - AI chat streaming lack of an explicit clinical safety seal, leaving anxious patients unsure if the response is clinically safe.
  - Clinical stats and empty screens feel sterile and punitive rather than empathetic and encouraging.

### 3. Social Dimension
- **Core Expectation**: Reassure family caregivers that the recovery plan is on track, and demonstrate adherence to the surgeon's exact protocol at the follow-up visit.
- **Where App Underdelivers**:
  - No easily glanceable recovery milestone card or shareable summary ("Day 3 of 14 — Protocol Followed 100%") for caregivers or clinical staff.

---

## Competing Alternatives

| Alternative | Why Hired | Critical Weakness (Why They Fire It) |
|---|---|---|
| **Paper Discharge Instructions + Plastic Pillbox** | Tangible, familiar, zero digital barrier | Static; no reminders; cannot verify taken doses; invisible to doctor; easily lost or misread. |
| **Native Phone Alarms / Calendar Reminders** | Free, loud, easy to set up | Generic alarm; no medication details or dose history; easy to snooze and dismiss; zero clinical telemetry. |
| **Generic Habit Trackers (Apple Health, Streaks)** | Clean visual polish, streak counters | Not clinician-linked; no post-op protocol intelligence; no adverse event or FDA safety checks. |
| **WebMD / Google Search for Symptoms** | Instant 24/7 availability | High risk of health anxiety / misdiagnosis; ungrounded in actual surgical case history. |
| **Non-Consumption (Improvising / Guessing)** | Zero effort when fatigued | High rate of medication non-adherence, preventable complications, and 30-day readmissions. |

---

## Big Hire vs Little Hire Dynamics

- **The Big Hire (Discharge / Onboarding)**:  
  The moment the patient is discharged home with prescriptions. The app is "hired" to replace confusing paper sheets with a guided mobile companion. Drop-off occurs if initial magic code auth or profile setup feels daunting.
- **The Little Hire (Daily Dose Habit Loop)**:  
  Every morning, afternoon, evening, and bedtime when a dose is due. The app is "hired" for 2 seconds of effortless confirmation ("Taken" → satisfying checkmark → immediate peace of mind). Friction occurs if the app takes >2s to open or buttons feel dead.

---

## Desired Outcomes & Metric Signals
- **Primary Metric**: Day-1 to Day-14 Dose Adherence Rate > 90%.
- **Secondary Metric**: Patient Onboarding Completion Rate > 95% within 24h of discharge.
- **Guardrail Metric**: Zero unhandled symptom escalations (>99.9% triage capture rate).

---
type: Interview Ledger
parent: spec.md
---

## Records

### L1
Status: current
Question: How should the greeting and date header on Screen A01 (TodayScreen) handle narrow viewports (<360dp)?
Answer: Apply a fluid clamp with `maxLines: 1` and overflow ellipsis so the date and greeting header never wrap unpredictably or overflow on narrow screens.
Decision: Standardize header text styling with fluid responsive scale and strict single-line ellipsis clamping.
Constraints:
- Must not wrap into unexpected multi-line layouts on viewports < 360dp.
- Must preserve date localization.

### L2
Status: current
Question: What typography and styling should be applied to the AI Assistant disclaimer guardrail banner (Screen A05)?
Answer: Set to system sans-serif 13.sp, weight 500, #334155 on #F0FDF4 background with 1.4 line-height, eliminating italic serif styling to maximize legibility during cognitive fatigue.
Decision: Refactor `GuardrailBanner` in `assistant_screen.dart` to use high-contrast sans-serif 13.sp with #334155 text and #F0FDF4 emerald background.

### L3
Status: current
Question: How should numeric OTP input cells (Screen B03) render digits during entry and countdowns?
Answer: Force tabular numbers using `fontFeatures: [FontFeature.tabularFigures()]` and monospaced styling to eliminate character width shifts and layout jitter.
Decision: Apply `FontFeature.tabularFigures()` to OTP entry cells and countdown displays.

### L4
Status: current
Question: How should recovery adherence metric percentages on Screen A04 (RecoveryScreen) be distinguished from category labels?
Answer: Emphasize the metric value with bold display weight (700) and distinct clinical emerald hue (#10B981 / `AppColors.primaryGreen`), differentiating from 400 weight secondary labels.
Decision: Update recovery adherence stat typography to font weight 700 and primary emerald accent.

### L5
Status: current
Question: How should severe symptom reporting ("Feeling Unwell" / 'bad') escalate in Screen A03 (CheckInCard)?
Answer: Pin a sticky Emergency Red Flag banner with 1-tap direct dial (911 / Clinic emergency hotline) above the fold immediately upon selecting 'bad' / 'unwell'.
Decision: Render sticky 1-tap direct emergency phone link when severe symptoms are selected.

### L6
Status: current
Question: How should 6-digit OTP verification on Screen B03 handle input ergonomics?
Answer: Implement automatic clipboard paste listening, segmented digit focus progression, auto-advance, and auto-submit on 6th digit entry.
Decision: Support seamless paste and auto-submission on 6th digit in `VerifyCodeScreen`.

### L7
Status: current
Question: How should dose skipping confirmation on Screen A02 (DoseSlotCard) behave?
Answer: Replace disruptive blocking modal alert dialogs with a 5-second non-blocking SnackBar featuring an instant `[Undo]` button.
Decision: Convert dose skip action to optimistic log with 5-second undo SnackBar.

### L8
Status: current
Question: When should password criteria and requirements be displayed on Screen B05 (CreatePasswordScreen)?
Answer: Display real-time dynamic requirement checklist (8+ chars, number, symbol) updating interactively on keypress rather than after form submit failure.
Decision: Add live interactive password validation feedback checklist.

### L9
Status: current
Question: How should phone number inputs on Screen A06 (ProfileScreen edit sheet) behave on re-focus?
Answer: Preserve cursor position at the end of text upon re-focus and format input with E.164 telecommunication mask.
Decision: Maintain cursor position and apply phone formatting mask in profile contact editing.

### L10
Status: current
Question: How should network latency and offline sync drops be communicated across A01 and A04?
Answer: Replace raw technical exceptions (`SocketException`, `HTTP 422`) with human-centered copy: "Saved locally. Will sync automatically once reconnected."
Decision: Standardize offline and sync error copy to reassuring plain language.

### L11
Status: current
Question: Where should AI clinical guardrail disclaimers live on Screen A05?
Answer: Consolidate disclaimers into a persistent top guardrail banner, eliminating repetitive medical disclaimer prefixes from individual chat bubbles.
Decision: Keep chat bubbles conversational while pinning the persistent disclaimer banner at the top of `AssistantScreen`.

### L12
Status: current
Question: How should authentication choices on Screen B01 (WelcomeScreen) be worded?
Answer: Disambiguate auth buttons: "New Patient? Enter Clinic Invitation" vs "Sign in with One-Time Code" vs "Clinician Sign In".
Decision: Re-label welcome buttons to eliminate semantic confusion between clinic invitation codes and email OTP.

### L13
Status: current
Question: What feedback should be given after submitting the daily check-in (Screen A03)?
Answer: Display explicit confirmation of clinician visibility: "Telemetry received • Dr. Miller's care team notified".
Decision: Add care team receipt confirmation banner/feedback upon check-in submission.

### L14
Status: current
Question: How should spacing tokens be standardized across card layouts (Screen A01)?
Answer: Enforce strict 8-point grid scale (4px, 8px, 12px, 16px, 24px, 32px), replacing arbitrary 6px, 10px, 14px, 15px margins with `AppSpacing.md` (16dp).
Decision: Refactor all card vertical and horizontal margins to `AppSpacing` tokens.

### L15
Status: current
Question: What touch target dimensions should interactive row chevrons meet on Screen A06 (ProfileScreen)?
Answer: Expand touch target to minimum 48x48dp interactive boundary using `IconButton` or `HitTestBehavior.opaque` container.
Decision: Enforce 48x48dp minimum touch bounds on all profile settings rows.

### L16
Status: current
Question: How should medication dosage forms be represented visually on Screen A02?
Answer: Add dedicated icon glyphs for Capsule, Tablet, and Liquid dosages beside text dosage badges.
Decision: Pair dosage text badges with matching medication form icons.

### L17
Status: current
Question: How should welcome illustration assets scale on small viewports (<600dp) on Screen B01?
Answer: Wrap illustration in flexible constraints with maximum height clamped to 180.h.
Decision: Constrain welcome illustration height on compact mobile screens.

### L18
Status: current
Question: How should dose logging latency be eliminated on Screen A01?
Answer: Implement optimistic Riverpod state mutations (<50ms) with background SQLite write queue and rollback handler on final error.
Decision: Ensure instant UI state transitions on dose logging without waiting for network response.

### L19
Status: current
Question: What visual and haptic feedback should trigger when 100% of daily doses are completed (Screen A01)?
Answer: Trigger "Day Complete" Celebration Ring Closure animation with emerald glow sweep and medium haptic impact (`HapticFeedback.mediumImpact()`).
Decision: Enhance `CelebrationRingCard` with completion animation and haptic pulse.

### L20
Status: current
Question: Should dose slots enforce a strict 15-minute logging window (Screen A02)?
Answer: No. Allow forgiving dose logging anytime during the active day with clear retroactive timestamp marking.
Decision: Allow logging for any due/overdue/upcoming slot across the current day.

### L21
Status: current
Question: What feeling options should be presented during daily symptom check-in (Screen A03)?
Answer: Simplify to 4 distinct intuitive choices: Great, OK, Not Great, Unwell.
Decision: Standardize 4 mood options with distinct color/icon mappings in `CheckInCard`.

### L22
Status: current
Question: How should missing clinician assignments render on Screen A04 (RecoveryScreen)?
Answer: Display honest absence: "No dedicated care team assigned — contact clinic main desk", never leaving blank or fabricated info.
Decision: Implement explicit honest absence placeholder for unassigned care teams.

### L23
Status: current
Question: What initial empty state should appear on Screen A05 (AssistantScreen)?
Answer: Provide 3 pre-seeded quick clinical prompt chips: "Is mild swelling normal?", "When can I shower?", "Medication instructions".
Decision: Pre-seed empty assistant chat view with 3 tap-to-send clinical prompt chips.

### L24
Status: current
Question: How should sign-in visual hierarchy be structured on Screen B01?
Answer: Establish a single dominant primary CTA button (Email Sign In) and demote secondary options (Code sign-in, Demo mode) to outlined or text links.
Decision: Establish clear primary vs secondary visual hierarchy on welcome screen.

### L25
Status: current
Question: What text capitalization and autocorrect rules apply to email fields (Screen B02)?
Answer: Set `textCapitalization: TextCapitalization.none` and `autocorrect: false` with `keyboardType: TextInputType.emailAddress`.
Decision: Configure email text fields with non-capitalizing, non-autocorrecting parameters.

### L26
Status: current
Question: How should the "Resend Code" action behave on Screen B03?
Answer: Implement a 60-second countdown timer on the "Resend Code" button with a remaining seconds indicator to prevent spam and rate limits.
Decision: Add 60s cooldown countdown timer to OTP resend trigger.

### L27
Status: current
Question: What information should display upon entering a valid clinic invitation code (Screen B04)?
Answer: Display verified clinic name and inviting physician name immediately upon valid code recognition before proceeding.
Decision: Show clinic and doctor identity preview upon invitation code validation.

### L28
Status: current
Question: When should password entropy be evaluated during account setup (Screen B05)?
Answer: Provide an inline progressive strength meter that evaluates entropy dynamically as the user types.
Decision: Implement live entropy/strength meter on password creation screen.

### L29
Status: current
Question: How should clinicians resolve minor triage alerts in the web portal (Screen C01)?
Answer: Provide 1-click inline resolution modal with mandatory reason note directly from the triage table row without requiring full navigation into patient profile.
Decision: Add inline triage alert resolution action in web clinician dashboard.

### L30
Status: current
Question: How should high-priority triage rows be styled in the web portal (Screen C01)?
Answer: Add subtle red/amber 4px left accent border and high-contrast status badge to critical triage rows.
Decision: Apply severity-based visual accent borders and tags to triage table rows.

### L31
Status: current
Question: How should medication frequencies be configured in the clinician web portal (Screen C02)?
Answer: Replace free-text frequency input with a constrained clinical slot picker (QD - Daily, BID - Twice daily, TID - 3x daily, QID - 4x daily, PRN - As needed).
Decision: Constrain web medication frequency input to standardized clinical schedule options.

### L32
Status: current
Question: How should marketing landing page testimonials be handled (Screen C03)?
Answer: Replace placeholder testimonials with verified clinical partner statements and truthful compliance certifications, removing unverified claims.
Decision: Audit and replace marketing copy with verified partner quotes and honest claims.

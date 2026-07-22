---
type: Interview Ledger
parent: spec.md
---

## Records

### L1

Status: current

Question: `ai_specs/work-items/04-interactive-notifications-dose-logging.md` (interactive notifications, 0/9 AC) and `05-ai-assistant-chat-guardrail-notifier.md` (AI guardrail UX, 0/11 AC) are existing pending mobile Work Items that overlap with new backlog findings FIND-M02 (undo toast), FIND-M04 (emergency CTA), FIND-M06 (timezone reconciliation), and FIND-M07 (offline sync banner). How should this iteration treat them?

Recommended Answer: Fold their remaining scope into this iteration's Work Items rather than tracking them as a separate parallel effort.

Answer: Fold into this plan's issues (Recommended)

Decision: WI-04 and WI-05's remaining acceptance criteria are completed as part of this Spec's Work Items — interactive notification actions are completed together with FIND-M06 timezone reconciliation, and AI guardrail UX is completed together with FIND-M04's emergency CTA. The original `ai_specs/work-items/04-...md` and `05-...md` files are marked superseded, not deleted, for traceability.

Reason: Building the emergency CTA or undo toast without also finishing the notification/guardrail work they depend on would ship a half-feature; tracking them separately risked duplicate or conflicting implementations of the same screens.

---

### L2

Status: current

Question: The backlog's mobile findings (FIND-M01–M07) are mostly bug/accessibility fixes, not visual polish. The iteration constraint states mobile should receive more visual and interaction polish than web this cycle — should net-new polish Work Items be added beyond the 10 backlog findings?

Recommended Answer: Add a small set of ~2-3 clearly-labeled additive Work Items (micro-interactions/animation on dose logging, design-token/empty-state consistency pass) rather than leaving polish implicit in the bug-fix items.

Answer: Add a small polish set (Recommended)

Decision: Two net-new mobile Work Items are added — dose-logging micro-interaction/animation polish, and a design-token/empty-loading-state consistency pass across the 5 touched screens — scoped tightly, with no gamification (streaks, badges) per `docs/product/09-measurement-plan.md` §5 experiment guardrails.

Reason: The backlog alone would leave mobile polish entirely implicit; an explicit constraint deserves explicit Work Items so it isn't silently dropped during implementation.

---

### L3

Status: current

Question: `docs/ux/08-prioritized-ux-backlog.md`'s own sequencing is layer-based (backend → mobile → web → verify). The iteration constraint asks to prioritize the end-to-end clinician→patient→clinician flow — should mobile Work Item sequencing be reframed around that loop instead?

Recommended Answer: Reframe around the E2E loop — order Work Items by where they sit on clinician-authors-plan → patient-logs/checks-in → clinician-sees-adherence, rather than by technical layer.

Answer: Reframe around the E2E loop (Recommended)

Decision: Mobile Work Items are sequenced as: 5-tab shell restructure + new Medications screen first (IA foundation everything else depends on) → core dose-logging UX (status pills, undo toast, interactive notifications/timezone reliability) → safety/resilience (AI guardrail + emergency CTA, offline banner, FDA provenance badge) → polish (micro-interactions, design-token pass).

Reason: By the end of the core-flow Work Items, the patient-logs → clinician-sees-it loop already works end-to-end even before every safety/polish item lands, which matches the iteration's stated priority.

---

### L4

Status: current

Question: Does the full mobile issue breakdown, file mapping, dependencies, Definition of Done, and PR sequencing written in `docs/product/10-implementation-plan.md` accurately capture the mobile scope for this iteration?

Answer: "looks perfect"

Decision: `docs/product/10-implementation-plan.md` is the approved source for this Spec's and its Work Items' content (descriptions, files likely affected, dependencies, Definition of Done, test plans). This Spec formalizes that already-approved content into ACT Spec/Work Item vocabulary; it does not re-derive or alter scope.

Source: docs/product/10-implementation-plan.md

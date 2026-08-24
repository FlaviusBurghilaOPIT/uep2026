# Remote CarePro — Build Plan (5-Person Team)

**Status:** Implementation plan for the build phase (AWS Hackathon, Week 3 onward).
**Operating model:** Contract-first, local-first, SLC scope.
**Companion doc:** `TRELLO.md` — every task with a detailed "what to do" + a test to confirm it works.

> **A note on how the work is split.** Every engineer owns a **complete, demoable track** end-to-end — frontend or backend, design through code. **P1** additionally holds the **architecture & integration** role (API contract, auth, AI core, AWS, final wiring) because someone has to own the seams. This is about *ownership areas*, not seniority ranking — each track is a real, self-contained piece of the product.

---

## 0. The one-paragraph strategy

We build **one lovable, complete loop** (SLC — Simple, Lovable, Complete), not ten half-features. The whole team locks the **API contract + data model + design system** in the first ~4 days as a group; after that, all five tracks build **in parallel against the frozen contract**, so nobody blocks anybody. Everything runs **locally in Docker** first — every AWS dependency hides behind an interface with a local adapter, so "switch to AWS" is a config flip in Week 9, not a rewrite. Only **P1** ever touches AWS.

---

## 1. SLC scope — what we build vs. park

### ✅ The golden loop (this *is* the product — must be polished and complete)
1. Clinician logs in → creates a patient + case (surgery type).
2. Clinician prescribes medications (name, dose, schedule, duration — free text) + writes recovery recommendations.
3. Patient logs in (invited by the clinician) → **sees the regimen automatically**, zero manual entry.
4. Patient gets **local medication reminders** → logs each dose **taken / missed / skipped** in 1–2 taps.
5. Patient does a **simple daily check-in** ("how do you feel?" — 3–4 options).
6. Patient asks the **AI chatbot** about their meds/recovery — context-aware, never diagnostic.
7. Clinician dashboard shows **adherence + recovery status per patient** — the loop closes.

### 🟡 Reduced (kept cheap — our differentiator)
- **FDA safety panel, on-demand only.** When a medication is viewed, call openFDA → summarize with the LLM → show plain-language safety info with a source label. **No** review queue, **no** propagation, **no** nightly job.

### ❌ Parked (write as "v2 roadmap" — pitch them, don't build them)
Wiki auto-generation · FDA warnings queue/review/approval/propagation · nightly FDA refresh · audit records · document management (S3 upload / discharge letters) · SNS/Pinpoint push (local notifications only) · Terraform/CDK IaC · RxNorm lookup · PDF/print export · Redis · CPG integration · caregiver access · clinician mobile app · multi-language.

### AWS services used (all serving the loop)
**RDS PostgreSQL** · **OpenRouter AI + Clinical RAG Guardrails** · **EC2 / Container Stack** · **CloudWatch / Phoenix** (observability). Five to six services that all earn their place.

---

## 2. Operating model — contract-first + local-first

### 2.1 Contract-first (how the team stays unblocked)
The only shared surface is the **API contract**. In Phase 0 the team freezes:
- the **data model / ERD**,
- the **OpenAPI contract** (every endpoint, request/response shape),
- a **mock server** that returns fake-but-realistic JSON for every endpoint.

After that, frontends build against the **mock**, the backend builds the **real** implementation behind the same contract, and they meet in the middle with no surprises. A frontend dev graduates by changing **one base URL**: `mock-server` → `localhost:8000` → `aws-url`.

### 2.2 Local-first (Docker now, AWS later — by config, not rewrite)
Every external dependency sits behind an interface ("port") with a local adapter and a cloud adapter, chosen by an environment variable.

| Dependency | Local (Docker — everyone) | AWS / Production | Adapter |
|---|---|---|---|
| **Database** | Postgres in docker-compose | RDS PostgreSQL | None — just change `DATABASE_URL` |
| **Auth** | Local JWT issuer (`/auth/login`) | Local JWT / Secure OTP | `AuthProvider` — same JWT claim shape (`sub`, `role`, `email`) |
| **AI** | **OpenRouter** (real answers via API key) or **Mock** | OpenRouter + Clinical Guardrails | `LLMProvider` — `mock \| openrouter` |
| **openFDA** | Real public API + fixture cache | Same (live openFDA) | `FDAProvider` — `live \| fixture` |
| **Observability** | Arize Phoenix UI | Phoenix / CloudWatch | OpenTelemetry trace export |
| **Compute** | docker-compose | EC2 Container Stack | None — same Dockerfile |

**`.env` is the whole switch:**
```
DATABASE_URL=postgresql://...
AUTH_PROVIDER=local        # local
LLM_PROVIDER=openrouter    # mock | openrouter
OPENROUTER_API_KEY=sk-...
OPENROUTER_MODEL=...
FDA_PROVIDER=live          # live | fixture
```
Local defaults are committed to the repo.

**Why OpenRouter:** the AI chat is fully buildable and testable locally and on EC2 with realistic answers (cents per call, just an API key) with full Clinical RAG and refusal guardrails. Same `/ai/chat` contract for both.

---

## 3. Team allocation

| Who | Ownership area | Stack | Owns |
|---|---|---|---|
| **P1** | Lead — Platform, AI core & Integration | Python + AWS | API contract + data model, mock server, **provider interfaces**, auth (`/auth`), `/ai/chat`, `/fda/drug`, docker-compose, CI, **all AWS + deploy**, PR reviews, final integration |
| **P2** | Clinician Web — **Authoring** | React/TS | Web app **shell** (routing/layout/nav), login UI, patients, create case, prescribe meds + schedule builder, recommendations editor |
| **P3** | Clinician Web — **Monitoring** | React/TS | Dashboard / triage home, case detail view, adherence charts, check-in review, FDA safety panel display, alerts list |
| **P4** | Patient Mobile | Flutter | The **whole app**: login/invite, today view, meds + detail, dose logging, local reminders, daily check-in, AI chat UI, recovery view |
| **P5** | Backend Services | Python/FastAPI | SQLAlchemy models + Alembic, patients, cases, meds, **scheduling**, adherence (read+write), recommendations, symptoms (read+write) |

**Design principle:** each engineer lives in **one stack** (focused, maximally independent). P1 is the only one who spans layers and the only one who touches AWS. The only cross-track seams are three, and they're explicit:
- **Web shell** — P2 builds it, P3 consumes it. Agree the layout in Phase 0.
- **Medication data shape** — P4 (mobile) ↔ P5 (backend). Agree the JSON in Phase 0.
- **Auth** — P1 provides, everyone consumes. Lock the token shape in Phase 0.

---

## 4. Build sequence — phases mapped to the AWS timeline

> Today = **29 Jun 2026** = start of AWS **Week 3 (Implementation)**. Final submission = AWS **Week 10 (24–31 Aug)**.

### Phase 0 — Lock the contract & shells · **Week 3, ~4 days · GROUP**
Whole team together: freeze SLC scope, data model, OpenAPI contract, design system; set up GitHub + docker-compose; P1 stands up the mock server + provider interfaces. **Create the Trello board (AWS Week-3 deliverable).**
**Exit:** `docker-compose up` works; mock server answers every endpoint; design tokens exist; everyone can start their track.

### Phase 1 — Walking skeleton · **Week 3–4 · thin vertical**
One paper-thin slice proven end-to-end on local Docker: dev-login → create case + 1 med → patient login → see med → log 1 dose → doctor sees it. Real local backend + local-JWT auth.
**Exit:** the loop runs locally, no AWS. Proves the contract is real.

### Phase 2 — Fan out · **Weeks 4–8 · PARALLEL / INDEPENDENT**
P2/P3/P4/P5 each build out their full track against the contract + mock + local backend. P1 builds the AI (OpenRouter) + FDA endpoints, reviews, and starts deployment configurations.
**Exit:** every track feature-complete and demoable on local Docker.

### Phase 3 — Integrate on AWS · **Week 9 · P1-led**
P1 deploys container stack: provision RDS/EC2, deploy Nginx + Phoenix + FastAPI + Astro SSR containers.
**Exit:** the golden loop runs end-to-end **on AWS EC2**.

### Phase 4 — Polish, demo, submit · **Weeks 9–10 · ALL**
Lovable polish pass, user-testing round 2, record demo video, final report, pitch deck + Q&A prep.
**Exit:** submitted.

---

## 5. Dependencies & risks

**Hard dependency:** Phase 0 contract + design system blocks polished UI and backend slot-in. Keep it to ~4 days; timebox it.

**Soft seams (agree early, then independent):**
- P2 → P3 (web shell), P4 ↔ P5 (medication JSON), P1 → all (auth token shape).
- P1 → P3/P4 (FDA + AI response shapes) — a mid-Phase-2 handoff is enough; mock returns the shape until then.

**Risks & mitigations:**
1. **P5 backend is a single point of load.** Mitigation: the frozen contract + mock means no frontend is ever blocked by backend lag; P1 (and P2, who also knows Python) can absorb a module if P5 falls behind.
2. **P1 carries architecture + AI + Cloud.** Mitigation: Phase 0 front-loads the hard interface design; once stable, P2 can assist with CI/infra.
3. **Multi-tier integration.** Mitigation: P1 tests the container stack early so integration is rehearsed, not discovered.
4. **Scope creep back toward the parked list.** Mitigation: the golden-loop acceptance criteria are frozen in Phase 0; new ideas go to the "v2 roadmap," which is a *pitch asset*, not a backlog.

---

## 6. Open decisions to lock in Phase 0
1. **Patient ↔ clinician linking** — clinician searches by name/email and invites (recommended), vs. clinic-code. Decide before P5 builds patient creation. *(Account creation itself = clinician invites via Cognito.)*
2. **Chatbot history** — persistent across sessions (recommended; backend already saves conversations) vs. per-session. Affects P4 UI + P1 `/ai/chat`.
3. **Reminder schedule generation** — server generates the `scheduled_reminders` rows on med creation (recommended), and the app schedules local notifications from them. Confirm timezone handling.

---

### Parked (post-MVP, pitch as roadmap)
Caregiver/family read-only access · clinician mobile companion · multi-language · patient dark mode + wearable companion · RxNorm drug lookup · Clinical Practice Guideline integration · document management · automated FDA propagation + nightly refresh · wiki auto-generation · Redis caching.

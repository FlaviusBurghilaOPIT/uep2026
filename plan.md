# Remote CarePro — Build Plan for a 5-Person Team

**Scope:** Full task breakdown across three layers — **Figma (design)**, **Frontend**, **Backend** — for the two surfaces of the platform.

**Key decision (resolves the conflict in the design doc):**
- **Clinician Web Dashboard → React** (data-dense, triage-oriented, desktop)
- **Patient Mobile App → Flutter** (calm, low-friction, accessible)

> The Week-2 design doc lists Flutter for *both* surfaces in the tech-stack section but React for the clinician dashboard in the core-requirements section. **We are going with React for clinician web, Flutter for patient mobile.** The Flutter stack (Riverpod, go_router, flutter_local_notifications, etc.) applies to the **patient app only**. The repo's `frontend/clinician_dashboard/` becomes a **React** app instead of Flutter web. Update `docs/` and the stack table to match.

---

## How to read this document

1. **Team allocation matrix** — who owns what, at a glance.
2. **Shared references** — data model, API contract, tech stack. Everyone uses these.
3. **Per-person breakdown** — each of the 5 people has **Figma + Frontend + Backend** tasks.
4. **Cross-cutting tasks** — auth, states, notifications, CI/CD.
5. **Dependencies & build order** — what blocks what, phased by week.
6. **Open questions & risks** — decisions to lock before/while building.

A note on reality: the original 5-way split in the source docs is a **design-phase** split. This plan extends it through the **build phase**. Backend is the bottleneck on a 5-person team, so it is shared — each person owns the backend modules that feed their own frontend (vertical ownership), with the AI/FDA/infra core sitting with Person 5.

---

## 1. Team allocation matrix

| Person | Track | Figma | Frontend | Backend (FastAPI / AWS) |
|---|---|---|---|---|
| **P1** | Foundations | Design system, components, states | React **and** Flutter foundations (tokens, component libs, cross-cutting states) | App skeleton, core/config, DB base, Alembic, JWT middleware, Docker, CI/CD |
| **P2** | Clinician — Auth, Dashboard, Cases | Auth, triage home, cases, settings | React: auth, triage home, inbox, cases, case detail shell, print/export, settings | **Cases**, **Documents (S3)**, **Clinician profile** |
| **P3** | Clinician — Patients, Meds, Adherence | Patients, meds, adherence, recs | React: patients, meds editor, FDA panel, adherence charts, recs editor, check-in review | **Patients**, **Medications**, **Adherence (read)**, **Recommendations**, **Symptoms (read)** |
| **P4** | Patient Mobile App | Patient app + check-in/AI/emergency screens | Flutter: the entire patient app (incl. check-in, AI chat, emergency — designed by P5) | **Adherence (write)**, **Check-in (write)**, **Scheduled reminders**, **Push tokens** |
| **P5** | FDA, AI, Wiki + Platform | FDA workflow, wiki, AI chat, check-in, emergency | React: FDA workflow + wiki screens. Spec/review for Flutter AI/check-in/emergency | **AI (Bedrock)**, **FDA (openFDA + nightly job)**, **Wiki**, **Cognito setup**, **Infra/deploy** |

**Load note:** P1 (foundations) and P5 (AI/FDA/infra) carry the most architectural weight. After Phase 1 stabilizes, P2 or P3 should help P5 with infra/CI. Auth/Cognito is an early **shared** task touching P1, P2, P4, P5.

---

## 2. Shared references (used by everyone)

### 2.1 Tech stack per layer

**React — Clinician Web (P1, P2, P3, P5)**
- React + **Vite** + **TypeScript**
- **React Router** (navigation)
- **TanStack Query** (server state) + **Zustand** (client/UI state)
- **TanStack Table** (data-dense rosters and case lists)
- **React Hook Form** + **Zod** (forms + validation)
- **Recharts** (adherence / symptom trend charts)
- Design system / component library (P1)
- Auth via **Amazon Cognito** (`amazon-cognito-identity-js` or Amplify Auth)
- Hosting: **S3 + CloudFront** (or Amplify Hosting)

**Flutter — Patient Mobile (P4, with P1 foundations)**
- Flutter SDK / Dart
- **Riverpod** (state), **go_router** (nav)
- **Dio** (HTTP), **json_serializable + build_runner** (models)
- **flutter_local_notifications** (offline-capable dose reminders)
- **flutter_secure_storage** (token storage)
- **fl_chart** (patient's own adherence/check-in trend)
- Build: APK / IPA for demo (TestFlight / internal testing)

**Backend — FastAPI (all, owned by module)**
- **FastAPI**, **Pydantic v2**, **SQLAlchemy 2.x**, **Alembic**
- **psycopg / asyncpg** (PostgreSQL driver)
- **boto3** (Bedrock, S3, Cognito), **python-jose** (JWT verify)
- **Uvicorn**, **Docker**
- Stretch: **httpx** (async openFDA), **APScheduler / AWS Lambda** (jobs), **pytest / pytest-asyncio**, **ruff / mypy**, **Redis**

**AWS**
- **Cognito** (auth + patient/clinician roles), **RDS PostgreSQL**, **S3** (documents)
- **Bedrock** (+ **Guardrails**) for AI chat + plain-language FDA summaries
- **ECS Fargate** + **ECR** (containers), **IAM**, **CloudWatch**
- **Lambda** (nightly FDA refresh), HTTPS via load balancer
- Stretch: **SNS / Pinpoint** (push), **Terraform / CDK** (IaC), **GitHub Actions** (CI/CD)

### 2.2 Data model (entities)

| Entity | Key fields | Relationships |
|---|---|---|
| **Clinician** | id, cognito_sub, name, specialty, preferences | 1—* Patient |
| **Patient** | id, cognito_sub, name, surname, age, allergies, clinician_id, invite_status | 1—* Case |
| **Case** | id, patient_id, clinician_id, surgery_type, status (open/closed), created_at, closed_at | 1—* Medication, Recommendation, Document |
| **Medication** | id, case_id, drug_name (free text MVP), dose, frequency, duration, timing | 1—* ScheduledReminder, DoseLog |
| **ScheduledReminder** | id, medication_id, patient_id, scheduled_time, status | belongs to Medication |
| **DoseLog (Adherence)** | id, medication_id, patient_id, reminder_id, status (taken/missed/skipped), logged_at, source | belongs to Medication |
| **Recommendation** | id, case_id, type (activity / wound-care / physio / warning-sign), content, target | belongs to Case |
| **SymptomCheckIn** | id, patient_id, case_id, feeling_rating, answers, flags, created_at | belongs to Patient |
| **AIConversation / AIMessage** | conv: id, patient_id, case_id · msg: id, conv_id, role, content, sources | conv 1—* msg |
| **FDAWarning** | id, drug_name, severity, new_info, status (pending/approved/dismissed), reviewed_by, reviewed_at | *—* Case (affected cases) |
| **Document** | id, case_id, s3_key, filename, content_type, uploaded_by | belongs to Case |
| **PushToken** | id, patient_id, token, platform | belongs to Patient |

### 2.3 API contract

| Method + path | Backend owner | Consumed by |
|---|---|---|
| Auth (Cognito login/refresh) | P5 setup · P1 middleware | Web (P2), Mobile (P4) |
| `POST /patients` | P3 | Web (P2 create-case, P3 mgmt) |
| `GET /patients/{id}` | P3 | Web + Mobile |
| `GET /patients/{id}/case` | P3 | Mobile (auto-fetch) |
| `POST /cases` | P2 | Web |
| `GET /cases/{id}` | P2 | Web + Mobile |
| `POST /cases/{id}/medications` | P3 | Web |
| `GET /cases/{id}/medications` | P3 | Web + Mobile |
| `POST /adherence/log` | **P4** | Mobile |
| `GET /patients/{id}/adherence` | P3 | Web |
| `POST /cases/{id}/recommendations` | P3 | Web |
| `GET /cases/{id}/recommendations` | P3 | Web + Mobile |
| `POST /symptoms/checkin` | **P4** | Mobile |
| `GET /patients/{id}/symptoms` | P3 | Web (check-in review) |
| `POST /ai/chat` | P5 | Mobile |
| `GET /fda/drug/{name}` | P5 | Web (safety panel) + Mobile (med detail) |
| `POST /documents/upload` | P2 | Web |
| `GET /cases/{id}/documents` | P2 | Web (+ Mobile if patient views) |
| FDA warnings queue / review / propagate | P5 | Web |
| Wiki index + article | P5 | Web |
| Push-token store | P4 | Mobile |

---

## 3. Per-person breakdown

### Person 1 — Foundations (design system + frontend foundations + backend scaffolding)

**Why first:** Hard dependency. Nobody can build polished UI consistently without the design system, and backend modules can't slot in without the app skeleton. Target a **1–2 week head start**; others wireframe in parallel.

**Figma**
- UI-001 Design system & tokens — color, type scale, spacing, elevation, radius, semantic state colors. One core, two expressions (dense web / calm mobile).
- UI-002 Component library — buttons, inputs, selects, date/time pickers, cards, tables, tabs, modals, toasts.
- UI-003 Status & data components — status pills (taken/missed/skipped), adherence badges, warning-severity badges, charts, skeleton loaders.
- UI-004 Iconography set — one icon family across both apps.
- UI-005 Accessibility spec — AA contrast, 44–48px touch targets, font scaling, focus/screen-reader states.
- UI-006 Layout grids — responsive desktop grid + mobile grid.
- Cross-cutting: UI-301 empty states, UI-302 loading/skeleton, UI-303 error states, UI-305 success/confirmation toasts, UI-306 notification templates.

**Frontend — React (clinician web foundations)**
- Scaffold the React app (Vite + TS), folder structure, routing shell, responsive desktop layout.
- Implement tokens as CSS variables / theme (dense web expression).
- Build the React component library matching Figma (buttons, inputs, pickers, cards, TanStack Table wrapper, tabs, modals, toasts).
- Status/data components: status pills, adherence/severity badges, Recharts chart wrappers, skeleton loaders.
- Accessibility primitives: focus rings, AA contrast tokens, keyboard nav, screen-reader labels.
- Reusable state components: `EmptyState`, `LoadingSkeleton`, `ErrorState`, `SuccessToast`.

**Frontend — Flutter (patient app foundations)**
- Flutter `ThemeData` implementing the **same tokens** (calm mobile expression): text scale, 44–48px touch targets, dynamic font scaling.
- Shared Flutter widget library mirroring the React components (buttons, inputs, pickers, cards, status pills, badges).
- Cross-cutting states in Flutter (empty / loading / error / success) + support P4's offline & sync (UI-304).
- **Maintain a single design-token source of truth** so web and mobile stay in sync.

**Backend — platform scaffolding**
- Repo structure per design doc (`backend/app`, `modules/`, `db/`, `core/`, `shared/`).
- FastAPI app skeleton (`main.py`); `core/config` (settings + `.env`); `core/security` (JWT verify with python-jose against Cognito JWKS).
- DB layer: SQLAlchemy 2.x session + base; Alembic init + first migration; pagination/error-envelope utilities; shared Pydantic base schemas.
- `docker-compose` (db + backend), `Dockerfile`, Uvicorn `--reload`.
- CI/CD skeleton (GitHub Actions): ruff (lint), mypy (types), pytest (tests) stages.
- Own API conventions + OpenAPI; publish generated types to both frontends.

---

### Person 2 — Clinician Web: Auth, Dashboard & Cases

**Figma**
- UI-101 Login · UI-102 Forgot/reset password · UI-103 Clinician first-run/profile setup.
- UI-110 Triage home (exception-driven roster) · UI-111 Notifications/inbox center.
- UI-130 Create-case flow · UI-131 Case form (surgery type, prescription, FAQ pre-fill) · UI-132 Case list with row actions · UI-133 Case detail single pane · UI-134 Confirmation modals.
- UI-1A1 Print case info · UI-1A2 Export PDF of medication list · UI-1A3 Clinician settings.

**Frontend — React**
- Auth: email/password login via Cognito, forgot/reset flows, protected routes, session handling.
- Clinician first-run / profile setup (name, specialty, preferences).
- Triage home: exception-driven list (low adherence, symptom flags, pending FDA approvals), sortable + filterable — answers "who needs me now?".
- Notifications / inbox center: feed for FDA warnings, low-adherence alerts, check-in flags.
- Create-case flow: pick patient from filtered list (**consumes P3's patient-list component**) → inherit details → create.
- Case form: surgery type, prescription entry hook (P3's med editor), recommendations hook (P3), FAQ pre-fill.
- Case list with row actions (edit / view / close / reopen).
- **Case detail single pane (shell):** owns the tabbed layout; **embeds P3's** meds, adherence, recommendations, symptoms widgets + documents + AI chat history.
- Confirmation modals (close / reopen / edit-prescription) with **audit note**.
- Print case info (print-optimized) + Export PDF of medication list.
- Clinician settings.

**Backend — modules owned**
- **Cases**: `POST /cases`, `GET /cases/{id}`; router + service + schemas + models; status transitions (open/close/reopen) writing **audit records**.
- **Documents (S3)**: `POST /documents/upload` (presigned URL), `GET /cases/{id}/documents`; boto3 S3 + metadata persistence.
- **Clinician profile**: clinician entity, first-run profile, settings persistence.
- Coordinate Cognito app-client config with P5; tests for cases + documents.

---

### Person 3 — Clinician Web: Patients, Medications & Adherence

**Figma**
- UI-120 Patient profile · UI-121 Patient list with filters · UI-122 Patient longitudinal view.
- UI-140 Add/edit medication + schedule builder · UI-141 Medication list per case · UI-142 Inline FDA safety panel.
- UI-150 Adherence timeline chart · UI-151 Adherence detail (missed-dose patterns).
- UI-160 Recommendations editor · UI-170 Patient check-in review · UI-1A0 Document upload & manage.

**Frontend — React**
- Patient profile view (name, age, surname, current meds, allergies).
- **Patient list with filters** — shared component **owned by P3, consumed by P2's create-case**. Agree the contract early.
- Patient longitudinal view (all cases over time).
- Add/edit medication + schedule builder (drug name free text, dose, frequency, duration, timing).
- Medication list per case.
- Inline FDA safety panel — **consumes `GET /fda/drug/{name}` (P5)**; warnings/recalls per medication.
- Adherence timeline chart (taken vs missed) using P1's chart wrapper.
- Adherence detail (missed-dose patterns / breakdowns).
- Recommendations editor (activity, wound-care, physio targets, warning signs as structured records).
- Patient check-in review (feeling feedback, trends, flags) — consumes `GET /patients/{id}/symptoms`.
- Document upload & manage UI (consumes P2's documents API).

**Backend — modules owned**
- **Patients**: `POST /patients`, `GET /patients/{id}`, `GET /patients/{id}/case`; patient↔clinician linking (**see open question**).
- **Medications**: `POST/GET /cases/{id}/medications`; on create, **trigger schedule generation** (coordinate with P4's scheduled-reminders).
- **Adherence (read)**: `GET /patients/{id}/adherence` — aggregation for rates, missed-dose patterns (the **write** path `POST /adherence/log` is P4).
- **Recommendations**: `POST/GET /cases/{id}/recommendations` (structured records).
- **Symptoms (read)**: `GET /patients/{id}/symptoms` (clinician review; **write** is P4).
- Tests for these modules.

---

### Person 4 — Patient Mobile App (Flutter)

**Note:** P4 builds **all** Flutter screens, including check-in, AI chat, and emergency — **designed by P5** in Figma, but they live in the one cohesive Flutter app. P5 provides the backend + guardrail spec + review. Per the dependency analysis, the patient app is **the most independent** track once foundations land.

**Figma (own)**
- UI-201 Login · UI-202 Accept invite/onboarding · UI-203 Consent & privacy · UI-204 Notification-permission priming.
- UI-210 Today view · UI-220 Medications list + reminders · UI-221 Medication detail · UI-222 Dose-logging.
- UI-230 Surgery detail · UI-231 Post-recovery notes · UI-232 Recovery progress/physio.
- UI-250 Medical history · UI-280 Profile & settings · UI-304 Offline & sync states.

**Frontend — Flutter (build, incl. P5-designed screens)**
- App setup: Riverpod, go_router, Dio, json_serializable + build_runner, flutter_secure_storage; consume P1's Flutter theme.
- Auth: login; accept-invite / first-run onboarding (open clinician invite link → set up via Cognito); consent & privacy notice; notification-permission priming (explain before the OS prompt).
- Today view: next dose, today's schedule, quick-log, recovery glance.
- Medications list + reminders; medication detail (dosing + FDA plain-language safety with **source labels** — consumes `/fda/drug/{name}`).
- **Dose-logging:** taken / missed / skipped in **1–2 taps**, actionable **from the notification**, easy **undo** (`POST /adherence/log`).
- Local notifications via **flutter_local_notifications**, scheduled from the medication schedule; **offline-capable**, syncs later.
- Surgery detail · post-recovery notes · recovery progress / physio targets (milestones + logging).
- Medical history (previous treatments).
- *(Designed by P5)* UI-240 Daily check-in (1–3 tap answers) · UI-241 Check-in history/trend (fl_chart) · UI-260 AI chat with guardrail framing · UI-261 Suggested questions / FAQ · UI-262 Out-of-scope/safety state · UI-270 Emergency contact / call clinician (reachable from anywhere).

**Backend — modules owned (patient write-side)**
- **Adherence (write)**: `POST /adherence/log` (taken/missed/skipped + undo) — patient-submitted.
- **Check-in (write)**: `POST /symptoms/checkin` — feeds the rating logic.
- **Scheduled reminders**: backend logic that, on medication creation (with P3), populates the `scheduled-reminders` table the app reads.
- **Push tokens**: endpoint to store device tokens (SNS/Pinpoint is stretch).
- Tests for adherence/check-in write + scheduling.

---

### Person 5 — FDA, AI, Wiki + Platform/Infra

**Figma**
- UI-180 Warnings queue · UI-181 Warning review & approval · UI-182 Propagation confirmation + audit.
- UI-190 Wiki index · UI-191 Auto-generated article view.
- UI-260 AI chat (guardrail framing) · UI-261 Suggested questions · UI-262 Out-of-scope/safety state.
- UI-240 Daily check-in · UI-241 Check-in history/trend · UI-270 Emergency contact.

**Frontend — React (self-contained clinician admin screens)**
- FDA warnings queue (incoming openFDA warnings awaiting review).
- Warning review & approval (drug, new vs current info, count of affected open cases; approve-as-danger / dismiss).
- Propagation confirmation + audit record (warning pushed to affected cases).
- Wiki index by surgery type (browsable auto-generated articles).
- Auto-generated article view (from extracted case notes; doctor review/edit; approved state; **source attribution**).

**Frontend — Flutter (spec + review, built by P4)**
- Provide guardrail/scope spec, sourced-answer rendering rules, and escalation behavior for the AI chat (260–262), check-in (240–241), and emergency (270). P4 implements.

**Backend — modules owned (the heavy core)**
- **AI (Bedrock)**: `POST /ai/chat`; context-aware prompt builder grounded in the **clinician's case notes/prescriptions**; **Bedrock Guardrails** (informational-only, never diagnostic, no dose changes); conversation persistence (AIConversation/AIMessage); source attribution.
- **FDA (openFDA)**: `GET /fda/drug/{name}`; openFDA integration; plain-language summaries via Bedrock; warnings queue + review/approval + **propagation to affected cases** + audit; **nightly refresh** via Lambda/APScheduler (decision: fetch on prescription creation **+** nightly).
- **Wiki**: auto-generate articles from extracted case notes (Bedrock); doctor review/approve; source attribution; index + article endpoints.
- **Cognito setup**: user pool, app clients (patient/clinician roles), invite flow; coordinate JWT middleware with P1.
- **Infra / deploy**: ECR image, ECS Fargate, RDS PostgreSQL, S3 buckets, IAM roles, HTTPS load balancer, CloudWatch; IaC (Terraform/CDK stretch); CI/CD with P1.
- Tests for AI / FDA / wiki.

---

## 4. Cross-cutting / shared tasks

- **Auth / Cognito** — P5 sets up the pool + invite flow; P1 builds JWT verify middleware; P2 builds web login; P4 builds mobile login + invite acceptance. Lock this **early** — every login screen depends on it.
- **Cross-cutting UI states** — P1 builds reusable empty / loading / error / success components; each owner applies them in their screens (don't leave to the end).
- **Notification templates** — P1 designs content; P4 wires mobile push/local notifications; P5 triggers backend events.
- **Audit records** — cross-cutting on every important action: case close/reopen/edit (P2), FDA approval/propagation (P5).
- **Design-token sync** — P1 keeps web and mobile tokens from drifting.
- **API contract + shared types** — P1 owns conventions/OpenAPI; each module owner publishes their schemas; frontends consume generated types.
- **Migrations** — P1 sets up Alembic base; each module owner adds their tables.

---

## 5. Dependencies & build order

**Hard dependency:** P1 foundations before any polished UI (web + mobile) and before backend modules slot into the skeleton. ~1–2 week head start.

**Soft dependencies**
- **P2 ↔ P3** — patient-list component (P3 owns → P2 consumes); case-detail single pane (P2 shell → P3 meds/adherence widgets). Agree the layout and ownership early.
- **P5 → P2, P3** — FDA warning flow and AI grounding need to know how **cases** (P2) and **medications** (P3) are structured/displayed. A mid-sprint handoff is enough.
- **P4** — most independent after foundations. Only align the **medication-detail data model** with P3.

**Phase 0 — Week 1–2 (Foundations)**
- P1: design system (Figma) + React/Flutter foundations + backend skeleton + JWT middleware + CI/CD skeleton. *(Blocking for polished UI.)*
- P5: Cognito setup + infra skeleton (RDS, S3, ECR) + start FDA/wiki (self-contained).
- P2 / P3 / P4: wireframes, user flows, lo-fi, content alignment, data-model agreement. P2↔P3 settle the patient-list + case-detail contracts.

**Phase 1 — Week 2/3+ (Core build, parallel)**
- P2: cases + documents backend → React auth / dashboard / cases.
- P3: patients / meds / adherence backend → React; **ship the patient-list component first** (P2 is waiting on it).
- P4: Flutter app + patient-write backend (adherence/check-in) + scheduling; runs most independently.
- P5: AI + FDA + wiki backend + FDA/wiki React screens; pick up case/med structure mid-sprint.
- P1: finish component library, support everyone, infra/CI with P5.

**Phase 2 — Differentiators & integration**
- AI chat grounded in case notes (P5 backend + P4 Flutter UI).
- FDA propagation to cases (P5 + P2 cases) with audit.
- Check-in loop: P4 write → P3 clinician review.
- Cross-cutting states woven into each epic.

---

## 6. Open questions & risks (lock these)

1. **React vs Flutter for clinician web — RESOLVED:** React for clinician web, Flutter for patient mobile. Update the design doc + stack table; the repo's `clinician_dashboard/` is now a React app.
2. **Patient ↔ clinician linking — OPEN:** search-by-name/ID vs clinic code vs hospital admin. Decide **before P3 builds patient creation**. (Account creation itself is decided: clinician invites via Cognito.)
3. **Chatbot history — confirm:** the data-flow narrative implies persistence (backend saves the conversation). Confirm per-session vs persistent UX for P4/P5.
4. **FDA fetch timing — decided:** on prescription creation **+** nightly Lambda refresh.
5. **Medication entry — decided:** free text for MVP; RxNorm lookup later.
6. **Push notifications — decided for MVP:** local (`flutter_local_notifications`); SNS/Pinpoint is a stretch.
7. **Team load:** P5 (AI/FDA/infra) and P1 (foundations) are the heaviest. Plan for P2/P3 to assist infra/CI once their frontend stabilizes.

---

### Parked (post-MVP, not in scope)
Caregiver/family read-only access · clinician mobile companion · multi-language patient app · patient dark mode + wearable reminder companion · RxNorm drug lookup · Clinical Practice Guideline integration · Redis caching.

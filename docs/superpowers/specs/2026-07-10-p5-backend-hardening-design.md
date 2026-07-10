# Remote CarePro — p5/backend Hardening & Feature Design

Date: 2026-07-10
Branch target: `p5/backend`
Author context: Person 5 (FDA workflow, AI assistant, check-in, wiki, emergency contact)

## 1. Purpose

Two things, done in order:

- **Sub-project A — Harden main**: bring the `p5/backend` branch up to date with `main`, then fix
  infrastructure, auth, security, docs, and code-quality gaps that exist in `main` today so the
  branch is a solid base for feature work.
- **Sub-project B — Person 5 backend features**: implement the backend half of the FDA warnings
  workflow, the AI recovery assistant with guardrails, check-in trends, the surgery knowledge
  wiki, and emergency contact — the areas assigned to Person 5 in the UI backlog.

This spec covers backend-only work. No commits are made as part of this work; the user commits
personally.

## 2. Current-state findings (baseline facts, not decisions)

- `p5/backend` (`origin/p5/backend`, commit `7e5e2f9`) is a strict ancestor of `main` — 13 commits
  behind, no divergent commits. Merging `main` into it is a fast-forward with zero conflicts.
- `backend/app/providers/{auth,fda,llm}.py` already define a Strategy/Factory pattern
  (`AuthProvider`/`LocalAuthProvider`/`CognitoAuthProvider`,
  `FDAProvider`/`LiveFDAProvider`/`FixtureFDAProvider`,
  `LLMProvider`/`MockLLMProvider`/`OpenRouterProvider`/`BedrockProvider`) but nothing in the app
  calls `get_auth_provider()`, `get_fda_provider()`, or `get_llm_provider()` — `dependencies.py`,
  `routers/fda.py`, and `routers/ai.py` all bypass them with inline/stub logic.
- `POST /auth/dev-login` (`routers/auth.py`) is the real local-auth implementation the
  `AUTH_PROVIDER=local` env var already points at — not a placeholder to remove.
- `docker-compose.yml`'s Postgres volume mount (`pgdata:/var/lib/docker/data`) targets the wrong
  path — Postgres's actual data directory is `/var/lib/postgresql/data` — so the mount is
  currently a no-op and data does not persist across `down`/`up`.
- No table is created automatically anywhere; `alembic upgrade head` must be run manually today.
  `alembic.ini`'s `sqlalchemy.url` is commented out — the URL comes from `.env` via
  `alembic/env.py` at runtime, confirmed working.
- `.env.example` is currently an empty file.
- `UserRole` enum has only `clinician`/`patient` — no `admin`.
- `checkins.py` has create + list already; no trend/rollup endpoint.
- `ai.py` and `fda.py` return hardcoded stub responses; `ChatMessage` model already exists and is
  unused (no persistence writes anywhere in the codebase yet).
- No FDA-warning model, wiki model, or emergency-contact fields exist yet.
- `web/package.json` is an empty file; `web/Dockerfile` uses `node:20-alpine`.

## 3. Sub-project A — Harden main

### 3.1 Git

Create local branch `p5/backend` tracking `origin/p5/backend`, then merge `main` into it
(fast-forward, confirmed no conflicts). No push, no commit — working tree only, per user
instruction.

### 3.2 Docker / infra

- `postgres:16` → `postgres:18` in `docker-compose.yml`.
- `node:20-alpine` → `node:24-alpine` in `web/Dockerfile`.
- Fix volume mount: `pgdata:/var/lib/postgresql/data`.
- Add a Postgres healthcheck (`pg_isready -U caredev -d remotecare`); `backend` service depends on
  `db` with `condition: service_healthy` instead of a bare `depends_on` list.
- Backend container runs `alembic upgrade head` before starting `uvicorn` (entrypoint script or
  chained shell command in the compose `command:`), so schema is created automatically on
  container start. This directly closes the "is there an entrypoint to init the DB" gap.

### 3.3 Auth factory

- `dependencies.get_current_user` calls `get_auth_provider().verify_token(token)` instead of
  inlining `jwt.decode`.
- `CognitoAuthProvider.verify_token` implemented to fetch and cache a Cognito JWKS (via
  `python-jose`) and verify signature/claims — will raise/fail without real Cognito config since
  no user pool exists yet; this is expected and matches the existing "built in Phase 3" comment.
  `AUTH_PROVIDER` env var continues to select `local` vs `cognito`.
- `dev-login` (`routers/auth.py`) is left as the local-provider login path — documented, not
  removed.

### 3.4 Roles & Postgres RLS

- Add `admin` to `UserRole` enum; new Alembic migration for the enum change.
- New Alembic migration: enable `ROW LEVEL SECURITY` on `cases`, `medications`,
  `scheduled_reminders`, `recommendations`, `checkins`, `chat_messages`. Policies:
  - clinician role: visible where `cases.clinician_id = current_setting('app.current_user_id')`
    (child tables join back to `cases`).
  - patient role: visible where `cases.patient_id = current_setting('app.current_user_id')`.
  - admin: `BYPASSRLS` on the DB role, or an explicit `USING (true)` policy branch.
- `get_db` (or a wrapper) issues `SET LOCAL app.current_user_id = ...; SET LOCAL app.current_role
  = ...` per request, sourced from the already-authenticated user (post `get_current_user`).
  Since `get_db` currently has no access to the authenticated user, this requires restructuring:
  the RLS session vars are set in a small dependency that runs after `get_current_user`, using the
  same `db` session, rather than inside `get_db` itself.

### 3.5 Seed script

`backend/scripts/seed.py`, runnable via `python -m app.scripts.seed` (or documented Make/compose
target). Creates one `admin`, one `clinician`, one `patient` with fixed dev credentials (documented
in README), idempotent — skips creation if the email already exists. Prints created
credentials to stdout.

### 3.6 Docs, formatting, tests

- `README.md`: architecture overview, local setup (compose up → auto-migrate → seed → login),
  auth model (local vs Cognito factory), RLS model, seed script usage, Swagger location (`/docs`).
- FastAPI app metadata: `title`, `description`, `version`, per-router tag descriptions, so
  `/docs` (Swagger UI, already auto-generated by FastAPI — nothing was broken here) reads clearly.
- Adopt `black` + `ruff`; run once across `backend/`.
- `pytest` unit tests: models (constraints/defaults), `security.py` (hash/verify/token
  round-trip), the three provider factories (`get_auth_provider`, `get_fda_provider`,
  `get_llm_provider` — env-var selection branches), and RLS session-var wiring.

### 3.7 .env / .env.example

Populate `.env.example` mirroring `.env`'s keys with placeholder values; add `POSTGRES_*` version
vars and `COGNITO_*` placeholders (`COGNITO_USER_POOL_ID`, `COGNITO_REGION`,
`COGNITO_APP_CLIENT_ID`) so both files stay in sync and Cognito wiring has a home once real
values exist.

## 4. Sub-project B — Person 5 backend features

### 4.1 FDA warnings queue → approval → propagation

- New model `FDAWarning`: `id`, `drug_name`, `summary`, `severity`, `status`
  (`pending`/`approved`/`dismissed`), `source_payload` (JSON/text), `created_at`, `reviewed_by`
  (FK `users.id`, nullable), `reviewed_at` (nullable).
- New join table `case_fda_warnings` (`case_id`, `fda_warning_id`, `created_at`) recording
  propagation — one row per affected case once a warning is approved.
- Endpoints:
  - `GET /fda/warnings` — pending queue (clinician-only).
  - `POST /fda/warnings/{id}/approve` — sets `status=approved`, `reviewed_by`, `reviewed_at`;
    finds all `Medication` rows with matching `drug_name` (case-insensitive) on cases with
    `status == "active"`, inserts `case_fda_warnings` rows (the audit trail).
  - `POST /fda/warnings/{id}/dismiss` — sets `status=dismissed`, `reviewed_by`, `reviewed_at`, no
    propagation.
  - `POST /fda/warnings/refresh` — calls `get_fda_provider().get_drug_info()` for every distinct
    `Medication.name` currently prescribed, inserts new `FDAWarning` rows as `pending` (dedup by
    `drug_name` + unchanged `summary`). Manual stand-in for the nightly Lambda job (no AWS infra
    provisioned yet).
  - `GET /fda/drug/{name}` rewired to use `get_fda_provider()` (`FDA_PROVIDER=live|fixture`)
    instead of the hardcoded stub string.

### 4.2 AI recovery assistant with guardrails

- `POST /ai/chat` rewired to use `get_llm_provider()` (`LLM_PROVIDER=mock|openrouter|bedrock`).
- System prompt built per request from the patient's active `Case`: its `Medication` rows and
  `Recommendation` rows, plus a fixed guardrail preamble (informational only, never diagnostic,
  never suggest changing a dose, defer to clinician/emergency contact otherwise).
- Every turn (user message + assistant reply) persisted to `ChatMessage` (model already exists,
  currently unused) — history is per-case and persistent across sessions, matching the design
  doc's resolved decision.
- `schemas.ChatResponse` gains `in_scope: bool` and `escalate: bool`. A lightweight
  keyword/heuristic check runs on the model's own output (e.g. dosage-change language, diagnostic
  claims) and flips these flags — a technical guardrail on the response, not just an instruction
  in the prompt.

### 4.3 Check-in trend

- `GET /patients/{id}/symptoms/trend` — rollup of `CheckIn.feeling` counts over the last N days
  (default 14, query-param configurable) for the patient. Backs UI-241 (check-in history/trend).

### 4.4 Surgery knowledge wiki

- New model `WikiArticle`: `id`, `surgery_type`, `content_md`, `status` (`draft`/`approved`),
  `source_case_ids` (JSON array of case ids used to generate it), `created_at`, `approved_by`
  (nullable FK `users.id`).
- `POST /wiki/generate?surgery_type=...` — deterministic template aggregation of `Recommendation`
  text across cases of that `surgery_type` into a new `draft` `WikiArticle` (no LLM call — kept
  cheap and predictable; swappable for LLM-authored generation later without an API change).
- `GET /wiki` — index grouped by `surgery_type`.
- `GET /wiki/{id}` — single article.
- `PATCH /wiki/{id}` — clinician edits `content_md` and/or sets `status=approved` (+
  `approved_by`).

### 4.5 Emergency contact

- `Case` gains `emergency_contact_name`, `emergency_contact_phone` (nullable strings), set at
  case creation — defaults to the assigned clinician's own name/contact if not explicitly
  provided.
- `GET /cases/{id}/emergency-contact` — returns the two fields, for the patient app's
  always-visible emergency button (UI-270).

## 5. Testing

- Unit tests (pytest) for: provider factory selection, security hash/verify/token, RLS
  session-var dependency, FDA-warning propagation logic (matching by drug name, active-case
  filter), AI guardrail flag logic (in_scope/escalate heuristics), wiki generation aggregation.
- No end-to-end/integration test harness is introduced in this pass (out of scope — flagged as a
  gap, not a decision to skip testing generally).

## 6. Out of scope (explicitly)

- Real AWS Cognito/Bedrock/S3 wiring (no credentials/user pool/model access provisioned) — the
  factory interfaces are completed and ready to receive real implementations, but they are not
  connected to live AWS services in this pass.
- AWS Lambda nightly FDA job — replaced by the manual `POST /fda/warnings/refresh` endpoint
  described in §4.1.
- Frontend (web/mobile) changes of any kind.
- CI/CD (GitHub Actions), Terraform/CDK, Redis caching — remain stretch items per the original
  tech-stack doc, not touched here.

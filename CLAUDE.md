# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Remote CarePro is a post-surgery care platform with three components sharing one FastAPI + Postgres backend:

- **`backend/`** — FastAPI + SQLAlchemy + Postgres (pgvector), Alembic migrations
- **`web/`** — Astro 7.2 + React clinician dashboard (with Lucide icons)
- **`mobile/`** — Flutter patient app (Dart 3.12+, Riverpod)

There is no mock server — the backend (with Postgres) is required for the web app, the mobile app, and any integration/e2e test. Unit/widget tests on both backend and mobile are self-contained (in-memory SQLite / fake API client) and need nothing running.

See root `README.md` for full local-stack setup (Docker Compose, seeding, demo credentials, the "golden loop" walkthrough) and `mobile/README.md` for Flutter-specific setup (simulators, `--dart-define` overrides).

## Common Commands

### Backend (`backend/`)
```bash
python3 -m pytest tests -q       # full suite — in-memory SQLite, no Docker needed
python3 -m pytest tests/test_auth_router.py -q -k test_name   # single test
ruff check .                     # lint (rules: E, F, I)
black .                          # format (line-length 100)
alembic upgrade head             # apply migrations (needs real Postgres)
python app/scripts/seed_data.py  # seed demo clinician + patient (current, tested path)
```
Note: `app/scripts/seed.py` also exists but is a separate, older seed script — don't confuse the two; `seed_data.py` is the one documented in the README and exercised by tests.

### Web (`web/`)
```bash
npm run dev      # Astro 7.2 dev server, http://localhost:3000
npm run build    # astro build — static entrypoints and bundles in dist/
npm run preview  # astro preview — preview production build
npm test         # vitest run — component, landing page, and i18n tests
npm run lint     # eslint .
```

### Mobile (`mobile/`)
```bash
flutter test                                   # unit/widget tests (207 tests), fake API client, no backend
flutter test test/some_test.dart               # single test file
flutter analyze                                # static analyzer (0 issues)
flutter test integration_test/golden_loop_test.dart   # e2e — needs backend + seeded DB + booted simulator
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed/json_serializable/riverpod code after touching @freezed or @riverpod classes
```

## Architecture Notes

### Backend: two parallel code paths — know which is live
- `main.py` wires up routers from `app/routers/` only. **`app/api/` (`ai.py`, `fda.py`) and `app/services/rag.py` are dead code** — not imported anywhere, left over from an earlier RAG prototype (mock-only LLM reply, hardcoded OpenRouter client). The live AI chat path is `app/routers/ai.py` → `app/providers/llm.py` (`get_llm_provider()`, switched via `LLM_PROVIDER` env: `mock` / `openrouter` / `bedrock`). Don't extend `app/api/` or `rag.py` by mistake.
- Similarly, `app/database.py` (used by routers/dependencies) and `app/core/database.py` (used only for `init_db()`'s `CREATE EXTENSION vector` on startup) are two separate SQLAlchemy engine/session setups pointing at the same `DATABASE_URL` — not a shared module. `app/models.py` (the real SQLAlchemy models: User, Case, Medication, DoseLog, etc.) and `app/models/` (a small package with just `Base` and the `Embedding` model used by the dead RAG path) also coexist; new models belong in `app/models.py`.

### Backend: auth
- Clinicians use password + JWT; patients are fully passwordless (emailed/logged one-time code — see `app/providers/auth.py`). Two JWT libraries are used intentionally and are not interchangeable: `pyjwt` (`import jwt`, plus `PyJWKClient` for Cognito RS256/JWKS) verifies tokens in `app/providers/auth.py`; `python-jose` (`from jose import jwt`) creates tokens in `app/security.py`.
- Row-level security: `app/dependencies.py`'s `get_db_for_user` sets `app.current_user_id` / `app.current_role` as Postgres session variables (`SET LOCAL`) on every request so RLS policies can scope queries — only takes effect against a real Postgres session (a no-op check on SQLite in tests). Use `get_db_for_user`, not the plain `get_db`, in any new router that must respect per-user row scoping.

### Backend: LLM / observability
- Phoenix tracing (`app/observability.py`) only activates if `PHOENIX_COLLECTOR_ENDPOINT` is set; otherwise `setup_tracing()` is a no-op, so local dev and tests run untraced by default.

### Mobile: two auth implementations exist — only one is live
- Production/runtime state uses a `ChangeNotifier`-based auth flow; a parallel Riverpod `StateNotifier` auth implementation exists only for older tests (`auth_provider_test.dart` still exercises the dead `AuthStateNotifier`). When touching auth, check which one a given screen/test actually depends on before assuming a change propagates to both.
- `ApiService` (`lib/core/network/api_service.dart`) is an abstract interface with a real `HttpApiService` and a `FakeApiService` used for widget/unit test injection — no backend needed for those tests. Integration tests (`integration_test/`) use the real service against a running backend.
- Code generation (`freezed`, `json_serializable`, `riverpod_generator`) requires `build_runner`; regenerate after editing any annotated class or the build will silently use stale generated code.

## ACT Workflow

ACT workflow storage for new Specs is configured in `.act/config.yaml`.

ACT workflow semantics, Workflow Storage selection, artifact vocabulary, and domain-doc guidance are defined in `.act/workflow.md`.

# Remote CarePro

A post-surgery care platform for clinicians and patients: a React clinician web dashboard, a Flutter patient mobile app, and a FastAPI + Postgres backend they share.

## Prerequisites

- [Git](https://git-scm.com)
- [Docker](https://www.docker.com/products/docker-desktop) — runs Postgres + the backend
- [Node.js](https://nodejs.org) v18+ — for the web app
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.27+ — for the mobile app (only needed if you're running the mobile side of the demo; see [mobile/README.md](mobile/README.md) for full setup including Android/iOS simulator requirements)

---

## Running the Stack Locally

The backend (+ Postgres) is required for almost everything below — there is no mock server anymore. Pick the row that matches what you're doing:

| Goal | What you need running |
|------|------------------------|
| Work on the web app | Backend + web |
| Work on the mobile app | Backend + seeded DB + mobile |
| Backend unit tests only | Nothing else — `pytest` is self-contained |
| Mobile unit/widget tests only | Nothing else — uses a fake API client, no backend |
| Mobile integration/e2e test | Backend + seeded DB + a booted simulator |

### 1. Clone and configure

```bash
git clone https://github.com/FlaviusBurghilaOPIT/uep2026.git
cd uep2026
cp .env.example .env
```

### 2. Start Postgres + the backend

```bash
docker-compose up backend
```

This also starts the `db` service (Postgres) as a dependency. Leave it running in this terminal. Verify it's up at `http://localhost:8000/docs`.

### 3. Seed demo data (new terminal tab)

```bash
docker-compose exec backend python app/scripts/seed_data.py
```

Creates the database tables from the current models and seeds a demo clinician + patient (see credentials below). Safe to re-run — it skips users that already exist. It does **not** run Alembic migrations; for a fresh container this is fine since it creates tables straight from the current SQLAlchemy models. If you're upgrading an existing, already-seeded database instead of starting fresh, run `docker-compose exec backend alembic upgrade head` first.

### 4. Start the web app (only if you're working on the clinician dashboard)

```bash
cd web
npm install
npm run dev
```

Open `http://localhost:5173`. The web app talks to the real backend at `http://localhost:8000` by default — no extra config needed.

### 5. Start the mobile app (only if you're working on the patient app)

```bash
cd mobile
flutter pub get
flutter run -d android   # or: flutter run -d iphonesimulator
```

The app resolves the backend URL automatically per platform. See **[mobile/README.md](mobile/README.md)** for simulator setup, device IDs, and `--dart-define` overrides for pointing at a remote demo backend.

### Demo credentials

| Role | Email | How to sign in |
|---|---|---|
| Clinician | `clinician@example.com` | Password: `password123` |
| Patient (already onboarded) | `patient@example.com` | Sign-in code: `424242` (fixed, long-lived, seeded by `seed_data.py`) |

Patients don't have passwords — sign-in is always an emailed one-time code. In real deployments the code is emailed via SES; locally (no `AWS_REGION` set), the code is logged to the backend's console output instead, so you can always find it there too, in addition to the fixed demo code above.

### Demo walkthrough (the golden loop)

1. **Web** — log in as the clinician at `http://localhost:5173/login`.
2. **Web** — `Patients` → `+ New Patient`, invite a new patient. A sign-in code is emailed to them immediately (or logged to the backend console in local dev) and also shown on screen as a backup.
3. **Web** — `+ New Case` for the invited patient, then prescribe 1–2 medications from the case's `Medications` screen.
4. **Mobile** — on the onboarding screen, tap **Sign In** (or **Create account** — both lead to the same flow), enter the patient's email, tap to send a code, then enter it. First-time patients continue to a short profile step (phone, date of birth); returning patients go straight in.
5. **Mobile** — land on `Today`, log a dose as `Taken`/`Skipped`.
6. **Mobile** — open `Assistant` and ask an in-scope question (e.g. "when should I take my medication?") to see a real AI reply, or an out-of-scope one (e.g. "can I take a double dose?") to see the safety guardrail refuse it.
7. **Web** — back on `Patients`, open the patient's case to see the prescribed medications and (once logged) the recorded dose.

Note: a dedicated clinician "Needs Attention" triage view (surfacing missed doses / AI escalations without opening each patient) is planned but not yet built — see [Project Status](#project-status) below. Today's web demo shows the roster and per-patient case detail.

---

## Ports

| Service | URL |
|---|---|
| Real backend (FastAPI) | `http://localhost:8000` (`/docs` for OpenAPI) |
| Mock server (Prism) | `http://localhost:8001` |
| Web dashboard (Vite dev) | `http://localhost:5173` |
| Postgres | `localhost:5432` (`caredev` / `caredev`, db `remotecare`) |

## Testing

Two tiers per platform — unit/widget tests need nothing but the language toolchain; integration/e2e tests need the full stack running.

| Platform | Unit / Widget (no backend needed) | Integration / E2E (needs the full stack) |
|----------|-------------------------------------|-------------------------------------------|
| Backend | `cd backend && python3 -m pytest tests -q` — in-memory SQLite, no Docker/Postgres, LLM/SNS/email all mocked or dry-run | *(none — the pytest suite already exercises real routes via FastAPI's `TestClient`)* |
| Web | `cd web && npm run build && npm run lint` — no automated tests exist yet (`vitest` is installed but unused) | *(none yet)* |
| Mobile | `cd mobile && flutter test && flutter analyze` — uses a fake API client, no backend needed | `cd mobile && flutter test integration_test/golden_loop_test.dart` — requires: backend running, DB seeded (`seed_data.py`), a booted simulator |

## Project Status & Roadmap

The current iteration ("Core Loop Hardening & Mobile Polish") is tracked in **[docs/product/10-implementation-plan.md](docs/product/10-implementation-plan.md)**, with live progress against GitHub issues and mobile ACT Work Items. Broader UX/product research lives in `docs/product/00-04`, `09` and `docs/ux/05-08`. Mobile implementation specs live under `ai_specs/`.

## Team Branches

- `p1/platform` — Platform, AI, AWS (P1)
- `p2/web-authoring` — Clinician web authoring screens (P2)
- `p3/web-monitoring` — Clinician web monitoring screens (P3)
- `p4/mobile` — Patient mobile app (P4)
- `p5/backend` — Backend services (P5)

## Mobile App (Flutter)

For detailed Flutter mobile app setup (Android, iOS, local backend seeding, demo credentials, debugging), see **[mobile/README.md](mobile/README.md)**.

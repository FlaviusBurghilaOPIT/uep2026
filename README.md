# Remote CarePro

A post-surgery care platform for clinicians and patients: a React clinician web dashboard, a Flutter patient mobile app, and a FastAPI + Postgres backend they share.

## Prerequisites

- [Git](https://git-scm.com)
- [Docker](https://www.docker.com/products/docker-desktop) — runs Postgres + the backend
- [Node.js](https://nodejs.org) v18+ — for the web app
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.27+ — for the mobile app (only needed if you're running the mobile side of the demo; see [mobile/README.md](mobile/README.md) for full setup including Android/iOS simulator requirements)

---

## Full Demo — Clinician + Patient, End to End

This is the fastest path to a working demo of the whole loop: a clinician invites a patient on the web dashboard, the patient onboards and logs a dose on mobile, and the clinician sees the result.

### 1. Clone and configure

```bash
git clone https://github.com/FlaviusBurghilaOPIT/uep2026.git
cd uep2026
cp .env.example .env
```

### 2. Start Postgres + the real backend

```bash
docker-compose up backend
```

This also starts the `db` service (Postgres) as a dependency. Leave it running in this terminal. Verify it's up at `http://localhost:8000/docs`.

### 3. Seed demo data (new terminal tab)

```bash
docker-compose exec backend python app/scripts/seed_data.py
```

This creates the database tables from the current models and seeds a demo clinician + patient (see credentials below). Safe to re-run — it skips users that already exist. It does **not** run Alembic migrations; for a fresh container this is fine since it creates tables straight from the current SQLAlchemy models. If you're upgrading an existing, already-seeded database instead of starting fresh, run `docker-compose exec backend alembic upgrade head` first.

### 4. Start the web app (new terminal tab)

```bash
cd web
npm install
npm run dev
```

Open `http://localhost:5173`. The web app talks to the real backend at `http://localhost:8000` by default — no extra config needed.

### 5. Start the mobile app (new terminal tab)

```bash
cd mobile
flutter pub get
flutter run -d android   # or: flutter run -d iphonesimulator
```

The app resolves the backend URL automatically per platform (`10.0.2.2:8000` on the Android emulator, `localhost:8000` on iOS). See **[mobile/README.md](mobile/README.md)** for simulator setup, device IDs, and `--dart-define` overrides for pointing at a remote demo backend.

### Demo credentials

| Role | Email | Password |
|---|---|---|
| Clinician | `clinician@example.com` | `password123` |
| Patient (already onboarded) | `patient@example.com` | `password123` |

### Demo walkthrough (the golden loop)

1. **Web** — log in as the clinician at `http://localhost:5173/login`.
2. **Web** — `Patients` → `+ New Patient`, invite a new patient. The 6-digit invite code is shown immediately and also persists on that patient's card back on the roster (with a Copy button) if you navigate away before onboarding.
3. **Web** — `+ New Case` for the invited patient, then prescribe 1–2 medications from the case's `Medications` screen.
4. **Mobile** — on the login screen, tap **"Have an invite code?"**, enter the patient's email and the 6-digit code, then complete onboarding (password, DOB, phone).
5. **Mobile** — land on `Today`, log a dose as `Taken`/`Skipped`.
6. **Mobile** — open `Assistant` and ask an in-scope question (e.g. "when should I take my medication?") to see a real AI reply, or an out-of-scope one (e.g. "can I take a double dose?") to see the safety guardrail refuse it.
7. **Web** — back on `Patients`, open the patient's case to see the prescribed medications and (once logged) the recorded dose.

Note: a dedicated clinician "Needs Attention" triage view (surfacing missed doses / AI escalations without opening each patient) is planned but not yet built — see [Project Status](#project-status) below. Today's web demo shows the roster and per-patient case detail.

---

## Frontend-Only Quick Start (no backend, mocked API)

Useful for iterating on the web UI without standing up Postgres/backend:

```bash
docker-compose up mock   # Prism mock server on http://localhost:8001, from mock/openapi.yaml
cd web
npm install
VITE_API_URL=http://localhost:8001 npm run dev
```

## Ports

| Service | URL |
|---|---|
| Real backend (FastAPI) | `http://localhost:8000` (`/docs` for OpenAPI) |
| Mock server (Prism) | `http://localhost:8001` |
| Web dashboard (Vite dev) | `http://localhost:5173` |
| Postgres | `localhost:5432` (`caredev` / `caredev`, db `remotecare`) |

## Testing

```bash
# Backend
cd backend && python3 -m pytest tests -q

# Web
cd web && npm run build && npm run lint

# Mobile
cd mobile && flutter test && flutter analyze
```

`web/` has no automated test runner configured yet — verification there is build/lint plus manual QA.

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

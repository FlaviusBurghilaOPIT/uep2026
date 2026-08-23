# Remote CarePro

A post-surgery care platform for clinicians and patients: a Pure Astro SSR clinician web dashboard (with Lucide icons and tri-lingual i18n), a Flutter patient mobile app, and a FastAPI + Postgres backend they share.

## Prerequisites

- [Git](https://git-scm.com)
- [Docker](https://www.docker.com/products/docker-desktop) — runs Postgres + the backend
- [Node.js](https://nodejs.org) v18+ — for the web app (Astro SSR)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.27+ (Dart 3.12+) — for the mobile app (only needed if you're running the mobile side of the demo; see [mobile/README.md](mobile/README.md) for full setup including Android/iOS simulator requirements)

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

Open `http://localhost:3000` (or `http://localhost:5173`). The web app talks to the real backend at `http://localhost:8000` by default — no extra config needed.

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

1. **Web (Clinician)** — Log in at `http://localhost:3000/login` (or 1-click Demo Clinician).
2. **Web (Authoring)** — `Patients` → `+ New Patient`, invite a new patient. `+ New Case` (e.g. Total Knee Replacement), prescribe medication regimen, and check openFDA drug safety warnings.
3. **Web (Triage)** — `Triage Dashboard` displays patients dynamically prioritized by urgency (`CRITICAL`, `WARNING`, `STABLE`) with 1-click alert resolution.
4. **Mobile (Patient)** — Onboarding with passwordless 6-digit OTP (clipboard auto-paste and auto-submit).
5. **Mobile (Adherence)** — Land on `Today`, log doses in 1 tap with pill form badges (Capsule, Tablet, Liquid) and 5s undo window.
6. **Mobile (Ring Closure)** — Logging all scheduled doses triggers the 600ms animated circular sweep with emerald sparkle and haptic pulse.
7. **Mobile (Emergency Escalation)** — Daily check-in selecting acute distress ("Feeling Unwell") immediately reveals the Emergency Red-Flag Banner with direct 911 / Clinic dial buttons.
8. **Mobile (AI Assistant)** — Context-aware recovery chat grounded via Streaming RAG with strict medical guardrail refusals.

---

## Ports

| Service | URL | Description |
|---|---|---|
| Backend API (FastAPI) | `http://localhost:8000` | OpenAPI docs at `/docs` |
| Web Portal (Pure Astro SSR) | `http://localhost:3000` | Clinician portal and landing page |
| PostgreSQL Database | `localhost:5432` | `caredev` / `caredev`, db `remotecare` |

---

## Testing & Quality Verification

Full test automation across all three platform components:

| Platform | Test Command | Scope & Coverage | Status |
|---|---|---|---|
| **Backend** | `cd backend && pytest` | 164 unit, RLS authorization, and integration tests | **164 Passing** |
| **Web Portal** | `cd web && npm test` | Vitest Astro page, template DOM, and i18n tests | **10 Passing** |
| **Mobile App** | `cd mobile && flutter test` | 207 unit, widget, and accessibility (WCAG) tests | **207 Passing** |
| **Mobile Linter** | `cd mobile && flutter analyze` | Dart/Flutter static analyzer | **0 Issues** |

---

## 🏆 Final Submission & Documentation

- **Official UEP 5.0 Report:** See [FINAL_SUBMISSION_REPORT.md](FINAL_SUBMISSION_REPORT.md) for the complete submission document formatted to the UEP template, including problem statement, architecture diagrams, challenges, and 2-minute demo script.
- **Product Strategy & Specs:**
  - [CUSTOMER.md](docs/CUSTOMER.md) — Patient persona, clinical pain points & jobs-to-be-done.
  - [PRODUCT.md](docs/PRODUCT.md) — Feature matrix and clinical outcome metrics.
  - [DESIGN.md](docs/DESIGN.md) — Design tokens, color system, and typography.
  - [POSITIONING.md](docs/POSITIONING.md) — Market differentiation and competition strategy.
  - [SPEC.md](SPEC.md) — Technical specifications and acceptance criteria.
- **Mobile Details:** See [mobile/README.md](mobile/README.md) for detailed mobile platform configurations.


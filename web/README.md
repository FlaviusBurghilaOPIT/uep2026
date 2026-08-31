# RemoteCare Pro — Clinician Web Portal (Astro SSR)

High-performance clinician portal for surgical case authoring, real-time patient triage exception queue, openFDA safety intelligence, and recovery trajectory analytics.

---

## ⚡ Quick Run (3 Steps)

```bash
# 1. Navigate to web directory
cd web

# 2. Install dependencies
npm install

# 3. Start local development server (http://localhost:3000)
npm run dev
```

---

## 🔑 Clinician Credentials

* **URL:** `http://localhost:3000` (or `http://localhost` via Nginx)
* **Email:** `clinician@example.com`
* **Password:** `CarePro#2026!Secure`

---

## 🛠️ Available Commands

```bash
# Run Vitest test suite (32 tests)
npm test

# Build production bundle
npm run build

# Preview production build
npm run preview

# Run linter
npm run lint
```

---

## ⚙️ Architecture

* **Framework:** Astro 7.2 SSR with Node adapter (`@astrojs/node`) and React hydration (`@astrojs/react`).
* **Styling & UI:** Tailwind CSS, Refactoring UI design tokens, Lucide Icons (`@lucide/astro`).
* **i18n:** Dynamic multi-locale support (English, Spanish, Italian).
* **Testing:** Vitest + JSDOM.

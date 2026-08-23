# RemoteCare Pro — Clinician Web Portal (Pure Astro SSR)

This project provides the clinician web portal for RemoteCare Pro, powered by **Astro 5+ SSR** with **Lucide Icons** (`lucide-astro`).

## Architecture

- **Framework**: [Astro](https://astro.build) with standalone SSR Node.js adapter (`@astrojs/node`)
- **Icons**: [Lucide Icons](https://lucide.dev) (`lucide-astro`)
- **i18n**: Multilingual support (English, Spanish, Italian) with dynamic parameter interpolation and SSR cookie detection
- **Testing**: Vitest (`vitest`) with JSDOM

## Available Scripts

In the `web/` directory, you can run:

### `npm run dev`
Starts the Astro local development server at `http://localhost:3000` (or `http://localhost:5173` if configured).

### `npm run build`
Builds static HTML entrypoints and optimized client bundles into the `dist/` directory.

### `npm run preview`
Locally preview the production build in `dist/`.

### `npm test`
Runs the Vitest unit and integration test suite (`vitest run`).

### `npm run lint`
Runs ESLint across TypeScript and TSX source files.

## Project Structure

```
web/
├── astro.config.mjs        # Astro 7.2 configuration with @astrojs/react
├── tsconfig.json           # TypeScript configuration extending astro/tsconfigs/strict
├── eslint.config.js        # ESLint flat config
├── public/                 # Static assets (favicons, images)
└── src/
    ├── layouts/            # Astro layout components (Layout.astro, AppLayout.astro)
    ├── pages/              # Native Astro routes (index.astro, landing.astro, login.astro, dashboard.astro, patients/, cases/, fda.astro, 404.astro)
    ├── components/         # Astro navigation & UI components (NavBar.astro, LanguageSwitcher.astro)
    ├── i18n/               # Localization dictionaries (en, es, it)
    ├── api/                # API client and analytics instrumentation
    └── __tests__/          # Vitest test suites
```

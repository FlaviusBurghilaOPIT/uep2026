# Clinician Web: Radix UI + Base UI + Font Awesome Migration — Design

**Date:** 2026-07-25
**Status:** Approved (brainstorming session)
**Scope:** `web/` only — all 12 pages. Backend untouched.

## 1. Goal

Migrate the clinician web dashboard from hand-rolled controls and emoji icons to a
shared, accessible component layer built on Radix UI Primitives and Base UI, with
Font Awesome replacing every emoji. No visual redesign — same look, better bones.

Decisions locked during brainstorming:

1. **Best-of-breed per component** — Radix Primitives for Dialog/Select/Tabs/RadioGroup/
   Toast/Tooltip; Base UI only for NumberField (the one primitive Radix lacks).
2. **Full migration in one pass** — all 12 pages; no coexistence period.
3. **All emoji replaced** — nav, buttons, severity badges, section headers, toasts.

## 2. Architecture

### 2.1 Shared wrapper layer — `web/src/components/ui/`

Pages consume only these wrappers, never raw primitives. Wrappers own styling
(existing inline style-object convention, centralized) and accessibility wiring.

| Wrapper | Underlying | Used for |
|---|---|---|
| `Dialog` | `@radix-ui/react-dialog` | Triage resolution modal — focus trap, Escape, `aria-modal` free (completes a11y spec W-04) |
| `Tabs` | `@radix-ui/react-tabs` | Triage filter (All / Red / Amber) |
| `Select` | `@radix-ui/react-select` | Language switcher, patient picker (CreateCase), frequency (Medications) |
| `RadioGroup` | `@radix-ui/react-radio-group` | Outreach method in resolution modal |
| `Toast` | `@radix-ui/react-toast` | Resolution success; export failures (replaces `alert()` in exportUtils) |
| `NumberField` | `@base-ui/react` NumberField | Duration (days) — min 1 enforced by the control |
| `Tooltip` | `@radix-ui/react-tooltip` | Disabled Call button explanation (no phone registered) |
| `FormField` | ours | label + input/textarea + `aria-invalid`/`aria-describedby` wiring for all forms |
| `Icon` | ours + `@fortawesome/react-fontawesome` | FA icon; `aria-hidden` default, optional accessible label |

### 2.2 Dependencies to add

```
@radix-ui/react-dialog @radix-ui/react-select @radix-ui/react-tabs
@radix-ui/react-radio-group @radix-ui/react-toast @radix-ui/react-tooltip
@radix-ui/react-visually-hidden
@base-ui/react
@fortawesome/fontawesome-svg-core @fortawesome/free-solid-svg-icons
@fortawesome/react-fontawesome
```

`axios` (unused) is removed in the same pass.

## 3. Icon map (emoji → Font Awesome, complete)

| Emoji | FA icon | Where |
|---|---|---|
| 🚨 | `faTriangleExclamation` | Nav: triage; triage section header, red tab |
| 👥 | `faUserGroup` | Nav: patients |
| 📋 | `faFileCirclePlus` | Nav: new case |
| 🛡️ | `faShieldHalved` | Nav: FDA safety |
| 🚪 | `faRightFromBracket` | Nav: logout |
| 🌐 | `faGlobe` | Language selector |
| 📥 | `faFileCsv` | Export CSV buttons |
| 📄 | `faFilePdf` | Print PDF buttons |
| ✅ | `faCircleCheck` | Resolve exception; toast success; empty-state check |
| 📞 | `faPhone` | Call patient; emergency contact card |
| 📋 | `faClipboardList` | Review case |
| 🔍 | `faMagnifyingGlass` | Search fields, FDA loading state |
| 🔄 | `faRotate` | Refresh triage |
| 🤖 | `faRobot` | AI assistant button/header |
| ⏰ | `faClock` | Reminder-times hint |
| 💊 | `faPills` | FDA empty state |
| 🛑 | `faCircleExclamation` | Red severity badges |
| ⚠️ | `faTriangleExclamation` | Amber severity badges |
| 🟢 | `faCircleCheck` | Stable section header |
| × | `faXmark` | Modal/toast/search close buttons |
| ← | `faArrowLeft` | Back links |
| + | `faPlus` | Add buttons |

Severity badges keep their text labels — icons are decoration, never the only
channel (dual color+text rule from the UX docs stands).

## 4. Page-by-page migration

- **NavBar** — FA icons; language switcher → `Select`; keep `<nav>`/`<ul>` landmarks.
- **LoginPage** — `FormField` for email/password (keeps form submit + labels).
- **CreatePatientPage / CreateCasePage** — `FormField` for all inputs; patient
  picker → `Select`; invite-success screen unchanged except icons.
- **MedicationsPage** — frequency → `Select`; duration → `NumberField` (Base UI,
  min 1); `FormField` elsewhere.
- **MedicationsListPage / RecommendationsListPage / FDAPage / CaseDetailPage** —
  FA icons; error/empty states unchanged.
- **TriageDashboardPage** — filter tabs → `Tabs`; resolution modal → `Dialog`
  (focus trap + Escape now handled by the primitive, completing W-04); outreach
  method → `RadioGroup`; success toast → `Toast`; disabled Call button →
  `Tooltip`; all badges/icons → FA.
- **PatientsPage** — FA icons; export failures via `Toast`.

## 5. Error handling

- `exportUtils` functions no longer `alert()` — they **throw**, and calling pages
  surface failures via `Toast`. (Success stays a file download / print window.)
- Primitives introduce no new app-level failure modes. `NumberField` enforces
  min 1 at the control level; existing submit validation stays as a second layer.
- Toast provider mounts once at the App root (`LanguageProvider` sibling).

## 6. Data flow

Unchanged. This is a pure presentation-layer migration — no API contracts,
routes, state shapes, or i18n keys change. (Exception: no user-facing copy
changes at all; icons replace decorative emoji only.)

## 7. Testing

- Gate: `npm run build` (`tsc -b && vite build`) must pass — it is the only
  type-check step.
- `npm run lint` remains broken repo-wide (pre-existing typescript-eslint vs
  TypeScript 7 incompatibility) — unchanged by this work, called out in the
  final report rather than fixed here.
- Manual smoke: dev server + seeded backend, walk the golden loop — login,
  triage (tabs, modal open/resolve/Escape, tooltip, toast), patients, invite,
  case create (Select), prescribe (Select + NumberField), FDA, case detail.
- No vitest suite exists; not introduced in this pass (noted as standing debt).

## 8. Explicit non-goals

- No visual redesign, no new color/typography tokens, no Tailwind.
- No routing, API, or backend changes.
- No new user-facing copy or i18n changes.
- eslint/TS7 repair (separate issue).

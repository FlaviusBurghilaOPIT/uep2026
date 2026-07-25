# Clinician Web: Radix UI + Base UI + Font Awesome Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate all 12 clinician web pages from hand-rolled controls + emoji icons to a shared, accessible wrapper layer over Radix Primitives and Base UI, with Font Awesome icons throughout — no visual redesign.

**Architecture:** Thin styled wrappers in `web/src/components/ui/` own all styling (existing inline style-object convention) and accessibility wiring; pages consume only wrappers. Radix Primitives for Dialog/Select/Tabs/RadioGroup/Toast/Tooltip; Base UI (`@base-ui-components/react`) for NumberField only.

**Tech Stack:** React 19, TypeScript 7, Vite 8, `@radix-ui/react-*`, `@base-ui-components/react`, `@fortawesome/react-fontawesome`.

**Spec:** `docs/superpowers/specs/2026-07-25-clinician-web-ui-libraries-design.md`

## Global Constraints

- No Tailwind, no CSS files added — inline style objects, matching existing code.
- No visual redesign: same colors, spacing, layout as current UI.
- No user-facing copy or i18n key changes; icons replace decorative emoji only.
- Severity badges keep text labels — icons are decoration, never the only channel.
- Every task ends with `npm run build` (`tsc -b && vite build`) green + a commit.
- `npm run lint` is broken repo-wide (typescript-eslint vs TS 7) — do not attempt to fix; note in final report.
- Web has no test runner configured — build + manual smoke (Task 7) is the verification gate per spec.

---

### Task 1: Dependencies, Icon wrapper, Toast foundation

**Files:**
- Modify: `web/package.json`
- Create: `web/src/components/ui/Icon.tsx`
- Create: `web/src/components/ui/Toast.tsx`
- Create: `web/src/components/ui/index.ts`
- Modify: `web/src/App.tsx`

**Interfaces:**
- Produces:
  - `Icon({ icon: IconDefinition, size?, label?, style? })` — `aria-hidden` unless `label` given.
  - `ToastProvider({ children })` — mount once at App root.
  - `useToast(): { show: (message: string) => void }` — consumed by TriageDashboardPage (Task 5) and export callers (Task 6).
- Consumes: nothing.

- [ ] **Step 1: Install dependencies, remove unused axios**

```bash
cd web
npm uninstall axios
npm install @radix-ui/react-dialog @radix-ui/react-select @radix-ui/react-tabs \
  @radix-ui/react-radio-group @radix-ui/react-toast @radix-ui/react-tooltip \
  @radix-ui/react-visually-hidden \
  @base-ui-components/react \
  @fortawesome/fontawesome-svg-core @fortawesome/free-solid-svg-icons \
  @fortawesome/react-fontawesome
```

- [ ] **Step 2: Create `web/src/components/ui/Icon.tsx`**

```tsx
import {
  FontAwesomeIcon,
  type FontAwesomeIconProps,
} from '@fortawesome/react-fontawesome'
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core'

type IconProps = {
  icon: IconDefinition
  size?: FontAwesomeIconProps['size']
  /** Accessible name. Omit for decorative icons (the default). */
  label?: string
  style?: React.CSSProperties
}

export function Icon({ icon, size, label, style }: IconProps) {
  return (
    <FontAwesomeIcon
      icon={icon}
      size={size}
      style={style}
      aria-hidden={label ? undefined : true}
      aria-label={label}
      role={label ? 'img' : undefined}
    />
  )
}
```

- [ ] **Step 3: Create `web/src/components/ui/Toast.tsx`**

```tsx
import * as RadixToast from '@radix-ui/react-toast'
import { createContext, useCallback, useContext, useState, type ReactNode } from 'react'
import { faCircleCheck, faXmark } from '@fortawesome/free-solid-svg-icons'
import { Icon } from './Icon'

type ToastContextValue = { show: (message: string) => void }

const ToastContext = createContext<ToastContextValue>({ show: () => {} })

export const useToast = () => useContext(ToastContext)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [message, setMessage] = useState<string | null>(null)
  const show = useCallback((msg: string) => setMessage(msg), [])

  return (
    <ToastContext.Provider value={{ show }}>
      <RadixToast.Provider swipeDirection="right" duration={4000}>
        {children}
        <RadixToast.Root
          open={message !== null}
          onOpenChange={(open) => !open && setMessage(null)}
          style={styles.root}
        >
          <RadixToast.Description style={styles.description}>
            <Icon icon={faCircleCheck} style={{ marginRight: '8px' }} />
            {message}
          </RadixToast.Description>
          <RadixToast.Close style={styles.close} aria-label="Close">
            <Icon icon={faXmark} />
          </RadixToast.Close>
        </RadixToast.Root>
        <RadixToast.Viewport style={styles.viewport} />
      </RadixToast.Provider>
    </ToastContext.Provider>
  )
}

const styles = {
  viewport: {
    position: 'fixed' as const,
    top: '20px',
    right: '20px',
    zIndex: 1100,
  },
  root: {
    backgroundColor: '#065f46',
    color: '#ffffff',
    padding: '12px 18px',
    borderRadius: '8px',
    boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
  },
  description: {
    fontSize: '13px',
    fontWeight: '500' as const,
    display: 'flex',
    alignItems: 'center',
    margin: 0,
  },
  close: {
    background: 'transparent',
    border: 'none',
    color: '#ffffff',
    fontSize: '14px',
    cursor: 'pointer',
    marginLeft: '8px',
    lineHeight: 1,
  },
}
```

- [ ] **Step 4: Create barrel `web/src/components/ui/index.ts`**

```tsx
export { Icon } from './Icon'
export { ToastProvider, useToast } from './Toast'
```

(Later tasks append their wrappers to this file.)

- [ ] **Step 5: Mount `ToastProvider` in `web/src/App.tsx`**

In the `App()` component, wrap `<BrowserRouter>` so every page can `useToast()`:

```tsx
function App() {
  return (
    <LanguageProvider>
      <ToastProvider>
        <BrowserRouter>
          {/* …unchanged Layout + Routes… */}
        </BrowserRouter>
      </ToastProvider>
    </LanguageProvider>
  )
}
```

Import: `import { ToastProvider } from './components/ui'`

- [ ] **Step 6: Build**

Run: `cd web && npm run build`
Expected: `tsc -b && vite build` passes.

- [ ] **Step 7: Commit**

```bash
git add web/package.json web/package-lock.json web/src/components/ui web/src/App.tsx
git commit -m "feat(web): add UI wrapper layer foundation (Icon, Toast) with Radix + Font Awesome"
```

---

### Task 2: FormField wrapper + Login & CreatePatient migration

**Files:**
- Create: `web/src/components/ui/FormField.tsx`
- Modify: `web/src/components/ui/index.ts`
- Modify: `web/src/pages/LoginPage.tsx`
- Modify: `web/src/pages/CreatePatientPage.tsx`

**Interfaces:**
- Produces:
  ```tsx
  FormField({
    label: string,
    error?: string,        // shown with role="alert"; also marks control invalid
    invalid?: boolean,     // marks control invalid without message
    hint?: string,         // helper text, hidden when error present
    children: (control: {
      id: string
      'aria-invalid': boolean
      'aria-describedby': string | undefined
    }) => ReactNode,
  })
  ```
- Consumes: `Icon` (Task 1) — no other wrappers.

- [ ] **Step 1: Create `web/src/components/ui/FormField.tsx`**

```tsx
import { useId, type ReactNode } from 'react'

type ControlProps = {
  id: string
  'aria-invalid': boolean
  'aria-describedby': string | undefined
}

type FormFieldProps = {
  label: string
  error?: string
  invalid?: boolean
  hint?: string
  children: (control: ControlProps) => ReactNode
}

export function FormField({ label, error, invalid, hint, children }: FormFieldProps) {
  const id = useId()
  const errorId = `${id}-error`
  const hintId = `${id}-hint`
  const describedBy = error ? errorId : hint ? hintId : undefined

  return (
    <div style={styles.field}>
      <label htmlFor={id} style={styles.label}>
        {label}
      </label>
      {children({
        id,
        'aria-invalid': !!error || !!invalid,
        'aria-describedby': describedBy,
      })}
      {hint && !error && (
        <p id={hintId} style={styles.hint}>
          {hint}
        </p>
      )}
      {error && (
        <p id={errorId} role="alert" style={styles.error}>
          {error}
        </p>
      )}
    </div>
  )
}

const styles = {
  field: { display: 'flex', flexDirection: 'column' as const, gap: '6px' },
  label: { fontSize: '13px', fontWeight: '500' as const, color: '#111827' },
  hint: { fontSize: '12px', color: '#64748b', margin: 0 },
  error: { fontSize: '13px', color: '#dc2626', margin: 0 },
}
```

Add `export { FormField } from './FormField'` to `web/src/components/ui/index.ts`.

- [ ] **Step 2: Migrate LoginPage inputs to FormField**

In `web/src/pages/LoginPage.tsx`, replace the label+input pairs inside the `<form>`:

```tsx
<FormField label={t('login.emailPlaceholder')} error={error || undefined}>
  {(control) => (
    <input
      {...control}
      style={styles.input}
      type="email"
      autoComplete="email"
      required
      value={email}
      onChange={(e) => setEmail(e.target.value)}
    />
  )}
</FormField>

<FormField label={t('login.passwordPlaceholder')} invalid={!!error}>
  {(control) => (
    <input
      {...control}
      style={styles.input}
      type="password"
      autoComplete="current-password"
      required
      value={password}
      onChange={(e) => setPassword(e.target.value)}
    />
  )}
</FormField>
```

Note: the shared server error renders once (on the email field); the password field is marked invalid without a duplicate message. Remove the old standalone `{error && <p role="alert">…}` block and the two `<label>` elements. Import `FormField` from `../components/ui`. Keep everything else (form submit, loading state, navigate, trackEvent) unchanged.

- [ ] **Step 3: Migrate CreatePatientPage to FormField**

Replace each label+input pair, wiring per-field invalid state that already exists (`missing` array). Example for full name — apply the same pattern to email, surgery type, and emergency contact phone (phone has no `invalid`):

```tsx
<FormField
  label={t('createPatient.fullName')}
  invalid={missing.includes('full-name')}
  error={error || undefined}
>
  {(control) => (
    <input
      {...control}
      style={styles.input}
      type="text"
      placeholder={t('createPatient.fullNamePlaceholder')}
      value={fullName}
      onChange={(e) => setFullName(e.target.value)}
    />
  )}
</FormField>
```

The shared form-level error renders on the first field only (same UX as today); remaining fields pass `invalid` only. Delete the old `<label>` elements and the standalone error `<span>`. Keep validation, submit, invite-success screen, and copy button unchanged.

- [ ] **Step 4: Build**

Run: `cd web && npm run build` — Expected: passes.

- [ ] **Step 5: Commit**

```bash
git add web/src/components/ui web/src/pages/LoginPage.tsx web/src/pages/CreatePatientPage.tsx
git commit -m "feat(web): FormField wrapper; migrate login and patient invite forms"
```

---

### Task 3: Select wrapper + NavBar & CreateCase migration

**Files:**
- Create: `web/src/components/ui/Select.tsx`
- Modify: `web/src/components/ui/index.ts`
- Modify: `web/src/components/NavBar.tsx`
- Modify: `web/src/pages/CreateCasePage.tsx`

**Interfaces:**
- Produces:
  ```tsx
  Select({
    value: string,
    onChange: (value: string) => void,
    options: { value: string; label: string }[],
    placeholder?: string,
    disabled?: boolean,
    id?: string,
    'aria-invalid'?: boolean,
    'aria-describedby'?: string,
    style?: React.CSSProperties,
  })
  ```
  Note: Radix Select forbids empty-string item values — use `placeholder` for the "nothing selected" state (replaces the current `<option value="">` pattern).
- Consumes: `Icon`, `FormField` (Task 2) — CreateCase wraps Select in FormField via render prop.

- [ ] **Step 1: Create `web/src/components/ui/Select.tsx`**

```tsx
import * as RadixSelect from '@radix-ui/react-select'
import { faCheck, faChevronDown } from '@fortawesome/free-solid-svg-icons'
import { Icon } from './Icon'

type SelectOption = { value: string; label: string }

type SelectProps = {
  value: string
  onChange: (value: string) => void
  options: SelectOption[]
  placeholder?: string
  disabled?: boolean
  id?: string
  'aria-invalid'?: boolean
  'aria-describedby'?: string
  style?: React.CSSProperties
}

export function Select({
  value,
  onChange,
  options,
  placeholder,
  disabled,
  id,
  style,
  ...aria
}: SelectProps) {
  return (
    <RadixSelect.Root value={value} onValueChange={onChange} disabled={disabled}>
      <RadixSelect.Trigger id={id} style={{ ...styles.trigger, ...style }} {...aria}>
        <RadixSelect.Value placeholder={placeholder} />
        <RadixSelect.Icon style={styles.triggerIcon}>
          <Icon icon={faChevronDown} />
        </RadixSelect.Icon>
      </RadixSelect.Trigger>
      <RadixSelect.Portal>
        <RadixSelect.Content style={styles.content} position="popper" sideOffset={4}>
          <RadixSelect.Viewport>
            {options.map((opt) => (
              <RadixSelect.Item key={opt.value} value={opt.value} style={styles.item}>
                <RadixSelect.ItemText>{opt.label}</RadixSelect.ItemText>
                <RadixSelect.ItemIndicator style={styles.indicator}>
                  <Icon icon={faCheck} />
                </RadixSelect.ItemIndicator>
              </RadixSelect.Item>
            ))}
          </RadixSelect.Viewport>
        </RadixSelect.Content>
      </RadixSelect.Portal>
    </RadixSelect.Root>
  )
}

const styles = {
  trigger: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: '8px',
    width: '100%',
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    backgroundColor: '#ffffff',
    color: '#111827',
    cursor: 'pointer',
  },
  triggerIcon: { color: '#64748b', fontSize: '12px' },
  content: {
    backgroundColor: '#ffffff',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)',
    padding: '4px',
    zIndex: 1200,
    minWidth: 'var(--radix-select-trigger-width)',
  },
  item: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '8px 10px',
    borderRadius: '6px',
    fontSize: '14px',
    color: '#111827',
    cursor: 'pointer',
    outline: 'none',
  },
  indicator: { color: '#0284c7' },
}
```

Add `export { Select } from './Select'` to the barrel.

- [ ] **Step 2: Migrate NavBar — FA icons + language Select**

In `web/src/components/NavBar.tsx`:

- Import: `import { Icon, Select } from './ui'` and the icons
  `faTriangleExclamation, faUserGroup, faFileCirclePlus, faShieldHalved, faRightFromBracket, faGlobe`
  from `@fortawesome/free-solid-svg-icons`.
- Replace each nav `<span aria-hidden="true">emoji</span>` with `<Icon icon={…} />`.
- Replace the language `<select>` + globe span:

```tsx
<div style={styles.langSelectorWrapper}>
  <Icon icon={faGlobe} style={{ color: '#38bdf8', fontSize: '12px' }} />
  <Select
    value={language}
    onChange={(v) => setLanguage(v as Language)}
    options={[
      { value: 'en', label: 'EN' },
      { value: 'es', label: 'ES' },
      { value: 'it', label: 'IT' },
    ]}
    aria-label={t('common.selectLanguage')}
    style={styles.langSelectTrigger}
  />
</div>
```

Add `langSelectTrigger` style overriding the trigger for the dark sidebar (`backgroundColor: 'transparent', color: '#38bdf8', border: 'none', fontSize: '12px', fontWeight: '700', padding: '0', width: 'auto'`). Remove the old `langSelect`/`langIcon` styles.

- [ ] **Step 3: Migrate CreateCasePage patient picker to Select inside FormField**

```tsx
<FormField
  label={t('createCase.selectPatient')}
  invalid={missing.includes('patient-select')}
  error={error || undefined}
>
  {(control) => (
    <Select
      {...control}
      value={patientId}
      onChange={setPatientId}
      placeholder={t('createCase.selectPatientPlaceholder')}
      disabled={loadingPatients}
      options={patients.map((p) => ({ value: p.id, label: p.full_name }))}
    />
  )}
</FormField>
```

Delete the old `<select>` + `<option value="">` block. The surgery-type input migrates to FormField the same way as Task 2 (keep `missing.includes('surgery-type')`). Delete the standalone error `<p>`.

- [ ] **Step 4: Build**

Run: `cd web && npm run build` — Expected: passes.

- [ ] **Step 5: Commit**

```bash
git add web/src/components/ui web/src/components/NavBar.tsx web/src/pages/CreateCasePage.tsx
git commit -m "feat(web): Select wrapper; migrate navbar icons/language and case-creation patient picker"
```

---

### Task 4: NumberField (Base UI) + MedicationsPage migration

**Files:**
- Create: `web/src/components/ui/NumberField.tsx`
- Modify: `web/src/components/ui/index.ts`
- Modify: `web/src/pages/MedicationsPage.tsx`

**Interfaces:**
- Produces:
  ```tsx
  NumberField({
    value: number | null,
    onChange: (value: number | null) => void,
    min?: number,          // default 1
    placeholder?: string,
    id?: string,
    'aria-invalid'?: boolean,
    'aria-describedby'?: string,
  })
  ```
- Consumes: `Icon`, `Select`, `FormField` (Tasks 1–3).

- [ ] **Step 1: Create `web/src/components/ui/NumberField.tsx`**

```tsx
import { NumberField as BaseNumberField } from '@base-ui-components/react/number-field'
import { faMinus, faPlus } from '@fortawesome/free-solid-svg-icons'
import { Icon } from './Icon'

type NumberFieldProps = {
  value: number | null
  onChange: (value: number | null) => void
  min?: number
  placeholder?: string
  id?: string
  'aria-invalid'?: boolean
  'aria-describedby'?: string
}

export function NumberField({
  value,
  onChange,
  min = 1,
  placeholder,
  id,
  ...aria
}: NumberFieldProps) {
  return (
    <BaseNumberField.Root
      value={value}
      onValueChange={(v) => onChange(v)}
      min={min}
    >
      <BaseNumberField.Group style={styles.group}>
        <BaseNumberField.Decrement style={styles.stepButton} aria-label="Decrease">
          <Icon icon={faMinus} />
        </BaseNumberField.Decrement>
        <BaseNumberField.Input
          id={id}
          style={styles.input}
          placeholder={placeholder}
          {...aria}
        />
        <BaseNumberField.Increment style={styles.stepButton} aria-label="Increase">
          <Icon icon={faPlus} />
        </BaseNumberField.Increment>
      </BaseNumberField.Group>
    </BaseNumberField.Root>
  )
}

const styles = {
  group: {
    display: 'flex',
    alignItems: 'stretch',
    border: '1px solid #e5e7eb',
    borderRadius: '8px',
    overflow: 'hidden',
    backgroundColor: '#ffffff',
  },
  input: {
    flex: 1,
    padding: '10px 12px',
    border: 'none',
    fontSize: '15px',
    textAlign: 'center' as const,
    outline: 'none',
  },
  stepButton: {
    padding: '0 14px',
    backgroundColor: '#f8fafc',
    border: 'none',
    color: '#475569',
    cursor: 'pointer',
    fontSize: '12px',
  },
}
```

Add `export { NumberField } from './NumberField'` to the barrel.

- [ ] **Step 2: Migrate MedicationsPage**

- `durationDays` state changes from `string` to `number | null` (initial `null`).
- Validation: `if (durationDays === null || durationDays < 1) missingFields.push('duration-days')`; submit body uses `duration: ${durationDays} days`.
- Duration input becomes:

```tsx
<FormField
  label={t('medication.durationDays')}
  invalid={missing.includes('duration-days')}
>
  {(control) => (
    <NumberField
      {...control}
      value={durationDays}
      onChange={setDurationDays}
      placeholder={t('medication.durationPlaceholder')}
    />
  )}
</FormField>
```

- Frequency `<select>` becomes `Select` inside FormField (same pattern as Task 3 Step 3), options from the five `medication.frequency*` keys.
- Drug name, dose, notes migrate to FormField (pattern from Task 2). The drug-name row keeps the inline FDA button next to the input (FormField wraps just the input; the flex row stays).
- Delete the standalone error `<p>` and old `<label>` elements. Keep reminder-times hint — it becomes the `hint` prop on the frequency FormField.

- [ ] **Step 3: Build**

Run: `cd web && npm run build` — Expected: passes.

- [ ] **Step 4: Commit**

```bash
git add web/src/components/ui web/src/pages/MedicationsPage.tsx
git commit -m "feat(web): Base UI NumberField for duration; migrate prescribe form to wrappers"
```

---

### Task 5: Dialog, RadioGroup, Tabs, Tooltip + TriageDashboardPage migration

**Files:**
- Create: `web/src/components/ui/Dialog.tsx`
- Create: `web/src/components/ui/RadioGroup.tsx`
- Create: `web/src/components/ui/Tabs.tsx`
- Create: `web/src/components/ui/Tooltip.tsx`
- Modify: `web/src/components/ui/index.ts`
- Modify: `web/src/pages/TriageDashboardPage.tsx`

**Interfaces:**
- Produces:
  ```tsx
  Dialog({ open: boolean, onClose: () => void, title: string,
           description?: string, closeLabel: string, children: ReactNode })
  RadioGroup({ value: string, onChange: (v: string) => void,
               options: { value: string; label: string }[], name: string })
  Tabs({ value: string, onChange: (v: string) => void,
         items: { value: string; label: ReactNode }[] })
  Tooltip({ content: string, children: ReactNode })
  ```
- Consumes: `Icon`, `useToast` (Task 1). Triage page drops its local toast state + toast styles and its manual Escape `useEffect` (Dialog provides Escape + focus trap).

- [ ] **Step 1: Create `web/src/components/ui/Dialog.tsx`**

```tsx
import * as RadixDialog from '@radix-ui/react-dialog'
import type { ReactNode } from 'react'
import { faXmark } from '@fortawesome/free-solid-svg-icons'
import { Icon } from './Icon'

type DialogProps = {
  open: boolean
  onClose: () => void
  title: string
  description?: string
  closeLabel: string
  children: ReactNode
}

export function Dialog({ open, onClose, title, description, closeLabel, children }: DialogProps) {
  return (
    <RadixDialog.Root open={open} onOpenChange={(o) => !o && onClose()}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay style={styles.overlay} />
        <RadixDialog.Content
          style={styles.content}
          aria-describedby={description ? undefined : undefined}
        >
          <div style={styles.header}>
            <div>
              <RadixDialog.Title style={styles.title}>{title}</RadixDialog.Title>
              {description && (
                <RadixDialog.Description style={styles.description}>
                  {description}
                </RadixDialog.Description>
              )}
            </div>
            <RadixDialog.Close style={styles.closeButton} aria-label={closeLabel}>
              <Icon icon={faXmark} />
            </RadixDialog.Close>
          </div>
          {children}
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  )
}

const styles = {
  overlay: {
    position: 'fixed' as const,
    inset: 0,
    backgroundColor: 'rgba(15, 23, 42, 0.6)',
    zIndex: 1000,
  },
  content: {
    position: 'fixed' as const,
    top: '50%',
    left: '50%',
    transform: 'translate(-50%, -50%)',
    backgroundColor: '#ffffff',
    borderRadius: '12px',
    width: '100%',
    maxWidth: '520px',
    padding: '24px',
    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
    border: '1px solid #e2e8f0',
    zIndex: 1001,
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: '16px',
  },
  title: { fontSize: '18px', fontWeight: '700' as const, color: '#0f172a', margin: 0 },
  description: { fontSize: '13px', color: '#64748b', marginTop: '4px' },
  closeButton: {
    background: 'transparent',
    border: 'none',
    fontSize: '16px',
    color: '#94a3b8',
    cursor: 'pointer',
    padding: 0,
    lineHeight: 1,
  },
}
```

- [ ] **Step 2: Create `web/src/components/ui/RadioGroup.tsx`**

```tsx
import * as RadixRadio from '@radix-ui/react-radio-group'

type RadioGroupProps = {
  value: string
  onChange: (value: string) => void
  options: { value: string; label: string }[]
  name: string
}

export function RadioGroup({ value, onChange, options, name }: RadioGroupProps) {
  return (
    <RadixRadio.Root
      value={value}
      onValueChange={onChange}
      name={name}
      style={styles.group}
    >
      {options.map((opt) => (
        <label key={opt.value} style={styles.option}>
          <RadixRadio.Item value={opt.value} style={styles.item}>
            <RadixRadio.Indicator style={styles.indicator} />
          </RadixRadio.Item>
          <span>{opt.label}</span>
        </label>
      ))}
    </RadixRadio.Root>
  )
}

const styles = {
  group: { display: 'flex', gap: '16px', flexWrap: 'wrap' as const },
  option: {
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    fontSize: '13px',
    color: '#0f172a',
    cursor: 'pointer',
  },
  item: {
    width: '16px',
    height: '16px',
    borderRadius: '50%',
    border: '2px solid #94a3b8',
    backgroundColor: '#ffffff',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'pointer',
    padding: 0,
  },
  indicator: {
    width: '8px',
    height: '8px',
    borderRadius: '50%',
    backgroundColor: '#0284c7',
    display: 'block',
  },
}
```

- [ ] **Step 3: Create `web/src/components/ui/Tabs.tsx`**

```tsx
import * as RadixTabs from '@radix-ui/react-tabs'
import type { ReactNode } from 'react'

type TabsProps = {
  value: string
  onChange: (value: string) => void
  items: { value: string; label: ReactNode }[]
}

export function Tabs({ value, onChange, items }: TabsProps) {
  return (
    <RadixTabs.Root value={value} onValueChange={onChange}>
      <RadixTabs.List style={styles.list}>
        {items.map((item) => {
          const active = item.value === value
          return (
            <RadixTabs.Trigger
              key={item.value}
              value={item.value}
              style={{
                ...styles.trigger,
                ...(active ? styles.triggerActive : {}),
              }}
            >
              {item.label}
            </RadixTabs.Trigger>
          )
        })}
      </RadixTabs.List>
    </RadixTabs.Root>
  )
}

const styles = {
  list: { display: 'flex', gap: '8px', flexWrap: 'wrap' as const },
  trigger: {
    padding: '8px 14px',
    borderRadius: '8px',
    border: '1px solid #e2e8f0',
    backgroundColor: '#ffffff',
    color: '#0f172a',
    fontSize: '13px',
    fontWeight: '600' as const,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
  },
  triggerActive: {
    backgroundColor: '#0284c7',
    color: '#ffffff',
    borderColor: '#0284c7',
  },
}
```

Note: the triage page's per-tab active colors (red/amber) are applied by the page via the `label` ReactNode styling; the wrapper handles the base active state.

- [ ] **Step 4: Create `web/src/components/ui/Tooltip.tsx`**

```tsx
import * as RadixTooltip from '@radix-ui/react-tooltip'
import type { ReactNode } from 'react'

export function Tooltip({ content, children }: { content: string; children: ReactNode }) {
  return (
    <RadixTooltip.Provider>
      <RadixTooltip.Root>
        <RadixTooltip.Trigger asChild>{children}</RadixTooltip.Trigger>
        <RadixTooltip.Portal>
          <RadixTooltip.Content style={styles.content} sideOffset={4}>
            {content}
          </RadixTooltip.Content>
        </RadixTooltip.Portal>
      </RadixTooltip.Root>
    </RadixTooltip.Provider>
  )
}

const styles = {
  content: {
    backgroundColor: '#0f172a',
    color: '#ffffff',
    fontSize: '12px',
    padding: '6px 10px',
    borderRadius: '6px',
    maxWidth: '220px',
    zIndex: 1200,
  },
}
```

Disabled buttons cannot be tooltip triggers (no pointer events) — wrap them in a `<span>` (see Step 5).

- [ ] **Step 5: Add all four to the barrel**

```tsx
export { Dialog } from './Dialog'
export { RadioGroup } from './RadioGroup'
export { Tabs } from './Tabs'
export { Tooltip } from './Tooltip'
```

- [ ] **Step 6: Migrate TriageDashboardPage**

- **Toast:** delete local `toastMessage` state, its auto-hide `useEffect`, the toast JSX block, and `toast*` styles. Add `const { show } = useToast()`; success calls `show(`${t('triage.resolvedToast')} — ${name}`)`.
- **Modal:** delete the modal overlay/container JSX, the manual Escape `useEffect`, and modal-related styles (`modalOverlay`, `modalContainer`, `modalHeader`, `modalCloseButton`). Render instead:

```tsx
<Dialog
  open={selectedPatientItem !== null}
  onClose={handleCloseResolutionModal}
  title={t('triage.resolveModalTitle')}
  description={selectedPatientItem?.patient.full_name}
  closeLabel={t('cta.close')}
>
  {/* existing modal body (context card, outreach RadioGroup, note fieldset,
      note textarea + error) and footer buttons, unchanged */}
</Dialog>
```

The outreach `<fieldset>`/radios become `<RadioGroup name="outreachMethod" value={outreachMethod} onChange={(v) => setOutreachMethod(v as OutreachMethod)} options={[...]} />`. The note textarea keeps its `htmlFor` label, `aria-invalid`, `aria-describedby`, and `role="alert"` error.
- **Filter tabs:** the three buttons become `<Tabs value={activeTab} onChange={(v) => setActiveTab(v as FilterTab)} items={[...]} />` with labels containing the FA icon + text + count badge. Delete `tabButton`/`activeTabButton`/`activeRedTabButton`/`activeAmberTabButton` styles.
- **Disabled Call button:** wrap in Tooltip:

```tsx
<Tooltip content={t('triage.noPhone')}>
  <span>
    <button style={{ ...styles.callButton, opacity: 0.5, cursor: 'not-allowed' }} disabled>
      <Icon icon={faPhone} /> {t('triage.callPatient')}
    </button>
  </span>
</Tooltip>
```

- **Icons:** replace every emoji span with `Icon`: `faMagnifyingGlass` (search), `faRotate` (refresh), `faFileCsv`, `faFilePdf`, `faCircleCheck` (resolve + stable + empty state), `faPhone`, `faClipboardList` (review), `faCircleExclamation` (red), `faTriangleExclamation` (amber). The 🚨/⚪/🟢 section headers get `faTriangleExclamation` / none (plain text) / `faCircleCheck` respectively.
- Keep all logic unchanged: fetchTriageData, suppression, sessionStorage viewed events, response stats widget, 10-char note validation.

- [ ] **Step 7: Build**

Run: `cd web && npm run build` — Expected: passes.

- [ ] **Step 8: Commit**

```bash
git add web/src/components/ui web/src/pages/TriageDashboardPage.tsx
git commit -m "feat(web): migrate triage dashboard to Radix Dialog/Tabs/RadioGroup/Tooltip/Toast"
```

---

### Task 6: Icon sweep on remaining pages + export error toasts

**Files:**
- Modify: `web/src/utils/exportUtils.ts`
- Modify: `web/src/pages/PatientsPage.tsx`
- Modify: `web/src/pages/MedicationsListPage.tsx`
- Modify: `web/src/pages/RecommendationsPage.tsx`
- Modify: `web/src/pages/RecommendationsListPage.tsx`
- Modify: `web/src/pages/FDAPage.tsx`
- Modify: `web/src/pages/CaseDetailPage.tsx`

**Interfaces:**
- Consumes: `Icon`, `useToast` (Task 1).
- Produces: `exportPatientAdherenceCSV` / `printPatientClinicalPDF` now **throw** on failure instead of `alert()` — every caller must catch and toast (done in this task).

- [ ] **Step 1: exportUtils throws instead of alert**

In `web/src/utils/exportUtils.ts`, in both `exportPatientAdherenceCSV` and `printPatientClinicalPDF`, replace the `catch` blocks that call `alert(...)` with:

```tsx
} catch (err) {
  throw err instanceof Error ? err : new Error('Clinical data could not be loaded.')
}
```

In `printPatientClinicalPDF`, replace the popup-blocked `alert(...)` + `return` with:

```tsx
if (!printWindow) {
  throw new Error('Popup window was blocked by the browser. Please allow popups to print.')
}
```

- [ ] **Step 2: Update export callers to toast on failure**

In `PatientsPage.tsx` and `TriageDashboardPage.tsx`, add `const { show } = useToast()` and wrap each export call:

```tsx
const handleExport = async (fn: () => Promise<void>) => {
  try {
    await fn()
  } catch (err) {
    show(err instanceof Error ? err.message : t('common.error'))
  }
}
```

Buttons call `onClick={() => handleExport(() => exportPatientAdherenceCSV(patient.id))}` (and the PDF equivalent).

- [ ] **Step 3: FA icon sweep — PatientsPage, MedicationsListPage, RecommendationsListPage, FDAPage, CaseDetailPage**

Replace every `<span aria-hidden="true">emoji</span>` with `Icon`:
- Export/print buttons: `faFileCsv` / `faFilePdf`
- CaseDetailPage: `faPhone` (emergency contact), `faArrowLeft` (back link)
- FDAPage: `faMagnifyingGlass` (loading state), `faPills` (empty state), remove `faRobot`-free 🤖 none present
- RecommendationsPage: `faRobot` (AI toggle button + chat header)

No layout or copy changes.

- [ ] **Step 4: RecommendationsPage AI toggle keeps aria wiring**

The 🤖 toggle becomes `<Icon icon={faRobot} />` inside the same button, keeping the existing `title`, `aria-label`, and `aria-expanded` attributes unchanged.

- [ ] **Step 5: Build**

Run: `cd web && npm run build` — Expected: passes. Also run `grep -rn "📥\|📄\|🤖\|📞\|🔍\|💊\|⏰\|🚨\|⚠️\|🛑\|🟢\|✅\|🌐\|🚪\|🩺\|📋\|🛡️" web/src --include="*.tsx"` — Expected: no matches (emoji fully replaced).

- [ ] **Step 6: Commit**

```bash
git add web/src/utils/exportUtils.ts web/src/pages
git commit -m "feat(web): replace remaining emoji with Font Awesome; export failures surface via toast"
```

---

### Task 7: Smoke verification + final report

**Files:** none (verification only).

- [ ] **Step 1: Full build**

Run: `cd web && npm run build` — Expected: passes clean.

- [ ] **Step 2: Boot the stack and walk the golden loop**

```bash
docker-compose up backend          # terminal 1
docker-compose exec backend python app/scripts/seed_data.py
cd web && npm run dev              # terminal 2
```

Manual checklist at `http://localhost:5173` (login: `clinician@example.com` / `password123`):
1. Login → lands on triage dashboard.
2. Triage: filter Tabs switch queues; language Select switches EN/ES/IT; refresh button works.
3. Resolution modal: opens with focus inside; Escape closes; <10-char note shows `role="alert"` error; successful resolve shows Toast and the alert stays gone after reload.
4. Disabled Call button shows Tooltip ("No phone number registered").
5. Patients: case name links to case detail; export CSV downloads; block popups once to see the PDF failure toast.
6. New Patient invite: per-field invalid states; Enter submits; copy code works.
7. New Case: patient Select works (including `?patient=` preselect); New Medication: frequency Select, duration NumberField enforces min 1 (try 0/−3).
8. FDA page: search, suggestion chips, source badge only when server provides it.
9. Keyboard-only pass: tab through nav → triage tabs → modal → close — visible focus ring everywhere.

- [ ] **Step 3: Report**

Report: what was verified, any smoke failures, and the standing known issues (eslint broken on TS 7, no vitest suite).

---

## Self-Review Notes

- Spec coverage: every spec section (wrappers, deps, icon map, page list, export-toast change, ToastProvider mount, axios removal) maps to a task. Icon map items not explicitly named in tasks are covered by the Task 6 grep gate.
- Type consistency: `FormField` control props, `Select` options shape, `useToast().show`, and export-function throw behavior are identical across all consuming tasks.
- No placeholders: every code step contains complete code; only trivially-repetitive per-field applications reference an earlier pattern with the exact pattern quoted.

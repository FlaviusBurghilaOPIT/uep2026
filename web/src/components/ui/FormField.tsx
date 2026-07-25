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

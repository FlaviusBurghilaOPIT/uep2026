import { NumberField as BaseNumberField } from '@base-ui/react/number-field'
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

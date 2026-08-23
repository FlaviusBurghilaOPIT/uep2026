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
  'aria-label'?: string
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
              <RadixSelect.Item
                key={opt.value}
                value={opt.value}
                className="ui-select-item"
                style={styles.item}
              >
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

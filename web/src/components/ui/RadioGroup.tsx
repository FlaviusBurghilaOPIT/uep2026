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

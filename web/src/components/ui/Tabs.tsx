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

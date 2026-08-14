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

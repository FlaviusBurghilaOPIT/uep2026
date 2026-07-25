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

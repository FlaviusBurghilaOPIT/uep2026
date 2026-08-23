import * as RadixToast from '@radix-ui/react-toast'
import { useCallback, useState, type ReactNode } from 'react'
import { faCircleCheck, faCircleExclamation, faXmark } from '@fortawesome/free-solid-svg-icons'
import { Icon } from './Icon'
import { useTranslation } from '../../i18n'
import { ToastContext, type ToastVariant } from './useToast'

export function ToastProvider({ children }: { children: ReactNode }) {
  const { t } = useTranslation()
  const [message, setMessage] = useState<string | null>(null)
  const [variant, setVariant] = useState<ToastVariant>('success')
  const show = useCallback((msg: string, v: ToastVariant = 'success') => {
    setVariant(v)
    setMessage(msg)
  }, [])

  return (
    <ToastContext.Provider value={{ show }}>
      <RadixToast.Provider swipeDirection="right" duration={4000}>
        {children}
        <RadixToast.Root
          open={message !== null}
          onOpenChange={(open) => !open && setMessage(null)}
          style={{ ...styles.root, backgroundColor: variantColors[variant] }}
        >
          <RadixToast.Description style={styles.description}>
            <Icon icon={variantIcons[variant]} style={{ marginRight: '8px' }} />
            {message}
          </RadixToast.Description>
          <RadixToast.Close style={styles.close} aria-label={t('cta.close')}>
            <Icon icon={faXmark} />
          </RadixToast.Close>
        </RadixToast.Root>
        <RadixToast.Viewport style={styles.viewport} />
      </RadixToast.Provider>
    </ToastContext.Provider>
  )
}

const variantColors: Record<ToastVariant, string> = {
  success: '#065f46',
  error: '#b91c1c',
}

const variantIcons: Record<ToastVariant, typeof faCircleCheck> = {
  success: faCircleCheck,
  error: faCircleExclamation,
}

const styles = {
  viewport: {
    position: 'fixed' as const,
    top: '20px',
    right: '20px',
    zIndex: 1100,
  },
  root: {
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

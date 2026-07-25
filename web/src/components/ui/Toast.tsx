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

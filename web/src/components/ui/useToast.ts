import { createContext, useContext } from 'react'

export type ToastVariant = 'success' | 'error'

export type ToastContextValue = { show: (message: string, variant?: ToastVariant) => void }

export const ToastContext = createContext<ToastContextValue>({ show: () => {} })

export const useToast = () => useContext(ToastContext)

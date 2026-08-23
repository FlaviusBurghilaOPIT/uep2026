import React, { useState, useCallback, useMemo } from 'react'
import type { Language } from './types'
import { translations } from './translations'
import { LanguageContext } from './context'
import { LANGUAGE_STORAGE_KEY, detectDefaultLanguage } from './detect'

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>(() => detectDefaultLanguage())

  const setLanguage = useCallback((lang: Language) => {
    setLanguageState(lang)
    localStorage.setItem(LANGUAGE_STORAGE_KEY, lang)
  }, [])

  const currentTranslations = useMemo(() => {
    return translations[language] || translations.en
  }, [language])

  const t = useCallback(
    (path: string, fallbackOrParams?: string | Record<string, string | number>, fallback?: string): string => {
      const params = typeof fallbackOrParams === 'object' ? fallbackOrParams : undefined
      const defaultFallback = typeof fallbackOrParams === 'string' ? fallbackOrParams : fallback

      const keys = path.split('.')
      let current: unknown = currentTranslations

      for (const key of keys) {
        if (current && typeof current === 'object' && key in current) {
          current = (current as Record<string, unknown>)[key]
        } else {
          let fallbackCurrent: unknown = translations.en
          for (const fk of keys) {
            if (fallbackCurrent && typeof fallbackCurrent === 'object' && fk in fallbackCurrent) {
              fallbackCurrent = (fallbackCurrent as Record<string, unknown>)[fk]
            } else {
              return defaultFallback || path
            }
          }
          current = fallbackCurrent
          break
        }
      }

      let result = typeof current === 'string' ? current : defaultFallback || path
      if (params) {
        for (const [pKey, pVal] of Object.entries(params)) {
          result = result.replace(new RegExp(`\\{${pKey}\\}`, 'g'), String(pVal))
        }
      }
      return result
    },
    [currentTranslations]
  )

  const contextValue = useMemo(
    () => ({
      language,
      setLanguage,
      t,
      translations: currentTranslations
    }),
    [language, setLanguage, t, currentTranslations]
  )

  return (
    <LanguageContext.Provider value={contextValue}>
      {children}
    </LanguageContext.Provider>
  )
}

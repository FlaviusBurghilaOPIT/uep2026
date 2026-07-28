import React, { useState } from 'react'
import type { Language } from './types'
import { translations } from './translations'
import { LanguageContext } from './context'
import { LANGUAGE_STORAGE_KEY, detectDefaultLanguage } from './detect'

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>(() => detectDefaultLanguage())

  const setLanguage = (lang: Language) => {
    setLanguageState(lang)
    localStorage.setItem(LANGUAGE_STORAGE_KEY, lang)
  }

  const currentTranslations = translations[language] || translations.en

  const t = (path: string, fallback?: string): string => {
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
            return fallback || path
          }
        }
        return typeof fallbackCurrent === 'string' ? fallbackCurrent : fallback || path
      }
    }

    return typeof current === 'string' ? current : fallback || path
  }

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t, translations: currentTranslations }}>
      {children}
    </LanguageContext.Provider>
  )
}

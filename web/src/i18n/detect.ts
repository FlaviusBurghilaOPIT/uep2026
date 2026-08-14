import type { Language } from './types'
import { translations } from './translations'

export const LANGUAGE_STORAGE_KEY = 'carepro_language'

function isLanguage(value: string | null | undefined): value is Language {
  return value === 'en' || value === 'es' || value === 'it'
}

/**
 * Language the app should default to before the user explicitly picks one:
 * stored choice → browser language → English.
 */
export function detectDefaultLanguage(): Language {
  if (typeof localStorage !== 'undefined') {
    const saved = localStorage.getItem(LANGUAGE_STORAGE_KEY)
    if (isLanguage(saved)) return saved
  }
  if (typeof navigator !== 'undefined') {
    const browser = (navigator.languages?.[0] ?? navigator.language ?? '').slice(0, 2).toLowerCase()
    if (isLanguage(browser)) return browser
  }
  return 'en'
}

/** Active language right now: the stored choice if present, otherwise the detected default. */
export function currentLanguage(): Language {
  if (typeof localStorage !== 'undefined') {
    const saved = localStorage.getItem(LANGUAGE_STORAGE_KEY)
    if (isLanguage(saved)) return saved
  }
  return detectDefaultLanguage()
}

function resolve(lang: Language, path: string, fallback?: string): string {
  const keys = path.split('.')
  const walk = (root: unknown): string | undefined => {
    let current: unknown = root
    for (const key of keys) {
      if (current && typeof current === 'object' && key in (current as Record<string, unknown>)) {
        current = (current as Record<string, unknown>)[key]
      } else {
        return undefined
      }
    }
    return typeof current === 'string' ? current : undefined
  }
  return walk(translations[lang]) ?? walk(translations.en) ?? fallback ?? path
}

/**
 * Non-hook translator for code that runs outside React components (e.g. the API
 * client). Mirrors the resolution logic of the LanguageProvider's `t`.
 */
export function translate(path: string, fallback?: string): string {
  return resolve(currentLanguage(), path, fallback)
}

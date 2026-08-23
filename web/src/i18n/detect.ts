import type { Language, Translations } from './types'
import { translations } from './translations'

export const LANGUAGE_STORAGE_KEY = 'carepro_language'
export const SUPPORTED_LANGUAGES: Language[] = ['en', 'es', 'it']

export function isLanguage(value: string | null | undefined): value is Language {
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
  if (typeof document !== 'undefined') {
    const match = document.cookie.match(new RegExp(`(?:^|; )${LANGUAGE_STORAGE_KEY}=([^;]*)`))
    if (match && isLanguage(match[1])) return match[1]
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

/**
 * Resolves a dot-notation key (e.g. 'landing.headline') in the specified language,
 * falling back to English and then to the provided fallback or path itself.
 * Supports placeholder interpolation: {count}, {name}, {email}, etc.
 */
export function resolve(
  lang: Language,
  path: string,
  paramsOrFallback?: Record<string, string | number> | string,
  fallback?: string
): string {
  let params: Record<string, string | number> | undefined
  let actualFallback = fallback

  if (typeof paramsOrFallback === 'string') {
    actualFallback = paramsOrFallback
  } else if (paramsOrFallback && typeof paramsOrFallback === 'object') {
    params = paramsOrFallback
  }

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

  let text = walk(translations[lang]) ?? walk(translations.en) ?? actualFallback ?? path

  if (params) {
    for (const [k, v] of Object.entries(params)) {
      text = text.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v))
    }
  }

  return text
}

/**
 * Creates a scoped translator `t(path, paramsOrFallback?, fallback?)` for a given language.
 */
export function createTranslator(lang: Language = currentLanguage()) {
  return (path: string, paramsOrFallback?: Record<string, string | number> | string, fallback?: string): string => {
    return resolve(lang, path, paramsOrFallback, fallback)
  }
}

/**
 * Universal translator using active language.
 */
export function translate(
  path: string,
  paramsOrFallback?: Record<string, string | number> | string,
  fallback?: string
): string {
  return resolve(currentLanguage(), path, paramsOrFallback, fallback)
}

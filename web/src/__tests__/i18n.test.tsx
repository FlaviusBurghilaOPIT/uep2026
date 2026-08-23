import { describe, it, expect, beforeEach } from 'vitest'
import { translate, detectDefaultLanguage, currentLanguage, LANGUAGE_STORAGE_KEY } from '../i18n'

describe('i18n pure TypeScript helpers', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('translate() returns the English headline by default', () => {
    const headline = translate('landing.headline')
    expect(headline).toContain('Close the Post-Op Recovery Gap with')
  })

  it('translate() falls back to English for unknown keys', () => {
    const result = translate('nonexistent.key.path')
    // Should return the path itself as fallback
    expect(result).toBe('nonexistent.key.path')
  })

  it('translate() respects a custom fallback string', () => {
    const result = translate('nonexistent.key', 'Custom Fallback')
    expect(result).toBe('Custom Fallback')
  })

  it('detectDefaultLanguage() returns "en" when localStorage is empty', () => {
    expect(detectDefaultLanguage()).toBe('en')
  })

  it('currentLanguage() returns stored language from localStorage', () => {
    localStorage.setItem(LANGUAGE_STORAGE_KEY, 'es')
    expect(currentLanguage()).toBe('es')
  })

  it('LANGUAGE_STORAGE_KEY matches the canonical key', () => {
    expect(LANGUAGE_STORAGE_KEY).toBe('carepro_language')
  })
})

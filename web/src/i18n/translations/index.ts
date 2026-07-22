import { en } from './en'
import { es } from './es'
import { it } from './it'
import type { Language, Translations } from '../types'

export const translations: Record<Language, Translations> = {
  en,
  es,
  it,
}

export { en, es, it }

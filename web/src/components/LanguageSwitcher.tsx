import { faGlobe } from '@fortawesome/free-solid-svg-icons'
import { useTranslation, type Language } from '../i18n'
import { Icon, Select } from './ui'

const FLAG_OPTIONS = [
  { value: 'en', label: '🇬🇧 EN' },
  { value: 'es', label: '🇪🇸 ES' },
  { value: 'it', label: '🇮🇹 IT' },
]

type LanguageSwitcherProps = {
  /** 'dark' for the sidebar, 'light' for pages such as the login screen. */
  variant?: 'dark' | 'light'
  showGlobe?: boolean
}

export function LanguageSwitcher({ variant = 'light', showGlobe = true }: LanguageSwitcherProps) {
  const { language, setLanguage, t } = useTranslation()
  const dark = variant === 'dark'

  return (
    <div style={dark ? styles.darkWrapper : styles.lightWrapper}>
      {showGlobe && (
        <Icon icon={faGlobe} style={{ color: dark ? '#38bdf8' : '#64748b', fontSize: '12px' }} />
      )}
      <Select
        value={language}
        onChange={(v) => setLanguage(v as Language)}
        options={FLAG_OPTIONS}
        aria-label={t('common.selectLanguage')}
        style={dark ? styles.darkTrigger : styles.lightTrigger}
      />
    </div>
  )
}

const styles = {
  darkWrapper: {
    display: 'flex',
    alignItems: 'center',
    gap: '4px',
    backgroundColor: '#1e293b',
    padding: '4px 6px',
    borderRadius: '6px',
    border: '1px solid #334155',
  },
  darkTrigger: {
    backgroundColor: 'transparent',
    color: '#38bdf8',
    border: 'none',
    fontSize: '12px',
    fontWeight: '700' as const,
    padding: '0',
    width: 'auto',
  },
  lightWrapper: {
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    backgroundColor: '#ffffff',
    padding: '4px 8px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
  },
  lightTrigger: {
    backgroundColor: 'transparent',
    color: '#374151',
    border: 'none',
    fontSize: '13px',
    fontWeight: '600' as const,
    padding: '0',
    width: 'auto',
  },
}

import { useTranslation, type Language } from '../i18n'

function NavBar() {
  const path = window.location.pathname
  const { language, setLanguage, t } = useTranslation()

  const linkStyle = (active: boolean) => ({
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '10px 16px',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '500' as const,
    color: active ? '#ffffff' : '#cbd5e1',
    backgroundColor: active ? '#0284c7' : 'transparent',
    textDecoration: 'none' as const,
    cursor: 'pointer'
  })

  return (
    <div style={styles.sidebar}>
      <div style={styles.brandHeader}>
        <div style={styles.brand}>
          <span style={styles.brandPlus}>+</span> CarePro
        </div>
        <div style={styles.langSelectorWrapper}>
          <span style={styles.langIcon}>🌐</span>
          <select
            value={language}
            onChange={(e) => setLanguage(e.target.value as Language)}
            style={styles.langSelect}
            aria-label="Select Language"
          >
            <option value="en">EN</option>
            <option value="es">ES</option>
            <option value="it">IT</option>
          </select>
        </div>
      </div>

      <div style={styles.nav}>
        <a href="/" style={linkStyle(path === '/' || path === '/triage')}>
          <span>🩺</span> {t('nav.triageDashboard')}
        </a>
        <a href="/patients" style={linkStyle(path === '/patients')}>
          <span>👤</span> {t('nav.patients')}
        </a>
        <a href="/cases/new" style={linkStyle(path === '/cases/new')}>
          <span>📋</span> {t('nav.newCase')}
        </a>
        <a href="/cases/case-001/medications/list" style={linkStyle(path.includes('medications'))}>
          <span>💊</span> {t('nav.medications')}
        </a>
        <a href="/cases/case-001/recommendations/list" style={linkStyle(path.includes('recommendations'))}>
          <span>📝</span> {t('nav.recommendations')}
        </a>
        <a href="/fda" style={linkStyle(path.includes('fda'))}>
          <span>⚕️</span> {t('nav.fdaSafety')}
        </a>
      </div>

      <div style={styles.bottom}>
        <div style={styles.divider} />
        <button
          style={styles.logout}
          onClick={() => {
            localStorage.removeItem('token')
            localStorage.removeItem('role')
            window.location.href = '/login'
          }}
        >
          <span>🚪</span> {t('nav.logout')}
        </button>
        <div style={styles.userCard}>
          <div style={styles.avatar}>DR</div>
          <div>
            <div style={styles.userName}>Dr. Clinician</div>
            <div style={styles.userRole}>Surgeon</div>
          </div>
        </div>
      </div>
    </div>
  )
}

const styles = {
  sidebar: {
    width: '220px',
    minHeight: '100vh',
    backgroundColor: '#0f172a',
    borderRight: '1px solid #1e293b',
    display: 'flex',
    flexDirection: 'column' as const,
    padding: '24px 16px',
    position: 'fixed' as const,
    top: 0,
    left: 0,
    zIndex: 100
  },
  brandHeader: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: '32px',
    paddingLeft: '4px',
    paddingRight: '4px'
  },
  brand: {
    fontSize: '20px',
    fontWeight: '700' as const,
    color: '#ffffff'
  },
  brandPlus: {
    color: '#38bdf8'
  },
  langSelectorWrapper: {
    display: 'flex',
    alignItems: 'center',
    gap: '4px',
    backgroundColor: '#1e293b',
    padding: '4px 6px',
    borderRadius: '6px',
    border: '1px solid #334155'
  },
  langIcon: {
    fontSize: '12px'
  },
  langSelect: {
    backgroundColor: 'transparent',
    color: '#38bdf8',
    border: 'none',
    fontSize: '12px',
    fontWeight: '700' as const,
    cursor: 'pointer',
    outline: 'none'
  },
  nav: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '4px',
    flex: 1
  },
  bottom: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px'
  },
  divider: {
    height: '1px',
    backgroundColor: '#1e293b',
    margin: '8px 0'
  },
  logout: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '10px 16px',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '500' as const,
    color: '#cbd5e1',
    backgroundColor: 'transparent',
    border: 'none',
    cursor: 'pointer',
    width: '100%',
    textAlign: 'left' as const
  },
  userCard: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '10px 8px',
    borderRadius: '8px',
    backgroundColor: '#1e293b'
  },
  avatar: {
    width: '36px',
    height: '36px',
    borderRadius: '50%',
    backgroundColor: '#0284c7',
    color: '#ffffff',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '12px',
    fontWeight: '600' as const,
    flexShrink: 0
  },
  userName: {
    fontSize: '13px',
    fontWeight: '500' as const,
    color: '#ffffff'
  },
  userRole: {
    fontSize: '11px',
    color: '#94a3b8'
  }
}

export default NavBar
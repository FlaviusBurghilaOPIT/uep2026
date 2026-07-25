import { NavLink, useNavigate } from 'react-router-dom'
import {
  faTriangleExclamation,
  faUserGroup,
  faFileCirclePlus,
  faShieldHalved,
  faRightFromBracket,
  faGlobe
} from '@fortawesome/free-solid-svg-icons'
import { useTranslation, type Language } from '../i18n'
import { Icon, Select } from './ui'

function NavBar() {
  const { language, setLanguage, t } = useTranslation()
  const navigate = useNavigate()

  const email = localStorage.getItem('email') || ''
  const initials = email ? email.slice(0, 2).toUpperCase() : '–'

  const linkStyle = ({ isActive }: { isActive: boolean }) => ({
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '10px 16px',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '500' as const,
    color: isActive ? '#ffffff' : '#cbd5e1',
    backgroundColor: isActive ? '#0284c7' : 'transparent',
    textDecoration: 'none' as const,
    cursor: 'pointer'
  })

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('role')
    localStorage.removeItem('email')
    navigate('/login')
  }

  return (
    <nav style={styles.sidebar} aria-label="Main navigation">
      <div style={styles.brandHeader}>
        <div style={styles.brand}>
          <span style={styles.brandPlus}>+</span> CarePro
        </div>
        <div style={styles.langSelectorWrapper}>
          <Icon icon={faGlobe} style={{ color: '#38bdf8', fontSize: '12px' }} />
          <Select
            value={language}
            onChange={(v) => setLanguage(v as Language)}
            options={[
              { value: 'en', label: 'EN' },
              { value: 'es', label: 'ES' },
              { value: 'it', label: 'IT' }
            ]}
            aria-label={t('common.selectLanguage')}
            style={styles.langSelectTrigger}
          />
        </div>
      </div>

      <ul style={styles.nav}>
        <li>
          <NavLink to="/" end style={linkStyle}>
            <Icon icon={faTriangleExclamation} /> {t('nav.triageDashboard')}
          </NavLink>
        </li>
        <li>
          <NavLink to="/patients" style={linkStyle}>
            <Icon icon={faUserGroup} /> {t('nav.patients')}
          </NavLink>
        </li>
        <li>
          <NavLink to="/cases/new" style={linkStyle}>
            <Icon icon={faFileCirclePlus} /> {t('nav.newCase')}
          </NavLink>
        </li>
        <li>
          <NavLink to="/fda" style={linkStyle}>
            <Icon icon={faShieldHalved} /> {t('nav.fdaSafety')}
          </NavLink>
        </li>
      </ul>

      <div style={styles.bottom}>
        <div style={styles.divider} />
        <button style={styles.logout} onClick={handleLogout}>
          <Icon icon={faRightFromBracket} /> {t('nav.logout')}
        </button>
        <div style={styles.userCard}>
          <div style={styles.avatar} aria-hidden="true">{initials}</div>
          <div>
            <div style={styles.userName}>{email}</div>
            <div style={styles.userRole}>{t('nav.clinicianRole')}</div>
          </div>
        </div>
      </div>
    </nav>
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
  langSelectTrigger: {
    backgroundColor: 'transparent',
    color: '#38bdf8',
    border: 'none',
    fontSize: '12px',
    fontWeight: '700' as const,
    padding: '0',
    width: 'auto'
  },
  nav: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '4px',
    flex: 1,
    listStyle: 'none' as const,
    margin: 0,
    padding: 0
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
    backgroundColor: '#1e293b',
    overflow: 'hidden'
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
    color: '#ffffff',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap' as const,
    maxWidth: '130px'
  },
  userRole: {
    fontSize: '11px',
    color: '#cbd5e1'
  }
}

export default NavBar

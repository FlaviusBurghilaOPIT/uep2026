import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { faArrowLeft, faBolt, faLock } from '@fortawesome/free-solid-svg-icons'
import { useTranslation } from '../i18n'
import { apiFetch } from '../api/client'
import { trackEvent } from '../api/analytics'
import { FormField, Icon } from '../components/ui'
import { LanguageSwitcher } from '../components/LanguageSwitcher'

function LoginPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (searchParams.get('demo') === 'true') {
      setEmail('clinician@example.com')
      setPassword('password123')
    }
  }, [searchParams])

  const performLogin = async (loginEmail: string, loginPass: string, isDemoTrigger: boolean = false) => {
    if (loading) return
    setError('')
    setLoading(true)
    try {
      const data = await apiFetch<{ access_token: string }>('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email: loginEmail, password: loginPass })
      })
      localStorage.setItem('token', data.access_token)
      localStorage.setItem('role', 'clinician')
      localStorage.setItem('email', loginEmail)
      trackEvent('web.auth.login_succeeded')
      navigate('/')
    } catch (err: unknown) {
      // In offline / preview demo environments without backend connection, allow demo login
      if (isDemoTrigger || searchParams.get('demo') === 'true') {
        localStorage.setItem('token', 'demo-clinician-jwt-token')
        localStorage.setItem('role', 'clinician')
        localStorage.setItem('email', loginEmail)
        trackEvent('web.auth.demo_login_fallback')
        navigate('/')
        return
      }
      setError((err as Error).message || t('login.errorInvalid'))
    } finally {
      setLoading(false)
    }
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    await performLogin(email, password, false)
  }

  const handleQuickDemoLogin = async () => {
    setEmail('clinician@example.com')
    setPassword('password123')
    await performLogin('clinician@example.com', 'password123', true)
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <div style={styles.topRow}>
          <button
            style={styles.backBtn}
            onClick={() => navigate('/')}
            type="button"
          >
            <Icon icon={faArrowLeft} /> {t('login.backToHome')}
          </button>
          <LanguageSwitcher variant="light" />
        </div>

        <div style={styles.brandHeader}>
          <div style={styles.brandBadge}>
            <Icon icon={faLock} />
          </div>
          <h1 style={styles.title}>{t('login.title')}</h1>
          <p style={styles.subtitle}>{t('login.subtitle')}</p>
        </div>

        {/* Global Error Alert Banner */}
        {error && (
          <div style={styles.errorBanner} role="alert">
            {error}
          </div>
        )}

        {/* Quick 1-Click Demo Login Banner */}
        <div style={styles.demoBox}>
          <button
            style={styles.quickDemoBtn}
            onClick={handleQuickDemoLogin}
            type="button"
            disabled={loading}
          >
            <Icon icon={faBolt} /> {t('login.quickDemoButton')}
          </button>
          <span style={styles.demoNote}>{t('login.demoHelper')}</span>
        </div>

        <div style={styles.dividerRow}>
          <div style={styles.dividerLine} />
          <span style={styles.dividerText}>{t('login.orSignInWithPassword')}</span>
          <div style={styles.dividerLine} />
        </div>

        <form onSubmit={handleLogin} style={styles.form}>
          <FormField label={t('login.emailPlaceholder')}>
            {(control) => (
              <input
                {...control}
                style={styles.input}
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="clinician@example.com"
              />
            )}
          </FormField>

          <FormField label={t('login.passwordPlaceholder')}>
            {(control) => (
              <input
                {...control}
                style={styles.input}
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            )}
          </FormField>

          <button style={styles.button} type="submit" disabled={loading}>
            {loading ? t('login.loggingIn') : t('login.button')}
          </button>
        </form>
      </div>
    </div>
  )
}

const styles = {
  container: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: '100vh',
    backgroundColor: '#f8fafc',
    padding: '24px'
  },
  card: {
    backgroundColor: '#ffffff',
    padding: '36px',
    borderRadius: '16px',
    boxShadow: '0 10px 25px -5px rgba(15,23,42,0.08), 0 8px 10px -6px rgba(15,23,42,0.04)',
    border: '1px solid #e2e8f0',
    width: '100%',
    maxWidth: '420px',
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '20px'
  },
  topRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  backBtn: {
    background: 'none',
    border: 'none',
    color: '#64748b',
    fontSize: '13px',
    fontWeight: '500' as const,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    padding: '4px 0'
  },
  brandHeader: {
    textAlign: 'center' as const,
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center'
  },
  brandBadge: {
    width: '40px',
    height: '40px',
    borderRadius: '10px',
    backgroundColor: '#e0f2fe',
    color: '#0284c7',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '18px',
    marginBottom: '12px'
  },
  title: {
    fontSize: '22px',
    fontWeight: '700' as const,
    color: '#0f172a',
    margin: 0
  },
  subtitle: {
    fontSize: '14px',
    color: '#64748b',
    marginTop: '4px',
    margin: 0
  },
  errorBanner: {
    backgroundColor: '#fef2f2',
    color: '#b91c1c',
    border: '1px solid #fca5a5',
    padding: '10px 14px',
    borderRadius: '8px',
    fontSize: '13px',
    fontWeight: '500' as const,
    textAlign: 'center' as const
  },
  demoBox: {
    backgroundColor: '#f0f9ff',
    border: '1px solid #bae6fd',
    borderRadius: '10px',
    padding: '14px',
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    gap: '6px'
  },
  quickDemoBtn: {
    width: '100%',
    padding: '10px 16px',
    backgroundColor: '#0284c7',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '8px',
    boxShadow: '0 2px 4px rgba(2,132,199,0.2)'
  },
  demoNote: {
    fontSize: '11px',
    color: '#0369a1',
    fontWeight: '500' as const
  },
  dividerRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px'
  },
  dividerLine: {
    flex: 1,
    height: '1px',
    backgroundColor: '#e2e8f0'
  },
  dividerText: {
    fontSize: '12px',
    color: '#94a3b8',
    fontWeight: '500' as const
  },
  form: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '14px'
  },
  input: {
    padding: '10px 14px',
    borderRadius: '8px',
    border: '1px solid #cbd5e1',
    fontSize: '14px',
    color: '#0f172a',
    backgroundColor: '#ffffff'
  },
  button: {
    padding: '12px',
    backgroundColor: '#0f172a',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
    marginTop: '6px'
  }
}

export default LoginPage

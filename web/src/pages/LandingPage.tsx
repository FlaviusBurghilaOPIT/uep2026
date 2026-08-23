import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  faShieldHalved,
  faTriangleExclamation,
  faCircleCheck,
  faArrowRight,
  faCheck,
  faXmark,
  faHeartPulse,
  faPills,
  faPhone,
  faLock,
  faClock
} from '@fortawesome/free-solid-svg-icons'
import { useTranslation } from '../i18n'
import { Icon } from '../components/ui'
import { LanguageSwitcher } from '../components/LanguageSwitcher'
import { trackEvent } from '../api/analytics'

export function LandingPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [demoResolved, setDemoResolved] = useState(false)
  const [resolving, setResolving] = useState(false)
  const resolveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    return () => {
      if (resolveTimerRef.current) {
        clearTimeout(resolveTimerRef.current)
      }
    }
  }, [])

  const handleLaunchDemo = () => {
    trackEvent('web.landing.launch_demo_clicked')
    navigate('/login?demo=true')
  }

  const handleSimulateResolve = () => {
    if (resolving || demoResolved) return
    setResolving(true)
    resolveTimerRef.current = setTimeout(() => {
      setDemoResolved(true)
      setResolving(false)
      trackEvent('web.landing.simulate_resolve_clicked')
    }, 600)
  }

  return (
    <div style={styles.page}>
      {/* Sticky Header */}
      <header style={styles.header}>
        <div style={styles.headerInner}>
          <div style={styles.brandGroup}>
            <span style={styles.brandPlus}>+</span>
            <span style={styles.brandName}>RemoteCare Pro</span>
          </div>

          <div style={styles.headerRight}>
            <LanguageSwitcher variant="light" />
            <button
              style={styles.headerLoginBtn}
              onClick={() => navigate('/login')}
              type="button"
            >
              <Icon icon={faLock} /> {t('landing.loginLink')}
            </button>
            <button
              style={styles.headerCtaBtn}
              onClick={handleLaunchDemo}
              type="button"
            >
              {t('landing.launchDemo')}
            </button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section style={styles.heroSection} aria-labelledby="hero-title">
        <div style={styles.heroInner}>
          <div style={styles.badgePill}>
            <Icon icon={faShieldHalved} /> {t('landing.badge')}
          </div>

          <h1 id="hero-title" style={styles.heroTitle}>
            {t('landing.headline')}{' '}
            <span style={styles.heroHighlight}>{t('landing.headlineHighlight')}</span>
          </h1>

          <p style={styles.heroSubtitle}>{t('landing.subheadline')}</p>

          <div style={styles.heroCtaGroup}>
            <button
              style={styles.primaryCta}
              onClick={handleLaunchDemo}
              type="button"
            >
              {t('landing.launchDemo')}
            </button>
            <a
              href="#features"
              style={styles.secondaryCta}
            >
              {t('landing.exploreFeatures')}
            </a>
          </div>

          {/* Trust Badges Bar */}
          <div style={styles.trustBar}>
            <div style={styles.trustItem}>
              <Icon icon={faShieldHalved} />
              <span>{t('landing.trustTrack')}</span>
            </div>
            <div style={styles.trustDivider} />
            <div style={styles.trustItem}>
              <Icon icon={faLock} />
              <span>{t('landing.trustBedrock')}</span>
            </div>
            <div style={styles.trustDivider} />
            <div style={styles.trustItem}>
              <Icon icon={faPills} />
              <span>{t('landing.trustFda')}</span>
            </div>
          </div>
        </div>
      </section>

      {/* Interactive Live Triage Preview */}
      <section style={styles.previewSection} aria-labelledby="preview-title">
        <div style={styles.sectionHeader}>
          <div style={styles.sectionBadge}>
            <Icon icon={faHeartPulse} /> {t('landing.previewLiveBadge')}
          </div>
          <h2 id="preview-title" style={styles.sectionTitle}>{t('landing.previewTitle')}</h2>
          <p style={styles.sectionSubtitle}>{t('landing.previewSubtitle')}</p>
        </div>

        <div style={styles.previewCard}>
          <div style={styles.previewCardHeader}>
            <div style={styles.patientMeta}>
              <span style={styles.patientAvatar}>MR</span>
              <div>
                <h3 style={styles.patientName}>Maria Rossi, 62yo</h3>
                <span style={styles.patientSub}>Total Knee Arthroplasty • Post-Op Day 3</span>
              </div>
            </div>
            <div style={demoResolved ? styles.statusGreen : styles.statusRed}>
              <Icon icon={demoResolved ? faCircleCheck : faTriangleExclamation} />
              <span>{demoResolved ? t('landing.previewResolvedAlert') : t('landing.previewSimulateAlert')}</span>
            </div>
          </div>

          <div style={styles.previewDetails}>
            <div style={styles.telemetryBox}>
              <div style={styles.telemetryLabel}>
                <Icon icon={faPills} /> {t('landing.telemetryPrescribedLabel')}
              </div>
              <div style={styles.telemetryValue}>{t('landing.telemetryOxycodone')}</div>
            </div>
            <div style={styles.telemetryBox}>
              <div style={styles.telemetryLabel}>
                <Icon icon={faClock} /> {t('landing.telemetryAdherenceLabel')}
              </div>
              <div style={demoResolved ? styles.telemetryGood : styles.telemetryBad}>
                {demoResolved ? t('landing.telemetryGoodStatus') : t('landing.telemetryMissedMorning')}
              </div>
            </div>
          </div>

          <div style={styles.previewActionRow}>
            {!demoResolved ? (
              <button
                style={styles.previewActionBtn}
                onClick={handleSimulateResolve}
                disabled={resolving}
                type="button"
              >
                <Icon icon={faPhone} />
                {resolving ? t('landing.telemetryInitiatingOutreach') : t('landing.telemetrySimulateOutreach')}
              </button>
            ) : (
              <div style={styles.resolvedBanner}>
                <Icon icon={faCircleCheck} /> {t('landing.telemetryOutreachLogged')}
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Problem vs Solution (StoryBrand SB7) */}
      <section style={styles.problemSection} aria-labelledby="problem-title">
        <div style={styles.sectionHeader}>
          <h2 id="problem-title" style={styles.sectionTitle}>{t('landing.problemTitle')}</h2>
          <p style={styles.sectionSubtitle}>{t('landing.problemSubtitle')}</p>
        </div>

        <div style={styles.comparisonGrid}>
          {/* Traditional Card */}
          <div style={styles.comparisonCardDark}>
            <div style={styles.cardBadgeRed}>
              <Icon icon={faXmark} /> {t('landing.traditionalTitle')}
            </div>
            <h3 style={styles.compHeading}>{t('landing.traditionalDesc')}</h3>
            <ul style={styles.compList}>
              <li style={styles.compItem}>
                <span style={styles.bulletX}>✕</span>
                <span>{t('landing.traditional1')}</span>
              </li>
              <li style={styles.compItem}>
                <span style={styles.bulletX}>✕</span>
                <span>{t('landing.traditional2')}</span>
              </li>
              <li style={styles.compItem}>
                <span style={styles.bulletX}>✕</span>
                <span>{t('landing.traditional3')}</span>
              </li>
            </ul>
          </div>

          {/* RemoteCare Pro Card */}
          <div style={styles.comparisonCardLight}>
            <div style={styles.cardBadgeGreen}>
              <Icon icon={faCheck} /> {t('landing.platformTitle')}
            </div>
            <h3 style={styles.compHeadingBlue}>{t('landing.platformDesc')}</h3>
            <ul style={styles.compList}>
              <li style={styles.compItem}>
                <span style={styles.bulletCheck}>✓</span>
                <span>{t('landing.platform1')}</span>
              </li>
              <li style={styles.compItem}>
                <span style={styles.bulletCheck}>✓</span>
                <span>{t('landing.platform2')}</span>
              </li>
              <li style={styles.compItem}>
                <span style={styles.bulletCheck}>✓</span>
                <span>{t('landing.platform3')}</span>
              </li>
            </ul>
          </div>
        </div>
      </section>

      {/* 3 Core Differentiators Grid */}
      <section id="features" style={styles.featuresSection} aria-labelledby="features-title">
        <div style={styles.sectionHeader}>
          <h2 id="features-title" style={styles.sectionTitle}>{t('landing.featuresSectionHeading')}</h2>
          <p style={styles.sectionSubtitle}>{t('landing.featuresSectionSubheading')}</p>
        </div>

        <div style={styles.featuresGrid}>
          {/* Feature 1 */}
          <div style={styles.featureCard}>
            <div style={styles.featureBadge}>{t('landing.feature1Badge')}</div>
            <div style={styles.featureIcon}>
              <Icon icon={faPills} />
            </div>
            <h3 style={styles.featureTitle}>{t('landing.feature1Title')}</h3>
            <p style={styles.featureDesc}>{t('landing.feature1Desc')}</p>
          </div>

          {/* Feature 2 */}
          <div style={styles.featureCard}>
            <div style={styles.featureBadge}>{t('landing.feature2Badge')}</div>
            <div style={styles.featureIcon}>
              <Icon icon={faShieldHalved} />
            </div>
            <h3 style={styles.featureTitle}>{t('landing.feature2Title')}</h3>
            <p style={styles.featureDesc}>{t('landing.feature2Desc')}</p>
          </div>

          {/* Feature 3 */}
          <div style={styles.featureCard}>
            <div style={styles.featureBadge}>{t('landing.feature3Badge')}</div>
            <div style={styles.featureIcon}>
              <Icon icon={faHeartPulse} />
            </div>
            <h3 style={styles.featureTitle}>{t('landing.feature3Title')}</h3>
            <p style={styles.featureDesc}>{t('landing.feature3Desc')}</p>
          </div>
        </div>
      </section>

      {/* 3-Step Golden Loop Timeline */}
      <section style={styles.timelineSection} aria-labelledby="timeline-title">
        <div style={styles.sectionHeader}>
          <h2 id="timeline-title" style={styles.sectionTitle}>{t('landing.timelineTitle')}</h2>
          <p style={styles.sectionSubtitle}>{t('landing.problemSubtitle')}</p>
        </div>

        <div style={styles.timelineGrid}>
          <div style={styles.timelineCard}>
            <div style={styles.stepNumber}>{t('landing.step1Num')}</div>
            <h3 style={styles.stepTitle}>{t('landing.step1Title')}</h3>
            <p style={styles.stepDesc}>{t('landing.step1Desc')}</p>
          </div>

          <div style={styles.timelineCard}>
            <div style={styles.stepNumber}>{t('landing.step2Num')}</div>
            <h3 style={styles.stepTitle}>{t('landing.step2Title')}</h3>
            <p style={styles.stepDesc}>{t('landing.step2Desc')}</p>
          </div>

          <div style={styles.timelineCard}>
            <div style={styles.stepNumber}>{t('landing.step3Num')}</div>
            <h3 style={styles.stepTitle}>{t('landing.step3Title')}</h3>
            <p style={styles.stepDesc}>{t('landing.step3Desc')}</p>
          </div>
        </div>
      </section>

      {/* Conversion Banner */}
      <section style={styles.ctaBanner} aria-labelledby="cta-banner-title">
        <div style={styles.ctaBannerInner}>
          <h2 id="cta-banner-title" style={styles.ctaBannerTitle}>{t('landing.ctaBannerTitle')}</h2>
          <p style={styles.ctaBannerDesc}>{t('landing.ctaBannerDesc')}</p>
          <button
            style={styles.ctaBannerBtn}
            onClick={handleLaunchDemo}
            type="button"
          >
            {t('landing.ctaBannerButton')} <Icon icon={faArrowRight} />
          </button>
        </div>
      </section>

      {/* Footer */}
      <footer style={styles.footer}>
        <p style={styles.footerText}>{t('landing.footerText')}</p>
      </footer>
    </div>
  )
}

const styles = {
  page: {
    backgroundColor: '#f8fafc',
    minHeight: '100vh',
    color: '#0f172a',
    display: 'flex',
    flexDirection: 'column' as const
  },
  header: {
    position: 'sticky' as const,
    top: 0,
    zIndex: 100,
    backgroundColor: '#ffffff',
    borderBottom: '1px solid #e2e8f0',
    padding: '12px 24px',
    boxShadow: '0 1px 3px rgba(15,23,42,0.05)'
  },
  headerInner: {
    maxWidth: '1200px',
    margin: '0 auto',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  brandGroup: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px'
  },
  brandPlus: {
    color: '#0284c7',
    fontSize: '24px',
    fontWeight: '800' as const
  },
  brandName: {
    fontSize: '18px',
    fontWeight: '700' as const,
    color: '#0f172a'
  },
  headerRight: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px'
  },
  headerLoginBtn: {
    backgroundColor: 'transparent',
    color: '#334155',
    border: '1px solid #cbd5e1',
    borderRadius: '8px',
    padding: '8px 14px',
    fontSize: '14px',
    fontWeight: '500' as const,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    gap: '6px'
  },
  headerCtaBtn: {
    backgroundColor: '#0284c7',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    padding: '8px 16px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
    boxShadow: '0 2px 4px rgba(2,132,199,0.2)'
  },
  heroSection: {
    padding: '64px 24px 48px',
    backgroundColor: '#ffffff',
    borderBottom: '1px solid #e2e8f0',
    textAlign: 'center' as const
  },
  heroInner: {
    maxWidth: '860px',
    margin: '0 auto',
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center'
  },
  badgePill: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '8px',
    backgroundColor: '#e0f2fe',
    color: '#0369a1',
    padding: '6px 14px',
    borderRadius: '9999px',
    fontSize: '13px',
    fontWeight: '600' as const,
    marginBottom: '20px'
  },
  heroTitle: {
    fontSize: 'clamp(2rem, 3.5vw + 1rem, 3.25rem)',
    fontWeight: '800' as const,
    color: '#0f172a',
    lineHeight: 1.15,
    letterSpacing: '-0.025em',
    marginBottom: '20px'
  },
  heroHighlight: {
    color: '#0284c7'
  },
  heroSubtitle: {
    fontSize: '17px',
    color: '#475569',
    lineHeight: 1.6,
    maxWidth: '66ch',
    marginBottom: '32px'
  },
  heroCtaGroup: {
    display: 'flex',
    gap: '16px',
    flexWrap: 'wrap' as const,
    justifyContent: 'center',
    marginBottom: '40px'
  },
  primaryCta: {
    backgroundColor: '#0284c7',
    color: '#ffffff',
    padding: '14px 28px',
    borderRadius: '8px',
    fontSize: '16px',
    fontWeight: '600' as const,
    border: 'none',
    cursor: 'pointer',
    boxShadow: '0 4px 6px -1px rgba(2,132,199,0.3)',
    transition: 'all 0.15s ease'
  },
  secondaryCta: {
    backgroundColor: '#f1f5f9',
    color: '#334155',
    padding: '14px 24px',
    borderRadius: '8px',
    fontSize: '16px',
    fontWeight: '500' as const,
    textDecoration: 'none',
    border: '1px solid #cbd5e1',
    cursor: 'pointer'
  },
  trustBar: {
    display: 'flex',
    alignItems: 'center',
    gap: '24px',
    flexWrap: 'wrap' as const,
    justifyContent: 'center',
    paddingTop: '24px',
    borderTop: '1px solid #f1f5f9'
  },
  trustItem: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    fontSize: '13px',
    fontWeight: '500' as const,
    color: '#64748b'
  },
  trustDivider: {
    width: '4px',
    height: '4px',
    borderRadius: '50%',
    backgroundColor: '#cbd5e1'
  },
  previewSection: {
    padding: '48px 24px',
    maxWidth: '1000px',
    margin: '0 auto',
    width: '100%'
  },
  sectionHeader: {
    textAlign: 'center' as const,
    marginBottom: '36px'
  },
  sectionBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    backgroundColor: '#fef2f2',
    color: '#b91c1c',
    padding: '4px 10px',
    borderRadius: '9999px',
    fontSize: '12px',
    fontWeight: '600' as const,
    marginBottom: '10px'
  },
  sectionTitle: {
    fontSize: '28px',
    fontWeight: '700' as const,
    color: '#0f172a',
    letterSpacing: '-0.02em',
    marginBottom: '8px'
  },
  sectionSubtitle: {
    fontSize: '15px',
    color: '#64748b',
    maxWidth: '56ch',
    margin: '0 auto'
  },
  previewCard: {
    backgroundColor: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '12px',
    padding: '24px',
    boxShadow: '0 10px 15px -3px rgba(15,23,42,0.08)'
  },
  previewCardHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap' as const,
    gap: '12px',
    paddingBottom: '16px',
    borderBottom: '1px solid #f1f5f9'
  },
  patientMeta: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px'
  },
  patientAvatar: {
    width: '44px',
    height: '44px',
    borderRadius: '50%',
    backgroundColor: '#0284c7',
    color: '#ffffff',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontWeight: '700' as const,
    fontSize: '16px'
  },
  patientName: {
    fontSize: '17px',
    fontWeight: '600' as const,
    color: '#0f172a',
    margin: 0
  },
  patientSub: {
    fontSize: '13px',
    color: '#64748b'
  },
  statusRed: {
    backgroundColor: '#fef2f2',
    color: '#b91c1c',
    border: '1px solid #fca5a5',
    padding: '6px 12px',
    borderRadius: '8px',
    fontSize: '13px',
    fontWeight: '600' as const,
    display: 'flex',
    alignItems: 'center',
    gap: '6px'
  },
  statusGreen: {
    backgroundColor: '#f0fdf4',
    color: '#15803d',
    border: '1px solid #86efac',
    padding: '6px 12px',
    borderRadius: '8px',
    fontSize: '13px',
    fontWeight: '600' as const,
    display: 'flex',
    alignItems: 'center',
    gap: '6px'
  },
  previewDetails: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
    gap: '16px',
    margin: '20px 0'
  },
  telemetryBox: {
    backgroundColor: '#f8fafc',
    padding: '14px 16px',
    borderRadius: '8px',
    border: '1px solid #e2e8f0'
  },
  telemetryLabel: {
    fontSize: '12px',
    fontWeight: '600' as const,
    color: '#64748b',
    marginBottom: '6px',
    display: 'flex',
    alignItems: 'center',
    gap: '6px'
  },
  telemetryValue: {
    fontSize: '14px',
    fontWeight: '500' as const,
    color: '#0f172a'
  },
  telemetryBad: {
    fontSize: '14px',
    fontWeight: '600' as const,
    color: '#dc2626'
  },
  telemetryGood: {
    fontSize: '14px',
    fontWeight: '600' as const,
    color: '#16a34a'
  },
  previewActionRow: {
    paddingTop: '8px',
    display: 'flex',
    justifyContent: 'center'
  },
  previewActionBtn: {
    backgroundColor: '#0284c7',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    padding: '12px 20px',
    fontSize: '14px',
    fontWeight: '600' as const,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    boxShadow: '0 2px 4px rgba(2,132,199,0.2)'
  },
  resolvedBanner: {
    backgroundColor: '#f0fdf4',
    color: '#16a34a',
    padding: '12px 18px',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '500' as const,
    display: 'flex',
    alignItems: 'center',
    gap: '8px'
  },
  problemSection: {
    padding: '48px 24px',
    backgroundColor: '#ffffff',
    borderTop: '1px solid #e2e8f0',
    borderBottom: '1px solid #e2e8f0'
  },
  comparisonGrid: {
    maxWidth: '1000px',
    margin: '0 auto',
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
    gap: '24px'
  },
  comparisonCardDark: {
    backgroundColor: '#0f172a',
    color: '#ffffff',
    padding: '28px',
    borderRadius: '12px',
    border: '1px solid #1e293b'
  },
  comparisonCardLight: {
    backgroundColor: '#f8fafc',
    color: '#0f172a',
    padding: '28px',
    borderRadius: '12px',
    border: '2px solid #0284c7',
    boxShadow: '0 4px 6px -1px rgba(2,132,199,0.1)'
  },
  cardBadgeRed: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    backgroundColor: 'rgba(239, 68, 68, 0.2)',
    color: '#f87171',
    padding: '4px 10px',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '600' as const,
    marginBottom: '14px'
  },
  cardBadgeGreen: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    backgroundColor: '#e0f2fe',
    color: '#0284c7',
    padding: '4px 10px',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '600' as const,
    marginBottom: '14px'
  },
  compHeading: {
    fontSize: '18px',
    fontWeight: '700' as const,
    color: '#ffffff',
    marginBottom: '16px'
  },
  compHeadingBlue: {
    fontSize: '18px',
    fontWeight: '700' as const,
    color: '#0284c7',
    marginBottom: '16px'
  },
  compList: {
    listStyle: 'none' as const,
    padding: 0,
    margin: 0,
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px'
  },
  compItem: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: '10px',
    fontSize: '14px',
    lineHeight: 1.5
  },
  bulletX: {
    color: '#ef4444',
    fontWeight: '700' as const,
    flexShrink: 0
  },
  bulletCheck: {
    color: '#0284c7',
    fontWeight: '700' as const,
    flexShrink: 0
  },
  featuresSection: {
    padding: '56px 24px',
    maxWidth: '1100px',
    margin: '0 auto',
    width: '100%'
  },
  featuresGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
    gap: '24px'
  },
  featureCard: {
    backgroundColor: '#ffffff',
    padding: '28px',
    borderRadius: '12px',
    border: '1px solid #e2e8f0',
    boxShadow: '0 1px 3px rgba(15,23,42,0.05)',
    display: 'flex',
    flexDirection: 'column' as const
  },
  featureBadge: {
    alignSelf: 'flex-start',
    backgroundColor: '#f1f5f9',
    color: '#475569',
    padding: '3px 8px',
    borderRadius: '6px',
    fontSize: '11px',
    fontWeight: '600' as const,
    marginBottom: '16px'
  },
  featureIcon: {
    width: '40px',
    height: '40px',
    borderRadius: '8px',
    backgroundColor: '#e0f2fe',
    color: '#0284c7',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '18px',
    marginBottom: '16px'
  },
  featureTitle: {
    fontSize: '18px',
    fontWeight: '700' as const,
    color: '#0f172a',
    marginBottom: '8px'
  },
  featureDesc: {
    fontSize: '14px',
    color: '#64748b',
    lineHeight: 1.6
  },
  timelineSection: {
    padding: '56px 24px',
    backgroundColor: '#ffffff',
    borderTop: '1px solid #e2e8f0',
    borderBottom: '1px solid #e2e8f0'
  },
  timelineGrid: {
    maxWidth: '1000px',
    margin: '0 auto',
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
    gap: '24px'
  },
  timelineCard: {
    backgroundColor: '#f8fafc',
    padding: '24px',
    borderRadius: '12px',
    border: '1px solid #e2e8f0'
  },
  stepNumber: {
    fontSize: '28px',
    fontWeight: '800' as const,
    color: '#0284c7',
    marginBottom: '10px'
  },
  stepTitle: {
    fontSize: '16px',
    fontWeight: '700' as const,
    color: '#0f172a',
    marginBottom: '8px'
  },
  stepDesc: {
    fontSize: '13px',
    color: '#64748b',
    lineHeight: 1.5
  },
  ctaBanner: {
    padding: '56px 24px',
    backgroundColor: '#0f172a',
    color: '#ffffff',
    textAlign: 'center' as const
  },
  ctaBannerInner: {
    maxWidth: '700px',
    margin: '0 auto',
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center'
  },
  ctaBannerTitle: {
    fontSize: '28px',
    fontWeight: '700' as const,
    color: '#ffffff',
    marginBottom: '12px'
  },
  ctaBannerDesc: {
    fontSize: '15px',
    color: '#cbd5e1',
    marginBottom: '28px',
    lineHeight: 1.6
  },
  ctaBannerBtn: {
    backgroundColor: '#0284c7',
    color: '#ffffff',
    padding: '14px 28px',
    borderRadius: '8px',
    fontSize: '16px',
    fontWeight: '600' as const,
    border: 'none',
    cursor: 'pointer',
    display: 'inline-flex',
    alignItems: 'center',
    gap: '8px',
    boxShadow: '0 4px 10px rgba(2,132,199,0.4)'
  },
  footer: {
    padding: '24px',
    backgroundColor: '#0f172a',
    borderTop: '1px solid #1e293b',
    textAlign: 'center' as const
  },
  footerText: {
    fontSize: '12px',
    color: '#cbd5e1', // WCAG AAA compliant on #0f172a
    margin: 0
  }
}

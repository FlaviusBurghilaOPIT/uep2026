import { useCallback, useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { faArrowLeft, faPhone } from '@fortawesome/free-solid-svg-icons'
import { useTranslation } from '../i18n'
import { apiFetch } from '../api/client'
import { Icon } from '../components/ui'

type CaseInfo = {
  id: string
  patient_id: string
  surgery_type: string
  status: string
  emergency_contact_name?: string | null
  emergency_contact_phone?: string | null
  created_at: string
}

type PatientInfo = {
  id: string
  full_name: string
  date_of_birth?: string | null
  phone?: string | null
  status?: string | null
}

type Medication = {
  id: string
  name: string
  dose: string
  schedule_text?: string
  frequency?: string
  duration?: string
}

type Recommendation = {
  id: string
  content?: string
  text?: string
  created_at: string
}

type DoseLog = {
  id: string
  status: 'pending' | 'taken' | 'missed' | 'skipped'
  logged_at?: string | null
  medication_name?: string | null
  scheduled_time?: string | null
}

type Trend = {
  great: number
  ok: number
  not_great: number
  bad: number
}

function CaseDetailPage() {
  const { t, language } = useTranslation()
  const { caseId } = useParams<{ caseId: string }>()
  const navigate = useNavigate()

  const [caseInfo, setCaseInfo] = useState<CaseInfo | null>(null)
  const [patient, setPatient] = useState<PatientInfo | null>(null)
  const [medications, setMedications] = useState<Medication[] | null>(null)
  const [recommendations, setRecommendations] = useState<Recommendation[] | null>(null)
  const [doseLogs, setDoseLogs] = useState<DoseLog[] | null>(null)
  const [trend, setTrend] = useState<Trend | null>(null)
  const [loading, setLoading] = useState(true)
  const [fatalError, setFatalError] = useState(false)

  const fetchAll = useCallback(async () => {
    if (!caseId) return
    setLoading(true)
    setFatalError(false)
    try {
      // Case + patient are the identity of this page — if they fail, say so.
      const c = await apiFetch<CaseInfo>(`/cases/${caseId}`)
      setCaseInfo(c)
      const p = await apiFetch<PatientInfo>(`/patients/${c.patient_id}`)
      setPatient(p)

      // Sections settle independently: a failed section shows an honest
      // error in place, never fabricated data.
      const [meds, recs, logs, tr] = await Promise.allSettled([
        apiFetch<Medication[]>(`/cases/${caseId}/medications`),
        apiFetch<Recommendation[]>(`/cases/${caseId}/recommendations`),
        apiFetch<DoseLog[]>(`/adherence/patients/${c.patient_id}`),
        apiFetch<Trend>(`/symptoms/patients/${c.patient_id}/symptoms/trend?days=14`),
      ])
      setMedications(meds.status === 'fulfilled' ? meds.value : null)
      setRecommendations(recs.status === 'fulfilled' ? recs.value : null)
      setDoseLogs(logs.status === 'fulfilled' ? logs.value : null)
      setTrend(tr.status === 'fulfilled' ? tr.value : null)
    } catch (err) {
      console.error('Failed to load case detail', err)
      setFatalError(true)
    } finally {
      setLoading(false)
    }
  }, [caseId])

  useEffect(() => {
    fetchAll()
  }, [fetchAll])

  const formatTs = (ts?: string | null) =>
    ts
      ? // dateStyle/timeStyle cannot be combined with timeZoneName (throws in WebKit)
        new Date(ts).toLocaleString(language, {
          dateStyle: 'short',
          timeStyle: 'short',
        } as Intl.DateTimeFormatOptions)
      : '—'

  const statusLabel = (status: DoseLog['status']) =>
    ({
      taken: t('caseDetail.statusTaken'),
      missed: t('caseDetail.statusMissed'),
      skipped: t('caseDetail.statusSkipped'),
      pending: t('caseDetail.statusPending'),
    })[status]

  const statusBadgeStyle = (status: DoseLog['status']) =>
    ({
      taken: { backgroundColor: '#f0fdf4', color: '#166534' },
      missed: { backgroundColor: '#fef2f2', color: '#b91c1c' },
      skipped: { backgroundColor: '#fffbe6', color: '#b45309' },
      pending: { backgroundColor: '#f1f5f9', color: '#64748b' },
    })[status]

  const sortedLogs = doseLogs
    ? [...doseLogs].sort((a, b) => (b.scheduled_time || '').localeCompare(a.scheduled_time || ''))
    : []

  const completedLogs = (doseLogs || []).filter((l) => l.status !== 'pending')
  const takenCount = (doseLogs || []).filter((l) => l.status === 'taken').length
  const adherence =
    completedLogs.length > 0 ? Math.round((takenCount / completedLogs.length) * 100) : null

  const trendEntries: { key: keyof Trend; label: string; color: string }[] = [
    { key: 'great', label: t('caseDetail.feelingGreat'), color: '#16a34a' },
    { key: 'ok', label: t('caseDetail.feelingOk'), color: '#0284c7' },
    { key: 'not_great', label: t('caseDetail.feelingNotGreat'), color: '#d97706' },
    { key: 'bad', label: t('caseDetail.feelingBad'), color: '#b91c1c' },
  ]
  const trendMax = trend ? Math.max(1, trend.great, trend.ok, trend.not_great, trend.bad) : 1
  const trendTotal = trend ? trend.great + trend.ok + trend.not_great + trend.bad : 0

  if (loading) {
    return (
      <div style={styles.container}>
        <p style={styles.muted}>{t('common.loading')}</p>
      </div>
    )
  }

  if (fatalError || !caseInfo || !patient) {
    return (
      <div style={styles.container}>
        <div style={styles.errorBox} role="alert">
          <p style={styles.errorText}>{t('caseDetail.caseNotFound')}</p>
          <button style={styles.retryButton} onClick={fetchAll}>
            {t('common.retry')}
          </button>
          <button style={styles.backButton} onClick={() => navigate('/patients')}>
            {t('caseDetail.backToPatients')}
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <button style={styles.backLink} onClick={() => navigate('/patients')}>
        <Icon icon={faArrowLeft} /> {t('caseDetail.backToPatients')}
      </button>

      {/* Header card: patient identity + emergency contact */}
      <div style={styles.headerCard}>
        <div>
          <h1 style={styles.patientName}>{patient.full_name}</h1>
          <p style={styles.patientSub}>
            {t('triage.surgery')}: {caseInfo.surgery_type} &bull; {t('patients.dob')}:{' '}
            {patient.date_of_birth || 'N/A'}
          </p>
          <span
            style={{
              ...styles.statusPill,
              backgroundColor: caseInfo.status === 'open' ? '#f0fdf4' : '#f1f5f9',
              color: caseInfo.status === 'open' ? '#166534' : '#64748b',
            }}
          >
            {caseInfo.status}
          </span>
        </div>
        <div style={styles.emergencyBox}>
          <p style={styles.emergencyLabel}>{t('caseDetail.emergencyContact')}</p>
          <p style={styles.emergencyName}>{caseInfo.emergency_contact_name || '—'}</p>
          {caseInfo.emergency_contact_phone ? (
            <a href={`tel:${caseInfo.emergency_contact_phone}`} style={styles.telLink}>
              <Icon icon={faPhone} /> {caseInfo.emergency_contact_phone}
            </a>
          ) : (
            <p style={styles.muted}>{t('triage.noPhone')}</p>
          )}
        </div>
      </div>

      {/* Symptom trend */}
      <section style={styles.section} aria-labelledby="trend-heading">
        <h2 id="trend-heading" style={styles.sectionTitle}>
          {t('caseDetail.symptomTrend')}
        </h2>
        {trend === null ? (
          <p style={styles.sectionError} role="alert">{t('common.errorLoading')}</p>
        ) : trendTotal === 0 ? (
          <p style={styles.muted}>{t('caseDetail.noCheckins')}</p>
        ) : (
          <div style={styles.trendBars}>
            {trendEntries.map(({ key, label, color }) => (
              <div key={key} style={styles.trendRow}>
                <span style={styles.trendLabel}>{label}</span>
                <div style={styles.trendTrack}>
                  <div
                    style={{
                      ...styles.trendFill,
                      width: `${(trend[key] / trendMax) * 100}%`,
                      backgroundColor: color,
                    }}
                  />
                </div>
                <span style={styles.trendCount}>{trend[key]}</span>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Adherence timeline */}
      <section style={styles.section} aria-labelledby="adherence-heading">
        <div style={styles.sectionHeaderRow}>
          <h2 id="adherence-heading" style={styles.sectionTitle}>
            {t('caseDetail.adherenceTimeline')}
          </h2>
          {adherence !== null && (
            <span style={styles.adherenceSummary}>
              {t('triage.adherenceLabel')}: <strong>{adherence}%</strong>
            </span>
          )}
        </div>
        {doseLogs === null ? (
          <p style={styles.sectionError} role="alert">{t('common.errorLoading')}</p>
        ) : sortedLogs.length === 0 ? (
          <p style={styles.muted}>{t('caseDetail.noDoseLogs')}</p>
        ) : (
          <table style={styles.table}>
            <thead>
              <tr>
                <th scope="col" style={styles.th}>{t('caseDetail.colMedication')}</th>
                <th scope="col" style={styles.th}>{t('caseDetail.colScheduled')}</th>
                <th scope="col" style={styles.th}>{t('caseDetail.colStatus')}</th>
                <th scope="col" style={styles.th}>{t('caseDetail.colLogged')}</th>
              </tr>
            </thead>
            <tbody>
              {sortedLogs.map((log) => (
                <tr key={log.id}>
                  <td style={styles.td}>{log.medication_name || '—'}</td>
                  <td style={styles.td}>{formatTs(log.scheduled_time)}</td>
                  <td style={styles.td}>
                    <span style={{ ...styles.logBadge, ...statusBadgeStyle(log.status) }}>
                      {statusLabel(log.status)}
                    </span>
                  </td>
                  <td style={styles.td}>{log.logged_at ? formatTs(log.logged_at) : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {/* Prescriptions */}
      <section style={styles.section} aria-labelledby="meds-heading">
        <div style={styles.sectionHeaderRow}>
          <h2 id="meds-heading" style={styles.sectionTitle}>
            {t('caseDetail.prescriptions')} ({medications?.length ?? 0})
          </h2>
          <button
            style={styles.manageButton}
            onClick={() => navigate(`/cases/${caseId}/medications/list`)}
          >
            {t('caseDetail.manageMedications')} →
          </button>
        </div>
        {medications === null ? (
          <p style={styles.sectionError} role="alert">{t('common.errorLoading')}</p>
        ) : medications.length === 0 ? (
          <p style={styles.muted}>{t('medicationsList.empty')}</p>
        ) : (
          <div style={styles.cardGrid}>
            {medications.map((med) => (
              <div key={med.id} style={styles.miniCard}>
                <div style={styles.miniCardHeader}>
                  <span style={styles.miniCardTitle}>{med.name}</span>
                  <span style={styles.freqBadge}>{med.schedule_text || med.frequency || ''}</span>
                </div>
                <p style={styles.miniCardDetail}>
                  {t('medicationsList.dose')}: {med.dose}
                  {med.duration ? ` · ${t('medicationsList.duration')}: ${med.duration}` : ''}
                </p>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Recovery instructions */}
      <section style={styles.section} aria-labelledby="recs-heading">
        <div style={styles.sectionHeaderRow}>
          <h2 id="recs-heading" style={styles.sectionTitle}>
            {t('caseDetail.recoveryInstructions')} ({recommendations?.length ?? 0})
          </h2>
          <button
            style={styles.manageButton}
            onClick={() => navigate(`/cases/${caseId}/recommendations/list`)}
          >
            {t('caseDetail.manageRecommendations')} →
          </button>
        </div>
        {recommendations === null ? (
          <p style={styles.sectionError} role="alert">{t('common.errorLoading')}</p>
        ) : recommendations.length === 0 ? (
          <p style={styles.muted}>{t('recommendationsList.empty')}</p>
        ) : (
          <div style={styles.cardGrid}>
            {recommendations.map((rec) => (
              <div key={rec.id} style={styles.miniCard}>
                <p style={styles.recContent}>{rec.content || rec.text || ''}</p>
                <p style={styles.miniCardDetail}>
                  {t('recommendationsList.added')}: {formatTs(rec.created_at)}
                </p>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}

const styles = {
  container: {
    padding: '32px',
    backgroundColor: '#f8fafc',
    minHeight: '100vh',
  },
  backLink: {
    background: 'none',
    border: 'none',
    color: '#0284c7',
    fontSize: '14px',
    fontWeight: '500' as const,
    cursor: 'pointer',
    padding: 0,
    marginBottom: '16px',
  },
  headerCard: {
    backgroundColor: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '12px',
    padding: '24px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: '16px',
    flexWrap: 'wrap' as const,
    marginBottom: '24px',
  },
  patientName: {
    fontSize: '22px',
    fontWeight: '700' as const,
    color: '#0f172a',
    margin: '0 0 6px 0',
  },
  patientSub: {
    fontSize: '14px',
    color: '#475569',
    margin: '0 0 10px 0',
  },
  statusPill: {
    fontSize: '11px',
    padding: '2px 10px',
    borderRadius: '20px',
    fontWeight: '600' as const,
    textTransform: 'uppercase' as const,
  },
  emergencyBox: {
    backgroundColor: '#fef2f2',
    border: '1px solid #fecaca',
    borderRadius: '10px',
    padding: '14px 18px',
    minWidth: '220px',
  },
  emergencyLabel: {
    fontSize: '11px',
    fontWeight: '700' as const,
    color: '#b91c1c',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.05em',
    margin: '0 0 4px 0',
  },
  emergencyName: {
    fontSize: '14px',
    fontWeight: '600' as const,
    color: '#0f172a',
    margin: '0 0 6px 0',
  },
  telLink: {
    fontSize: '14px',
    color: '#b91c1c',
    fontWeight: '600' as const,
    textDecoration: 'none' as const,
  },
  section: {
    marginBottom: '28px',
  },
  sectionHeaderRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '12px',
    gap: '12px',
    flexWrap: 'wrap' as const,
  },
  sectionTitle: {
    fontSize: '17px',
    fontWeight: '600' as const,
    color: '#0f172a',
    margin: 0,
  },
  adherenceSummary: {
    fontSize: '14px',
    color: '#475569',
  },
  sectionError: {
    fontSize: '13px',
    color: '#b91c1c',
    backgroundColor: '#fef2f2',
    border: '1px solid #fecaca',
    borderRadius: '8px',
    padding: '10px 14px',
    margin: 0,
  },
  muted: {
    fontSize: '14px',
    color: '#64748b',
  },
  trendBars: {
    backgroundColor: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '12px',
    padding: '20px',
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '10px',
  },
  trendRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
  },
  trendLabel: {
    width: '90px',
    fontSize: '13px',
    color: '#475569',
    flexShrink: 0,
  },
  trendTrack: {
    flex: 1,
    height: '14px',
    backgroundColor: '#f1f5f9',
    borderRadius: '7px',
    overflow: 'hidden',
  },
  trendFill: {
    height: '100%',
    borderRadius: '7px',
    minWidth: '2px',
  },
  trendCount: {
    width: '28px',
    fontSize: '13px',
    fontWeight: '600' as const,
    color: '#0f172a',
    textAlign: 'right' as const,
    flexShrink: 0,
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse' as const,
    backgroundColor: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '12px',
    overflow: 'hidden',
    fontSize: '13px',
  },
  th: {
    textAlign: 'left' as const,
    padding: '10px 14px',
    backgroundColor: '#f1f5f9',
    color: '#334155',
    fontWeight: '600' as const,
    borderBottom: '1px solid #e2e8f0',
  },
  td: {
    padding: '10px 14px',
    borderBottom: '1px solid #f1f5f9',
    color: '#0f172a',
  },
  logBadge: {
    padding: '2px 8px',
    borderRadius: '12px',
    fontSize: '11px',
    fontWeight: '700' as const,
    textTransform: 'uppercase' as const,
  },
  cardGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
    gap: '12px',
  },
  miniCard: {
    backgroundColor: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '10px',
    padding: '14px 16px',
  },
  miniCardHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: '8px',
    marginBottom: '6px',
  },
  miniCardTitle: {
    fontSize: '14px',
    fontWeight: '600' as const,
    color: '#0f172a',
  },
  freqBadge: {
    backgroundColor: '#eff6ff',
    color: '#2563eb',
    padding: '2px 10px',
    borderRadius: '20px',
    fontSize: '11px',
    fontWeight: '500' as const,
  },
  miniCardDetail: {
    fontSize: '12px',
    color: '#64748b',
    margin: 0,
  },
  recContent: {
    fontSize: '13px',
    color: '#0f172a',
    margin: '0 0 8px 0',
    lineHeight: '1.5',
    whiteSpace: 'pre-wrap' as const,
  },
  manageButton: {
    background: 'none',
    border: 'none',
    color: '#0284c7',
    fontSize: '13px',
    fontWeight: '600' as const,
    cursor: 'pointer',
    padding: 0,
  },
  errorBox: {
    backgroundColor: '#fef2f2',
    border: '1px solid #fecaca',
    borderRadius: '12px',
    padding: '32px',
    textAlign: 'center' as const,
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px',
    alignItems: 'center',
  },
  errorText: {
    fontSize: '15px',
    color: '#b91c1c',
    margin: 0,
  },
  retryButton: {
    padding: '8px 20px',
    backgroundColor: '#b91c1c',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer',
  },
  backButton: {
    padding: '8px 20px',
    backgroundColor: '#ffffff',
    color: '#6b7280',
    border: '1px solid #e5e7eb',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer',
  },
}

export default CaseDetailPage

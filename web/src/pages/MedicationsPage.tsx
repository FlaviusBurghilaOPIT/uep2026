import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'
import { trackEvent } from '../api/analytics'
import { useTranslation } from '../i18n/useTranslation'

const FREQUENCY_TIMES: Record<string, string[]> = {
  QD:  ['08:00'],
  BID: ['08:00', '20:00'],
  TID: ['08:00', '13:00', '20:00'],
  QID: ['08:00', '12:00', '16:00', '20:00'],
  PRN: [],
}

type CaseInfo = {
  id: string
  surgery_type: string
}

function MedicationsPage() {
  const { caseId } = useParams<{ caseId: string }>()
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [caseInfo, setCaseInfo] = useState<CaseInfo | null>(null)
  const [name, setName] = useState('')
  const [dose, setDose] = useState('')
  const [frequency, setFrequency] = useState<'QD'|'BID'|'TID'|'QID'|'PRN'>('QD')
  const [durationDays, setDurationDays] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')
  const [missing, setMissing] = useState<string[]>([])

  useEffect(() => {
    if (!caseId) return
    apiFetch<CaseInfo>(`/cases/${caseId}`)
      .then(setCaseInfo)
      .catch(() => setCaseInfo(null))
  }, [caseId])

  const reminderTimes = FREQUENCY_TIMES[frequency] ?? []

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const missingFields: string[] = []
    if (!name.trim()) missingFields.push('drug-name')
    if (!dose.trim()) missingFields.push('dose')
    const days = parseInt(durationDays, 10)
    if (!durationDays || isNaN(days) || days < 1) missingFields.push('duration-days')
    setMissing(missingFields)
    if (missingFields.length > 0) {
      setError(t('medication.errorMissingFields'))
      return
    }

    setLoading(true)
    setError('')
    try {
      await apiFetch(`/cases/${caseId}/medications`, {
        method: 'POST',
        body: JSON.stringify({
          name: name.trim(),
          dose: dose.trim(),
          frequency,
          duration: `${days} days`,
          notes: notes.trim(),
        }),
      })
      setSuccess(true)
      if (caseId) trackEvent('web.medication.prescribed', { case_id: caseId })
    } catch (err: unknown) {
      setError((err as Error).message || t('medication.errorAddFailed'))
    } finally {
      setLoading(false)
    }
  }

  const openFDA = () => {
    // New tab so the in-progress prescription form is not lost
    window.open(`/fda?drug=${encodeURIComponent(name.trim().toLowerCase())}`, '_blank')
  }

  if (success) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>{t('medication.successTitle')}</h1>
          <p style={styles.subtitle}>{t('medication.successSubtitle')}</p>
          <button
            style={styles.button}
            onClick={() => navigate(`/cases/${caseId}/medications/list`)}
          >
            {t('medication.viewAll')}
          </button>
          <button
            style={styles.backButton}
            onClick={() => navigate('/patients')}
          >
            {t('medication.backToPatients')}
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>{t('medication.title')}</h1>
        {caseInfo && (
          <p style={styles.subtitle}>
            {t('medication.caseSubtitle').replace('{surgery}', caseInfo.surgery_type)}
          </p>
        )}

        <form onSubmit={handleSubmit} style={styles.form} noValidate>
          <label style={styles.label} htmlFor="drug-name">{t('medication.drugName')}</label>
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <input
              id="drug-name"
              style={{ ...styles.input, flex: 1 }}
              type="text"
              placeholder={t('medication.drugNamePlaceholder')}
              value={name}
              onChange={(e) => setName(e.target.value)}
              aria-invalid={missing.includes('drug-name')}
              aria-describedby={error ? 'form-error' : undefined}
            />
            {name.trim() && (
              <button type="button" style={styles.fdaWarningButton} onClick={openFDA}>
                {t('medication.viewFdaSafety')}
              </button>
            )}
          </div>

          <label style={styles.label} htmlFor="dose">{t('medication.dose')}</label>
          <input
            id="dose"
            style={styles.input}
            type="text"
            placeholder={t('medication.dosePlaceholder')}
            value={dose}
            onChange={(e) => setDose(e.target.value)}
            aria-invalid={missing.includes('dose')}
            aria-describedby={error ? 'form-error' : undefined}
          />

          <label style={styles.label} htmlFor="frequency">{t('medication.frequencyLabel')}</label>
          <select
            id="frequency"
            style={styles.input}
            value={frequency}
            onChange={(e) => setFrequency(e.target.value as 'QD'|'BID'|'TID'|'QID'|'PRN')}
            aria-describedby={error ? 'form-error' : 'frequency-hint'}
          >
            <option value="QD">{t('medication.frequencyQD')}</option>
            <option value="BID">{t('medication.frequencyBID')}</option>
            <option value="TID">{t('medication.frequencyTID')}</option>
            <option value="QID">{t('medication.frequencyQID')}</option>
            <option value="PRN">{t('medication.frequencyPRN')}</option>
          </select>
          <p id="frequency-hint" style={{ fontSize: '0.8rem', color: '#64748b', margin: '4px 0 12px' }}>
            {reminderTimes.length > 0
              ? `${t('medication.remindersAt')} ${reminderTimes.join(', ')}`
              : t('medication.noReminders')}
          </p>

          <label style={styles.label} htmlFor="duration-days">{t('medication.durationDays')}</label>
          <input
            id="duration-days"
            style={styles.input}
            type="number"
            min={1}
            placeholder={t('medication.durationPlaceholder')}
            value={durationDays}
            onChange={(e) => setDurationDays(e.target.value)}
            aria-invalid={missing.includes('duration-days')}
            aria-describedby={error ? 'form-error' : undefined}
          />

          <label style={styles.label} htmlFor="notes">{t('medication.notesOptional')}</label>
          <textarea
            id="notes"
            style={styles.textarea}
            placeholder={t('medication.notesPlaceholder')}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
          />

          {error && <p id="form-error" role="alert" style={styles.error}>{error}</p>}

          <button style={styles.button} type="submit" disabled={loading}>
            {loading ? t('medication.adding') : t('medication.addMedication')}
          </button>

          <button style={styles.backButton} type="button" onClick={() => navigate('/patients')}>
            {t('medication.cancel')}
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
    backgroundColor: '#f9fafb'
  },
  card: {
    backgroundColor: '#ffffff',
    padding: '40px',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
    width: '400px',
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '16px'
  },
  title: {
    fontSize: '22px',
    fontWeight: '600',
    color: '#111827',
    margin: 0
  },
  subtitle: {
    fontSize: '13px',
    color: '#6b7280',
    margin: 0
  },
  form: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '16px'
  },
  label: {
    fontSize: '13px',
    fontWeight: '500',
    color: '#111827',
    marginBottom: '-10px'
  },
  input: {
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px'
  },
  textarea: {
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    resize: 'vertical' as const,
    minHeight: '80px'
  },
  button: {
    padding: '10px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '15px',
    cursor: 'pointer'
  },
  backButton: {
    padding: '10px',
    backgroundColor: '#ffffff',
    color: '#6b7280',
    border: '1px solid #e5e7eb',
    borderRadius: '8px',
    fontSize: '15px',
    cursor: 'pointer'
  },
  fdaWarningButton: {
    padding: '8px 12px',
    backgroundColor: '#fffbe6',
    color: '#d97706',
    border: '1px solid #fde68a',
    borderRadius: '8px',
    fontSize: '13px',
    cursor: 'pointer',
    fontWeight: '500' as const,
    whiteSpace: 'nowrap' as const
  },
  error: {
    color: '#dc2626',
    fontSize: '13px',
    margin: 0
  }
}

export default MedicationsPage

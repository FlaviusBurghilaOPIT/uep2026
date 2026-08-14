import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'
import { trackEvent } from '../api/analytics'
import { useTranslation } from '../i18n/useTranslation'
import { FormField, NumberField, Select } from '../components/ui'

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
  const [durationDays, setDurationDays] = useState<number | null>(null)
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
    if (durationDays === null || durationDays < 1) missingFields.push('duration-days')
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
          duration: `${durationDays} days`,
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
          <FormField
            label={t('medication.drugName')}
            invalid={missing.includes('drug-name')}
            error={error || undefined}
          >
            {(control) => (
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                <input
                  {...control}
                  style={{ ...styles.input, flex: 1 }}
                  type="text"
                  placeholder={t('medication.drugNamePlaceholder')}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
                {name.trim() && (
                  <button type="button" style={styles.fdaWarningButton} onClick={openFDA}>
                    {t('medication.viewFdaSafety')}
                  </button>
                )}
              </div>
            )}
          </FormField>

          <FormField
            label={t('medication.dose')}
            invalid={missing.includes('dose')}
          >
            {(control) => (
              <input
                {...control}
                style={styles.input}
                type="text"
                placeholder={t('medication.dosePlaceholder')}
                value={dose}
                onChange={(e) => setDose(e.target.value)}
              />
            )}
          </FormField>

          <FormField
            label={t('medication.frequencyLabel')}
            hint={
              reminderTimes.length > 0
                ? `${t('medication.remindersAt')} ${reminderTimes.join(', ')}`
                : t('medication.noReminders')
            }
          >
            {(control) => (
              <Select
                {...control}
                value={frequency}
                onChange={(v) => setFrequency(v as 'QD'|'BID'|'TID'|'QID'|'PRN')}
                options={[
                  { value: 'QD', label: t('medication.frequencyQD') },
                  { value: 'BID', label: t('medication.frequencyBID') },
                  { value: 'TID', label: t('medication.frequencyTID') },
                  { value: 'QID', label: t('medication.frequencyQID') },
                  { value: 'PRN', label: t('medication.frequencyPRN') },
                ]}
              />
            )}
          </FormField>

          <FormField
            label={t('medication.durationDays')}
            invalid={missing.includes('duration-days')}
          >
            {(control) => (
              <NumberField
                {...control}
                value={durationDays}
                onChange={setDurationDays}
                placeholder={t('medication.durationPlaceholder')}
              />
            )}
          </FormField>

          <FormField label={t('medication.notesOptional')}>
            {(control) => (
              <textarea
                {...control}
                style={styles.textarea}
                placeholder={t('medication.notesPlaceholder')}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
              />
            )}
          </FormField>

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
  }
}

export default MedicationsPage

import { useState, useEffect, useCallback } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from '../i18n'
import { apiFetch } from '../api/client'
import { trackEvent } from '../api/analytics'

type Patient = {
  id: string
  full_name: string
}

type CreatedCase = {
  id: string
  patient_id: string
  surgery_type: string
}

function CreateCasePage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const [patients, setPatients] = useState<Patient[]>([])
  const [patientId, setPatientId] = useState(searchParams.get('patient') || '')
  const [surgeryType, setSurgeryType] = useState('')
  const [loading, setLoading] = useState(false)
  const [createdCaseId, setCreatedCaseId] = useState<string | null>(null)
  const [error, setError] = useState('')
  const [loadError, setLoadError] = useState(false)
  const [loadingPatients, setLoadingPatients] = useState(true)
  const [missing, setMissing] = useState<string[]>([])

  const fetchPatients = useCallback(async () => {
    setLoadingPatients(true)
    setLoadError(false)
    try {
      const data = await apiFetch<Patient[]>('/patients')
      setPatients(data)
    } catch (err) {
      console.error('Failed to fetch patients', err)
      setLoadError(true)
    } finally {
      setLoadingPatients(false)
    }
  }, [])

  useEffect(() => {
    fetchPatients()
  }, [fetchPatients])

  const handleCreateCase = async (e: React.FormEvent) => {
    e.preventDefault()

    const missingFields: string[] = []
    if (!patientId) missingFields.push('patient-select')
    if (!surgeryType.trim()) missingFields.push('surgery-type')
    setMissing(missingFields)
    if (missingFields.length > 0) {
      setError(t('createCase.errorMissingFields'))
      return
    }

    setLoading(true)
    setError('')
    try {
      const res = await apiFetch<CreatedCase>('/cases', {
        method: 'POST',
        body: JSON.stringify({
          patient_id: patientId,
          surgery_type: surgeryType.trim()
        })
      })
      setCreatedCaseId(res.id)
      trackEvent('web.case.created', { case_id: res.id, patient_id: patientId })
    } catch (err: unknown) {
      setError((err as Error).message || t('createCase.errorCreateFailed'))
    } finally {
      setLoading(false)
    }
  }

  if (createdCaseId) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>{t('createCase.successTitle')}</h1>
          <p style={styles.subtitle}>{t('createCase.successSubtitle')}</p>
          <button
            style={styles.button}
            onClick={() => navigate(`/cases/${createdCaseId}/medications`)}
          >
            {t('createCase.prescribeMedications')}
          </button>
          <button
            style={styles.button}
            onClick={() => navigate(`/cases/${createdCaseId}/recommendations`)}
          >
            {t('createCase.addRecommendations')}
          </button>
          <button
            style={styles.backButton}
            onClick={() => navigate('/patients')}
          >
            {t('createCase.backToPatients')}
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>{t('createCase.title')}</h1>

        {loadError ? (
          <div role="alert" style={styles.loadErrorBox}>
            <p style={styles.error}>{t('createCase.errorLoadPatients')}</p>
            <button style={styles.backButton} onClick={fetchPatients}>
              {t('common.retry')}
            </button>
          </div>
        ) : (
          <form onSubmit={handleCreateCase} style={styles.form} noValidate>
            <label style={styles.label} htmlFor="patient-select">{t('createCase.selectPatient')}</label>
            <select
              id="patient-select"
              style={styles.input}
              value={patientId}
              onChange={(e) => setPatientId(e.target.value)}
              disabled={loadingPatients}
              aria-invalid={missing.includes('patient-select')}
              aria-describedby={error ? 'form-error' : undefined}
            >
              <option value="">{t('createCase.selectPatientPlaceholder')}</option>
              {patients.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.full_name}
                </option>
              ))}
            </select>

            <label style={styles.label} htmlFor="surgery-type">{t('createCase.surgeryType')}</label>
            <input
              id="surgery-type"
              style={styles.input}
              type="text"
              placeholder={t('createCase.surgeryTypePlaceholder')}
              value={surgeryType}
              onChange={(e) => setSurgeryType(e.target.value)}
              aria-invalid={missing.includes('surgery-type')}
              aria-describedby={error ? 'form-error' : undefined}
            />

            {error && <p id="form-error" role="alert" style={styles.error}>{error}</p>}

            <button
              style={styles.button}
              type="submit"
              disabled={loading || loadingPatients}
            >
              {loading ? t('createCase.creating') : t('createCase.createCase')}
            </button>

            <button
              style={styles.backButton}
              type="button"
              onClick={() => navigate('/patients')}
            >
              {t('createCase.cancel')}
            </button>
          </form>
        )}
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
    fontSize: '15px',
    width: '100%'
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
  loadErrorBox: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px',
    alignItems: 'center'
  },
  error: {
    color: '#dc2626',
    fontSize: '13px',
    margin: 0
  }
}

export default CreateCasePage

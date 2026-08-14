import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from '../i18n'
import { useNavigate, useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'

type Medication = {
  id: string
  name: string
  dose: string
  schedule_text?: string
  frequency?: string
  duration?: string
  duration_days?: number
  notes?: string
}

type CaseInfo = {
  id: string
  surgery_type: string
}

function MedicationsListPage() {
  const { t } = useTranslation()
  const { caseId } = useParams<{ caseId: string }>()
  const navigate = useNavigate()
  const [medications, setMedications] = useState<Medication[]>([])
  const [caseInfo, setCaseInfo] = useState<CaseInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const fetchMedications = useCallback(async () => {
    setLoading(true)
    setError(false)
    try {
      const data = await apiFetch<Medication[]>(`/cases/${caseId}/medications`)
      setMedications(data)
    } catch (err) {
      console.error('Failed to fetch medications', err)
      setError(true)
    } finally {
      setLoading(false)
    }
  }, [caseId])

  useEffect(() => {
    fetchMedications()
    apiFetch<CaseInfo>(`/cases/${caseId}`)
      .then(setCaseInfo)
      .catch(() => setCaseInfo(null))
  }, [caseId, fetchMedications])

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>{t('medicationsList.title')}</h1>
        {caseInfo && (
          <p style={styles.subtitle}>{t('medicationsList.case')}: {caseInfo.surgery_type}</p>
        )}
      </div>

      <button
        style={styles.addButton}
        onClick={() => navigate(`/cases/${caseId}/medications`)}
      >
        + {t('medicationsList.addMedication')}
      </button>

      {loading && <p style={styles.loading}>{t('medicationsList.loading')}</p>}

      {!loading && error && (
        <div style={styles.errorBox} role="alert">
          <p style={styles.errorText}>{t('common.errorLoading')}</p>
          <button style={styles.retryButton} onClick={fetchMedications}>
            {t('common.retry')}
          </button>
        </div>
      )}

      {!loading && !error && medications.length === 0 && (
        <p style={styles.empty}>{t('medicationsList.empty')}</p>
      )}

      {!loading && !error && (
        <div style={styles.list}>
          {medications.map((med) => (
            <div key={med.id} style={styles.card}>
              <div style={styles.cardHeader}>
                <p style={styles.medName}>{med.name}</p>
                <span style={styles.badge}>{med.schedule_text || med.frequency || ''}</span>
              </div>
              <p style={styles.detail}>{t('medicationsList.dose')}: {med.dose}</p>
              <p style={styles.detail}>
                {t('medicationsList.duration')}: {med.duration || (med.duration_days ? `${med.duration_days} ${t('medicationsList.days')}` : '—')}
              </p>
              {med.notes && <p style={styles.notes}>{med.notes}</p>}
              <button
                style={styles.fdaButton}
                onClick={() => navigate(`/fda?drug=${encodeURIComponent(med.name.toLowerCase())}`)}
              >
                {t('medicationsList.viewFdaSafety')}
              </button>
            </div>
          ))}
        </div>
      )}

      <button
        style={styles.backButton}
        onClick={() => navigate('/patients')}
      >
        {t('medicationsList.backToPatients')}
      </button>
    </div>
  )
}

const styles = {
  container: {
    padding: '32px',
    backgroundColor: '#f9fafb',
    minHeight: '100vh'
  },
  header: {
    marginBottom: '24px'
  },
  title: {
    fontSize: '22px',
    fontWeight: '600',
    color: '#111827',
    margin: '0 0 4px 0'
  },
  subtitle: {
    fontSize: '13px',
    color: '#6b7280',
    margin: 0
  },
  addButton: {
    padding: '10px 20px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer',
    marginBottom: '24px'
  },
  loading: {
    color: '#6b7280',
    fontSize: '14px'
  },
  errorBox: {
    backgroundColor: '#fef2f2',
    border: '1px solid #fecaca',
    borderRadius: '12px',
    padding: '24px',
    textAlign: 'center' as const,
    marginBottom: '24px'
  },
  errorText: {
    color: '#b91c1c',
    fontSize: '14px',
    margin: '0 0 12px 0'
  },
  retryButton: {
    padding: '8px 20px',
    backgroundColor: '#b91c1c',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer'
  },
  empty: {
    color: '#64748b',
    fontSize: '14px',
    fontStyle: 'italic' as const,
    marginBottom: '24px'
  },
  list: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px',
    marginBottom: '24px'
  },
  card: {
    backgroundColor: '#ffffff',
    padding: '20px',
    borderRadius: '12px',
    border: '1px solid #e5e7eb'
  },
  cardHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '8px'
  },
  medName: {
    fontSize: '16px',
    fontWeight: '600',
    color: '#111827',
    margin: 0
  },
  badge: {
    backgroundColor: '#eff6ff',
    color: '#2563eb',
    padding: '2px 10px',
    borderRadius: '20px',
    fontSize: '12px',
    fontWeight: '500'
  },
  fdaButton: {
    padding: '6px 12px',
    backgroundColor: '#fffbe6',
    color: '#d97706',
    border: '1px solid #fde68a',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '500' as const,
    cursor: 'pointer',
    marginTop: '8px'
  },
  detail: {
    fontSize: '13px',
    color: '#6b7280',
    margin: '0 0 4px 0'
  },
  notes: {
    fontSize: '13px',
    color: '#111827',
    margin: '8px 0 0 0',
    fontStyle: 'italic'
  },
  backButton: {
    padding: '10px 20px',
    backgroundColor: '#ffffff',
    color: '#6b7280',
    border: '1px solid #e5e7eb',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer'
  }
}

export default MedicationsListPage

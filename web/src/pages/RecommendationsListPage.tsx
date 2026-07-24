import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from '../i18n'
import { useNavigate, useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'

type Recommendation = {
  id: string
  content?: string
  text?: string
  created_at: string
}

type CaseInfo = {
  id: string
  surgery_type: string
}

function RecommendationsListPage() {
  const { t, language } = useTranslation()
  const { caseId } = useParams<{ caseId: string }>()
  const navigate = useNavigate()
  const [recommendations, setRecommendations] = useState<Recommendation[]>([])
  const [caseInfo, setCaseInfo] = useState<CaseInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const fetchRecommendations = useCallback(async () => {
    setLoading(true)
    setError(false)
    try {
      const data = await apiFetch<Recommendation[]>(`/cases/${caseId}/recommendations`)
      setRecommendations(data)
    } catch (err) {
      console.error('Failed to fetch recommendations', err)
      setError(true)
    } finally {
      setLoading(false)
    }
  }, [caseId])

  useEffect(() => {
    fetchRecommendations()
    apiFetch<CaseInfo>(`/cases/${caseId}`)
      .then(setCaseInfo)
      .catch(() => setCaseInfo(null))
  }, [caseId, fetchRecommendations])

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>{t('recommendationsList.title')}</h1>
        {caseInfo && (
          <p style={styles.subtitle}>{t('recommendationsList.case')}: {caseInfo.surgery_type}</p>
        )}
      </div>

      <button
        style={styles.addButton}
        onClick={() => navigate(`/cases/${caseId}/recommendations`)}
      >
        + {t('recommendationsList.addRecommendation')}
      </button>

      {loading && <p style={styles.loading}>{t('recommendationsList.loading')}</p>}

      {!loading && error && (
        <div style={styles.errorBox} role="alert">
          <p style={styles.errorText}>{t('common.errorLoading')}</p>
          <button style={styles.retryButton} onClick={fetchRecommendations}>
            {t('common.retry')}
          </button>
        </div>
      )}

      {!loading && !error && recommendations.length === 0 && (
        <p style={styles.empty}>{t('recommendationsList.empty')}</p>
      )}

      {!loading && !error && (
        <div style={styles.list}>
          {recommendations.map((rec) => (
            <div key={rec.id} style={styles.card}>
              <p style={styles.content}>{rec.content || rec.text || ''}</p>
              <p style={styles.date}>
                {t('recommendationsList.added')}: {new Date(rec.created_at).toLocaleDateString(language)}
              </p>
            </div>
          ))}
        </div>
      )}

      <button
        style={styles.backButton}
        onClick={() => navigate('/patients')}
      >
        {t('recommendationsList.backToPatients')}
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
  content: {
    fontSize: '15px',
    color: '#111827',
    margin: '0 0 8px 0',
    lineHeight: '1.6'
  },
  date: {
    fontSize: '12px',
    color: '#6b7280',
    margin: 0
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

export default RecommendationsListPage

import { useEffect, useState } from 'react'
import { useTranslation } from '../i18n'
import { useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'

type Recommendation = {
  id: string
  content?: string
  text?: string
  created_at: string
}

function RecommendationsListPage() {
  const { t } = useTranslation()
  const { caseId = 'case-001' } = useParams<{ caseId: string }>()
  const [recommendations, setRecommendations] = useState<Recommendation[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchRecommendations = async () => {
      try {
        const data = await apiFetch<Recommendation[]>(`/cases/${caseId}/recommendations`)
        setRecommendations(data)
      } catch (err) {
        console.error('Failed to fetch recommendations', err)
      } finally {
        setLoading(false)
      }
    }

    fetchRecommendations()
  }, [caseId])

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>{t('recommendationsList.title')}</h1>
        <p style={styles.subtitle}>{t('recommendationsList.case')}: {caseId}</p>
      </div>

      <button
        style={styles.addButton}
        onClick={() => window.location.href = `/cases/${caseId}/recommendations`}
      >
        + {t('recommendationsList.addRecommendation')}
      </button>

      {loading && <p style={styles.loading}>{t('recommendationsList.loading')}</p>}

      <div style={styles.list}>
        {recommendations.map((rec) => (
          <div key={rec.id} style={styles.card}>
            <p style={styles.content}>{rec.content || rec.text || ''}</p>
            <p style={styles.date}>
              {t('recommendationsList.added')}: {new Date(rec.created_at).toLocaleDateString()}
            </p>
          </div>
        ))}
      </div>

      <button
        style={styles.backButton}
        onClick={() => window.location.href = '/patients'}
      >
        Back to Patients
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
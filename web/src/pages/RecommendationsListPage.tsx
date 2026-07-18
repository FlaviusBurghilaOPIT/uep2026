import { useEffect, useState } from 'react'
import axios from 'axios'

const API_URL = 'http://localhost:8001'

type Recommendation = {
  id: string
  content: string
  created_at: string
}

function RecommendationsListPage() {
  const [recommendations, setRecommendations] = useState<Recommendation[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchRecommendations = async () => {
      try {
        const token = localStorage.getItem('token') || 'faketoken'
        const response = await axios.get(`${API_URL}/cases/case-001/recommendations`, {
          headers: { Authorization: `Bearer ${token}` }
        })
        setRecommendations(response.data)
      } catch (err) {
        console.error('Failed to fetch recommendations', err)
      } finally {
        setLoading(false)
      }
    }

    fetchRecommendations()
  }, [])

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>Recovery Recommendations</h1>
        <p style={styles.subtitle}>Case: Knee Replacement — Maria Rossi</p>
      </div>

      <button
        style={styles.addButton}
        onClick={() => window.location.href = '/cases/case-001/recommendations'}
      >
        + Add Recommendation
      </button>

      {loading && <p style={styles.loading}>Loading...</p>}

      <div style={styles.list}>
        {recommendations.map((rec) => (
          <div key={rec.id} style={styles.card}>
            <p style={styles.content}>{rec.content}</p>
            <p style={styles.date}>
              Added: {new Date(rec.created_at).toLocaleDateString()}
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
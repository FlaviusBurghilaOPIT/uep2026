import { useState } from 'react'
import axios from 'axios'

const API_URL = 'http://localhost:8001'

function RecommendationsPage() {
  const [content, setContent] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async () => {
    if (!content) {
      setError('Please write some recommendations')
      return
    }

    setLoading(true)
    try {
      const token = localStorage.getItem('token') || 'faketoken'
      await axios.post(
        `${API_URL}/cases/case-001/recommendations`,
        { content },
        { headers: { Authorization: `Bearer ${token}` } }
      )
      setSuccess(true)
    } catch (err) {
      setError('Failed to save recommendations. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Recommendations Saved ✓</h1>
          <p style={styles.subtitle}>Recovery instructions have been saved successfully.</p>
          <button
            style={styles.button}
            onClick={() => window.location.href = '/cases/case-001/recommendations/list'}
          >
            View All Recommendations
          </button>
          <button
            style={styles.backButton}
            onClick={() => window.location.href = '/patients'}
          >
            Back to Patients
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>Recovery Recommendations</h1>
        <p style={styles.subtitle}>Case: Knee Replacement — Maria Rossi</p>

        <label style={styles.label}>Recovery Instructions</label>
        <textarea
          style={styles.textarea}
          placeholder="e.g. Avoid weight-bearing for 2 weeks. Ice the knee 3x daily. Attend physiotherapy sessions twice a week."
          value={content}
          onChange={(e) => setContent(e.target.value)}
        />

        {error && <p style={styles.error}>{error}</p>}

        <button
          style={styles.button}
          onClick={handleSubmit}
          disabled={loading}
        >
          {loading ? 'Saving...' : 'Save Recommendations'}
        </button>

        <button
          style={styles.backButton}
          onClick={() => window.location.href = '/patients'}
        >
          Cancel
        </button>
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
    width: '480px',
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
  label: {
    fontSize: '13px',
    fontWeight: '500',
    color: '#111827'
  },
  textarea: {
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    outline: 'none',
    resize: 'vertical' as const,
    minHeight: '160px'
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
  error: {
    color: '#dc2626',
    fontSize: '13px',
    margin: 0
  }
}

export default RecommendationsPage
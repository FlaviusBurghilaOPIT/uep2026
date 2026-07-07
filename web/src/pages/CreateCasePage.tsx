import { useState } from 'react'
import axios from 'axios'

const API_URL = 'http://localhost:8001'

function CreateCasePage() {
  const [surgeryType, setSurgeryType] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleCreateCase = async () => {
    if (!surgeryType) {
      setError('Please enter a surgery type')
      return
    }

    setLoading(true)
    try {
      const token = localStorage.getItem('token') || 'faketoken'
      await axios.post(
        `${API_URL}/cases`,
        {
          patient_id: 'pat-001',
          surgery_type: surgeryType
        },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      setSuccess(true)
    } catch (err) {
      setError('Failed to create case. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Case Created ✓</h1>
          <p style={styles.subtitle}>The case has been created successfully.</p>
          <button
            style={styles.button}
            onClick={() => window.location.href = '/cases/case-001/medications'}
          >
            Prescribe Medications
          </button>
          <button
            style={styles.button}
            onClick={() => window.location.href = '/cases/case-001/recommendations'}
          >
            Add Recovery Recommendations
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
        <h1 style={styles.title}>Create Case</h1>
        <p style={styles.subtitle}>Patient: Maria Rossi</p>

        <label style={styles.label}>Surgery Type</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. knee replacement"
          value={surgeryType}
          onChange={(e) => setSurgeryType(e.target.value)}
        />

        {error && <p style={styles.error}>{error}</p>}

        <button
          style={styles.button}
          onClick={handleCreateCase}
          disabled={loading}
        >
          {loading ? 'Creating...' : 'Create Case'}
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
  label: {
    fontSize: '13px',
    fontWeight: '500',
    color: '#111827'
  },
  input: {
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    outline: 'none'
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

export default CreateCasePage
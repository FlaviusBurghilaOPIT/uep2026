import { useState } from 'react'
import axios from 'axios'

const API_URL = 'http://localhost:8001'

function MedicationsPage() {
  const [name, setName] = useState('')
  const [dose, setDose] = useState('')
  const [frequency, setFrequency] = useState('')
  const [durationDays, setDurationDays] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async () => {
    if (!name || !dose || !frequency || !durationDays) {
      setError('Please fill in all required fields')
      return
    }

    setLoading(true)
    try {
      const token = localStorage.getItem('token') || 'faketoken'
      await axios.post(
        `${API_URL}/cases/case-001/medications`,
        {
          name,
          dose,
          frequency,
          duration_days: parseInt(durationDays),
          notes
        },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      setSuccess(true)
    } catch (err) {
      setError('Failed to add medication. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Medication Added ✓</h1>
          <p style={styles.subtitle}>The medication has been prescribed successfully.</p>
          <button
            style={styles.button}
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
        <h1 style={styles.title}>Prescribe Medication</h1>
        <p style={styles.subtitle}>Case: Knee Replacement — Maria Rossi</p>

        <label style={styles.label}>Drug Name *</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. Ibuprofen"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />

        <label style={styles.label}>Dose *</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. 400mg"
          value={dose}
          onChange={(e) => setDose(e.target.value)}
        />

        <label style={styles.label}>Frequency *</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. 3x daily"
          value={frequency}
          onChange={(e) => setFrequency(e.target.value)}
        />

        <label style={styles.label}>Duration (days) *</label>
        <input
          style={styles.input}
          type="number"
          placeholder="e.g. 14"
          value={durationDays}
          onChange={(e) => setDurationDays(e.target.value)}
        />

        <label style={styles.label}>Notes (optional)</label>
        <textarea
          style={styles.textarea}
          placeholder="e.g. Take with food"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
        />

        {error && <p style={styles.error}>{error}</p>}

        <button
          style={styles.button}
          onClick={handleSubmit}
          disabled={loading}
        >
          {loading ? 'Adding...' : 'Add Medication'}
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
  textarea: {
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    outline: 'none',
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
  error: {
    color: '#dc2626',
    fontSize: '13px',
    margin: 0
  }
}

export default MedicationsPage
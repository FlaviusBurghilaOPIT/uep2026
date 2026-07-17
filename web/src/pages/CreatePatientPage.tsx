import { useState } from 'react'
import axios from 'axios'

const API_URL = 'http://localhost:8001'

function CreatePatientPage() {
  const [fullName, setFullName] = useState('')
  const [dateOfBirth, setDateOfBirth] = useState('')
  const [allergies, setAllergies] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async () => {
    if (!fullName || !dateOfBirth) {
      setError('Please fill in name and date of birth')
      return
    }

    setLoading(true)
    try {
      const token = localStorage.getItem('token') || 'faketoken'
      await axios.post(
        `${API_URL}/patients`,
        {
          full_name: fullName,
          date_of_birth: dateOfBirth,
          allergies: allergies
            ? allergies.split(',').map((a) => a.trim())
            : []
        },
        { headers: { Authorization: `Bearer ${token}` } }
      )
      setSuccess(true)
    } catch (err) {
      setError('Failed to create patient. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Patient Created ✓</h1>
          <p style={styles.subtitle}>The patient profile has been created.</p>
          <button
            style={styles.button}
            onClick={() => window.location.href = '/cases/new'}
          >
            Create Case for this Patient
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
        <h1 style={styles.title}>New Patient</h1>

        <label style={styles.label}>Full Name *</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. Maria Rossi"
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
        />

        <label style={styles.label}>Date of Birth *</label>
        <input
          style={styles.input}
          type="date"
          value={dateOfBirth}
          onChange={(e) => setDateOfBirth(e.target.value)}
        />

        <label style={styles.label}>Allergies (comma separated)</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. penicillin, aspirin"
          value={allergies}
          onChange={(e) => setAllergies(e.target.value)}
        />

        {error && <p style={styles.error}>{error}</p>}

        <button
          style={styles.button}
          onClick={handleSubmit}
          disabled={loading}
        >
          {loading ? 'Creating...' : 'Create Patient'}
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
    outline: 'none',
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
  error: {
    color: '#dc2626',
    fontSize: '13px',
    margin: 0
  }
}

export default CreatePatientPage
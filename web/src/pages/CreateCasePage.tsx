import { useState, useEffect } from 'react'
import { apiFetch } from '../api/client'

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
  const [patients, setPatients] = useState<Patient[]>([])
  const [patientId, setPatientId] = useState('')
  const [surgeryType, setSurgeryType] = useState('')
  const [loading, setLoading] = useState(false)
  const [createdCaseId, setCreatedCaseId] = useState<string | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchPatients = async () => {
      try {
        const data = await apiFetch<Patient[]>('/patients')
        setPatients(data)
      } catch (err) {
        console.error('Failed to fetch patients', err)
      }
    }
    fetchPatients()
  }, [])

  const handleCreateCase = async () => {
    if (!patientId || !surgeryType) {
      setError('Please select a patient and enter a surgery type')
      return
    }

    setLoading(true)
    setError('')
    try {
      const res = await apiFetch<CreatedCase>('/cases', {
        method: 'POST',
        body: JSON.stringify({
          patient_id: patientId,
          surgery_type: surgeryType
        })
      })
      setCreatedCaseId(res.id)
    } catch (err: unknown) {
      setError((err as Error).message || 'Failed to create case. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (createdCaseId) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Case Created ✓</h1>
          <p style={styles.subtitle}>The case has been created successfully.</p>
          <button
            style={styles.button}
            onClick={() => window.location.href = `/cases/${createdCaseId}/medications`}
          >
            Prescribe Medications
          </button>
          <button
            style={styles.button}
            onClick={() => window.location.href = `/cases/${createdCaseId}/recommendations`}
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
        <h1 style={styles.title}>New Case</h1>

        <label style={styles.label} htmlFor="patient-select">Select Patient</label>
        <select
          id="patient-select"
          style={styles.input}
          value={patientId}
          onChange={(e) => setPatientId(e.target.value)}
          aria-invalid={!!error}
          aria-describedby={error ? 'form-error' : undefined}
        >
          <option value="">-- Select a patient --</option>
          {patients.map((p) => (
            <option key={p.id} value={p.id}>
              {p.full_name}
            </option>
          ))}
        </select>

        <label style={styles.label} htmlFor="surgery-type">Surgery Type</label>
        <input
          id="surgery-type"
          style={styles.input}
          type="text"
          placeholder="e.g. Knee Replacement"
          value={surgeryType}
          onChange={(e) => setSurgeryType(e.target.value)}
          aria-invalid={!!error}
          aria-describedby={error ? 'form-error' : undefined}
        />

        {error && <p id="form-error" role="alert" style={styles.error}>{error}</p>}

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

export default CreateCasePage
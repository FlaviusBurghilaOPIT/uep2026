import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'

function MedicationsPage() {
  const { caseId = 'case-001' } = useParams<{ caseId: string }>()
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
    setError('')
    try {
      await apiFetch(`/cases/${caseId}/medications`, {
        method: 'POST',
        body: JSON.stringify({
          name,
          dose,
          schedule_text: frequency,
          duration: `${durationDays} days`,
          notes
        })
      })
      setSuccess(true)
    } catch (err: any) {
      setError(err.message || 'Failed to add medication. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const openFDA = () => {
    window.open('/fda?drug=' + name.toLowerCase(), '_blank')
  }

  const openFDAWebsite = () => {
    window.open('https://www.accessdata.fda.gov/scripts/cder/daf/index.cfm?event=BasicSearch.process&query=' + name.toLowerCase(), '_blank')
  }

  if (success) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Medication Added</h1>
          <p style={styles.subtitle}>The medication has been prescribed successfully.</p>
          <button
            style={styles.button}
            onClick={() => window.location.href = `/cases/${caseId}/medications/list`}
          >
            View All Medications
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
        <h1 style={styles.title}>Prescribe Medication</h1>
        <p style={styles.subtitle}>Case: Knee Replacement</p>

        <label style={styles.label}>Drug Name</label>
        <div style={{ display: 'flex', gap: '8px' }}>
          <input
            style={{ ...styles.input, flex: 1 }}
            type="text"
            placeholder="e.g. Ibuprofen"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          {name && (
            <button style={styles.fdaButton} onClick={openFDA}>
              FDA Check
            </button>
          )}
        </div>

        {name && (
          <button style={styles.fdaExternalLink} onClick={openFDAWebsite}>
            View on FDA Website
          </button>
        )}

        <label style={styles.label}>Dose</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. 400mg"
          value={dose}
          onChange={(e) => setDose(e.target.value)}
        />

        <label style={styles.label}>Frequency</label>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. 3x daily"
          value={frequency}
          onChange={(e) => setFrequency(e.target.value)}
        />

        <label style={styles.label}>Duration (days)</label>
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

        <button style={styles.button} onClick={handleSubmit} disabled={loading}>
          {loading ? 'Adding...' : 'Add Medication'}
        </button>

        <button style={styles.backButton} onClick={() => window.location.href = '/patients'}>
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
  fdaButton: {
    padding: '8px 12px',
    backgroundColor: '#fef9f0',
    color: '#d97706',
    border: '1px solid #fde68a',
    borderRadius: '8px',
    fontSize: '13px',
    cursor: 'pointer',
    fontWeight: '500' as const
  },
  fdaExternalLink: {
    padding: '6px 12px',
    backgroundColor: '#f0fdf4',
    color: '#16a34a',
    border: '1px solid #bbf7d0',
    borderRadius: '8px',
    fontSize: '12px',
    cursor: 'pointer',
    fontWeight: '500' as const,
    textAlign: 'left' as const
  },
  error: {
    color: '#dc2626',
    fontSize: '13px',
    margin: 0
  }
}

export default MedicationsPage
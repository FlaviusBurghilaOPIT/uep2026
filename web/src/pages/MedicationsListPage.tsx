import { useEffect, useState } from 'react'
import axios from 'axios'

const API_URL = 'http://localhost:8001'

type Medication = {
  id: string
  name: string
  dose: string
  frequency: string
  duration_days: number
  notes: string
}

function MedicationsListPage() {
  const [medications, setMedications] = useState<Medication[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchMedications = async () => {
      try {
        const token = localStorage.getItem('token') || 'faketoken'
        const response = await axios.get(`${API_URL}/cases/case-001/medications`, {
          headers: { Authorization: `Bearer ${token}` }
        })
        setMedications(response.data)
      } catch (err) {
        console.error('Failed to fetch medications', err)
      } finally {
        setLoading(false)
      }
    }

    fetchMedications()
  }, [])

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>Medications</h1>
        <p style={styles.subtitle}>Case: Knee Replacement — Maria Rossi</p>
      </div>

      <button
        style={styles.addButton}
        onClick={() => window.location.href = '/cases/case-001/medications'}
      >
        + Add Medication
      </button>

      {loading && <p style={styles.loading}>Loading...</p>}

      <div style={styles.list}>
        {medications.map((med) => (
          <div key={med.id} style={styles.card}>
            <div style={styles.cardHeader}>
              <p style={styles.medName}>{med.name}</p>
              <span style={styles.badge}>{med.frequency}</span>
            </div>
            <p style={styles.detail}>Dose: {med.dose}</p>
            <p style={styles.detail}>Duration: {med.duration_days} days</p>
            {med.notes && <p style={styles.notes}>{med.notes}</p>}
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
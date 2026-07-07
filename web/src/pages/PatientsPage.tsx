import { useEffect, useState } from 'react'
import axios from 'axios'

const API_URL = 'http://localhost:8001'

type Patient = {
  id: string
  full_name: string
  date_of_birth: string
  allergies: string[]
}

function PatientsPage() {
  const [patients, setPatients] = useState<Patient[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchPatients = async () => {
      try {
        const token = localStorage.getItem('token') || 'faketoken'
        const response = await axios.get(`${API_URL}/patients`, {
          headers: { Authorization: `Bearer ${token}` }
        })
        setPatients(response.data)
      } catch (err) {
        console.error('Failed to fetch patients', err)
      } finally {
        setLoading(false)
      }
    }

    fetchPatients()
  }, [])

  return (
    <div style={styles.container}>
      <h1 style={styles.title}>Patients</h1>

      {loading && <p>Loading...</p>}

      <div style={styles.list}>
        {patients.map((patient) => (
          <div key={patient.id} style={styles.card}>
            <p style={styles.name}>{patient.full_name}</p>
            <p style={styles.detail}>DOB: {patient.date_of_birth}</p>
            <p style={styles.detail}>
              Allergies: {patient.allergies.length > 0 ? patient.allergies.join(', ') : 'None'}
            </p>
            <button
              style={styles.button}
              onClick={() => window.location.href = '/cases/new'}
            >
              Create Case
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}

const styles = {
  container: {
    padding: '32px',
    backgroundColor: '#f9fafb',
    minHeight: '100vh'
  },
  title: {
    fontSize: '22px',
    fontWeight: '600',
    color: '#111827',
    marginBottom: '24px'
  },
  list: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px'
  },
  card: {
    backgroundColor: '#ffffff',
    padding: '20px',
    borderRadius: '12px',
    border: '1px solid #e5e7eb'
  },
  name: {
    fontSize: '16px',
    fontWeight: '600',
    color: '#111827',
    margin: '0 0 4px 0'
  },
  detail: {
    fontSize: '13px',
    color: '#6b7280',
    margin: '0 0 4px 0'
  },
  button: {
    marginTop: '12px',
    padding: '8px 16px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '13px',
    cursor: 'pointer'
  }
}

export default PatientsPage
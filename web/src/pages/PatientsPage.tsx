import { useEffect, useState } from 'react'
import { apiFetch } from '../api/client'

type Patient = {
  id: string
  full_name: string
  date_of_birth?: string | null
  allergies?: string[]
  status?: string | null
  invite_code?: string | null
}

type Case = {
  id: string
  patient_id: string
  surgery_type: string
  status: string
  created_at: string
}

function PatientsPage() {
  const [patients, setPatients] = useState<Patient[]>([])
  const [cases, setCases] = useState<Case[]>([])
  const [loading, setLoading] = useState(true)
  const [copiedId, setCopiedId] = useState<string | null>(null)

  const handleCopyCode = (patientId: string, code: string) => {
    navigator.clipboard.writeText(code)
    setCopiedId(patientId)
    setTimeout(() => setCopiedId((current) => (current === patientId ? null : current)), 2000)
  }

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [patientsRes, casesRes] = await Promise.all([
          apiFetch<Patient[]>('/patients'),
          apiFetch<Case[]>('/cases')
        ])

        setPatients(patientsRes)
        setCases(casesRes)
      } catch (err) {
        console.error('Failed to fetch data', err)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  const getCasesForPatient = (patientId: string) =>
    cases.filter((c) => c.patient_id === patientId)

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>Patients</h1>
        <button
          style={styles.newButton}
          onClick={() => window.location.href = '/patients/new'}
        >
          + New Patient
        </button>
      </div>

      {loading && <p>Loading...</p>}

      <div style={styles.list}>
        {patients.map((patient) => {
          const patientCases = getCasesForPatient(patient.id)
          return (
            <div key={patient.id} style={styles.card}>
              <div style={styles.patientHeader}>
                <div>
                  <p style={styles.name}>{patient.full_name}</p>
                  <p style={styles.detail}>DOB: {patient.date_of_birth}</p>
                  <p style={styles.detail}>
                    Allergies: {patient.allergies && patient.allergies.length > 0 ? patient.allergies.join(', ') : 'None'}
                  </p>
                </div>
                <button
                  style={styles.newCaseButton}
                  onClick={() => window.location.href = '/cases/new'}
                >
                  + New Case
                </button>
              </div>

              {patient.status === 'pending_onboarding' && patient.invite_code && (
                <div style={styles.inviteBox}>
                  <p style={styles.inviteLabel}>Pending onboarding &mdash; 6-Digit Invite Code:</p>
                  <p style={styles.inviteCode}>{patient.invite_code}</p>
                  <button
                    style={styles.copyButton}
                    onClick={() => handleCopyCode(patient.id, patient.invite_code as string)}
                  >
                    {copiedId === patient.id ? 'Copied!' : 'Copy Code'}
                  </button>
                </div>
              )}

              {patientCases.length > 0 && (
                <div style={styles.casesSection}>
                  <p style={styles.casesTitle}>Cases</p>
                  {patientCases.map((c) => (
                    <div key={c.id} style={styles.caseRow}>
                      <span style={styles.caseType}>{c.surgery_type}</span>
                      <span style={{
                        ...styles.caseStatus,
                        backgroundColor: c.status === 'open' ? '#dcfce7' : '#f1f5f9',
                        color: c.status === 'open' ? '#16a34a' : '#6b7280'
                      }}>
                        {c.status}
                      </span>
                      <div style={styles.caseButtons}>
                        <button
                          style={styles.secondaryButton}
                          onClick={() => window.location.href = `/cases/${c.id}/medications/list`}
                        >
                          Medications
                        </button>
                        <button
                          style={styles.secondaryButton}
                          onClick={() => window.location.href = `/cases/${c.id}/recommendations/list`}
                        >
                          Recommendations
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {patientCases.length === 0 && (
                <p style={styles.noCases}>No cases yet</p>
              )}
            </div>
          )
        })}
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
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '24px'
  },
  title: {
    fontSize: '22px',
    fontWeight: '600',
    color: '#111827',
    margin: 0
  },
  newButton: {
    padding: '8px 16px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer'
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
  patientHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start'
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
  newCaseButton: {
    padding: '6px 12px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '12px',
    cursor: 'pointer',
    flexShrink: 0
  },
  casesSection: {
    marginTop: '16px',
    borderTop: '1px solid #e5e7eb',
    paddingTop: '12px'
  },
  casesTitle: {
    fontSize: '12px',
    fontWeight: '600',
    color: '#6b7280',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.05em',
    margin: '0 0 8px 0'
  },
  caseRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    flexWrap: 'wrap' as const,
    marginBottom: '8px'
  },
  caseType: {
    fontSize: '14px',
    color: '#111827',
    fontWeight: '500'
  },
  caseStatus: {
    fontSize: '11px',
    padding: '2px 8px',
    borderRadius: '20px',
    fontWeight: '500'
  },
  caseButtons: {
    display: 'flex',
    gap: '6px',
    marginLeft: 'auto'
  },
  secondaryButton: {
    padding: '4px 10px',
    backgroundColor: '#eff6ff',
    color: '#2563eb',
    border: '1px solid #bfdbfe',
    borderRadius: '6px',
    fontSize: '12px',
    cursor: 'pointer'
  },
  noCases: {
    fontSize: '13px',
    color: '#9ca3af',
    marginTop: '12px',
    fontStyle: 'italic'
  },
  inviteBox: {
    marginTop: '16px',
    backgroundColor: '#eff6ff',
    padding: '16px',
    borderRadius: '8px',
    textAlign: 'center' as const,
    border: '1px solid #bfdbfe'
  },
  inviteLabel: {
    margin: '0 0 4px 0',
    fontSize: '13px',
    color: '#1e40af',
    fontWeight: '500' as const
  },
  inviteCode: {
    margin: '0 0 8px 0',
    fontSize: '24px',
    fontWeight: 'bold' as const,
    letterSpacing: '3px',
    color: '#1e3a8a'
  },
  copyButton: {
    padding: '6px 14px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '500' as const,
    cursor: 'pointer'
  }
}

export default PatientsPage
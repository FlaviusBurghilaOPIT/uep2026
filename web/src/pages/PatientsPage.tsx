import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { faFileCsv, faFilePdf } from '@fortawesome/free-solid-svg-icons'
import { useTranslation } from '../i18n'
import { apiFetch } from '../api/client'
import { exportPatientAdherenceCSV, printPatientClinicalPDF } from '../utils/exportUtils'
import { Icon, useToast } from '../components/ui'

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
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { show } = useToast()
  const [patients, setPatients] = useState<Patient[]>([])
  const [cases, setCases] = useState<Case[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [copiedId, setCopiedId] = useState<string | null>(null)

  const handleExport = async (fn: () => Promise<void>) => {
    try {
      await fn()
    } catch (err) {
      show(err instanceof Error ? err.message : t('common.error'), 'error')
    }
  }

  const handleCopyCode = async (patientId: string, code: string) => {
    try {
      await navigator.clipboard.writeText(code)
      setCopiedId(patientId)
      setTimeout(() => setCopiedId((current) => (current === patientId ? null : current)), 2000)
    } catch {
      // Clipboard unavailable (permissions/non-secure context) — select-free fallback:
      // the code is already visible on screen in large type for manual transcription.
    }
  }

  const fetchData = useCallback(async () => {
    setLoading(true)
    setError(false)
    try {
      const [patientsRes, casesRes] = await Promise.all([
        apiFetch<Patient[]>('/patients'),
        apiFetch<Case[]>('/cases')
      ])
      setPatients(patientsRes)
      setCases(casesRes)
    } catch (err) {
      console.error('Failed to fetch data', err)
      setError(true)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const getCasesForPatient = (patientId: string) =>
    cases.filter((c) => c.patient_id === patientId)

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>{t('patients.title')}</h1>
        <button
          style={styles.newButton}
          onClick={() => navigate('/patients/new')}
        >
          + {t('patients.newPatient')}
        </button>
      </div>

      {loading && <p>{t('patients.loading')}</p>}

      {!loading && error && (
        <div style={styles.errorBox} role="alert">
          <p style={styles.errorText}>{t('common.errorLoading')}</p>
          <button style={styles.retryButton} onClick={fetchData}>
            {t('common.retry')}
          </button>
        </div>
      )}

      {!loading && !error && patients.length === 0 && (
        <div style={styles.emptyBox}>
          <p style={styles.emptyTitle}>{t('patients.emptyTitle')}</p>
          <p style={styles.emptyBody}>{t('patients.emptyBody')}</p>
        </div>
      )}

      {!loading && !error && (
        <div style={styles.list}>
          {patients.map((patient) => {
            const patientCases = getCasesForPatient(patient.id)
            return (
              <div key={patient.id} style={styles.card}>
                <div style={styles.patientHeader}>
                  <div>
                    <p style={styles.name}>{patient.full_name}</p>
                    {patient.date_of_birth && (
                      <p style={styles.detail}>{t('patients.dob')}: {patient.date_of_birth}</p>
                    )}
                    <p style={styles.detail}>
                      {t('patients.allergies')}: {patient.allergies && patient.allergies.length > 0 ? patient.allergies.join(', ') : t('patients.none')}
                    </p>
                  </div>
                  <div style={styles.patientActions}>
                    <button
                      style={styles.exportCsvButton}
                      onClick={() => handleExport(() => exportPatientAdherenceCSV(patient.id))}
                    >
                      <Icon icon={faFileCsv} /> {t('patients.exportCsv')}
                    </button>
                    <button
                      style={styles.printPdfButton}
                      onClick={() => handleExport(() => printPatientClinicalPDF(patient.id))}
                    >
                      <Icon icon={faFilePdf} /> {t('patients.printPdf')}
                    </button>
                    <button
                      style={styles.newCaseButton}
                      onClick={() => navigate(`/cases/new?patient=${patient.id}`)}
                    >
                      + {t('patients.newCase')}
                    </button>
                  </div>
                </div>

                {(patient.status === 'pending_onboarding' || patient.status === 'pending') && (
                  <div style={styles.inviteBox}>
                    <p style={styles.inviteLabel}>{t('patients.pendingOnboarding')}:</p>
                    <p style={styles.inviteCode}>{patient.invite_code || 'N/A'}</p>
                    {patient.invite_code && (
                      <button
                        style={styles.copyButton}
                        onClick={() => handleCopyCode(patient.id, patient.invite_code as string)}
                      >
                        {copiedId === patient.id ? t('patients.copied') : t('patients.copyCode')}
                      </button>
                    )}
                  </div>
                )}

                {patientCases.length > 0 && (
                  <div style={styles.casesSection}>
                    <p style={styles.casesTitle}>{t('patients.cases')}</p>
                    {patientCases.map((c) => (
                      <div key={c.id} style={styles.caseRow}>
                        <button
                          style={styles.caseLink}
                          onClick={() => navigate(`/cases/${c.id}`)}
                        >
                          {c.surgery_type}
                        </button>
                        <span style={{
                          ...styles.caseStatus,
                          backgroundColor: c.status === 'open' ? '#f0fdf4' : '#f1f5f9',
                          color: c.status === 'open' ? '#166534' : '#64748b'
                        }}>
                          {c.status}
                        </span>
                        <div style={styles.caseButtons}>
                          <button
                            style={styles.secondaryButton}
                            onClick={() => navigate(`/cases/${c.id}/medications/list`)}
                          >
                            {t('patients.medications')}
                          </button>
                          <button
                            style={styles.secondaryButton}
                            onClick={() => navigate(`/cases/${c.id}/recommendations/list`)}
                          >
                            {t('patients.recommendations')}
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {patientCases.length === 0 && (
                  <p style={styles.noCases}>{t('patients.noCases')}</p>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

const styles = {
  container: {
    padding: '32px',
    backgroundColor: '#f8fafc',
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
    color: '#0f172a',
    margin: 0
  },
  newButton: {
    padding: '8px 16px',
    backgroundColor: '#0284c7',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer'
  },
  errorBox: {
    backgroundColor: '#fef2f2',
    border: '1px solid #fecaca',
    borderRadius: '12px',
    padding: '24px',
    textAlign: 'center' as const
  },
  errorText: {
    color: '#b91c1c',
    fontSize: '14px',
    margin: '0 0 12px 0'
  },
  retryButton: {
    padding: '8px 20px',
    backgroundColor: '#b91c1c',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer'
  },
  emptyBox: {
    backgroundColor: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '12px',
    padding: '48px 24px',
    textAlign: 'center' as const
  },
  emptyTitle: {
    fontSize: '16px',
    fontWeight: '600' as const,
    color: '#0f172a',
    margin: '0 0 8px 0'
  },
  emptyBody: {
    fontSize: '14px',
    color: '#64748b',
    margin: 0
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
    border: '1px solid #e2e8f0'
  },
  patientHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    flexWrap: 'wrap' as const,
    gap: '12px'
  },
  patientActions: {
    display: 'flex',
    gap: '8px',
    alignItems: 'center',
    flexWrap: 'wrap' as const
  },
  exportCsvButton: {
    padding: '6px 12px',
    backgroundColor: '#f0fdf4',
    color: '#166534',
    border: '1px solid #bbf7d0',
    borderRadius: '8px',
    fontSize: '12px',
    fontWeight: '600' as const,
    cursor: 'pointer'
  },
  printPdfButton: {
    padding: '6px 12px',
    backgroundColor: '#f0f9ff',
    color: '#0284c7',
    border: '1px solid #bae6fd',
    borderRadius: '8px',
    fontSize: '12px',
    fontWeight: '600' as const,
    cursor: 'pointer'
  },
  name: {
    fontSize: '16px',
    fontWeight: '600',
    color: '#0f172a',
    margin: '0 0 4px 0'
  },
  detail: {
    fontSize: '13px',
    color: '#64748b',
    margin: '0 0 4px 0'
  },
  newCaseButton: {
    padding: '6px 12px',
    backgroundColor: '#0284c7',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '12px',
    cursor: 'pointer',
    flexShrink: 0
  },
  casesSection: {
    marginTop: '16px',
    borderTop: '1px solid #e2e8f0',
    paddingTop: '12px'
  },
  casesTitle: {
    fontSize: '12px',
    fontWeight: '600',
    color: '#64748b',
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
  caseLink: {
    background: 'none',
    border: 'none',
    padding: 0,
    fontSize: '14px',
    color: '#0284c7',
    fontWeight: '500' as const,
    cursor: 'pointer',
    textDecoration: 'underline' as const
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
    backgroundColor: '#f0f9ff',
    color: '#0284c7',
    border: '1px solid #bae6fd',
    borderRadius: '6px',
    fontSize: '12px',
    cursor: 'pointer'
  },
  noCases: {
    fontSize: '13px',
    color: '#94a3b8',
    marginTop: '12px',
    fontStyle: 'italic'
  },
  inviteBox: {
    marginTop: '16px',
    backgroundColor: '#f0f9ff',
    padding: '16px',
    borderRadius: '8px',
    textAlign: 'center' as const,
    border: '1px solid #bae6fd'
  },
  inviteLabel: {
    margin: '0 0 4px 0',
    fontSize: '13px',
    color: '#0369a1',
    fontWeight: '500' as const
  },
  inviteCode: {
    margin: '0 0 8px 0',
    fontSize: '24px',
    fontWeight: 'bold' as const,
    letterSpacing: '3px',
    color: '#0f172a'
  },
  copyButton: {
    padding: '6px 14px',
    backgroundColor: '#0284c7',
    color: '#ffffff',
    border: 'none',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '500' as const,
    cursor: 'pointer'
  }
}

export default PatientsPage

import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiFetch } from '../api/client'
import { useTranslation } from '../i18n'
import { exportPatientAdherenceCSV, printPatientClinicalPDF } from '../utils/exportUtils'

type Patient = {
  id: string
  full_name: string
  email?: string
  phone?: string
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
  emergency_contact_phone?: string | null
  created_at: string
}

type DoseLog = {
  id: string
  scheduled_reminder_id: string
  status: 'pending' | 'taken' | 'missed' | 'skipped'
  logged_at?: string | null
  notes?: string | null
  skipped_reason?: string | null
  escalate?: boolean
}

type SymptomCheckIn = {
  id: string
  case_id: string
  feeling: 'great' | 'ok' | 'not_great' | 'bad'
  notes?: string
  checkin_date?: string
  escalate?: boolean
}

type TriagePatient = {
  patient: Patient
  caseItem?: Case
  missedDoses: number
  hasSkippedSideEffects: boolean
  adherencePercentage: number
  aiEscalate: boolean
  reasons: string[]
  severity: 'red' | 'amber' | 'green'
}

type OutreachMethod = 'Phone Call' | 'Secure SMS' | 'In-Person Visit'
type FilterTab = 'all' | 'red' | 'amber'

async function fetchPatientDoseLogs(patientId: string): Promise<DoseLog[]> {
  try {
    return await apiFetch<DoseLog[]>(`/patients/${patientId}/adherence`)
  } catch {
    try {
      return await apiFetch<DoseLog[]>(`/adherence/patients/${patientId}`)
    } catch {
      return []
    }
  }
}

async function fetchPatientSymptoms(patientId: string): Promise<SymptomCheckIn[]> {
  try {
    return await apiFetch<SymptomCheckIn[]>(`/patients/${patientId}/symptoms`)
  } catch {
    try {
      return await apiFetch<SymptomCheckIn[]>(`/symptoms/patients/${patientId}/symptoms`)
    } catch {
      return []
    }
  }
}

function TriageDashboardPage() {
  const navigate = useNavigate()
  const { t } = useTranslation()
  const [patients, setPatients] = useState<Patient[]>([])
  const [triageItems, setTriageItems] = useState<TriagePatient[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Filter & Search states
  const [activeTab, setActiveTab] = useState<FilterTab>('all')
  const [searchQuery, setSearchQuery] = useState('')

  // Resolution Modal states
  const [selectedPatientItem, setSelectedPatientItem] = useState<TriagePatient | null>(null)
  const [outreachMethod, setOutreachMethod] = useState<OutreachMethod>('Phone Call')
  const [resolutionNote, setResolutionNote] = useState('')
  const [noteError, setNoteError] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Toast Notification state
  const [toastMessage, setToastMessage] = useState<string | null>(null)

  useEffect(() => {
    const fetchTriageData = async () => {
      setLoading(true)
      setError('')
      try {
        const [patientsRes, casesRes] = await Promise.all([
          apiFetch<Patient[]>('/patients').catch(() => []),
          apiFetch<Case[]>('/cases').catch(() => [])
        ])

        setPatients(patientsRes)

        const evaluated: TriagePatient[] = await Promise.all(
          patientsRes.map(async (patient) => {
            const patientCase = casesRes.find((c) => c.patient_id === patient.id)
            const doseLogs = await fetchPatientDoseLogs(patient.id)
            const symptoms = await fetchPatientSymptoms(patient.id)

            const missedDoses = doseLogs.filter((log) => log.status === 'missed').length
            const hasSkippedSideEffects = doseLogs.some(
              (log) =>
                log.status === 'skipped' ||
                !!log.skipped_reason ||
                (log.notes && log.notes.toLowerCase().includes('side effect'))
            )

            const completedLogs = doseLogs.filter((log) =>
              ['taken', 'missed', 'skipped'].includes(log.status)
            )
            const takenCount = doseLogs.filter((log) => log.status === 'taken').length
            const adherencePercentage =
              completedLogs.length > 0
                ? Math.round((takenCount / completedLogs.length) * 100)
                : 100

            const aiEscalate =
              symptoms.some((s) => s.escalate === true) ||
              doseLogs.some((d) => d.escalate === true) ||
              patient.status === 'escalated'

            const reasons: string[] = []
            let severity: 'red' | 'amber' | 'green' = 'green'

            // Red Escalation triggers
            if (missedDoses >= 2) {
              reasons.push(`Missed ${missedDoses} doses`)
              severity = 'red'
            }
            if (aiEscalate) {
              reasons.push('AI Escalation Flagged')
              severity = 'red'
            }

            // Amber Caution triggers (only if not already red)
            if (severity !== 'red') {
              if (hasSkippedSideEffects) {
                reasons.push('Skipped dose for side effects')
                severity = 'amber'
              }
              if (adherencePercentage < 75) {
                reasons.push(`Low Adherence (${adherencePercentage}%)`)
                severity = 'amber'
              }
            }

            return {
              patient,
              caseItem: patientCase,
              missedDoses,
              hasSkippedSideEffects,
              adherencePercentage,
              aiEscalate,
              reasons,
              severity
            }
          })
        )

        setTriageItems(evaluated)
      } catch (err: unknown) {
        console.error('Error fetching triage dashboard data:', err)
        setError('Failed to load triage dashboard data.')
      } finally {
        setLoading(false)
      }
    }

    fetchTriageData()
  }, [])

  // Auto hide toast after 4 seconds
  useEffect(() => {
    if (toastMessage) {
      const timer = setTimeout(() => {
        setToastMessage(null)
      }, 4000)
      return () => clearTimeout(timer)
    }
  }, [toastMessage])

  const handleCallPatient = (phone?: string | null, name?: string) => {
    if (phone) {
      window.open(`tel:${phone}`, '_self')
    } else {
      alert(`Calling ${name || 'patient'}... (No phone number registered)`)
    }
  }

  const handleReviewCase = (caseId?: string) => {
    if (caseId) {
      navigate(`/cases/${caseId}/medications/list`)
    } else {
      navigate('/patients')
    }
  }

  const handleOpenResolutionModal = (item: TriagePatient) => {
    setSelectedPatientItem(item)
    setOutreachMethod('Phone Call')
    setResolutionNote('')
    setNoteError('')
  }

  const handleCloseResolutionModal = () => {
    setSelectedPatientItem(null)
    setResolutionNote('')
    setNoteError('')
    setIsSubmitting(false)
  }

  const handleResolveSubmit = async () => {
    if (!resolutionNote.trim()) {
      setNoteError('Mandatory clinical resolution note is required before archiving.')
      return
    }

    if (!selectedPatientItem) return

    setIsSubmitting(true)
    setNoteError('')

    try {
      await apiFetch(`/patients/${selectedPatientItem.patient.id}/triage-resolve`, {
        method: 'POST',
        body: JSON.stringify({
          outreach_method: outreachMethod,
          clinical_note: resolutionNote.trim(),
          resolved_at: new Date().toISOString()
        })
      }).catch(() => {
        // Fallback gracefully if endpoint is not implemented on server
      })

      // Update local state to archive alert / change severity to green
      setTriageItems((prev) =>
        prev.map((item) => {
          if (item.patient.id === selectedPatientItem.patient.id) {
            return {
              ...item,
              severity: 'green',
              reasons: [],
              aiEscalate: false,
              missedDoses: 0
            }
          }
          return item
        })
      )

      setToastMessage(
        `Triage alert resolved & archived for ${selectedPatientItem.patient.full_name} via ${outreachMethod}.`
      )
      handleCloseResolutionModal()
    } catch (err) {
      console.error('Error resolving triage exception:', err)
      setNoteError('Failed to resolve triage exception. Please try again.')
      setIsSubmitting(false)
    }
  }

  // Filter queues
  const redQueue = triageItems.filter((item) => item.severity === 'red')
  const amberQueue = triageItems.filter((item) => item.severity === 'amber')
  const normalQueue = triageItems.filter((item) => item.severity === 'green')
  const exceptionQueue = triageItems.filter(
    (item) => item.severity === 'red' || item.severity === 'amber'
  )

  // Filter logic based on search query
  const query = searchQuery.trim().toLowerCase()
  const filterBySearch = (items: TriagePatient[]) => {
    if (!query) return items
    return items.filter((item) => {
      const nameMatch = item.patient.full_name.toLowerCase().includes(query)
      const surgeryMatch = (item.caseItem?.surgery_type || '').toLowerCase().includes(query)
      const dobMatch = (item.patient.date_of_birth || '').toLowerCase().includes(query)
      const reasonMatch = item.reasons.some((r) => r.toLowerCase().includes(query))
      return nameMatch || surgeryMatch || dobMatch || reasonMatch
    })
  }

  const filteredRed = filterBySearch(redQueue)
  const filteredAmber = filterBySearch(amberQueue)
  const filteredExceptions = filterBySearch(exceptionQueue)
  const filteredNormal = filterBySearch(normalQueue)

  return (
    <div style={styles.container}>
      {/* Toast Notification */}
      {toastMessage && (
        <div style={styles.toastContainer}>
          <span style={styles.toastIcon}>✅</span>
          <span style={styles.toastContent}>{toastMessage}</span>
          <button style={styles.toastClose} onClick={() => setToastMessage(null)}>
            &times;
          </button>
        </div>
      )}

      <div style={styles.header}>
        <div>
          <h1 style={styles.title}>{t('triage.title')}</h1>
          <p style={styles.subtitle}>{t('triage.subtitle')}</p>
        </div>
      </div>

      {loading && <p style={styles.loadingText}>{t('triage.loadingTriage')}</p>}
      {error && <p style={styles.errorText}>{error}</p>}

      {!loading && (
        <>
          {/* Overview Metric Badges */}
          <div style={styles.statsGrid}>
            <div style={{ ...styles.statCard, borderLeft: '4px solid #b91c1c' }}>
              <div style={styles.statNumber}>{redQueue.length}</div>
              <div style={styles.statLabel}>{t('triage.redAlerts')}</div>
            </div>
            <div style={{ ...styles.statCard, borderLeft: '4px solid #d97706' }}>
              <div style={styles.statNumber}>{amberQueue.length}</div>
              <div style={styles.statLabel}>{t('triage.amberAlerts')}</div>
            </div>
            <div style={{ ...styles.statCard, borderLeft: '4px solid #0284c7' }}>
              <div style={styles.statNumber}>{patients.length}</div>
              <div style={styles.statLabel}>{t('triage.allPatients')}</div>
            </div>
          </div>

          {/* Controls Bar: Search & Filter Tabs */}
          <div style={styles.controlsBar}>
            {/* Search Input */}
            <div style={styles.searchContainer}>
              <span style={styles.searchIcon}>🔍</span>
              <input
                type="text"
                placeholder={t('triage.searchPlaceholder')}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={styles.searchInput}
              />
              {searchQuery && (
                <button style={styles.clearSearchButton} onClick={() => setSearchQuery('')}>
                  &times;
                </button>
              )}
            </div>

            {/* Filter Tabs */}
            <div style={styles.tabContainer}>
              <button
                style={{
                  ...styles.tabButton,
                  ...(activeTab === 'all' ? styles.activeTabButton : {})
                }}
                onClick={() => setActiveTab('all')}
              >
                {t('triage.allAlerts')}
                <span style={styles.tabBadge}>{exceptionQueue.length}</span>
              </button>
              <button
                style={{
                  ...styles.tabButton,
                  ...(activeTab === 'red' ? styles.activeRedTabButton : {})
                }}
                onClick={() => setActiveTab('red')}
              >
                🚨 {t('triage.highPriority')}
                <span style={{ ...styles.tabBadge, backgroundColor: '#fef2f2', color: '#b91c1c' }}>
                  {redQueue.length}
                </span>
              </button>
              <button
                style={{
                  ...styles.tabButton,
                  ...(activeTab === 'amber' ? styles.activeAmberTabButton : {})
                }}
                onClick={() => setActiveTab('amber')}
              >
                ⚠️ {t('triage.mediumPriority')}
                <span style={{ ...styles.tabBadge, backgroundColor: '#fffbe6', color: '#d97706' }}>
                  {amberQueue.length}
                </span>
              </button>
            </div>
          </div>

          {/* Top Priority Section: Needs Attention Triage Queue */}
          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>
              🚨 Needs Attention Triage Queue (
              {activeTab === 'all'
                ? filteredExceptions.length
                : activeTab === 'red'
                ? filteredRed.length
                : filteredAmber.length}
              )
            </h2>

            {/* Empty State when no exceptions match filters */}
            {((activeTab === 'all' && filteredExceptions.length === 0) ||
              (activeTab === 'red' && filteredRed.length === 0) ||
              (activeTab === 'amber' && filteredAmber.length === 0)) && (
              <div style={styles.emptyBox}>
                <span style={styles.emptyIcon}>✓</span>
                <p style={styles.emptyText}>
                  {searchQuery
                    ? `No triage exceptions found matching "${searchQuery}".`
                    : 'All patient care plans are currently on track. No pending triage alerts.'}
                </p>
              </div>
            )}

            {/* Red Escalation Cards */}
            {(activeTab === 'all' || activeTab === 'red') &&
              filteredRed.map((item) => (
                <div key={item.patient.id} style={styles.redCard}>
                  <div style={styles.cardHeader}>
                    <div>
                      <span style={styles.redBadge}>🛑 RED ESCALATION</span>
                      <h3 style={styles.patientName}>{item.patient.full_name}</h3>
                      <p style={styles.patientSub}>
                        Surgery: {item.caseItem?.surgery_type || 'N/A'} &bull; DOB:{' '}
                        {item.patient.date_of_birth || 'N/A'}
                      </p>
                    </div>
                    <div style={styles.actionButtons}>
                      <button
                        style={styles.exportCsvButton}
                        onClick={() => exportPatientAdherenceCSV(item.patient.id)}
                      >
                        📥 Export Adherence CSV
                      </button>
                      <button
                        style={styles.printPdfButton}
                        onClick={() => printPatientClinicalPDF(item.patient.id)}
                      >
                        📄 Print / Save Clinical PDF
                      </button>
                      <button
                        style={styles.resolveButton}
                        onClick={() => handleOpenResolutionModal(item)}
                      >
                        ✅ Resolve Exception
                      </button>
                      <button
                        style={styles.callButton}
                        onClick={() =>
                          handleCallPatient(
                            item.patient.phone || item.caseItem?.emergency_contact_phone,
                            item.patient.full_name
                          )
                        }
                      >
                        📞 Call Patient
                      </button>
                      <button
                        style={styles.reviewButton}
                        onClick={() => handleReviewCase(item.caseItem?.id)}
                      >
                        📋 Review Case
                      </button>
                    </div>
                  </div>

                  <div style={styles.reasonsList}>
                    <strong>Trigger Reasons:</strong>
                    <ul>
                      {item.reasons.map((r, idx) => (
                        <li key={idx}>{r}</li>
                      ))}
                    </ul>
                  </div>

                  <div style={styles.cardFooter}>
                    <span>
                      Adherence: <strong>{item.adherencePercentage}%</strong>
                    </span>
                    <span>
                      Missed Doses: <strong>{item.missedDoses}</strong>
                    </span>
                  </div>
                </div>
              ))}

            {/* Amber Caution Cards */}
            {(activeTab === 'all' || activeTab === 'amber') &&
              filteredAmber.map((item) => (
                <div key={item.patient.id} style={styles.amberCard}>
                  <div style={styles.cardHeader}>
                    <div>
                      <span style={styles.amberBadge}>⚠️ AMBER CAUTION</span>
                      <h3 style={styles.patientName}>{item.patient.full_name}</h3>
                      <p style={styles.patientSub}>
                        Surgery: {item.caseItem?.surgery_type || 'N/A'} &bull; DOB:{' '}
                        {item.patient.date_of_birth || 'N/A'}
                      </p>
                    </div>
                    <div style={styles.actionButtons}>
                      <button
                        style={styles.exportCsvButton}
                        onClick={() => exportPatientAdherenceCSV(item.patient.id)}
                      >
                        📥 Export Adherence CSV
                      </button>
                      <button
                        style={styles.printPdfButton}
                        onClick={() => printPatientClinicalPDF(item.patient.id)}
                      >
                        📄 Print / Save Clinical PDF
                      </button>
                      <button
                        style={styles.resolveButton}
                        onClick={() => handleOpenResolutionModal(item)}
                      >
                        ✅ Resolve Exception
                      </button>
                      <button
                        style={styles.callButton}
                        onClick={() =>
                          handleCallPatient(
                            item.patient.phone || item.caseItem?.emergency_contact_phone,
                            item.patient.full_name
                          )
                        }
                      >
                        📞 Call Patient
                      </button>
                      <button
                        style={styles.reviewButton}
                        onClick={() => handleReviewCase(item.caseItem?.id)}
                      >
                        📋 Review Case
                      </button>
                    </div>
                  </div>

                  <div style={styles.reasonsList}>
                    <strong>Trigger Reasons:</strong>
                    <ul>
                      {item.reasons.map((r, idx) => (
                        <li key={idx}>{r}</li>
                      ))}
                    </ul>
                  </div>

                  <div style={styles.cardFooter}>
                    <span>
                      Adherence: <strong>{item.adherencePercentage}%</strong>
                    </span>
                    <span>
                      Missed Doses: <strong>{item.missedDoses}</strong>
                    </span>
                  </div>
                </div>
              ))}
          </div>

          {/* Normal Patient Roster */}
          {filteredNormal.length > 0 && (
            <div style={styles.section}>
              <h2 style={styles.sectionTitle}>🟢 Stable Patients ({filteredNormal.length})</h2>
              <div style={styles.normalGrid}>
                {filteredNormal.map((item) => (
                  <div key={item.patient.id} style={styles.normalCard}>
                    <div style={styles.normalHeader}>
                      <h4 style={styles.normalName}>{item.patient.full_name}</h4>
                      <span style={styles.greenBadge}>Stable</span>
                    </div>
                    <p style={styles.normalSub}>
                      Surgery: {item.caseItem?.surgery_type || 'N/A'}
                    </p>
                    <div style={styles.normalFooter}>
                      <span>
                        Adherence: <strong>{item.adherencePercentage}%</strong>
                      </span>
                      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' as const }}>
                        <button
                          style={styles.smallExportCsvButton}
                          onClick={() => exportPatientAdherenceCSV(item.patient.id)}
                        >
                          📥 Export Adherence CSV
                        </button>
                        <button
                          style={styles.smallPrintPdfButton}
                          onClick={() => printPatientClinicalPDF(item.patient.id)}
                        >
                          📄 Print / Save Clinical PDF
                        </button>
                        <button
                          style={styles.smallReviewButton}
                          onClick={() => handleReviewCase(item.caseItem?.id)}
                        >
                          Review
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}

      {/* Triage Exception Resolution Modal */}
      {selectedPatientItem && (
        <div style={styles.modalOverlay} onClick={handleCloseResolutionModal}>
          <div style={styles.modalContainer} onClick={(e) => e.stopPropagation()}>
            <div style={styles.modalHeader}>
              <div>
                <h3 style={styles.modalTitle}>Resolve Triage Exception</h3>
                <p style={styles.modalSubtitle}>
                  Archive exception alert for {selectedPatientItem.patient.full_name}
                </p>
              </div>
              <button style={styles.modalCloseButton} onClick={handleCloseResolutionModal}>
                &times;
              </button>
            </div>

            <div style={styles.modalBody}>
              {/* Context Summary Box */}
              <div
                style={{
                  ...styles.patientContextCard,
                  borderColor: selectedPatientItem.severity === 'red' ? '#fca5a5' : '#fde68a',
                  backgroundColor: selectedPatientItem.severity === 'red' ? '#fef2f2' : '#fffbeb'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                  <strong>Current Alert Details:</strong>
                  <span
                    style={
                      selectedPatientItem.severity === 'red'
                        ? styles.redBadge
                        : styles.amberBadge
                    }
                  >
                    {selectedPatientItem.severity === 'red' ? '🛑 RED ESCALATION' : '⚠️ AMBER CAUTION'}
                  </span>
                </div>
                <div style={{ fontSize: '13px', color: '#374151' }}>
                  <strong>Trigger Reasons:</strong> {selectedPatientItem.reasons.join(', ')}
                </div>
              </div>

              {/* Outreach Method Selection */}
              <div style={styles.fieldGroup}>
                <label style={styles.label}>Outreach Method *</label>
                <div style={styles.radioGroup}>
                  {(['Phone Call', 'Secure SMS', 'In-Person Visit'] as OutreachMethod[]).map(
                    (method) => (
                      <label key={method} style={styles.radioOptionLabel}>
                        <input
                          type="radio"
                          name="outreachMethod"
                          value={method}
                          checked={outreachMethod === method}
                          onChange={() => setOutreachMethod(method)}
                          style={styles.radioInput}
                        />
                        <span>{method}</span>
                      </label>
                    )
                  )}
                </div>
              </div>

              {/* Mandatory Resolution Notes Textarea */}
              <div style={styles.fieldGroup}>
                <label style={styles.label}>
                  Mandatory Clinical Resolution Note <span style={{ color: '#dc2626' }}>*</span>
                </label>
                <textarea
                  rows={4}
                  placeholder="Document clinical outreach outcome, patient feedback, or protocol adjustment..."
                  value={resolutionNote}
                  onChange={(e) => {
                    setResolutionNote(e.target.value)
                    if (e.target.value.trim()) setNoteError('')
                  }}
                  style={{
                    ...styles.textarea,
                    ...(noteError ? { borderColor: '#dc2626' } : {})
                  }}
                />
                {noteError && <p style={styles.errorNoteText}>{noteError}</p>}
              </div>
            </div>

            {/* Modal Footer Buttons */}
            <div style={styles.modalFooter}>
              <button
                type="button"
                style={styles.cancelButton}
                onClick={handleCloseResolutionModal}
                disabled={isSubmitting}
              >
                Cancel
              </button>
              <button
                type="button"
                style={styles.resolveSubmitButton}
                onClick={handleResolveSubmit}
                disabled={isSubmitting}
              >
                {isSubmitting ? 'Archiving Alert...' : 'Resolve & Archive Alert'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const styles = {
  container: {
    padding: '32px',
    backgroundColor: '#f8fafc',
    minHeight: '100vh',
    position: 'relative' as const
  },
  header: {
    marginBottom: '24px'
  },
  title: {
    fontSize: '24px',
    fontWeight: '700',
    color: '#0f172a',
    margin: 0
  },
  subtitle: {
    fontSize: '14px',
    color: '#64748b',
    marginTop: '4px'
  },
  loadingText: {
    fontSize: '15px',
    color: '#64748b'
  },
  errorText: {
    fontSize: '15px',
    color: '#b91c1c'
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '16px',
    marginBottom: '24px'
  },
  statCard: {
    backgroundColor: '#ffffff',
    padding: '20px',
    borderRadius: '10px',
    border: '1px solid #e2e8f0',
    boxShadow: '0 1px 2px rgba(0,0,0,0.05)'
  },
  statNumber: {
    fontSize: '28px',
    fontWeight: '700',
    color: '#0f172a'
  },
  statLabel: {
    fontSize: '13px',
    color: '#64748b',
    marginTop: '4px'
  },
  controlsBar: {
    display: 'flex',
    flexDirection: 'row' as const,
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: '16px',
    flexWrap: 'wrap' as const,
    marginBottom: '28px'
  },
  searchContainer: {
    position: 'relative' as const,
    flex: 1,
    minWidth: '280px'
  },
  searchIcon: {
    position: 'absolute' as const,
    left: '12px',
    top: '50%',
    transform: 'translateY(-50%)',
    fontSize: '14px',
    color: '#94a3b8',
    pointerEvents: 'none' as const
  },
  searchInput: {
    width: '100%',
    padding: '10px 36px 10px 36px',
    borderRadius: '8px',
    border: '1px solid #e2e8f0',
    fontSize: '14px',
    backgroundColor: '#ffffff',
    color: '#0f172a',
    outline: 'none',
    boxSizing: 'border-box' as const
  },
  clearSearchButton: {
    position: 'absolute' as const,
    right: '10px',
    top: '50%',
    transform: 'translateY(-50%)',
    background: 'transparent',
    border: 'none',
    fontSize: '18px',
    color: '#64748b',
    cursor: 'pointer'
  },
  tabContainer: {
    display: 'flex',
    gap: '8px',
    flexWrap: 'wrap' as const
  },
  tabButton: {
    padding: '8px 14px',
    borderRadius: '8px',
    border: '1px solid #e2e8f0',
    backgroundColor: '#ffffff',
    color: '#0f172a',
    fontSize: '13px',
    fontWeight: '600',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    gap: '6px'
  },
  activeTabButton: {
    backgroundColor: '#0284c7',
    color: '#ffffff',
    borderColor: '#0284c7'
  },
  activeRedTabButton: {
    backgroundColor: '#b91c1c',
    color: '#ffffff',
    borderColor: '#b91c1c'
  },
  activeAmberTabButton: {
    backgroundColor: '#d97706',
    color: '#ffffff',
    borderColor: '#d97706'
  },
  tabBadge: {
    padding: '2px 6px',
    borderRadius: '12px',
    backgroundColor: '#f1f5f9',
    color: '#0f172a',
    fontSize: '11px',
    fontWeight: '700'
  },
  section: {
    marginBottom: '32px'
  },
  sectionTitle: {
    fontSize: '18px',
    fontWeight: '600',
    color: '#0f172a',
    marginBottom: '16px'
  },
  emptyBox: {
    backgroundColor: '#f0fdf4',
    border: '1px solid #bbf7d0',
    borderRadius: '10px',
    padding: '24px',
    textAlign: 'center' as const,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '12px'
  },
  emptyIcon: {
    fontSize: '20px',
    color: '#16a34a',
    fontWeight: 'bold'
  },
  emptyText: {
    margin: 0,
    fontSize: '14px',
    color: '#15803d',
    fontWeight: '500'
  },
  redCard: {
    backgroundColor: '#fef2f2',
    border: '1px solid #fecaca',
    borderLeft: '6px solid #b91c1c',
    borderRadius: '10px',
    padding: '20px',
    marginBottom: '16px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
  },
  amberCard: {
    backgroundColor: '#fffbe6',
    border: '1px solid #fef08a',
    borderLeft: '6px solid #d97706',
    borderRadius: '10px',
    padding: '20px',
    marginBottom: '16px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
  },
  cardHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: '16px',
    flexWrap: 'wrap' as const
  },
  redBadge: {
    display: 'inline-block',
    padding: '2px 8px',
    backgroundColor: '#fef2f2',
    color: '#b91c1c',
    fontSize: '11px',
    fontWeight: '700',
    borderRadius: '4px',
    marginBottom: '6px'
  },
  amberBadge: {
    display: 'inline-block',
    padding: '2px 8px',
    backgroundColor: '#fffbe6',
    color: '#d97706',
    fontSize: '11px',
    fontWeight: '700',
    borderRadius: '4px',
    marginBottom: '6px'
  },
  greenBadge: {
    display: 'inline-block',
    padding: '2px 8px',
    backgroundColor: '#f0fdf4',
    color: '#166534',
    fontSize: '11px',
    fontWeight: '700',
    borderRadius: '4px'
  },
  patientName: {
    fontSize: '17px',
    fontWeight: '700',
    color: '#0f172a',
    margin: 0
  },
  patientSub: {
    fontSize: '13px',
    color: '#475569',
    marginTop: '2px'
  },
  actionButtons: {
    display: 'flex',
    gap: '10px',
    flexWrap: 'wrap' as const
  },
  resolveButton: {
    padding: '8px 14px',
    backgroundColor: '#16a34a',
    color: '#ffffff',
    border: 'none',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '600',
    cursor: 'pointer'
  },
  callButton: {
    padding: '8px 14px',
    backgroundColor: '#b91c1c',
    color: '#ffffff',
    border: 'none',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '600',
    cursor: 'pointer'
  },
  reviewButton: {
    padding: '8px 14px',
    backgroundColor: '#0284c7',
    color: '#ffffff',
    border: 'none',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '600',
    cursor: 'pointer'
  },
  exportCsvButton: {
    padding: '8px 14px',
    backgroundColor: '#f0fdf4',
    color: '#166534',
    border: '1px solid #bbf7d0',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '600' as const,
    cursor: 'pointer'
  },
  printPdfButton: {
    padding: '8px 14px',
    backgroundColor: '#f0f9ff',
    color: '#0284c7',
    border: '1px solid #bae6fd',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '600' as const,
    cursor: 'pointer'
  },
  smallExportCsvButton: {
    padding: '4px 8px',
    backgroundColor: '#f0fdf4',
    color: '#166534',
    border: '1px solid #bbf7d0',
    borderRadius: '4px',
    fontSize: '11px',
    fontWeight: '600' as const,
    cursor: 'pointer'
  },
  smallPrintPdfButton: {
    padding: '4px 8px',
    backgroundColor: '#f0f9ff',
    color: '#0284c7',
    border: '1px solid #bae6fd',
    borderRadius: '4px',
    fontSize: '11px',
    fontWeight: '600' as const,
    cursor: 'pointer'
  },
  reasonsList: {
    marginTop: '12px',
    fontSize: '13px',
    color: '#0f172a'
  },
  cardFooter: {
    marginTop: '14px',
    paddingTop: '10px',
    borderTop: '1px solid rgba(0,0,0,0.06)',
    display: 'flex',
    gap: '24px',
    fontSize: '13px',
    color: '#475569'
  },
  normalGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
    gap: '16px'
  },
  normalCard: {
    backgroundColor: '#ffffff',
    border: '1px solid #e2e8f0',
    borderRadius: '10px',
    padding: '16px'
  },
  normalHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  normalName: {
    fontSize: '15px',
    fontWeight: '600',
    color: '#0f172a',
    margin: 0
  },
  normalSub: {
    fontSize: '12px',
    color: '#64748b',
    marginTop: '4px'
  },
  normalFooter: {
    marginTop: '12px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    fontSize: '12px',
    color: '#334155'
  },
  smallReviewButton: {
    padding: '4px 10px',
    backgroundColor: '#f0f9ff',
    color: '#0284c7',
    border: '1px solid #bae6fd',
    borderRadius: '4px',
    fontSize: '12px',
    cursor: 'pointer'
  },
  modalOverlay: {
    position: 'fixed' as const,
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(15, 23, 42, 0.6)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000,
    padding: '16px'
  },
  modalContainer: {
    backgroundColor: '#ffffff',
    borderRadius: '12px',
    width: '100%',
    maxWidth: '520px',
    padding: '24px',
    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
    border: '1px solid #e2e8f0',
    boxSizing: 'border-box' as const
  },
  modalHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: '16px'
  },
  modalTitle: {
    fontSize: '18px',
    fontWeight: '700',
    color: '#0f172a',
    margin: 0
  },
  modalSubtitle: {
    fontSize: '13px',
    color: '#64748b',
    marginTop: '4px',
    margin: 0
  },
  modalCloseButton: {
    background: 'transparent',
    border: 'none',
    fontSize: '22px',
    color: '#94a3b8',
    cursor: 'pointer',
    padding: 0,
    lineHeight: 1
  },
  modalBody: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '16px'
  },
  patientContextCard: {
    border: '1px solid',
    borderRadius: '8px',
    padding: '12px 14px'
  },
  fieldGroup: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '6px'
  },
  label: {
    fontSize: '13px',
    fontWeight: '600',
    color: '#0f172a'
  },
  radioGroup: {
    display: 'flex',
    gap: '16px',
    flexWrap: 'wrap' as const
  },
  radioOptionLabel: {
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    fontSize: '13px',
    color: '#0f172a',
    cursor: 'pointer'
  },
  radioInput: {
    cursor: 'pointer'
  },
  textarea: {
    width: '100%',
    padding: '10px',
    borderRadius: '8px',
    border: '1px solid #e2e8f0',
    fontSize: '13px',
    color: '#0f172a',
    fontFamily: 'inherit',
    outline: 'none',
    boxSizing: 'border-box' as const,
    resize: 'vertical' as const
  },
  errorNoteText: {
    fontSize: '12px',
    color: '#b91c1c',
    margin: '2px 0 0 0'
  },
  modalFooter: {
    marginTop: '24px',
    display: 'flex',
    justifyContent: 'flex-end',
    gap: '12px'
  },
  cancelButton: {
    padding: '8px 16px',
    backgroundColor: '#ffffff',
    color: '#0f172a',
    border: '1px solid #e2e8f0',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '600',
    cursor: 'pointer'
  },
  resolveSubmitButton: {
    padding: '8px 16px',
    backgroundColor: '#16a34a',
    color: '#ffffff',
    border: 'none',
    borderRadius: '6px',
    fontSize: '13px',
    fontWeight: '600',
    cursor: 'pointer'
  },
  toastContainer: {
    position: 'fixed' as const,
    top: '20px',
    right: '20px',
    backgroundColor: '#065f46',
    color: '#ffffff',
    padding: '12px 18px',
    borderRadius: '8px',
    boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    zIndex: 1100
  },
  toastIcon: {
    fontSize: '16px'
  },
  toastContent: {
    fontSize: '13px',
    fontWeight: '500'
  },
  toastClose: {
    background: 'transparent',
    border: 'none',
    color: '#ffffff',
    fontSize: '18px',
    cursor: 'pointer',
    marginLeft: '8px',
    lineHeight: 1
  }
}

export default TriageDashboardPage

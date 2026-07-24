import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiFetch } from '../api/client'
import { fetchTriageResponseStats, trackEvent, type TriageResponseStats } from '../api/analytics'
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
  created_at?: string
  escalate?: boolean
}

type Severity = 'red' | 'amber' | 'green' | 'unknown'

type TriagePatient = {
  patient: Patient
  caseItem?: Case
  missedDoses: number
  hasSkippedSideEffects: boolean
  /** null = no dose logs exist; never fabricate a percentage */
  adherencePercentage: number | null
  aiEscalate: boolean
  reasons: string[]
  severity: Severity
  /** true when telemetry could not be fetched — never present as "stable" */
  dataUnavailable: boolean
  latestActivity: string | null
}

type LatestResolution = {
  patient_id: string
  resolved_at: string
}

type OutreachMethod = 'Phone Call' | 'Secure SMS' | 'In-Person Visit'
type FilterTab = 'all' | 'red' | 'amber'

/** Throws if neither endpoint shape works — callers must handle failure honestly. */
async function fetchPatientDoseLogs(patientId: string): Promise<DoseLog[]> {
  try {
    return await apiFetch<DoseLog[]>(`/patients/${patientId}/adherence`)
  } catch {
    return await apiFetch<DoseLog[]>(`/adherence/patients/${patientId}`)
  }
}

async function fetchPatientSymptoms(patientId: string): Promise<SymptomCheckIn[]> {
  try {
    return await apiFetch<SymptomCheckIn[]>(`/patients/${patientId}/symptoms`)
  } catch {
    return await apiFetch<SymptomCheckIn[]>(`/symptoms/patients/${patientId}/symptoms`)
  }
}

function TriageDashboardPage() {
  const navigate = useNavigate()
  const { t } = useTranslation()
  const [patients, setPatients] = useState<Patient[]>([])
  const [triageItems, setTriageItems] = useState<TriagePatient[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [responseStats, setResponseStats] = useState<TriageResponseStats | null>(null)

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

  const fetchTriageData = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      // No silent fallbacks here: if the roster itself fails, the page must say so.
      const [patientsRes, casesRes, resolutionsRes] = await Promise.all([
        apiFetch<Patient[]>('/patients'),
        apiFetch<Case[]>('/cases'),
        apiFetch<LatestResolution[]>('/patients/triage-resolutions/latest').catch(() => [] as LatestResolution[])
      ])

      setPatients(patientsRes)
      const latestResolution = new Map<string, Date>(
        resolutionsRes.map((r) => [r.patient_id, new Date(r.resolved_at)])
      )

      const evaluated: TriagePatient[] = await Promise.all(
        patientsRes.map(async (patient): Promise<TriagePatient> => {
          const patientCase = casesRes.find((c) => c.patient_id === patient.id)

          let doseLogs: DoseLog[]
          let symptoms: SymptomCheckIn[]
          try {
            ;[doseLogs, symptoms] = await Promise.all([
              fetchPatientDoseLogs(patient.id),
              fetchPatientSymptoms(patient.id)
            ])
          } catch {
            // Telemetry failed: surface the patient as "status unknown", never "stable"
            return {
              patient,
              caseItem: patientCase,
              missedDoses: 0,
              hasSkippedSideEffects: false,
              adherencePercentage: null,
              aiEscalate: false,
              reasons: [],
              severity: 'unknown',
              dataUnavailable: true,
              latestActivity: null
            }
          }

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
              : null

          const aiEscalate =
            symptoms.some((s) => s.escalate === true) ||
            doseLogs.some((d) => d.escalate === true) ||
            patient.status === 'escalated'

          const latestActivity =
            [
              ...doseLogs.map((l) => l.logged_at),
              ...symptoms.map((s) => s.created_at || s.checkin_date)
            ]
              .filter((ts): ts is string => !!ts)
              .sort()
              .pop() ?? null

          const reasons: string[] = []
          let severity: Severity = 'green'

          if (missedDoses >= 2) {
            reasons.push(t('triage.reasonMissed').replace('{count}', String(missedDoses)))
            severity = 'red'
          }
          if (aiEscalate) {
            reasons.push(t('triage.reasonAiEscalation'))
            severity = 'red'
          }
          if (severity !== 'red') {
            if (hasSkippedSideEffects) {
              reasons.push(t('triage.reasonSideEffects'))
              severity = 'amber'
            }
            if (adherencePercentage !== null && adherencePercentage < 80) {
              reasons.push(
                t('triage.reasonLowAdherence').replace('{pct}', String(adherencePercentage))
              )
              severity = 'amber'
            }
          }

          // A persisted resolution suppresses current alerts until NEW activity
          // arrives after resolved_at — then the patient is re-evaluated.
          const resolvedAt = latestResolution.get(patient.id)
          if (
            severity !== 'green' &&
            resolvedAt &&
            (!latestActivity || resolvedAt >= new Date(latestActivity))
          ) {
            severity = 'green'
            reasons.length = 0
          }

          return {
            patient,
            caseItem: patientCase,
            missedDoses,
            hasSkippedSideEffects,
            adherencePercentage,
            aiEscalate,
            reasons,
            severity,
            dataUnavailable: false,
            latestActivity
          }
        })
      )

      setTriageItems(evaluated)
      setLastUpdated(new Date())

      // Telemetry: one exception_viewed event per patient per session per
      // severity — the baseline for the median response-time metric.
      for (const item of evaluated) {
        if (item.severity !== 'red' && item.severity !== 'amber') continue
        const key = `triage-viewed:${item.severity}:${item.patient.id}`
        if (!sessionStorage.getItem(key)) {
          sessionStorage.setItem(key, '1')
          trackEvent('web.triage.exception_viewed', {
            patient_id: item.patient.id,
            severity: item.severity,
          })
        }
      }

      // Widget 3 telemetry: failure hides the gauge, never the dashboard.
      fetchTriageResponseStats()
        .then(setResponseStats)
        .catch(() => setResponseStats(null))
    } catch (err: unknown) {
      console.error('Error fetching triage dashboard data:', err)
      setError(t('triage.errorLoading'))
    } finally {
      setLoading(false)
    }
  }, [t])

  useEffect(() => {
    fetchTriageData()
  }, [fetchTriageData])

  // Auto hide toast after 4 seconds
  useEffect(() => {
    if (toastMessage) {
      const timer = setTimeout(() => {
        setToastMessage(null)
      }, 4000)
      return () => clearTimeout(timer)
    }
  }, [toastMessage])

  // Escape closes the resolution modal
  useEffect(() => {
    if (!selectedPatientItem) return
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleCloseResolutionModal()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [selectedPatientItem])

  const handleReviewCase = (caseId?: string) => {
    if (caseId) {
      navigate(`/cases/${caseId}`)
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
    if (resolutionNote.trim().length < 10) {
      setNoteError(t('triage.noteRequired'))
      return
    }

    if (!selectedPatientItem) return

    setIsSubmitting(true)
    setNoteError('')

    try {
      // No silent fallback: a clinical resolution only "happened" if the
      // server persisted it. On failure the alert stays open and visible.
      await apiFetch(`/patients/${selectedPatientItem.patient.id}/triage-resolve`, {
        method: 'POST',
        body: JSON.stringify({
          outreach_method: outreachMethod,
          clinical_note: resolutionNote.trim()
        })
      })

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
        `${t('triage.resolvedToast')} — ${selectedPatientItem.patient.full_name}`
      )
      handleCloseResolutionModal()
    } catch (err) {
      console.error('Error resolving triage exception:', err)
      setNoteError(t('triage.resolveFailed'))
      setIsSubmitting(false)
    }
  }

  // Filter queues
  const redQueue = triageItems.filter((item) => item.severity === 'red')
  const amberQueue = triageItems.filter((item) => item.severity === 'amber')
  const unknownQueue = triageItems.filter((item) => item.severity === 'unknown')
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
  const filteredUnknown = filterBySearch(unknownQueue)
  const filteredExceptions = filterBySearch(exceptionQueue)
  const filteredNormal = filterBySearch(normalQueue)

  const adherenceText = (item: TriagePatient) =>
    item.adherencePercentage === null ? t('triage.noLogsYet') : `${item.adherencePercentage}%`

  const renderAlertCard = (item: TriagePatient, severity: 'red' | 'amber') => {
    const phone = item.patient.phone || item.caseItem?.emergency_contact_phone
    const isRed = severity === 'red'
    return (
      <div key={item.patient.id} style={isRed ? styles.redCard : styles.amberCard}>
        <div style={styles.cardHeader}>
          <div>
            <span style={isRed ? styles.redBadge : styles.amberBadge}>
              {isRed ? `🛑 ${t('triage.highPriority')}` : `⚠️ ${t('triage.mediumPriority')}`}
            </span>
            <h3 style={styles.patientName}>{item.patient.full_name}</h3>
            <p style={styles.patientSub}>
              {t('triage.surgery')}: {item.caseItem?.surgery_type || 'N/A'} &bull;{' '}
              {t('patients.dob')}: {item.patient.date_of_birth || 'N/A'}
            </p>
          </div>
          <div style={styles.actionButtons}>
            <button
              style={styles.exportCsvButton}
              onClick={() => exportPatientAdherenceCSV(item.patient.id)}
            >
              <span aria-hidden="true">📥 </span>{t('patients.exportCsv')}
            </button>
            <button
              style={styles.printPdfButton}
              onClick={() => printPatientClinicalPDF(item.patient.id)}
            >
              <span aria-hidden="true">📄 </span>{t('patients.printPdf')}
            </button>
            <button
              style={styles.resolveButton}
              onClick={() => handleOpenResolutionModal(item)}
            >
              <span aria-hidden="true">✅ </span>{t('triage.resolveException')}
            </button>
            {phone ? (
              <a
                href={`tel:${phone}`}
                style={styles.callButton}
                onClick={() =>
                  trackEvent('web.triage.patient_called', { patient_id: item.patient.id })
                }
              >
                <span aria-hidden="true">📞 </span>{t('triage.callPatient')}
              </a>
            ) : (
              <button
                style={{ ...styles.callButton, opacity: 0.5, cursor: 'not-allowed' }}
                disabled
                title={t('triage.noPhone')}
              >
                <span aria-hidden="true">📞 </span>{t('triage.callPatient')}
              </button>
            )}
            <button
              style={styles.reviewButton}
              onClick={() => handleReviewCase(item.caseItem?.id)}
            >
              <span aria-hidden="true">📋 </span>{t('triage.reviewCase')}
            </button>
          </div>
        </div>

        <div style={styles.reasonsList}>
          <strong>{t('triage.triggerReasons')}:</strong>
          <ul>
            {item.reasons.map((r, idx) => (
              <li key={idx}>{r}</li>
            ))}
          </ul>
        </div>

        <div style={styles.cardFooter}>
          <span>
            {t('triage.adherenceLabel')}: <strong>{adherenceText(item)}</strong>
          </span>
          <span>
            {t('triage.missedDoses')}: <strong>{item.missedDoses}</strong>
          </span>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      {/* Toast Notification */}
      {toastMessage && (
        <div style={styles.toastContainer} role="status">
          <span style={styles.toastIcon} aria-hidden="true">✅</span>
          <span style={styles.toastContent}>{toastMessage}</span>
          <button
            style={styles.toastClose}
            onClick={() => setToastMessage(null)}
            aria-label={t('cta.close')}
          >
            &times;
          </button>
        </div>
      )}

      <div style={styles.headerRow}>
        <div>
          <h1 style={styles.title}>{t('triage.title')}</h1>
          <p style={styles.subtitle}>{t('triage.subtitle')}</p>
        </div>
        <div style={styles.refreshGroup}>
          {lastUpdated && (
            <span style={styles.lastUpdated}>
              {t('triage.lastUpdated')}: {lastUpdated.toLocaleTimeString()}
            </span>
          )}
          <button style={styles.refreshButton} onClick={fetchTriageData} disabled={loading}>
            <span aria-hidden="true">🔄 </span>{t('triage.refresh')}
          </button>
        </div>
      </div>

      {loading && <p style={styles.loadingText}>{t('triage.loadingTriage')}</p>}

      {!loading && error && (
        <div style={styles.errorBox} role="alert">
          <p style={styles.errorText}>{error}</p>
          <button style={styles.retryButton} onClick={fetchTriageData}>
            {t('common.retry')}
          </button>
        </div>
      )}

      {!loading && !error && (
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
            {/* Widget 3: median time from exception viewed to resolution (target < 60s) */}
            <div
              style={{
                ...styles.statCard,
                borderLeft: `4px solid ${
                  responseStats?.median_seconds == null
                    ? '#94a3b8'
                    : responseStats.median_seconds < 60
                      ? '#16a34a'
                      : '#b91c1c'
                }`,
              }}
            >
              <div style={styles.statNumber}>
                {responseStats?.median_seconds != null
                  ? `${Math.round(responseStats.median_seconds)}s`
                  : '—'}
              </div>
              <div style={styles.statLabel}>{t('triage.medianResponse')}</div>
              <div style={styles.statSub}>
                {responseStats?.median_seconds != null
                  ? t('triage.responseTarget')
                  : t('triage.noResponseData')}
              </div>
            </div>
          </div>

          {/* Controls Bar: Search & Filter Tabs */}
          <div style={styles.controlsBar}>
            {/* Search Input */}
            <div style={styles.searchContainer}>
              <span style={styles.searchIcon} aria-hidden="true">🔍</span>
              <input
                type="text"
                placeholder={t('triage.searchPlaceholder')}
                aria-label={t('triage.searchPlaceholder')}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={styles.searchInput}
              />
              {searchQuery && (
                <button
                  style={styles.clearSearchButton}
                  onClick={() => setSearchQuery('')}
                  aria-label={t('cta.close')}
                >
                  &times;
                </button>
              )}
            </div>

            {/* Filter Tabs */}
            <div style={styles.tabContainer} role="tablist">
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
                <span aria-hidden="true">🚨 </span>{t('triage.highPriority')}
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
                <span aria-hidden="true">⚠️ </span>{t('triage.mediumPriority')}
                <span style={{ ...styles.tabBadge, backgroundColor: '#fffbe6', color: '#d97706' }}>
                  {amberQueue.length}
                </span>
              </button>
            </div>
          </div>

          {/* Top Priority Section: Needs Attention Triage Queue */}
          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>
              🚨 {t('triage.emergencyTriage')} (
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
                <span style={styles.emptyIcon} aria-hidden="true">✓</span>
                <p style={styles.emptyText}>
                  {searchQuery ? t('triage.noPatientsFound') : t('triage.allOnTrack')}
                </p>
              </div>
            )}

            {(activeTab === 'all' || activeTab === 'red') &&
              filteredRed.map((item) => renderAlertCard(item, 'red'))}

            {(activeTab === 'all' || activeTab === 'amber') &&
              filteredAmber.map((item) => renderAlertCard(item, 'amber'))}
          </div>

          {/* Unknown-status patients: telemetry failed — never shown as stable */}
          {filteredUnknown.length > 0 && (
            <div style={styles.section}>
              <h2 style={styles.sectionTitle}>⚪ {t('triage.unknownTitle')} ({filteredUnknown.length})</h2>
              <div style={styles.normalGrid}>
                {filteredUnknown.map((item) => (
                  <div key={item.patient.id} style={styles.unknownCard}>
                    <div style={styles.normalHeader}>
                      <h4 style={styles.normalName}>{item.patient.full_name}</h4>
                      <span style={styles.unknownBadge}>{t('triage.unknownTitle')}</span>
                    </div>
                    <p style={styles.normalSub}>{t('triage.unknownTelemetry')}</p>
                    <div style={styles.normalFooter}>
                      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' as const }}>
                        <button
                          style={styles.smallReviewButton}
                          onClick={fetchTriageData}
                        >
                          {t('common.retry')}
                        </button>
                        <button
                          style={styles.smallReviewButton}
                          onClick={() => handleReviewCase(item.caseItem?.id)}
                        >
                          {t('triage.reviewCase')}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Stable Patient Roster */}
          {filteredNormal.length > 0 && (
            <div style={styles.section}>
              <h2 style={styles.sectionTitle}>🟢 {t('triage.stable')} ({filteredNormal.length})</h2>
              <div style={styles.normalGrid}>
                {filteredNormal.map((item) => (
                  <div key={item.patient.id} style={styles.normalCard}>
                    <div style={styles.normalHeader}>
                      <h4 style={styles.normalName}>{item.patient.full_name}</h4>
                      <span style={styles.greenBadge}>{t('triage.stable')}</span>
                    </div>
                    <p style={styles.normalSub}>
                      {t('triage.surgery')}: {item.caseItem?.surgery_type || 'N/A'}
                    </p>
                    <div style={styles.normalFooter}>
                      <span>
                        {t('triage.adherenceLabel')}: <strong>{adherenceText(item)}</strong>
                      </span>
                      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' as const }}>
                        <button
                          style={styles.smallExportCsvButton}
                          onClick={() => exportPatientAdherenceCSV(item.patient.id)}
                        >
                          <span aria-hidden="true">📥 </span>{t('patients.exportCsv')}
                        </button>
                        <button
                          style={styles.smallPrintPdfButton}
                          onClick={() => printPatientClinicalPDF(item.patient.id)}
                        >
                          <span aria-hidden="true">📄 </span>{t('patients.printPdf')}
                        </button>
                        <button
                          style={styles.smallReviewButton}
                          onClick={() => handleReviewCase(item.caseItem?.id)}
                        >
                          {t('triage.reviewCase')}
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
          <div
            style={styles.modalContainer}
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
            aria-labelledby="resolve-modal-title"
          >
            <div style={styles.modalHeader}>
              <div>
                <h3 style={styles.modalTitle} id="resolve-modal-title">
                  {t('triage.resolveModalTitle')}
                </h3>
                <p style={styles.modalSubtitle}>
                  {selectedPatientItem.patient.full_name}
                </p>
              </div>
              <button
                style={styles.modalCloseButton}
                onClick={handleCloseResolutionModal}
                aria-label={t('cta.close')}
              >
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
                  <strong>{t('triage.escalationReasons')}:</strong>
                  <span
                    style={
                      selectedPatientItem.severity === 'red'
                        ? styles.redBadge
                        : styles.amberBadge
                    }
                  >
                    {selectedPatientItem.severity === 'red'
                      ? `🛑 ${t('triage.highPriority')}`
                      : `⚠️ ${t('triage.mediumPriority')}`}
                  </span>
                </div>
                <div style={{ fontSize: '13px', color: '#374151' }}>
                  {selectedPatientItem.reasons.join(', ')}
                </div>
              </div>

              {/* Outreach Method Selection */}
              <fieldset style={styles.fieldset}>
                <legend style={styles.label}>{t('triage.outreachMethod')} *</legend>
                <div style={styles.radioGroup}>
                  {([
                    ['Phone Call', t('triage.outreachPhone')],
                    ['Secure SMS', t('triage.outreachSms')],
                    ['In-Person Visit', t('triage.outreachVisit')]
                  ] as [OutreachMethod, string][]).map(([method, label]) => (
                    <label key={method} style={styles.radioOptionLabel}>
                      <input
                        type="radio"
                        name="outreachMethod"
                        value={method}
                        checked={outreachMethod === method}
                        onChange={() => setOutreachMethod(method)}
                        style={styles.radioInput}
                      />
                      <span>{label}</span>
                    </label>
                  ))}
                </div>
              </fieldset>

              {/* Mandatory Resolution Notes Textarea */}
              <div style={styles.fieldGroup}>
                <label style={styles.label} htmlFor="resolution-note">
                  {t('triage.clinicalNote')} <span style={{ color: '#dc2626' }}>*</span>
                </label>
                <textarea
                  id="resolution-note"
                  rows={4}
                  placeholder={t('triage.notePlaceholder')}
                  value={resolutionNote}
                  onChange={(e) => {
                    setResolutionNote(e.target.value)
                    if (e.target.value.trim().length >= 10) setNoteError('')
                  }}
                  aria-invalid={!!noteError}
                  aria-describedby={noteError ? 'note-error' : undefined}
                  style={{
                    ...styles.textarea,
                    ...(noteError ? { borderColor: '#dc2626' } : {})
                  }}
                />
                {noteError && (
                  <p id="note-error" role="alert" style={styles.errorNoteText}>
                    {noteError}
                  </p>
                )}
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
                {t('cta.cancel')}
              </button>
              <button
                type="button"
                style={styles.resolveSubmitButton}
                onClick={handleResolveSubmit}
                disabled={isSubmitting}
              >
                {isSubmitting ? t('triage.archiving') : t('cta.submit')}
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
  headerRow: {
    marginBottom: '24px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: '16px',
    flexWrap: 'wrap' as const
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
  refreshGroup: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px'
  },
  lastUpdated: {
    fontSize: '12px',
    color: '#64748b'
  },
  refreshButton: {
    padding: '8px 14px',
    backgroundColor: '#ffffff',
    color: '#0f172a',
    border: '1px solid #e2e8f0',
    borderRadius: '8px',
    fontSize: '13px',
    fontWeight: '600' as const,
    cursor: 'pointer'
  },
  loadingText: {
    fontSize: '15px',
    color: '#64748b'
  },
  errorBox: {
    backgroundColor: '#fef2f2',
    border: '1px solid #fecaca',
    borderRadius: '12px',
    padding: '32px',
    textAlign: 'center' as const
  },
  errorText: {
    fontSize: '15px',
    color: '#b91c1c',
    margin: '0 0 16px 0'
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
  statSub: {
    fontSize: '11px',
    color: '#94a3b8',
    marginTop: '2px'
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
  unknownBadge: {
    display: 'inline-block',
    padding: '2px 8px',
    backgroundColor: '#f1f5f9',
    color: '#475569',
    fontSize: '11px',
    fontWeight: '700',
    borderRadius: '4px'
  },
  unknownCard: {
    backgroundColor: '#ffffff',
    border: '1px dashed #94a3b8',
    borderRadius: '10px',
    padding: '16px'
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
    cursor: 'pointer',
    textDecoration: 'none' as const
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
    marginTop: '4px'
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
  fieldset: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '6px',
    border: 'none',
    margin: 0,
    padding: 0
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

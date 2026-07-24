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

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

function sanitizeCsv(field?: string | number | boolean | null): string {
  if (field == null) return '""'
  const str = String(field).replace(/"/g, '""')
  return `"${str}"`
}

/** Escape any server-supplied string before interpolating into print-window HTML. */
function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

/** Throws when telemetry is unavailable — an export with silently missing data is worse than no export. */
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

/** Returns adherence % or null when there are no completed dose logs. Never fabricates 100%. */
function computeAdherence(doseLogs: DoseLog[]): number | null {
  const completedLogs = doseLogs.filter((log) => ['taken', 'missed', 'skipped'].includes(log.status))
  if (completedLogs.length === 0) return null
  const takenCount = doseLogs.filter((log) => log.status === 'taken').length
  return Math.round((takenCount / completedLogs.length) * 100)
}

async function fetchPatientData(patientId: string): Promise<{
  patient: Patient
  cases: Case[]
  doseLogs: DoseLog[]
  symptoms: SymptomCheckIn[]
}> {
  const [patientsRes, casesRes, doseLogs, symptoms] = await Promise.all([
    apiFetch<Patient[]>('/patients'),
    apiFetch<Case[]>('/cases'),
    fetchPatientDoseLogs(patientId),
    fetchPatientSymptoms(patientId)
  ])

  const patient = patientsRes.find((p) => p.id === patientId)
  if (!patient) {
    throw new Error('Patient record could not be loaded — export aborted.')
  }

  const patientCases = casesRes.filter((c) => c.patient_id === patientId)

  return { patient, cases: patientCases, doseLogs, symptoms }
}

export async function exportPatientAdherenceCSV(patientId: string): Promise<void> {
  const filename = `patient_${patientId}_adherence_report.csv`
  const token = localStorage.getItem('token')
  const headers: Record<string, string> = {}
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  try {
    // Attempt backend endpoint GET /patients/{id}/export?format=csv
    const res = await fetch(`${BASE_URL}/patients/${patientId}/export?format=csv`, {
      headers
    })

    if (res.ok) {
      const contentType = res.headers.get('content-type') || ''
      if (contentType.includes('csv') || contentType.includes('text')) {
        const textData = await res.text()
        if (textData && textData.trim().length > 0) {
          downloadFile(textData, filename, 'text/csv;charset=utf-8;')
          return
        }
      }
    }
  } catch (err) {
    console.warn('Backend CSV export endpoint unavailable, falling back to client generator', err)
  }

  // Client CSV Fallback
  let data: Awaited<ReturnType<typeof fetchPatientData>>
  try {
    data = await fetchPatientData(patientId)
  } catch (err) {
    alert(`Export failed: ${err instanceof Error ? err.message : 'clinical data could not be loaded.'}`)
    return
  }
  const { patient, cases, doseLogs, symptoms } = data
  const surgeryTypes = cases.map((c) => c.surgery_type).join('; ') || 'N/A'
  const allergiesStr = patient.allergies && patient.allergies.length > 0 ? patient.allergies.join(', ') : 'None'

  const adherencePercentage = computeAdherence(doseLogs)

  const lines: string[] = []

  lines.push('=== CLINICAL TELEMETRY & ADHERENCE REPORT ===')
  lines.push(`Generated Date,${sanitizeCsv(new Date().toLocaleString())}`)
  lines.push(`Patient ID,${sanitizeCsv(patient.id)}`)
  lines.push(`Patient Name,${sanitizeCsv(patient.full_name)}`)
  lines.push(`Date of Birth,${sanitizeCsv(patient.date_of_birth || 'N/A')}`)
  lines.push(`Allergies,${sanitizeCsv(allergiesStr)}`)
  lines.push(`Status,${sanitizeCsv(patient.status || 'Active')}`)
  lines.push(`Surgery Type,${sanitizeCsv(surgeryTypes)}`)
  lines.push(`Adherence Rate,${sanitizeCsv(adherencePercentage === null ? 'N/A (no dose logs recorded)' : `${adherencePercentage}%`)}`)
  lines.push('')

  lines.push('=== MEDICATION & DOSE LOGS ===')
  lines.push('Log ID,Scheduled Reminder ID,Status,Logged At,Skipped Reason,Escalate,Notes')
  if (doseLogs.length === 0) {
    lines.push('No dose logs recorded,,,,,')
  } else {
    doseLogs.forEach((log) => {
      lines.push(
        [
          sanitizeCsv(log.id),
          sanitizeCsv(log.scheduled_reminder_id),
          sanitizeCsv(log.status),
          sanitizeCsv(log.logged_at || 'N/A'),
          sanitizeCsv(log.skipped_reason || ''),
          sanitizeCsv(log.escalate ? 'YES' : 'NO'),
          sanitizeCsv(log.notes || '')
        ].join(',')
      )
    })
  }

  lines.push('')
  lines.push('=== SYMPTOM CHECK-INS ===')
  lines.push('Check-in ID,Date,Feeling,Escalate,Notes')
  if (symptoms.length === 0) {
    lines.push('No symptom check-ins recorded,,,,')
  } else {
    symptoms.forEach((s) => {
      lines.push(
        [
          sanitizeCsv(s.id),
          sanitizeCsv(s.checkin_date || 'N/A'),
          sanitizeCsv(s.feeling),
          sanitizeCsv(s.escalate ? 'YES' : 'NO'),
          sanitizeCsv(s.notes || '')
        ].join(',')
      )
    })
  }

  const csvContent = lines.join('\n')
  downloadFile(csvContent, filename, 'text/csv;charset=utf-8;')
}

function downloadFile(content: string, filename: string, mimeType: string) {
  const blob = new Blob([content], { type: mimeType })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.setAttribute('download', filename)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

export async function printPatientClinicalPDF(patientId: string): Promise<void> {
  let data: Awaited<ReturnType<typeof fetchPatientData>>
  try {
    data = await fetchPatientData(patientId)
  } catch (err) {
    alert(`Export failed: ${err instanceof Error ? err.message : 'clinical data could not be loaded.'}`)
    return
  }
  const { patient, cases, doseLogs, symptoms } = data
  const surgeryTypes = cases.map((c) => c.surgery_type).join(', ') || 'N/A'
  const allergiesStr = patient.allergies && patient.allergies.length > 0 ? patient.allergies.join(', ') : 'None'

  const takenCount = doseLogs.filter((log) => log.status === 'taken').length
  const missedCount = doseLogs.filter((log) => log.status === 'missed').length
  const skippedCount = doseLogs.filter((log) => log.status === 'skipped').length
  const adherencePercentage = computeAdherence(doseLogs)
  const adherenceDisplay = adherencePercentage === null ? 'N/A' : `${adherencePercentage}%`

  const hasEscalations =
    symptoms.some((s) => s.escalate) ||
    doseLogs.some((d) => d.escalate) ||
    patient.status === 'escalated' ||
    missedCount >= 2

  const printWindow = window.open('', '_blank', 'width=900,height=1000')
  if (!printWindow) {
    alert('Popup window was blocked by the browser. Please allow popups to view and print clinical PDF.')
    return
  }

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Clinical Telemetry Report - ${escapeHtml(patient.full_name)}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      color: #0f172a;
      padding: 32px;
      margin: 0;
      background-color: #ffffff;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 2px solid #0284c7;
      padding-bottom: 16px;
      margin-bottom: 24px;
    }
    .brand {
      font-size: 22px;
      font-weight: 700;
      color: #0284c7;
      margin: 0;
    }
    .title {
      font-size: 16px;
      font-weight: 600;
      color: #475569;
      margin: 4px 0 0 0;
    }
    .meta {
      text-align: right;
      font-size: 12px;
      color: #64748b;
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 24px;
    }
    .card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 16px;
    }
    .card-title {
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #64748b;
      margin: 0 0 8px 0;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      font-size: 13px;
      margin-bottom: 6px;
    }
    .info-label {
      color: #64748b;
    }
    .info-value {
      font-weight: 600;
      color: #0f172a;
    }
    .metrics {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;
      margin-bottom: 24px;
    }
    .metric-box {
      background: #ffffff;
      border: 1px solid #cbd5e1;
      border-radius: 8px;
      padding: 12px;
      text-align: center;
    }
    .metric-num {
      font-size: 22px;
      font-weight: 700;
      color: #0284c7;
    }
    .metric-label {
      font-size: 11px;
      color: #64748b;
      margin-top: 2px;
    }
    .section-title {
      font-size: 15px;
      font-weight: 700;
      color: #0f172a;
      margin: 24px 0 12px 0;
      border-bottom: 1px solid #e2e8f0;
      padding-bottom: 6px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 12px;
      margin-bottom: 24px;
    }
    th, td {
      border: 1px solid #e2e8f0;
      padding: 8px 12px;
      text-align: left;
    }
    th {
      background-color: #f1f5f9;
      font-weight: 600;
      color: #334155;
    }
    .badge {
      display: inline-block;
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 10px;
      font-weight: 700;
    }
    .badge-taken { background: #dcfce7; color: #15803d; }
    .badge-missed { background: #fee2e2; color: #b91c1c; }
    .badge-skipped { background: #fef3c7; color: #b45309; }
    .badge-pending { background: #f1f5f9; color: #64748b; }
    .footer {
      margin-top: 40px;
      padding-top: 16px;
      border-top: 1px solid #e2e8f0;
      font-size: 11px;
      color: #94a3b8;
      display: flex;
      justify-content: space-between;
    }
    @media print {
      body { padding: 16px; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="no-print" style="margin-bottom: 16px; text-align: right;">
    <button onclick="window.print()" style="padding: 8px 16px; background-color: #0284c7; color: #fff; border: none; border-radius: 6px; font-weight: 600; cursor: pointer;">
      🖨️ Print / Save to PDF
    </button>
  </div>

  <div class="header">
    <div>
      <h1 class="brand">RemoteCare Pro</h1>
      <h2 class="title">Clinical Telemetry & Adherence Report</h2>
    </div>
    <div class="meta">
      <div>Report Date: <strong>${new Date().toLocaleDateString()} ${new Date().toLocaleTimeString()}</strong></div>
      <div>Patient ID: <strong>${escapeHtml(patient.id)}</strong></div>
    </div>
  </div>

  <div class="grid">
    <div class="card">
      <div class="card-title">Patient Profile</div>
      <div class="info-row"><span class="info-label">Full Name:</span><span class="info-value">${escapeHtml(patient.full_name)}</span></div>
      <div class="info-row"><span class="info-label">Date of Birth:</span><span class="info-value">${escapeHtml(patient.date_of_birth || 'N/A')}</span></div>
      <div class="info-row"><span class="info-label">Allergies:</span><span class="info-value">${escapeHtml(allergiesStr)}</span></div>
      <div class="info-row"><span class="info-label">Status:</span><span class="info-value">${escapeHtml(patient.status || 'Active')}</span></div>
    </div>

    <div class="card">
      <div class="card-title">Case Information</div>
      <div class="info-row"><span class="info-label">Surgery / Case Type:</span><span class="info-value">${escapeHtml(surgeryTypes)}</span></div>
      <div class="info-row"><span class="info-label">Escalation Status:</span><span class="info-value" style="color: ${hasEscalations ? '#b91c1c' : '#15803d'};">${hasEscalations ? '🚨 ESCALATED / HIGH RISK' : '🟢 STABLE'}</span></div>
    </div>
  </div>

  <div class="metrics">
    <div class="metric-box">
      <div class="metric-num">${adherenceDisplay}</div>
      <div class="metric-label">Adherence Rate</div>
    </div>
    <div class="metric-box">
      <div class="metric-num" style="color: #15803d;">${takenCount}</div>
      <div class="metric-label">Doses Taken</div>
    </div>
    <div class="metric-box">
      <div class="metric-num" style="color: #b91c1c;">${missedCount}</div>
      <div class="metric-label">Doses Missed</div>
    </div>
    <div class="metric-box">
      <div class="metric-num" style="color: #b45309;">${skippedCount}</div>
      <div class="metric-label">Doses Skipped</div>
    </div>
  </div>

  <div class="section-title">Medication Adherence Logs (${doseLogs.length})</div>
  <table>
    <thead>
      <tr>
        <th>Logged / Date</th>
        <th>Reminder ID</th>
        <th>Status</th>
        <th>Skipped Reason</th>
        <th>Notes</th>
      </tr>
    </thead>
    <tbody>
      ${
        doseLogs.length === 0
          ? '<tr><td colspan="5" style="text-align:center; color:#94a3b8;">No medication logs recorded</td></tr>'
          : doseLogs
              .map(
                (log) => `
        <tr>
          <td>${log.logged_at ? new Date(log.logged_at).toLocaleString() : 'N/A'}</td>
          <td>${escapeHtml(log.scheduled_reminder_id || 'N/A')}</td>
          <td><span class="badge badge-${log.status}">${log.status.toUpperCase()}</span></td>
          <td>${escapeHtml(log.skipped_reason || '-')}</td>
          <td>${escapeHtml(log.notes || '-')}</td>
        </tr>
      `
              )
              .join('')
      }
    </tbody>
  </table>

  <div class="section-title">Symptom Check-ins (${symptoms.length})</div>
  <table>
    <thead>
      <tr>
        <th>Check-in Date</th>
        <th>Feeling Grade</th>
        <th>AI Escalated Flag</th>
        <th>Clinical Notes</th>
      </tr>
    </thead>
    <tbody>
      ${
        symptoms.length === 0
          ? '<tr><td colspan="4" style="text-align:center; color:#94a3b8;">No symptom check-ins recorded</td></tr>'
          : symptoms
              .map(
                (s) => `
        <tr>
          <td>${escapeHtml(s.checkin_date || 'N/A')}</td>
          <td><strong>${escapeHtml(s.feeling.toUpperCase())}</strong></td>
          <td><span class="badge ${s.escalate ? 'badge-missed' : 'badge-taken'}">${s.escalate ? 'YES - FLAG' : 'NO'}</span></td>
          <td>${escapeHtml(s.notes || '-')}</td>
        </tr>
      `
              )
              .join('')
      }
    </tbody>
  </table>

  <div class="footer">
    <span>Confidential Medical & Telemetry Record &bull; RemoteCare Pro</span>
    <span>Page 1 of 1</span>
  </div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 300);
    };
  </script>
</body>
</html>
  `

  printWindow.document.open()
  printWindow.document.write(html)
  printWindow.document.close()
}

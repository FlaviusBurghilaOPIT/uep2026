/**
 * Clinical Summary Formatter
 * Parses raw LLM / Bedrock clinical roster summaries into structured,
 * clinic-ready HTML elements with status badges, medication pills,
 * and high-priority action items.
 */

export interface ParsedPatientBrief {
  name: string
  surgery?: string
  medications?: string[]
  feeling?: string
  recommendation?: string
}

export interface ParsedClinicalBrief {
  overview: string
  patients: ParsedPatientBrief[]
  considerations: string[]
  rawText: string
}

export function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

/**
 * Basic markdown inline formatter for bold, italic, and inline code
 */
export function formatInlineMarkdown(text: string): string {
  let formatted = escapeHtml(text)
  // Bold: **text** or __text__
  formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
  formatted = formatted.replace(/__(.*?)__/g, '<strong>$1</strong>')
  // Italic: *text* or _text_
  formatted = formatted.replace(/\*([^*]+)\*/g, '<em>$1</em>')
  formatted = formatted.replace(/_([^_]+)_/g, '<em>$1</em>')
  return formatted
}

/**
 * Parses raw LLM clinical output into structured sections
 */
export function parseClinicalSummary(rawText: string): ParsedClinicalBrief {
  const brief: ParsedClinicalBrief = {
    overview: '',
    patients: [],
    considerations: [],
    rawText
  }

  if (!rawText || !rawText.trim()) {
    brief.overview = 'No clinical telemetry summary available.'
    return brief
  }

  // Split into Summary and Things to Consider sections
  const considerSplit = rawText.split(/(?:\*\*Things to consider\*\*|Things to consider:|## Things to consider)/i)
  const summaryPart = considerSplit[0] || ''
  const considerPart = considerSplit[1] || ''

  // Parse summary part
  const patientMatches = summaryPart.split(/(?:- \*\*Patient:\*\*|\*\*Patient:\*\*|Patient:)/i)
  
  if (patientMatches.length > 1) {
    brief.overview = patientMatches[0]
      .replace(/\*\*Overall Summary\*\*/i, '')
      .replace(/\*\*Summary\*\*/i, '')
      .replace(/^[-\s*:]+/, '')
      .trim()

    for (let i = 1; i < patientMatches.length; i++) {
      const pChunk = patientMatches[i]
      const pData: ParsedPatientBrief = { name: '' }

      // Extract Name
      const nameMatch = pChunk.match(/^([^\n\-*]+)/)
      if (nameMatch) {
        pData.name = nameMatch[1].trim()
      }

      // Extract Surgery
      const surgMatch = pChunk.match(/(?:Surgery|Procedure):\s*([^\n*]+)/i)
      if (surgMatch) {
        pData.surgery = surgMatch[1].replace(/^[-–—\s]+/, '').trim()
      }

      // Extract Active Medications
      const medsMatch = pChunk.match(/(?:Active medications|Medications):\s*([^\n*]+)/i)
      if (medsMatch) {
        const medsStr = medsMatch[1].trim()
        pData.medications = medsStr.split(',').map(m => m.trim()).filter(Boolean)
      }

      // Extract Latest Feeling
      const feelingMatch = pChunk.match(/(?:Latest check[-‑]in feeling|Feeling|Mood):\s*([^\n*]+)/i)
      if (feelingMatch) {
        pData.feeling = feelingMatch[1].replace(/[*_]/g, '').trim()
      }

      // Extract Latest Recommendation
      const recMatch = pChunk.match(/(?:Latest recovery recommendation|Latest recommendation|Recommendation):\s*([^\n*]+)/i)
      if (recMatch) {
        pData.recommendation = recMatch[1].trim()
      }

      if (pData.name) {
        brief.patients.push(pData)
      }
    }
  } else {
    brief.overview = summaryPart
      .replace(/\*\*Overall Summary\*\*/i, '')
      .replace(/\*\*Summary\*\*/i, '')
      .trim()
  }

  // Parse Considerations
  if (considerPart) {
    const rawItems = considerPart.split(/(?:^|\n)\s*[-*•]\s+/).map(s => s.trim()).filter(Boolean)
    brief.considerations = rawItems
  }

  return brief
}

/**
 * Formats a feeling string into a clinical severity badge
 */
export function renderFeelingBadge(feeling?: string): string {
  if (!feeling) return ''
  const clean = feeling.toLowerCase().replace(/[^a-z_]/g, '')
  if (clean === 'not_great' || clean === 'bad' || clean === 'severe') {
    return `<span class="clinical-pill pill-alert" title="Reported Discomfort / Symptom Concern">
      <span class="pill-dot red"></span>
      <strong>Check-In:</strong> ${escapeHtml(feeling.replace(/_/g, ' ').toUpperCase())}
    </span>`
  }
  if (clean === 'ok' || clean === 'moderate') {
    return `<span class="clinical-pill pill-warn">
      <span class="pill-dot amber"></span>
      <strong>Check-In:</strong> ${escapeHtml(feeling.replace(/_/g, ' ').toUpperCase())}
    </span>`
  }
  return `<span class="clinical-pill pill-stable">
    <span class="pill-dot green"></span>
    <strong>Check-In:</strong> ${escapeHtml(feeling.replace(/_/g, ' ').toUpperCase())}
  </span>`
}

/**
 * Renders complete, structured clinical HTML from the parsed brief
 */
export function renderClinicalBriefHtml(brief: ParsedClinicalBrief): string {
  let html = '<div class="clinical-synthesis-wrapper">'

  // 1. Executive Summary Strip
  if (brief.overview && brief.overview.trim().length > 0) {
    html += `
      <div class="synthesis-overview-card">
        <div class="overview-header">
          <span class="clinical-tag">COHORT CLINICAL INTELLIGENCE</span>
          <span class="live-pill">Telemetry Active</span>
        </div>
        <p class="overview-text">${formatInlineMarkdown(brief.overview)}</p>
      </div>
    `
  }

  // 2. Patient-by-Patient Clinical Cards
  if (brief.patients && brief.patients.length > 0) {
    html += `
      <div class="synthesis-patients-section">
        <h4 class="synthesis-section-title">
          <span>Patient Roster Status</span>
          <span class="patient-count-badge">${brief.patients.length} Patient${brief.patients.length > 1 ? 's' : ''} Analyzed</span>
        </h4>
        <div class="synthesis-patient-grid">
    `

    for (const p of brief.patients) {
      html += `
        <div class="synthesis-patient-card">
          <div class="card-top">
            <div class="patient-identity">
              <span class="patient-avatar">${escapeHtml(p.name.slice(0, 2).toUpperCase())}</span>
              <div>
                <h5 class="patient-name">${escapeHtml(p.name)}</h5>
                ${p.surgery ? `<span class="surgery-tag">${escapeHtml(p.surgery)}</span>` : ''}
              </div>
            </div>
            ${renderFeelingBadge(p.feeling)}
          </div>

          ${p.medications && p.medications.length > 0 ? `
            <div class="meds-row">
              <span class="meds-label">Active Regimen:</span>
              <div class="meds-chips">
                ${p.medications.map(m => `<span class="med-chip">${escapeHtml(m)}</span>`).join('')}
              </div>
            </div>
          ` : ''}

          ${p.recommendation ? `
            <div class="recommendation-callout">
              <div class="rec-icon">🧊</div>
              <div class="rec-body">
                <span class="rec-label">Active Care Protocol</span>
                <p class="rec-text">${formatInlineMarkdown(p.recommendation)}</p>
              </div>
            </div>
          ` : ''}
        </div>
      `
    }

    html += `
        </div>
      </div>
    `
  }

  // 3. Clinical Vigilance & Considerations
  if (brief.considerations && brief.considerations.length > 0) {
    html += `
      <div class="synthesis-considerations-section">
        <h4 class="synthesis-section-title considerations-title">
          <span>Clinical Vigilance & Action Items</span>
          <span class="vigilance-badge">Priority Watchlist</span>
        </h4>
        <div class="considerations-list">
    `

    for (const item of brief.considerations) {
      html += `
        <div class="consideration-item">
          <div class="item-bullet"></div>
          <div class="item-content">
            <p>${formatInlineMarkdown(item)}</p>
          </div>
        </div>
      `
    }

    html += `
        </div>
      </div>
    `
  }

  // Fallback if nothing structured was parsed
  if (!brief.overview && brief.patients.length === 0 && brief.considerations.length === 0) {
    html += `
      <div class="synthesis-fallback">
        <p>${formatInlineMarkdown(brief.rawText)}</p>
      </div>
    `
  }

  // 4. Clinical Footer Actions Bar
  html += `
    <div class="synthesis-footer-actions">
      <button type="button" class="synthesis-btn btn-copy" id="synthesis-copy-btn">
        <span>📋 Copy Clinical Brief</span>
      </button>
      <button type="button" class="synthesis-btn btn-close" id="synthesis-close-btn">
        <span>✕ Dismiss Brief</span>
      </button>
    </div>
  </div>`

  return html
}

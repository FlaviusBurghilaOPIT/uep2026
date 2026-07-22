import { useState, useEffect } from 'react'
import { apiFetch } from '../api/client'

type FDAResult = {
  drug: string
  warnings: string[]
  source: string
  retrieved_at: string
}

function FDAPage() {
  const params = new URLSearchParams(window.location.search)
  const initialDrug = params.get('drug') || ''
  const [drugName, setDrugName] = useState(initialDrug)
  const [result, setResult] = useState<FDAResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSearch = async (searchTerm?: string) => {
    const term = searchTerm || drugName
    if (!term.trim()) {
      setError('Please enter a drug name')
      return
    }
    setError('')
    setResult(null)
    setLoading(true)
    try {
      const data = await apiFetch<Record<string, unknown>>(`/fda/drug/${encodeURIComponent(term.toLowerCase().trim())}`)
      const name = (data.drug || data.drug_name || term) as string
      const rawWarnings = data.warnings as string[] | undefined
      const summary = data.summary as string | undefined
      const warnings = rawWarnings || (summary ? summary.split('\n').filter(Boolean) : ['No specific warnings found.'])
      const retrieved_at = (data.retrieved_at || new Date().toISOString()) as string
      setResult({
        drug: name,
        warnings,
        source: (data.source || 'openFDA') as string,
        retrieved_at
      })
    } catch (err: unknown) {
      setError((err as Error).message || 'Could not fetch FDA data. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const openFDAWebsite = (drug: string) => {
    window.open('https://www.accessdata.fda.gov/scripts/cder/daf/index.cfm?event=BasicSearch.process&query=' + drug, '_blank')
  }

  useEffect(() => {
    if (initialDrug) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      void handleSearch(initialDrug)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>FDA Drug Safety</h1>
        <p style={styles.subtitle}>
          Search for FDA warnings and side effects for any medication
        </p>
      </div>

      <div style={styles.searchRow}>
        <input
          style={styles.input}
          type="text"
          placeholder="e.g. ibuprofen, metformin, aspirin"
          value={drugName}
          onChange={(e) => setDrugName(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
        />
        <button
          style={styles.searchButton}
          onClick={() => handleSearch()}
          disabled={loading}
        >
          {loading ? 'Searching...' : 'Search'}
        </button>
      </div>

      {error && <p style={styles.error}>{error}</p>}

      {result && (
        <div style={styles.resultCard}>
          <div style={styles.resultHeader}>
            <div>
              <h2 style={styles.drugName}>{result.drug.toUpperCase()}</h2>
              <div style={styles.sourceBadge}>
                <span>📋</span>
                <span>{result.source}</span>
              </div>
            </div>
            <div style={styles.rightHeader}>
              <span style={styles.timestamp}>
                Retrieved: {new Date(result.retrieved_at).toLocaleString()}
              </span>
              <button
                style={styles.fdaWebsiteLink}
                onClick={() => openFDAWebsite(result.drug)}
              >
                View on FDA Website
              </button>
            </div>
          </div>

          <div style={styles.warningsSection}>
            <h3 style={styles.warningsTitle}>Warnings & Side Effects</h3>
            <div style={styles.warningsList}>
              {result.warnings.map((warning, i) => (
                <div key={i} style={styles.warningItem}>
                  <span style={styles.warningDot}>•</span>
                  <p style={styles.warningText}>{warning}</p>
                </div>
              ))}
            </div>
          </div>

          <p style={styles.disclaimer}>
            This information is sourced from the FDA and summarized by AI.
            Always consult clinical guidelines and your own judgment before
            making prescribing decisions.
          </p>
        </div>
      )}

      {loading && (
        <div style={styles.emptyState}>
          <p style={styles.emptyIcon}>🔍</p>
          <p style={styles.emptyText}>Fetching FDA data...</p>
        </div>
      )}

      {!result && !loading && !error && (
        <div style={styles.emptyState}>
          <p style={styles.emptyIcon}>💊</p>
          <p style={styles.emptyText}>
            Search for a drug to see FDA warnings and side effects
          </p>
          <div style={styles.suggestions}>
            {['ibuprofen', 'metformin', 'aspirin', 'paracetamol'].map((drug) => (
              <button
                key={drug}
                style={styles.suggestionChip}
                onClick={() => {
                  setDrugName(drug)
                  handleSearch(drug)
                }}
              >
                {drug}
              </button>
            ))}
          </div>
        </div>
      )}
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
  searchRow: {
    display: 'flex',
    gap: '12px',
    marginBottom: '16px'
  },
  input: {
    flex: 1,
    padding: '10px 16px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    outline: 'none',
    backgroundColor: '#ffffff'
  },
  searchButton: {
    padding: '10px 24px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '15px',
    cursor: 'pointer',
    fontWeight: '500'
  },
  error: {
    color: '#dc2626',
    fontSize: '13px'
  },
  resultCard: {
    backgroundColor: '#ffffff',
    borderRadius: '12px',
    border: '1px solid #e5e7eb',
    padding: '24px',
    marginTop: '16px'
  },
  resultHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: '20px'
  },
  rightHeader: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'flex-end',
    gap: '8px'
  },
  drugName: {
    fontSize: '20px',
    fontWeight: '700',
    color: '#111827',
    margin: '0 0 8px 0'
  },
  sourceBadge: {
    display: 'flex',
    alignItems: 'center',
    gap: '4px',
    backgroundColor: '#eff6ff',
    color: '#2563eb',
    padding: '4px 10px',
    borderRadius: '20px',
    fontSize: '12px',
    fontWeight: '500',
    width: 'fit-content'
  },
  timestamp: {
    fontSize: '11px',
    color: '#9ca3af'
  },
  fdaWebsiteLink: {
    fontSize: '12px',
    color: '#16a34a',
    backgroundColor: '#f0fdf4',
    border: '1px solid #bbf7d0',
    padding: '4px 10px',
    borderRadius: '8px',
    fontWeight: '500',
    cursor: 'pointer'
  },
  warningsSection: {
    marginBottom: '20px'
  },
  warningsTitle: {
    fontSize: '15px',
    fontWeight: '600',
    color: '#111827',
    margin: '0 0 12px 0'
  },
  warningsList: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '10px'
  },
  warningItem: {
    display: 'flex',
    gap: '10px',
    alignItems: 'flex-start',
    backgroundColor: '#fef9f0',
    padding: '12px',
    borderRadius: '8px',
    border: '1px solid #fde68a'
  },
  warningDot: {
    color: '#d97706',
    fontWeight: '700',
    fontSize: '16px',
    flexShrink: 0
  },
  warningText: {
    fontSize: '14px',
    color: '#111827',
    margin: 0,
    lineHeight: '1.5'
  },
  disclaimer: {
    fontSize: '12px',
    color: '#9ca3af',
    margin: 0,
    fontStyle: 'italic',
    lineHeight: '1.5'
  },
  emptyState: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    padding: '60px 20px',
    gap: '12px'
  },
  emptyIcon: {
    fontSize: '48px',
    margin: 0
  },
  emptyText: {
    fontSize: '14px',
    color: '#6b7280',
    margin: 0
  },
  suggestions: {
    display: 'flex',
    gap: '8px',
    flexWrap: 'wrap' as const,
    justifyContent: 'center',
    marginTop: '8px'
  },
  suggestionChip: {
    padding: '6px 14px',
    backgroundColor: '#eff6ff',
    color: '#2563eb',
    border: '1px solid #bfdbfe',
    borderRadius: '20px',
    fontSize: '13px',
    cursor: 'pointer'
  }
}

export default FDAPage
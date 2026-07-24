import { useState, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useTranslation } from '../i18n'
import { apiFetch } from '../api/client'

type FDAResult = {
  drug: string
  warnings: string[]
  source: string | null
  retrieved_at: string | null
}

function FDAPage() {
  const { t, language } = useTranslation()
  const [searchParams] = useSearchParams()
  const initialDrug = searchParams.get('drug') || ''
  const [drugName, setDrugName] = useState(initialDrug)
  const [result, setResult] = useState<FDAResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSearch = async (searchTerm?: string) => {
    const term = searchTerm || drugName
    if (!term.trim()) {
      setError(t('fda.errorMissingDrug'))
      return
    }
    setError('')
    setResult(null)
    setLoading(true)
    try {
      const data = await apiFetch<Record<string, unknown>>(`/fda/drug/${encodeURIComponent(term.toLowerCase().trim())}`)
      const name = (data.drug || data.drug_name || term.trim()) as string
      const rawWarnings = data.warnings as string[] | undefined
      const summary = data.summary as string | undefined
      const warnings = rawWarnings || (summary ? summary.split('\n').filter(Boolean) : [t('fda.noWarnings')])
      setResult({
        drug: name,
        warnings,
        // Honest provenance: render source/timestamp only when the server provides them
        source: typeof data.source === 'string' ? data.source : null,
        retrieved_at: typeof data.retrieved_at === 'string' ? data.retrieved_at : null
      })
    } catch (err: unknown) {
      setError((err as Error).message || t('fda.errorFetchFailed'))
    } finally {
      setLoading(false)
    }
  }

  const openFDAWebsite = (drug: string) => {
    window.open('https://www.accessdata.fda.gov/scripts/cder/daf/index.cfm?event=BasicSearch.process&query=' + encodeURIComponent(drug), '_blank')
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
        <h1 style={styles.title}>{t('fda.title')}</h1>
        <p style={styles.subtitle}>
          {t('fda.subtitle')}
        </p>
      </div>

      <div style={styles.searchRow}>
        <input
          style={styles.input}
          type="text"
          placeholder={t('fda.searchPlaceholder')}
          aria-label={t('fda.searchLabel')}
          value={drugName}
          onChange={(e) => setDrugName(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
        />
        <button
          style={styles.searchButton}
          onClick={() => handleSearch()}
          disabled={loading}
        >
          {loading ? t('fda.searching') : t('fda.search')}
        </button>
      </div>

      {error && <p style={styles.error} role="alert">{error}</p>}

      {result && (
        <div style={styles.resultCard}>
          <div style={styles.resultHeader}>
            <div>
              <h2 style={styles.drugName}>{result.drug}</h2>
              {result.source && (
                <div style={styles.sourceBadge}>
                  <span aria-hidden="true">📋</span>
                  <span>{result.source}</span>
                </div>
              )}
            </div>
            <div style={styles.rightHeader}>
              {result.retrieved_at && (
                <span style={styles.timestamp}>
                  {t('fda.retrieved')}: {new Date(result.retrieved_at).toLocaleString(language)}
                </span>
              )}
              <button
                style={styles.fdaWebsiteLink}
                onClick={() => openFDAWebsite(result.drug)}
              >
                {t('fda.viewOnFDAWebsite')}
              </button>
            </div>
          </div>

          <div style={styles.warningsSection}>
            <h3 style={styles.warningsTitle}>{t('fda.warningsTitle')}</h3>
            <ul style={styles.warningsList}>
              {result.warnings.map((warning, i) => (
                <li key={i} style={styles.warningItem}>
                  <p style={styles.warningText}>{warning}</p>
                </li>
              ))}
            </ul>
          </div>

          <p style={styles.disclaimer}>
            {t('fda.disclaimer')}
          </p>
        </div>
      )}

      {loading && (
        <div style={styles.emptyState}>
          <p style={styles.emptyIcon} aria-hidden="true">🔍</p>
          <p style={styles.emptyText}>{t('fda.fetching')}</p>
        </div>
      )}

      {!result && !loading && !error && (
        <div style={styles.emptyState}>
          <p style={styles.emptyIcon} aria-hidden="true">💊</p>
          <p style={styles.emptyText}>
            {t('fda.emptyText')}
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
    margin: '0 0 8px 0',
    textTransform: 'capitalize' as const
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
    fontSize: '12px',
    color: '#6b7280'
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
    gap: '10px',
    listStyle: 'none' as const,
    margin: 0,
    padding: 0
  },
  warningItem: {
    backgroundColor: '#fef9f0',
    padding: '12px',
    borderRadius: '8px',
    border: '1px solid #fde68a',
    borderLeft: '4px solid #d97706'
  },
  warningText: {
    fontSize: '14px',
    color: '#111827',
    margin: 0,
    lineHeight: '1.5'
  },
  disclaimer: {
    fontSize: '13px',
    color: '#4b5563',
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

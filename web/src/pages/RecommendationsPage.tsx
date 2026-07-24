import { useEffect, useState } from 'react'
import { useTranslation } from '../i18n'
import { useNavigate, useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'
import { trackEvent } from '../api/analytics'

type Message = {
  role: 'user' | 'assistant'
  content: string
}

type CaseInfo = {
  id: string
  patient_id: string
  surgery_type: string
}

type PatientInfo = {
  id: string
  full_name: string
}

function RecommendationsPage() {
  const { t } = useTranslation()
  const { caseId } = useParams<{ caseId: string }>()
  const navigate = useNavigate()
  const [caseInfo, setCaseInfo] = useState<CaseInfo | null>(null)
  const [patientName, setPatientName] = useState('')
  const [content, setContent] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')
  const [contentInvalid, setContentInvalid] = useState(false)
  const [chatOpen, setChatOpen] = useState(false)
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      content: t('recommendations.aiGreeting')
    }
  ])
  const [chatInput, setChatInput] = useState('')
  const [chatLoading, setChatLoading] = useState(false)

  useEffect(() => {
    if (!caseId) return
    apiFetch<CaseInfo>(`/cases/${caseId}`)
      .then(async (c) => {
        setCaseInfo(c)
        try {
          const p = await apiFetch<PatientInfo>(`/patients/${c.patient_id}`)
          setPatientName(p.full_name)
        } catch {
          setPatientName('')
        }
      })
      .catch(() => setCaseInfo(null))
  }, [caseId])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!content.trim()) {
      setContentInvalid(true)
      setError(t('recommendations.errorMissingContent'))
      return
    }
    setContentInvalid(false)
    setLoading(true)
    setError('')
    try {
      await apiFetch(`/cases/${caseId}/recommendations`, {
        method: 'POST',
        body: JSON.stringify({ content: content.trim(), text: content.trim() })
      })
      setSuccess(true)
      if (caseId) trackEvent('web.recommendation.saved', { case_id: caseId })
    } catch (err: unknown) {
      setError((err as Error).message || t('recommendations.errorSaveFailed'))
    } finally {
      setLoading(false)
    }
  }

  const handleSendChat = async () => {
    if (!chatInput.trim()) return
    const userMessage: Message = { role: 'user', content: chatInput }
    setMessages((prev) => [...prev, userMessage])
    const currentInput = chatInput
    setChatInput('')
    setChatLoading(true)
    try {
      const response = await apiFetch<{ reply: string }>('/ai/chat', {
        method: 'POST',
        body: JSON.stringify({ case_id: caseId, message: currentInput })
      })
      const assistantMessage: Message = {
        role: 'assistant',
        content: response.reply
      }
      setMessages((prev) => [...prev, assistantMessage])
    } catch {
      const errorMessage: Message = {
        role: 'assistant',
        content: t('recommendations.aiError')
      }
      setMessages((prev) => [...prev, errorMessage])
    } finally {
      setChatLoading(false)
    }
  }

  const applyAISuggestion = (text: string) => {
    setContent(text)
    setChatOpen(false)
  }

  if (success) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>{t('recommendations.successTitle')}</h1>
          <p style={styles.subtitle}>{t('recommendations.successSubtitle')}</p>
          <button style={styles.button} onClick={() => navigate(`/cases/${caseId}/recommendations/list`)}>
            {t('recommendations.viewAll')}
          </button>
          <button style={styles.backButton} onClick={() => navigate('/patients')}>
            {t('recommendations.backToPatients')}
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>{t('recommendations.title')}</h1>
        {caseInfo && (
          <p style={styles.subtitle}>
            {t('recommendations.caseSubtitle')
              .replace('{surgery}', caseInfo.surgery_type)
              .replace('{patient}', patientName)}
          </p>
        )}

        <form onSubmit={handleSubmit} style={styles.form} noValidate>
          <label style={styles.label} htmlFor="recommendations-content">
            {t('recommendations.instructionsLabel')}
          </label>

          <div style={styles.textareaWrapper}>
            <textarea
              id="recommendations-content"
              style={styles.textarea}
              placeholder={t('recommendations.instructionsPlaceholder')}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              aria-invalid={contentInvalid}
              aria-describedby={error ? 'form-error' : undefined}
            />
            <button
              type="button"
              style={styles.aiButton}
              onClick={() => setChatOpen(!chatOpen)}
              title={t('recommendations.askAiTitle')}
              aria-label={t('recommendations.askAiTitle')}
              aria-expanded={chatOpen}
            >
              <span aria-hidden="true">🤖</span>
            </button>
          </div>

          {chatOpen && (
            <div style={styles.chatPanel}>
              <div style={styles.chatHeader}>
                <span style={styles.chatTitle}>
                  <span aria-hidden="true">🤖 </span>{t('recommendations.aiTitle')}
                </span>
                <span style={styles.chatSubtitle}>{t('recommendations.aiSubtitle')}</span>
              </div>
              <div style={styles.messages} role="log" aria-live="polite">
                {messages.map((msg, i) => (
                  <div key={i} style={msg.role === 'user' ? styles.userMessage : styles.assistantMessage}>
                    <p style={styles.messageText}>{msg.content}</p>
                    {msg.role === 'assistant' && i > 0 && (
                      <button type="button" style={styles.useButton} onClick={() => applyAISuggestion(msg.content)}>
                        {t('recommendations.useSuggestion')}
                      </button>
                    )}
                  </div>
                ))}
                {chatLoading && (
                  <div style={styles.assistantMessage}>
                    <p style={styles.messageText}>{t('recommendations.thinking')}</p>
                  </div>
                )}
              </div>
              <div style={styles.chatInputRow}>
                <input
                  style={styles.chatInput}
                  type="text"
                  placeholder={t('recommendations.chatPlaceholder')}
                  aria-label={t('recommendations.chatPlaceholder')}
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSendChat()}
                />
                <button type="button" style={styles.sendButton} onClick={handleSendChat} disabled={chatLoading}>
                  {t('recommendations.send')}
                </button>
              </div>
            </div>
          )}

          {error && <p id="form-error" role="alert" style={styles.error}>{error}</p>}

          <button style={styles.button} type="submit" disabled={loading}>
            {loading ? t('recommendations.saving') : t('recommendations.saveRecommendations')}
          </button>

          <button style={styles.backButton} type="button" onClick={() => navigate('/patients')}>
            {t('recommendations.cancel')}
          </button>
        </form>
      </div>
    </div>
  )
}

const styles = {
  container: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'flex-start',
    minHeight: '100vh',
    backgroundColor: '#f9fafb',
    padding: '40px 20px'
  },
  card: {
    backgroundColor: '#ffffff',
    padding: '40px',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
    width: '560px',
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '16px'
  },
  title: {
    fontSize: '22px',
    fontWeight: '600',
    color: '#111827',
    margin: 0
  },
  subtitle: {
    fontSize: '13px',
    color: '#6b7280',
    margin: 0
  },
  form: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '16px'
  },
  label: {
    fontSize: '13px',
    fontWeight: '500',
    color: '#111827'
  },
  textareaWrapper: {
    position: 'relative' as const
  },
  textarea: {
    width: '100%',
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    resize: 'vertical' as const,
    minHeight: '160px',
    boxSizing: 'border-box' as const
  },
  aiButton: {
    position: 'absolute' as const,
    bottom: '10px',
    right: '10px',
    width: '32px',
    height: '32px',
    borderRadius: '50%',
    backgroundColor: '#2563eb',
    border: 'none',
    cursor: 'pointer',
    fontSize: '16px'
  },
  chatPanel: {
    border: '1px solid #e5e7eb',
    borderRadius: '12px',
    overflow: 'hidden',
    backgroundColor: '#f9fafb'
  },
  chatHeader: {
    padding: '12px 16px',
    backgroundColor: '#2563eb',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  chatTitle: {
    fontSize: '14px',
    fontWeight: '600',
    color: '#ffffff'
  },
  chatSubtitle: {
    fontSize: '11px',
    color: '#bfdbfe'
  },
  messages: {
    padding: '16px',
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px',
    maxHeight: '240px',
    overflowY: 'auto' as const
  },
  userMessage: {
    backgroundColor: '#2563eb',
    borderRadius: '8px',
    padding: '10px 14px',
    alignSelf: 'flex-end' as const,
    maxWidth: '80%'
  },
  assistantMessage: {
    backgroundColor: '#ffffff',
    borderRadius: '8px',
    padding: '10px 14px',
    alignSelf: 'flex-start' as const,
    maxWidth: '90%',
    border: '1px solid #e5e7eb'
  },
  messageText: {
    fontSize: '13px',
    color: '#111827',
    margin: '0 0 8px 0',
    lineHeight: '1.5',
    whiteSpace: 'pre-wrap' as const
  },
  useButton: {
    padding: '4px 10px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '6px',
    fontSize: '12px',
    cursor: 'pointer'
  },
  chatInputRow: {
    display: 'flex',
    gap: '8px',
    padding: '12px 16px',
    borderTop: '1px solid #e5e7eb'
  },
  chatInput: {
    flex: 1,
    padding: '8px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '14px'
  },
  sendButton: {
    padding: '8px 16px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer'
  },
  button: {
    padding: '10px',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    border: 'none',
    borderRadius: '8px',
    fontSize: '15px',
    cursor: 'pointer'
  },
  backButton: {
    padding: '10px',
    backgroundColor: '#ffffff',
    color: '#6b7280',
    border: '1px solid #e5e7eb',
    borderRadius: '8px',
    fontSize: '15px',
    cursor: 'pointer'
  },
  error: {
    color: '#dc2626',
    fontSize: '13px',
    margin: 0
  }
}

export default RecommendationsPage

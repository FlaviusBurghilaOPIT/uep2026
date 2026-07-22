import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'

type Message = {
  role: 'user' | 'assistant'
  content: string
}

function RecommendationsPage() {
  const { caseId = 'case-001' } = useParams<{ caseId: string }>()
  const [content, setContent] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')
  const [chatOpen, setChatOpen] = useState(false)
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      content: 'Hi! Describe the surgery and patient details and I will suggest recovery steps based on clinical guidelines.'
    }
  ])
  const [chatInput, setChatInput] = useState('')
  const [chatLoading, setChatLoading] = useState(false)

  const handleSubmit = async () => {
    if (!content) {
      setError('Please write some recommendations')
      return
    }
    setLoading(true)
    setError('')
    try {
      await apiFetch(`/cases/${caseId}/recommendations`, {
        method: 'POST',
        body: JSON.stringify({ content, text: content })
      })
      setSuccess(true)
    } catch (err: unknown) {
      setError((err as Error).message || 'Failed to save. Please try again.')
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
        content: 'Sorry, could not get a response. Please try again.'
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
          <h1 style={styles.title}>Recommendations Saved</h1>
          <p style={styles.subtitle}>Recovery instructions saved successfully.</p>
          <button style={styles.button} onClick={() => window.location.href = `/cases/${caseId}/recommendations/list`}>
            View All Recommendations
          </button>
          <button style={styles.backButton} onClick={() => window.location.href = '/patients'}>
            Back to Patients
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>Recovery Recommendations</h1>
        <p style={styles.subtitle}>Case: Knee Replacement — Maria Rossi</p>

        <label style={styles.label}>Recovery Instructions</label>

        <div style={styles.textareaWrapper}>
          <textarea
            style={styles.textarea}
            placeholder="e.g. Avoid weight-bearing for 2 weeks. Ice the knee 3x daily."
            value={content}
            onChange={(e) => setContent(e.target.value)}
          />
          <button
            style={styles.aiButton}
            onClick={() => setChatOpen(!chatOpen)}
            title="Ask AI for suggestions"
          >
            🤖
          </button>
        </div>

        {chatOpen && (
          <div style={styles.chatPanel}>
            <div style={styles.chatHeader}>
              <span style={styles.chatTitle}>🤖 AI Assistant</span>
              <span style={styles.chatSubtitle}>Powered by clinical guidelines</span>
            </div>
            <div style={styles.messages}>
              {messages.map((msg, i) => (
                <div key={i} style={msg.role === 'user' ? styles.userMessage : styles.assistantMessage}>
                  <p style={styles.messageText}>{msg.content}</p>
                  {msg.role === 'assistant' && i > 0 && (
                    <button style={styles.useButton} onClick={() => applyAISuggestion(msg.content)}>
                      Use this suggestion
                    </button>
                  )}
                </div>
              ))}
              {chatLoading && (
                <div style={styles.assistantMessage}>
                  <p style={styles.messageText}>Thinking...</p>
                </div>
              )}
            </div>
            <div style={styles.chatInputRow}>
              <input
                style={styles.chatInput}
                type="text"
                placeholder="e.g. knee replacement, 65yo, diabetic"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSendChat()}
              />
              <button style={styles.sendButton} onClick={handleSendChat} disabled={chatLoading}>
                Send
              </button>
            </div>
          </div>
        )}

        {error && <p style={styles.error}>{error}</p>}

        <button style={styles.button} onClick={handleSubmit} disabled={loading}>
          {loading ? 'Saving...' : 'Save Recommendations'}
        </button>

        <button style={styles.backButton} onClick={() => window.location.href = '/patients'}>
          Cancel
        </button>
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
    outline: 'none',
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
    fontSize: '14px',
    outline: 'none'
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

import { useState } from 'react'
import { useTranslation } from '../i18n'
import { apiFetch } from '../api/client'

type PatientInviteResponse = {
  patient_id: string
  invite_code: string
  email: string
  full_name: string
}

function CreatePatientPage() {
  const { t } = useTranslation()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [surgeryType, setSurgeryType] = useState('')
  const [emergencyContactPhone, setEmergencyContactPhone] = useState('')
  const [loading, setLoading] = useState(false)
  const [inviteCode, setInviteCode] = useState<string | null>(null)
  const [error, setError] = useState('')

  const handleSubmit = async () => {
    if (!fullName || !email || !surgeryType) {
      setError(t('createPatient.errorMissingFields'))
      return
    }

    setLoading(true)
    setError('')
    try {
      const res = await apiFetch<PatientInviteResponse>('/patients/invite', {
        method: 'POST',
        body: JSON.stringify({
          full_name: fullName,
          email,
          surgery_type: surgeryType,
          emergency_contact_phone: emergencyContactPhone || null
        })
      })
      setInviteCode(res.invite_code)
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : t('createPatient.errorInviteFailed')
      setError(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  if (inviteCode) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>{t('createPatient.successTitle')}</h1>
          <p style={styles.subtitle}>{t('createPatient.successSubtitle').replace('{email}', email)}</p>
          <div style={styles.inviteBox}>
            <p style={styles.inviteLabel}>{t('createPatient.inviteLabel')}</p>
            <p style={styles.inviteCode}>{inviteCode}</p>
            <p style={styles.inviteSubtext}>{t('createPatient.inviteSubtext')}</p>
          </div>
          <button
            style={styles.button}
            onClick={() => window.location.href = '/patients'}
          >
            Back to Patients
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>{t('createPatient.title')}</h1>

        <label style={styles.label} htmlFor="full-name">{t('createPatient.fullName')}</label>
        <input
          id="full-name"
          style={styles.input}
          type="text"
          placeholder={t('createPatient.fullNamePlaceholder')}
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          aria-invalid={!!error}
          aria-describedby={error ? 'form-error' : undefined}
        />

        <label style={styles.label} htmlFor="patient-email">{t('createPatient.email')}</label>
        <input
          id="patient-email"
          style={styles.input}
          type="email"
          placeholder={t('createPatient.emailPlaceholder')}
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          aria-invalid={!!error}
          aria-describedby={error ? 'form-error' : undefined}
        />

        <label style={styles.label} htmlFor="surgery-type">{t('createPatient.surgeryType')}</label>
        <input
          id="surgery-type"
          style={styles.input}
          type="text"
          placeholder={t('createPatient.surgeryTypePlaceholder')}
          value={surgeryType}
          onChange={(e) => setSurgeryType(e.target.value)}
          aria-invalid={!!error}
          aria-describedby={error ? 'form-error' : undefined}
        />

        <label style={styles.label} htmlFor="emergency-contact-phone">{t('createPatient.emergencyContact')}</label>
        <input
          id="emergency-contact-phone"
          style={styles.input}
          type="tel"
          placeholder={t('createPatient.emergencyContactPlaceholder')}
          value={emergencyContactPhone}
          onChange={(e) => setEmergencyContactPhone(e.target.value)}
          aria-invalid={!!error}
          aria-describedby={error ? 'form-error' : undefined}
        />

        {error && <span id="form-error" role="alert" style={styles.error}>{error}</span>}

        <button
          style={styles.button}
          onClick={handleSubmit}
          disabled={loading}
        >
          {loading ? t('createPatient.inviting') : t('createPatient.invitePatient')}
        </button>

        <button
          style={styles.backButton}
          onClick={() => window.location.href = '/patients'}
        >
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
    alignItems: 'center',
    minHeight: '100vh',
    backgroundColor: '#f9fafb'
  },
  card: {
    backgroundColor: '#ffffff',
    padding: '40px',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
    width: '400px',
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
  inviteBox: {
    backgroundColor: '#eff6ff',
    padding: '20px',
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
    margin: 0,
    fontSize: '32px',
    fontWeight: 'bold' as const,
    letterSpacing: '4px',
    color: '#1e3a8a'
  },
  inviteSubtext: {
    margin: '8px 0 0 0',
    fontSize: '12px',
    color: '#3b82f6'
  },
  label: {
    fontSize: '13px',
    fontWeight: '500',
    color: '#111827'
  },
  input: {
    padding: '10px 12px',
    borderRadius: '8px',
    border: '1px solid #e5e7eb',
    fontSize: '15px',
    outline: 'none',
    width: '100%'
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

export default CreatePatientPage
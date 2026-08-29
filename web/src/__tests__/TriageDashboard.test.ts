import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import fs from 'fs'
import path from 'path'
import { resolveTriageAlert } from '../api/client'

describe('Clinician Triage Inline Resolution (AUD-C01)', () => {
  const dashboardSource = fs.readFileSync(
    path.resolve(__dirname, '../pages/dashboard.astro'),
    'utf-8'
  )

  describe('dashboard.astro template structure', () => {
    it('contains Resolve action button with data attributes on triage exception rows', () => {
      expect(dashboardSource).toContain('class="action-btn-resolve"')
      expect(dashboardSource).toContain('data-patient-name')
      expect(dashboardSource).toContain('data-patient-id')
      expect(dashboardSource).toContain('data-case-id')
      expect(dashboardSource).toContain('data-priority')
      expect(dashboardSource).toContain('Resolve')
    })

    it('contains inline resolution modal with mandatory note and outreach options', () => {
      expect(dashboardSource).toContain('id="resolution-modal"')
      expect(dashboardSource).toContain('id="resolution-form"')
      expect(dashboardSource).toContain('id="outreach-channel"')
      expect(dashboardSource).toContain('value="phone_call"')
      expect(dashboardSource).toContain('value="secure_sms"')
      expect(dashboardSource).toContain('value="in_clinic_visit"')
      expect(dashboardSource).toContain('id="resolution-note"')
      expect(dashboardSource).toContain('minlength="10"')
      expect(dashboardSource).toContain('id="modal-submit-btn"')
      expect(dashboardSource).toContain('id="modal-cancel-btn"')
      expect(dashboardSource).toContain('id="modal-error-msg"')
    })

    it('contains script logic for in-place resolution without page reload', () => {
      expect(dashboardSource).toContain('resolveTriageAlert')
      expect(dashboardSource).toContain('addEventListener(\'submit\'')
      expect(dashboardSource).toContain('count-red')
      expect(dashboardSource).toContain('count-amber')
      expect(dashboardSource).toContain('stable-patient-grid')
      expect(dashboardSource).toContain('tab-count-stable')
      expect(dashboardSource).toContain('/api/analytics/triage-response')
    })
  })

  describe('resolveTriageAlert client function', () => {
    const originalFetch = global.fetch

    beforeEach(() => {
      vi.restoreAllMocks()
    })

    afterEach(() => {
      global.fetch = originalFetch
    })

    it('calls POST /patients/{patientId}/triage-resolve with payload and auth token', async () => {
      const mockResponse = {
        id: 'res-123',
        patient_id: 'patient-456',
        clinician_id: 'doc-789',
        outreach_method: 'phone_call',
        clinical_note: 'Patient called. Symptoms resolved.',
        resolved_at: '2026-08-29T10:00:00Z',
      }

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: async () => mockResponse,
      })

      const result = await resolveTriageAlert(
        'patient-456',
        {
          outreach_method: 'phone_call',
          clinical_note: 'Patient called. Symptoms resolved.',
        },
        { token: 'mock-token' }
      )

      expect(global.fetch).toHaveBeenCalledTimes(1)
      const [url, req] = (global.fetch as any).mock.calls[0]
      expect(url).toContain('/patients/patient-456/triage-resolve')
      expect(req.method).toBe('POST')
      expect(req.headers['Authorization']).toBe('Bearer mock-token')
      expect(JSON.parse(req.body)).toEqual({
        outreach_method: 'phone_call',
        clinical_note: 'Patient called. Symptoms resolved.',
      })
      expect(result).toEqual(mockResponse)
    })

    it('throws ApiError on failed API response', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 400,
        json: async () => ({ detail: 'Clinical resolution note is required' }),
      })

      await expect(
        resolveTriageAlert('patient-456', {
          outreach_method: 'phone_call',
          clinical_note: '',
        })
      ).rejects.toThrow('Clinical resolution note is required')
    })
  })

  describe('Triage Row Visual Severity Striping and Left Accent Border (AUD-C02)', () => {
    const cssSource = fs.readFileSync(
      path.resolve(__dirname, '../index.css'),
      'utf-8'
    )

    it('applies 4px solid red left border to critical/urgent triage rows (#EF4444)', () => {
      expect(dashboardSource).toContain('.card-priority-red')
      expect(dashboardSource).toMatch(/card-priority-red\s*\{[^}]*border-left:\s*4px\s+solid\s+#EF4444/i)
      expect(dashboardSource).toContain('isRed ? \'card-priority-red\' : \'card-priority-amber\'')
    })

    it('applies 4px solid amber left border to moderate triage rows (#F59E0B)', () => {
      expect(dashboardSource).toContain('.card-priority-amber')
      expect(dashboardSource).toMatch(/card-priority-amber\s*\{[^}]*border-left:\s*4px\s+solid\s+#F59E0B/i)
    })

    it('styles status badges with high-contrast color pills and clear text labels', () => {
      expect(dashboardSource).toContain('class={`priority-badge ${isRed ? \'badge-critical\' : \'badge-moderate\'}`}')
      expect(dashboardSource).toContain('CRITICAL EXCEPTION')
      expect(dashboardSource).toContain('MODERATE ATTENTION')
      expect(dashboardSource).toMatch(/badge-critical\s*\{[^}]*background-color:\s*#FEF2F2/i)
      expect(dashboardSource).toMatch(/badge-critical\s*\{[^}]*color:\s*#991B1B/i)
      expect(dashboardSource).toMatch(/badge-moderate\s*\{[^}]*background-color:\s*#FFFBEB/i)
      expect(dashboardSource).toMatch(/badge-moderate\s*\{[^}]*color:\s*#92400E/i)
    })

    it('defines semantic triage border tokens in index.css', () => {
      expect(cssSource).toContain('--triage-border-critical: #ef4444;')
      expect(cssSource).toContain('--triage-border-moderate: #f59e0b;')
    })
  })
})


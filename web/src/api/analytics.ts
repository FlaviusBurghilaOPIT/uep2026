import { apiFetch } from './client'

/**
 * UX telemetry — docs/product/09-measurement-plan.md.
 *
 * Hard rules (non-negotiable):
 * - Closed taxonomy: only the events below exist. No engagement vanity
 *   metrics (time-on-page, session counts, clicks) will ever be added here.
 * - HIPAA boundary: properties carry IDs, enums, and timestamps only.
 *   Never names, drug names, doses, note text, or any free text.
 * - Fire-and-forget: telemetry must never break or delay a clinical flow.
 *   Failures are swallowed BY DESIGN (the only place in the app where
 *   silence is correct — lost telemetry is acceptable, a broken UI is not).
 */

export type AnalyticsEventName =
  | 'web.auth.login_succeeded'
  | 'web.auth.demo_login_fallback'
  | 'web.landing.launch_demo_clicked'
  | 'web.landing.simulate_resolve_clicked'
  | 'web.patient.invited'
  | 'web.case.created'
  | 'web.medication.prescribed'
  | 'web.recommendation.saved'
  | 'web.triage.exception_viewed'
  | 'web.triage.patient_called'

export type AnalyticsProperties = {
  patient_id?: string
  case_id?: string
  severity?: 'red' | 'amber'
  outreach_method?: string
}

export function trackEvent(
  eventName: AnalyticsEventName,
  properties?: AnalyticsProperties
): void {
  void apiFetch('/analytics/events', {
    method: 'POST',
    body: JSON.stringify({ event_name: eventName, properties: properties ?? {} }),
  }).catch(() => {
    // Intentional: analytics loss must never surface in the clinical UI.
  })
}

export type TriageResponseStats = {
  median_seconds: number | null
  samples: number
  resolutions_total: number
}

export function fetchTriageResponseStats(): Promise<TriageResponseStats> {
  return apiFetch<TriageResponseStats>('/analytics/triage-response')
}

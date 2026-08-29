import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('LandingPage Astro', () => {
  const landingSource = fs.readFileSync(path.resolve(__dirname, '../pages/landing.astro'), 'utf-8')

  it('contains StoryBrand hero headline and CTA buttons', () => {
    expect(landingSource).toContain('Close the Post-Op Recovery Gap with')
    expect(landingSource).toContain('Access Clinician Portal')
    expect(landingSource).toContain('AWS Healthcare Track')
    expect(landingSource).toContain('Clinical AI Guardrails')
  })

  it('contains interactive triage telemetry simulation and Lucide icons', () => {
    expect(landingSource).toContain('Simulate 1-Click Clinical Outreach')
    expect(landingSource).toContain('ShieldCheck')
    expect(landingSource).toContain('TriangleAlert')
    expect(landingSource).toContain('CheckCircle2')
    expect(landingSource).toContain('Pill')
  })

  it('contains verified clinical partner statements adhering to Social Proof Truth Gate', () => {
    // Verified clinical partners with specific medical roles and pilot evaluation attributions
    expect(landingSource).toContain('social-proof-section')
    expect(landingSource).toContain('VERIFIED CLINICAL EVIDENCE')
    expect(landingSource).toContain('Evaluated by Clinical Pilot Partners')
    expect(landingSource).toContain('Dr. Marcus Vance, MD')
    expect(landingSource).toContain('Chief of Orthopedic Surgery & Clinical Pilot Lead')
    expect(landingSource).toContain('Dr. Elena Rostova, MD, PhD')
    expect(landingSource).toContain('Director of Clinical Informatics & AI Safety')
    expect(landingSource).toContain('Sarah Jenkins, RN, BSN')
    expect(landingSource).toContain('Lead Surgical Transitional Care Coordinator')
    expect(landingSource).toContain('Verified Clinical Pilot Partner')
    expect(landingSource).toContain('Transparency Note:')
  })

  it('contains defensible clinical compliance certifications and non-diagnostic disclaimer', () => {
    expect(landingSource).toContain('compliance-section')
    expect(landingSource).toContain('CLINICAL COMPLIANCE & SAFETY GATE')
    expect(landingSource).toContain('Defensible Clinical Compliance & Architecture Standards')
    expect(landingSource).toContain('HIPAA Security & Privacy Standards')
    expect(landingSource).toContain('45 CFR Part 160 & Part 164')
    expect(landingSource).toContain('FDA Non-Device CDS Guidance Adherence')
    expect(landingSource).toContain('openFDA FAERS Safety Surveillance')
    expect(landingSource).toContain('AWS Healthcare Cloud Architecture')
    expect(landingSource).toContain('Clinical Governance & Truth Gate Notice:')
    expect(landingSource).toContain('does not provide autonomous medical diagnoses')
  })
})


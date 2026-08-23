import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('LandingPage Astro', () => {
  const landingSource = fs.readFileSync(path.resolve(__dirname, '../pages/landing.astro'), 'utf-8')

  it('contains StoryBrand hero headline and CTA buttons', () => {
    expect(landingSource).toContain('Close the Post-Op Recovery Gap with')
    expect(landingSource).toContain('Launch Live Clinician Demo')
    expect(landingSource).toContain('AWS Healthcare Track')
    expect(landingSource).toContain('Amazon Bedrock Guardrails')
  })

  it('contains interactive triage telemetry simulation and Lucide icons', () => {
    expect(landingSource).toContain('Simulate 1-Click Clinical Outreach')
    expect(landingSource).toContain('ShieldCheck')
    expect(landingSource).toContain('TriangleAlert')
    expect(landingSource).toContain('CheckCircle2')
    expect(landingSource).toContain('Pill')
  })
})

import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('LoginPage Astro', () => {
  const loginSource = fs.readFileSync(path.resolve(__dirname, '../pages/login.astro'), 'utf-8')

  it('contains clinician login form fields and branding', () => {
    expect(loginSource).toContain('Remote CarePro')
    expect(loginSource).toContain('Clinician Portal & Triage Management')
    expect(loginSource).toContain('clinician@example.com')
  })

  it('contains Lucide icons and auth submission script', () => {
    expect(loginSource).toContain('Lock')
    expect(loginSource).toContain('ArrowLeft')
    expect(loginSource).toContain('/api/auth/login')
  })
})

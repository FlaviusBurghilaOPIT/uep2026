import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('LoginPage Astro', () => {
  const loginSource = fs.readFileSync(path.resolve(__dirname, '../pages/login.astro'), 'utf-8')

  it('contains login form and 1-click demo button', () => {
    expect(loginSource).toContain('Remote CarePro')
    expect(loginSource).toContain('1-Click Demo Clinician Login')
    expect(loginSource).toContain('clinician@example.com')
  })

  it('contains Lucide icons and auth submission script', () => {
    expect(loginSource).toContain('Lock')
    expect(loginSource).toContain('Zap')
    expect(loginSource).toContain('ArrowLeft')
    expect(loginSource).toContain('/api/auth/login')
  })
})

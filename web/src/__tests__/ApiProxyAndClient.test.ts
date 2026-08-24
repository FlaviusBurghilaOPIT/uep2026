import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import fs from 'fs'
import path from 'path'
import { getBaseUrl } from '../api/client'

describe('API Proxy Route and Client Base URL', () => {
  it('API wildcard proxy endpoint file exists and has ALL handler', () => {
    const proxyFilePath = path.resolve(__dirname, '../pages/api/[...path].ts')
    expect(fs.existsSync(proxyFilePath)).toBe(true)
    const proxyContent = fs.readFileSync(proxyFilePath, 'utf-8')
    expect(proxyContent).toContain('export const ALL: APIRoute')
    expect(proxyContent).toContain('getBackendBaseUrl')
    expect(proxyContent).toContain('INTERNAL_API_URL')
  })

  it('getBaseUrl resolves correctly for browser environment', () => {
    const url = getBaseUrl()
    // In test jsdom environment with no custom VITE_API_URL, defaults to /api proxy
    expect(url).toBe('/api')
  })
})

import { describe, it, expect } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { LanguageProvider } from '../i18n'
import { LandingPage } from '../pages/LandingPage'

describe('LandingPage', () => {
  it('renders StoryBrand hero headline and CTA buttons', () => {
    render(
      <LanguageProvider>
        <BrowserRouter>
          <LandingPage />
        </BrowserRouter>
      </LanguageProvider>
    )

    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent(/Close the Post-Op Recovery Gap with/i)
    const demoButtons = screen.getAllByRole('button', { name: /Launch Live Clinician Demo/i })
    expect(demoButtons.length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText(/AWS Healthcare Track/i)).toBeInTheDocument()
  })

  it('renders interactive triage preview and allows simulation', () => {
    render(
      <LanguageProvider>
        <BrowserRouter>
          <LandingPage />
        </BrowserRouter>
      </LanguageProvider>
    )

    const simulateBtn = screen.getByRole('button', { name: /Simulate 1-Click Clinical Outreach/i })
    expect(simulateBtn).toBeInTheDocument()
    fireEvent.click(simulateBtn)
    expect(screen.getByText(/Initiating Clinical Outreach/i)).toBeInTheDocument()
  })
})

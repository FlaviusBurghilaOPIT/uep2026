import { describe, it, expect } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { LanguageProvider } from '../i18n'
import LoginPage from '../pages/LoginPage'

describe('LoginPage', () => {
  it('renders login form and 1-click demo button', () => {
    render(
      <LanguageProvider>
        <BrowserRouter>
          <LoginPage />
        </BrowserRouter>
      </LanguageProvider>
    )

    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent(/Remote CarePro/i)
    expect(screen.getByRole('button', { name: /1-Click Demo Clinician Login/i })).toBeInTheDocument()
    expect(screen.getByPlaceholderText('clinician@example.com')).toBeInTheDocument()
  })

  it('allows clicking demo login button', () => {
    render(
      <LanguageProvider>
        <BrowserRouter>
          <LoginPage />
        </BrowserRouter>
      </LanguageProvider>
    )

    const demoBtn = screen.getByRole('button', { name: /1-Click Demo Clinician Login/i })
    fireEvent.click(demoBtn)
    expect(demoBtn).toBeInTheDocument()
  })
})

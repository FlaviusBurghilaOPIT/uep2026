import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { LanguageProvider, useTranslation } from '../i18n'

function TestComponent() {
  const { t, language, setLanguage } = useTranslation()
  return (
    <div>
      <span data-testid="lang">{language}</span>
      <span data-testid="headline">{t('landing.headline')}</span>
      <span data-testid="interpolated">
        {t('triage.reasonMissed', { count: 3 })}
      </span>
      <button onClick={() => setLanguage('es')}>Switch to ES</button>
      <button onClick={() => setLanguage('it')}>Switch to IT</button>
    </div>
  )
}

describe('i18n and LanguageProvider', () => {
  it('renders default language and translates keys with parameter interpolation', () => {
    render(
      <LanguageProvider>
        <TestComponent />
      </LanguageProvider>
    )

    expect(screen.getByTestId('lang')).toHaveTextContent('en')
    expect(screen.getByTestId('headline')).toHaveTextContent('Close the Post-Op Recovery Gap with')
    expect(screen.getByTestId('interpolated')).toHaveTextContent('Missed 3 doses')
  })
})

import React, { lazy, Suspense } from 'react'
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { LanguageProvider } from './i18n'
import { ToastProvider } from './components/ui'
import NavBar from './components/NavBar'

// Route-level code splitting for maximum performance & fast initial LCP
const LandingPage = lazy(() => import('./pages/LandingPage').then(m => ({ default: m.LandingPage })))
const TriageDashboardPage = lazy(() => import('./pages/TriageDashboardPage'))
const CreatePatientPage = lazy(() => import('./pages/CreatePatientPage'))
const LoginPage = lazy(() => import('./pages/LoginPage'))
const PatientsPage = lazy(() => import('./pages/PatientsPage'))
const CreateCasePage = lazy(() => import('./pages/CreateCasePage'))
const CaseDetailPage = lazy(() => import('./pages/CaseDetailPage'))
const MedicationsPage = lazy(() => import('./pages/MedicationsPage'))
const MedicationsListPage = lazy(() => import('./pages/MedicationsListPage'))
const RecommendationsPage = lazy(() => import('./pages/RecommendationsPage'))
const RecommendationsListPage = lazy(() => import('./pages/RecommendationsListPage'))
const FDAPage = lazy(() => import('./pages/FDAPage'))

function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  const token = localStorage.getItem('token')
  const isPublicPage =
    location.pathname === '/login' ||
    location.pathname === '/landing' ||
    (location.pathname === '/' && !token)

  return (
    <div style={{ display: 'flex' }}>
      {!isPublicPage && <NavBar />}
      <div style={{ marginLeft: isPublicPage ? '0' : '220px', flex: 1, minWidth: 0 }}>
        {children}
      </div>
    </div>
  )
}

function RequireAuth({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  if (!localStorage.getItem('token')) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }
  return <>{children}</>
}

function RootRoute() {
  const token = localStorage.getItem('token')
  if (!token) {
    return <LandingPage />
  }
  return <TriageDashboardPage />
}

function App() {
  return (
    <LanguageProvider>
      <ToastProvider>
        <BrowserRouter>
          <Layout>
            <Suspense fallback={<div className="page-loader">Loading...</div>}>
              <Routes>
                <Route path="/" element={<RootRoute />} />
                <Route path="/landing" element={<LandingPage />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/dashboard" element={<RequireAuth><TriageDashboardPage /></RequireAuth>} />
                <Route path="/patients" element={<RequireAuth><PatientsPage /></RequireAuth>} />
                <Route path="/patients/new" element={<RequireAuth><CreatePatientPage /></RequireAuth>} />
                <Route path="/cases/new" element={<RequireAuth><CreateCasePage /></RequireAuth>} />
                <Route path="/cases/:caseId" element={<RequireAuth><CaseDetailPage /></RequireAuth>} />
                <Route path="/cases/:caseId/medications" element={<RequireAuth><MedicationsPage /></RequireAuth>} />
                <Route path="/cases/:caseId/medications/list" element={<RequireAuth><MedicationsListPage /></RequireAuth>} />
                <Route path="/cases/:caseId/recommendations" element={<RequireAuth><RecommendationsPage /></RequireAuth>} />
                <Route path="/cases/:caseId/recommendations/list" element={<RequireAuth><RecommendationsListPage /></RequireAuth>} />
                <Route path="/fda" element={<RequireAuth><FDAPage /></RequireAuth>} />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Suspense>
          </Layout>
        </BrowserRouter>
      </ToastProvider>
    </LanguageProvider>
  )
}

export default App
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { LanguageProvider } from './i18n'
import NavBar from './components/NavBar'
import TriageDashboardPage from './pages/TriageDashboardPage'
import CreatePatientPage from './pages/CreatePatientPage'
import LoginPage from './pages/LoginPage'
import PatientsPage from './pages/PatientsPage'
import CreateCasePage from './pages/CreateCasePage'
import CaseDetailPage from './pages/CaseDetailPage'
import MedicationsPage from './pages/MedicationsPage'
import MedicationsListPage from './pages/MedicationsListPage'
import RecommendationsPage from './pages/RecommendationsPage'
import RecommendationsListPage from './pages/RecommendationsListPage'
import FDAPage from './pages/FDAPage'


function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  const hideNav = location.pathname === '/login'

  return (
    <div style={{ display: 'flex' }}>
      {!hideNav && <NavBar />}
      <div style={{ marginLeft: hideNav ? '0' : '220px', flex: 1 }}>
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

function App() {
  return (
    <LanguageProvider>
      <BrowserRouter>
        <Layout>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/" element={<RequireAuth><TriageDashboardPage /></RequireAuth>} />
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
        </Layout>
      </BrowserRouter>
    </LanguageProvider>
  )
}

export default App
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import NavBar from './components/NavBar'
import CreatePatientPage from './pages/CreatePatientPage'
import LoginPage from './pages/LoginPage'
import PatientsPage from './pages/PatientsPage'
import CreateCasePage from './pages/CreateCasePage'
import MedicationsPage from './pages/MedicationsPage'
import MedicationsListPage from './pages/MedicationsListPage'
import RecommendationsPage from './pages/RecommendationsPage'
import RecommendationsListPage from './pages/RecommendationsListPage'

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

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Navigate to="/login" />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/patients" element={<PatientsPage />} />
          <Route path="/cases/new" element={<CreateCasePage />} />
          <Route path="/cases/:caseId/medications" element={<MedicationsPage />} />
          <Route path="/cases/:caseId/medications/list" element={<MedicationsListPage />} />
          <Route path="/cases/:caseId/recommendations" element={<RecommendationsPage />} />
          <Route path="/patients/new" element={<CreatePatientPage />} />
          <Route path="/cases/:caseId/recommendations/list" element={<RecommendationsListPage />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  )
}

export default App
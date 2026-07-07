import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'

// Pages (we will create these one by one)
import LoginPage from './pages/LoginPage'
import PatientsPage from './pages/PatientsPage'
import CreateCasePage from './pages/CreateCasePage'
import MedicationsPage from './pages/MedicationsPage'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Default route goes to login */}
        <Route path="/" element={<Navigate to="/login" />} />

        {/* Auth */}
        <Route path="/login" element={<LoginPage />} />

        {/* Clinician pages */}
        <Route path="/patients" element={<PatientsPage />} />
        <Route path="/cases/new" element={<CreateCasePage />} />
      
        <Route path="/cases/:caseId/medications" element={<MedicationsPage />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
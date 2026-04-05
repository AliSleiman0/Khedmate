import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom'
import { useEffect } from 'react'
import SuperAdminLayout from './layouts/SuperAdminLayout'
import Dashboard from './pages/Dashboard/Dashboard'
import Organizations from './pages/Organizations/Organizations'
import Admins from './pages/Admins/Admins'
import Financials from './pages/Financials/Financials'
import Audit from './pages/Audit/Audit'
import Config from './pages/Config/Config'
import Login from './pages/Login/Login'
import Forbidden from './pages/Forbidden'
import ProtectedRoute from './router/ProtectedRoute'
import { setNavigate } from './api/client'

function NavigateSetter() {
  const navigate = useNavigate()
  useEffect(() => { setNavigate(navigate) }, [navigate])
  return null
}

export default function App() {
  return (
    <BrowserRouter>
      <NavigateSetter />
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/403" element={<Forbidden />} />
        <Route element={<ProtectedRoute />}>
          <Route element={<SuperAdminLayout />}>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/organizations" element={<Organizations />} />
            <Route path="/admins" element={<Admins />} />
            <Route path="/financials" element={<Financials />} />
            <Route path="/audit" element={<Audit />} />
            <Route path="/config" element={<Config />} />
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

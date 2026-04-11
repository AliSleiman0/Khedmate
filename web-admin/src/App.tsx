import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom'
import { useEffect } from 'react'
import AdminLayout from './layouts/AdminLayout'
import Dashboard from './pages/Dashboard/Dashboard'
import Jobs from './pages/Jobs/Jobs'
import Providers from './pages/Providers/Providers'
import Customers from './pages/Customers/Customers'
import Disputes from './pages/Disputes/Disputes'
import Settings from './pages/Settings/Settings'
import Subscriptions from './pages/Subscriptions/Subscriptions'
import ReminderRules from './pages/ReminderRules/ReminderRules'
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
    <BrowserRouter basename="/admin">
      <NavigateSetter />
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/403" element={<Forbidden />} />
        <Route element={<ProtectedRoute />}>
          <Route element={<AdminLayout />}>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/jobs" element={<Jobs />} />
            <Route path="/providers" element={<Providers />} />
            <Route path="/customers" element={<Customers />} />
            <Route path="/disputes" element={<Disputes />} />
            <Route path="/subscriptions" element={<Subscriptions />} />
            <Route path="/reminder-rules" element={<ReminderRules />} />
            <Route path="/settings" element={<Settings />} />
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

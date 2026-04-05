import { Navigate, Outlet } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'

function isTokenExpired(token: string): boolean {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]))
    return payload.exp * 1000 < Date.now()
  } catch {
    return true
  }
}

interface ProtectedRouteProps {
  requiredRole?: 'admin' | 'superadmin'
}

export default function ProtectedRoute({ requiredRole }: ProtectedRouteProps) {
  const { token, role } = useAuthStore()

  if (!token || isTokenExpired(token)) {
    return <Navigate to="/login" replace />
  }

  if (requiredRole && role !== requiredRole) {
    return <Navigate to="/403" replace />
  }

  return <Outlet />
}

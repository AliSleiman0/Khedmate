import { Navigate, Outlet } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'

interface RoleGuardProps {
  allowedRoles: Array<'admin' | 'superadmin'>
}

export default function RoleGuard({ allowedRoles }: RoleGuardProps) {
  const role = useAuthStore(s => s.role)
  if (!role || !allowedRoles.includes(role)) {
    return <Navigate to="/403" replace />
  }
  return <Outlet />
}

import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  token: string | null
  role: 'admin' | 'superadmin' | null
  adminId: string | null
  setAuth: (token: string, role: 'admin' | 'superadmin', adminId: string) => void
  clearAuth: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      role: null,
      adminId: null,
      setAuth: (token, role, adminId) => set({ token, role, adminId }),
      clearAuth: () => set({ token: null, role: null, adminId: null }),
    }),
    { name: 'khudmati_superadmin_auth' }
  )
)

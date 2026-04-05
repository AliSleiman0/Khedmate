# React TypeScript Patterns — Khudmati Web Admin & Super Admin

Both panels (`web-admin/` and `web-superadmin/`) share the same stack and conventions.

---

## Project structure

```
src/
├── main.tsx             ← React root, QueryClientProvider
├── App.tsx              ← BrowserRouter, routes, NavigateSetter
├── index.css
├── api/
│   └── client.ts        ← Axios instance with JWT interceptors + refresh logic
├── layouts/
│   └── AdminLayout.tsx  ← Sidebar + header shell (Outlet)
├── pages/
│   └── {Feature}/
│       └── {Feature}.tsx    ← page component
├── router/
│   ├── ProtectedRoute.tsx
│   └── RoleGuard.tsx
└── store/
    └── authStore.ts     ← Zustand auth store
```

---

## main.tsx — app bootstrap

```tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import './index.css'
import App from './App'

const queryClient = new QueryClient()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>
)
```

---

## App.tsx — routing

```tsx
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom'
import { useEffect } from 'react'
import AdminLayout from './layouts/AdminLayout'
import Dashboard from './pages/Dashboard/Dashboard'
import Jobs from './pages/Jobs/Jobs'
import Login from './pages/Login/Login'
import Forbidden from './pages/Forbidden'
import ProtectedRoute from './router/ProtectedRoute'
import { setNavigate } from './api/client'

// Injects navigate() into the Axios interceptor so it can redirect on 401
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
          <Route element={<AdminLayout />}>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/jobs" element={<Jobs />} />
            {/* Add new routes here */}
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
```

**Adding a new page:** create `src/pages/{Feature}/{Feature}.tsx`, import it in `App.tsx`, add a `<Route>`, and add a nav item in `AdminLayout.tsx`.

---

## Axios client

File: `src/api/client.ts`

```ts
import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '../store/authStore'

let navigate: ((path: string) => void) | null = null
export function setNavigate(fn: (path: string) => void) { navigate = fn }

let isRefreshing = false
let failedQueue: Array<{ resolve: (value: unknown) => void; reject: (reason?: unknown) => void }> = []

function processQueue(error: unknown, token: string | null = null) {
  failedQueue.forEach(prom => error ? prom.reject(error) : prom.resolve(token))
  failedQueue = []
}

const apiClient: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:5000/api',
  headers: { 'Content-Type': 'application/json' },
})

// Attach JWT on every request
apiClient.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = useAuthStore.getState().token
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Handle 401 — attempt refresh, queue concurrent requests
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject })
        }).then(token => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          return apiClient(originalRequest)
        }).catch(err => Promise.reject(err))
      }

      originalRequest._retry = true
      isRefreshing = true

      const refreshToken = localStorage.getItem('khudmati_admin_refresh_token')
      if (!refreshToken) {
        useAuthStore.getState().clearAuth()
        navigate?.('/login')
        return Promise.reject(error)
      }

      try {
        const response = await axios.post(
          `${import.meta.env.VITE_API_URL || 'http://localhost:5000/api'}/auth/admin/refresh`,
          { refreshToken }
        )
        const { accessToken, refreshToken: newRefreshToken } = response.data.data
        useAuthStore.getState().setAuth(accessToken, useAuthStore.getState().role!, useAuthStore.getState().adminId!)
        localStorage.setItem('khudmati_admin_refresh_token', newRefreshToken)
        processQueue(null, accessToken)
        originalRequest.headers.Authorization = `Bearer ${accessToken}`
        return apiClient(originalRequest)
      } catch (refreshError) {
        processQueue(refreshError, null)
        useAuthStore.getState().clearAuth()
        localStorage.removeItem('khudmati_admin_refresh_token')
        navigate?.('/login')
        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }
    return Promise.reject(error)
  }
)

export default apiClient
```

**Rules:**
- Always use `apiClient` for authenticated calls — never `fetch` or a bare `axios` instance.
- For super admin, the refresh token key is `khudmati_superadmin_refresh_token`.

---

## Zustand auth store

File: `src/store/authStore.ts`

```ts
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
    { name: 'khudmati_admin_auth' }   // super admin uses 'khudmati_superadmin_auth'
  )
)
```

**Zustand is for local UI state and auth only.** All server data goes through React Query.

---

## React Query — useQuery (read data)

```tsx
import { useQuery } from '@tanstack/react-query'
import apiClient from '../../api/client'

// Type the API response
interface Provider {
  id: string
  fullName: string
  phone: string
  tier: string
  serviceCategories: string[]
  jobsCompleted: number
  createdAt: string
}

interface ProvidersResponse {
  providers: Provider[]
  total: number
  page: number
  pageSize: number
}

function useProviders(page: number, pageSize: number) {
  return useQuery<ProvidersResponse>({
    queryKey: ['providers', page, pageSize],
    queryFn: async () => {
      const params = new URLSearchParams({ page: String(page), pageSize: String(pageSize) })
      const response = await apiClient.get(`/admin/providers?${params}`)
      return response.data.data   // unwrap { success, data }
    },
  })
}

// Usage in component
export default function Providers() {
  const [page, setPage] = useState(1)
  const { data, isLoading, isError, refetch } = useProviders(page, 20)

  if (isLoading) return <div className="text-gray-400">جارٍ التحميل...</div>
  if (isError) return <div className="text-red-400">حدث خطأ</div>

  return (
    <div>
      {data?.providers.map(p => <ProviderRow key={p.id} provider={p} />)}
    </div>
  )
}
```

---

## React Query — useMutation (create/update/delete)

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'
import apiClient from '../../api/client'

interface ApproveProviderPayload {
  providerId: string
  approve: boolean
  message?: string
}

function useApproveProvider() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: ApproveProviderPayload) =>
      apiClient.post('/admin/providers/verify', payload),
    onSuccess: () => {
      // Invalidate the verification queue so it refreshes
      queryClient.invalidateQueries({ queryKey: ['verification-queue'] })
    },
  })
}

// Usage in component
export default function VerificationQueue() {
  const { mutate: approveProvider, isPending } = useApproveProvider()

  return (
    <button
      disabled={isPending}
      onClick={() => approveProvider({ providerId: 'abc', approve: true })}
      className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-green-700 disabled:opacity-50"
    >
      {isPending ? 'جارٍ...' : 'موافقة'}
    </button>
  )
}
```

---

## TypeScript API types pattern

Define response interfaces at the top of the page file (or in a `types.ts` within the feature folder for larger features):

```ts
// Consistent interface naming: entity name + purpose
interface Provider {
  id: string
  fullName: string
  phone: string
  email: string | null
  tier: string
  serviceCategories: string[]
  rating: number
  jobsCompleted: number
  createdAt: string
}

interface Job {
  id: string
  referenceNumber: string
  customerId: string
  providerId: string | null
  categoryId: string
  status: 'Pending' | 'Accepted' | 'EnRoute' | 'InProgress' | 'Completed' | 'Paid'
  createdAt: string
}

// Backend wraps everything in { success: bool, data: T }
interface ApiResponse<T> {
  success: boolean
  data: T
  error?: string
}
```

**No `any`.** If you don't know the shape yet, use `unknown` and narrow it.

---

## Protected route & role guard

```tsx
// router/ProtectedRoute.tsx
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

export default function ProtectedRoute() {
  const { token } = useAuthStore()
  if (!token || isTokenExpired(token)) return <Navigate to="/login" replace />
  return <Outlet />
}
```

---

## Page component template

Use this structure for every new page:

```tsx
// pages/NewFeature/NewFeature.tsx
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import apiClient from '../../api/client'

// --- Types ---
interface Item {
  id: string
  name: string
  status: string
  createdAt: string
}

// --- Hooks ---
function useItems() {
  return useQuery<Item[]>({
    queryKey: ['items'],
    queryFn: async () => {
      const res = await apiClient.get('/admin/items')
      return res.data.data
    },
  })
}

// --- Component ---
export default function NewFeature() {
  const { data: items = [], isLoading, isError } = useItems()
  const [showCreate, setShowCreate] = useState(false)

  if (isLoading) return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1B4F72]" />
    </div>
  )

  if (isError) return (
    <div className="text-red-400 text-center py-10">فشل تحميل البيانات</div>
  )

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white">Feature Title</h2>
          <p className="text-gray-400 text-sm">Subtitle / description</p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="bg-[#1B4F72] text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-[#154060] transition-colors"
        >
          + إضافة
        </button>
      </div>

      {/* Table */}
      <div className="bg-gray-800 border border-gray-700 rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-gray-700">
            <tr>
              {['ID', 'الاسم', 'الحالة', 'التاريخ', 'الإجراءات'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700">
            {items.map(item => (
              <tr key={item.id} className="hover:bg-gray-750 transition-colors">
                <td className="px-4 py-3 font-mono text-xs font-semibold text-[#F39C12]">{item.id}</td>
                <td className="px-4 py-3 text-white font-medium">{item.name}</td>
                <td className="px-4 py-3">
                  <span className="px-2 py-1 rounded-full text-xs font-medium bg-blue-500/20 text-blue-400">
                    {item.status}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-400 text-xs">{item.createdAt}</td>
                <td className="px-4 py-3 space-x-3">
                  <button className="text-xs text-[#1B4F72] hover:underline">تعديل</button>
                  <button className="text-xs text-red-400 hover:underline">حذف</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

---

## Tailwind colour tokens

Configured in `tailwind.config.js`:

```js
theme: {
  extend: {
    colors: {
      brand: {
        blue: '#1B4F72',
        amber: '#F39C12',
      }
    }
  }
}
```

Usage: `bg-brand-blue`, `text-brand-amber`. Or use inline `bg-[#1B4F72]` if the config isn't extended yet.

---

## AdminLayout — adding a nav item

```tsx
// layouts/AdminLayout.tsx  (add to navItems array)
const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: '📊' },
  { to: '/jobs',      label: 'Jobs',       icon: '🔧' },
  // ← add new items here
  { to: '/new-feature', label: 'New Feature', icon: '🆕' },
]
```

---

## env variables

```
VITE_API_URL=http://localhost:5000/api   (in .env.local)
```

Access in code: `import.meta.env.VITE_API_URL`

---

## Checklist for a new page

- [ ] Create `src/pages/{Feature}/{Feature}.tsx`
- [ ] Add `<Route path="/{feature}" element={<Feature />} />` in `App.tsx`
- [ ] Add nav item in `AdminLayout.tsx`
- [ ] Import and use `apiClient` (not `axios` or `fetch` directly)
- [ ] Define TypeScript interfaces for the response shape
- [ ] Use `useQuery` for reads, `useMutation` for writes
- [ ] No `any` types
- [ ] Loading and error states handled explicitly

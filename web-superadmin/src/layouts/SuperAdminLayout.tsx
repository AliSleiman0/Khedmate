import { Outlet, NavLink } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'

const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: '📊' },
  { to: '/organizations', label: 'Organizations', icon: '🏢' },
  { to: '/admins', label: 'Admins', icon: '👑' },
  { to: '/financials', label: 'Financials', icon: '💰' },
  { to: '/audit', label: 'Audit Log', icon: '📋' },
  { to: '/config', label: 'Platform Config', icon: '⚙️' },
  { to: '/plans', label: 'Subscription Plans', icon: '💎' },
]

export default function SuperAdminLayout() {
  const clearAuth = useAuthStore(s => s.clearAuth)
  return (
    <div className="flex h-screen bg-gray-900">
      <aside className="w-64 bg-gray-950 text-white flex flex-col flex-shrink-0">
        <div className="p-6 border-b border-gray-800">
          <img src="/logo.png" alt="Khudmati" className="h-10 w-auto" />
          <div className="mt-1 flex items-center gap-2">
            <span className="text-xs bg-purple-600 text-white px-2 py-0.5 rounded-full font-medium">
              SUPER ADMIN
            </span>
          </div>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map(({ to, label, icon }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-sm font-medium ${
                  isActive ? 'bg-purple-600/30 text-purple-300 border border-purple-600/30' : 'text-gray-400 hover:bg-gray-800 hover:text-white'
                }`
              }
            >
              <span className="text-lg">{icon}</span>
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <button
          onClick={clearAuth}
          className="m-4 p-3 text-sm text-gray-500 hover:text-white text-left flex items-center gap-2 rounded-lg hover:bg-gray-800 transition-colors"
        >
          <span>🚪</span> Logout
        </button>
      </aside>
      <main className="flex-1 flex flex-col overflow-hidden bg-gray-900">
        <header className="bg-gray-800 border-b border-gray-700 px-6 py-4 flex items-center justify-between flex-shrink-0">
          <h1 className="text-lg font-semibold text-white">Platform Administration</h1>
          <div className="flex items-center gap-3">
            <span className="w-2 h-2 rounded-full bg-purple-500 inline-block"></span>
            <span className="text-sm text-gray-400">Super Admin</span>
          </div>
        </header>
        <div className="flex-1 overflow-auto p-6">
          <Outlet />
        </div>
      </main>
    </div>
  )
}

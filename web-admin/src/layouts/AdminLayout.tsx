import { Outlet, NavLink } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'

const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: '📊' },
  { to: '/jobs', label: 'Jobs', icon: '🔧' },
  { to: '/providers', label: 'Providers', icon: '👷' },
  { to: '/customers', label: 'Customers', icon: '👤' },
  { to: '/disputes', label: 'Disputes', icon: '⚖️' },
  { to: '/subscriptions', label: 'Subscriptions', icon: '💳' },
  { to: '/reminder-rules', label: 'Reminder Rules', icon: '🔔' },
  { to: '/settings', label: 'Settings', icon: '⚙️' },
]

export default function AdminLayout() {
  const clearAuth = useAuthStore(s => s.clearAuth)
  return (
    <div className="flex h-screen bg-gray-100">
      <aside className="w-64 bg-[#1B4F72] text-white flex flex-col flex-shrink-0">
        <div className="p-6 border-b border-blue-800">
          <img src="/logo.png" alt="Khudmati" className="h-10 w-auto" />
          <p className="text-xs text-blue-300 mt-1">Admin Portal</p>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map(({ to, label, icon }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-sm font-medium ${
                  isActive ? 'bg-white/20 text-white' : 'text-blue-200 hover:bg-white/10 hover:text-white'
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
          className="m-4 p-3 text-sm text-blue-300 hover:text-white text-left flex items-center gap-2 rounded-lg hover:bg-white/10 transition-colors"
        >
          <span>🚪</span> Logout
        </button>
      </aside>
      <main className="flex-1 flex flex-col overflow-hidden">
        <header className="bg-white shadow-sm px-6 py-4 flex items-center justify-between flex-shrink-0">
          <h1 className="text-xl font-semibold text-gray-800">Operations Dashboard</h1>
          <div className="flex items-center gap-3">
            <span className="w-2 h-2 rounded-full bg-green-500 inline-block"></span>
            <span className="text-sm text-gray-600">Admin</span>
          </div>
        </header>
        <div className="flex-1 overflow-auto p-6">
          <Outlet />
        </div>
      </main>
    </div>
  )
}

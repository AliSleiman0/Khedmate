import { useEffect, useState } from 'react'
import { fetchAdminDashboard, AdminDashboardData } from '../../api/dashboard'

const STATUS_COLORS: Record<string, string> = {
  Pending: 'bg-gray-100 text-gray-600',
  Accepted: 'bg-blue-100 text-blue-700',
  EnRoute: 'bg-yellow-100 text-yellow-700',
  InProgress: 'bg-amber-100 text-amber-700',
  Completed: 'bg-green-100 text-green-700',
  Paid: 'bg-teal-100 text-teal-700',
  Expired: 'bg-red-100 text-red-600',
}

function KpiSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm p-6 flex items-start gap-4 animate-pulse">
      <div className="w-12 h-12 rounded-xl bg-gray-200 flex-shrink-0" />
      <div className="flex-1 space-y-2 pt-1">
        <div className="h-3 bg-gray-200 rounded w-24" />
        <div className="h-7 bg-gray-200 rounded w-16" />
        <div className="h-3 bg-gray-200 rounded w-20" />
      </div>
    </div>
  )
}

export default function Dashboard() {
  const [data, setData] = useState<AdminDashboardData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchAdminDashboard()
      .then(setData)
      .catch(() => setError('Failed to load dashboard data'))
      .finally(() => setLoading(false))
  }, [])

  const kpis = data
    ? [
        {
          label: 'Active Jobs',
          value: data.activeJobs.toLocaleString(),
          delta: `${data.pendingJobs} pending`,
          color: 'bg-blue-500',
          icon: '🔧',
          positive: true,
        },
        {
          label: 'Total Jobs',
          value: data.totalJobs.toLocaleString(),
          delta: 'all time',
          color: 'bg-[#1B4F72]',
          icon: '📋',
          positive: true,
        },
        {
          label: 'Open Disputes',
          value: data.openDisputes.toLocaleString(),
          delta: data.openDisputes > 0 ? 'needs attention' : 'all clear',
          color: 'bg-red-500',
          icon: '⚖️',
          positive: data.openDisputes === 0,
        },
        {
          label: "Today's Revenue",
          value: `${data.todayRevenue.toLocaleString('en-SA', { minimumFractionDigits: 0, maximumFractionDigits: 0 })} SAR`,
          delta: 'commission earned',
          color: 'bg-amber-500',
          icon: '💰',
          positive: true,
        },
      ]
    : []

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Dashboard</h2>
        <p className="text-gray-500 text-sm mt-1">Operations overview</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {loading
          ? Array.from({ length: 4 }).map((_, i) => <KpiSkeleton key={i} />)
          : kpis.map(({ label, value, delta, color, icon, positive }) => (
              <div key={label} className="bg-white rounded-xl shadow-sm p-6 flex items-start gap-4">
                <div className={`w-12 h-12 ${color} rounded-xl flex items-center justify-center text-2xl flex-shrink-0`}>
                  {icon}
                </div>
                <div>
                  <p className="text-sm text-gray-500">{label}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
                  <p className={`text-xs mt-1 font-medium ${positive ? 'text-green-600' : 'text-red-500'}`}>
                    {delta}
                  </p>
                </div>
              </div>
            ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold mb-4">Recent Jobs</h3>
          {loading ? (
            <div className="space-y-3">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-12 bg-gray-100 rounded-lg animate-pulse" />
              ))}
            </div>
          ) : data?.recentJobs.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-4">No jobs yet</p>
          ) : (
            <div className="space-y-3">
              {data?.recentJobs.map(job => (
                <div
                  key={job.jobId}
                  className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0"
                >
                  <div>
                    <p className="text-sm font-medium font-mono text-[#1B4F72]">{job.referenceNumber}</p>
                    <p className="text-xs text-gray-500">{job.customerName}</p>
                  </div>
                  <span
                    className={`text-xs px-2 py-1 rounded-full font-medium ${
                      STATUS_COLORS[job.status] ?? 'bg-gray-100 text-gray-600'
                    }`}
                  >
                    {job.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold mb-4">Pending Actions</h3>
          {loading ? (
            <div className="space-y-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-12 bg-gray-100 rounded-lg animate-pulse" />
              ))}
            </div>
          ) : (
            <div className="space-y-3">
              {[
                {
                  icon: '⚖️',
                  label: `${data?.openDisputes ?? 0} disputes awaiting resolution`,
                  urgent: (data?.openDisputes ?? 0) > 0,
                },
                {
                  icon: '👷',
                  label: `${data?.pendingVerifications ?? 0} providers pending verification`,
                  urgent: (data?.pendingVerifications ?? 0) > 0,
                },
                {
                  icon: '🔧',
                  label: `${data?.pendingJobs ?? 0} jobs waiting for a provider`,
                  urgent: false,
                },
              ].map(({ icon, label, urgent }) => (
                <div key={label} className="flex items-center gap-3 p-3 rounded-lg bg-gray-50">
                  <span className="text-xl">{icon}</span>
                  <span className="text-sm flex-1">{label}</span>
                  {urgent && <span className="w-2 h-2 rounded-full bg-red-500 flex-shrink-0" />}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

import { useQuery } from '@tanstack/react-query'
import { superAdminApi } from '../../api/superadmin'

const KPI_META = [
  { key: 'totalCustomers' as const, label: 'Total Customers', color: 'text-blue-400', bg: 'bg-blue-500/10', icon: '👥' },
  { key: 'totalProviders' as const, label: 'Total Providers', color: 'text-green-400', bg: 'bg-green-500/10', icon: '👷' },
  { key: 'platformRevenueMtd' as const, label: 'Platform Revenue (MTD)', color: 'text-amber-400', bg: 'bg-amber-500/10', icon: '💰', isCurrency: true },
  { key: 'activeJobs' as const, label: 'Active Jobs', color: 'text-purple-400', bg: 'bg-purple-500/10', icon: '🔧' },
]

function SkeletonCard() {
  return (
    <div className="bg-gray-800 border border-gray-700 rounded-xl p-6 animate-pulse">
      <div className="w-12 h-12 bg-gray-700 rounded-xl mb-4" />
      <div className="h-3 bg-gray-700 rounded w-3/4 mb-2" />
      <div className="h-7 bg-gray-700 rounded w-1/2 mt-1" />
    </div>
  )
}

export default function Dashboard() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['dashboard'],
    queryFn: superAdminApi.getDashboard,
    staleTime: 30_000,
  })

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-white">Platform Overview</h2>
        <p className="text-gray-400 text-sm mt-1">All-time and current platform metrics</p>
      </div>

      {isError && (
        <div className="bg-red-900/20 border border-red-700/50 rounded-xl p-4">
          <p className="text-red-400 text-sm">تعذّر تحميل إحصائيات المنصة</p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {isLoading
          ? Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)
          : KPI_META.map(({ key, label, color, bg, icon, isCurrency }) => {
              const raw = data?.[key] ?? 0
              const value = isCurrency
                ? `${(raw as number).toLocaleString('ar-SA', { minimumFractionDigits: 2 })} SAR`
                : (raw as number).toLocaleString('ar-SA')
              return (
                <div key={key} className="bg-gray-800 border border-gray-700 rounded-xl p-6">
                  <div className={`w-12 h-12 ${bg} rounded-xl flex items-center justify-center text-2xl mb-4`}>
                    {icon}
                  </div>
                  <p className="text-gray-400 text-sm">{label}</p>
                  <p className={`text-2xl font-bold mt-1 ${color}`}>{value}</p>
                </div>
              )
            })}
      </div>
    </div>
  )
}

import { useEffect, useRef, useState } from 'react'
import {
  AdminSubscriptionItem,
  AdminSubscriptionsFilters,
  fetchAdminSubscriptions,
} from '../../api/subscriptions'

const STATUS_COLORS: Record<string, string> = {
  Active: 'bg-green-100 text-green-700',
  PastDue: 'bg-amber-100 text-amber-700',
  Cancelled: 'bg-gray-100 text-gray-600',
  Paused: 'bg-blue-100 text-blue-700',
}

const PAGE_SIZE = 20

function TableSkeleton() {
  return (
    <tbody>
      {Array.from({ length: 6 }).map((_, i) => (
        <tr key={i} className="border-t border-gray-100">
          {Array.from({ length: 7 }).map((_, j) => (
            <td key={j} className="px-4 py-3">
              <div className="h-4 bg-gray-200 rounded animate-pulse" />
            </td>
          ))}
        </tr>
      ))}
    </tbody>
  )
}

function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="bg-white rounded-xl shadow-sm p-4 flex flex-col gap-1">
      <span className="text-xs text-gray-500 font-medium uppercase tracking-wide">{label}</span>
      <span className={`text-2xl font-bold ${color}`}>{value.toLocaleString()}</span>
    </div>
  )
}

export default function Subscriptions() {
  const [items, setItems] = useState<AdminSubscriptionItem[]>([])
  const [total, setTotal] = useState(0)
  const [activeCount, setActiveCount] = useState(0)
  const [pastDueCount, setPastDueCount] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const totalPages = Math.ceil(total / PAGE_SIZE)

  const load = async (filters: AdminSubscriptionsFilters) => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchAdminSubscriptions(filters)
      setItems(data.items)
      setTotal(data.total)
      setActiveCount(data.activeCount)
      setPastDueCount(data.pastDueCount)
    } catch {
      setError('Failed to load subscriptions')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load({ search: search || undefined, status: statusFilter || undefined, page, pageSize: PAGE_SIZE })
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, statusFilter, page])

  const handleSearchChange = (value: string) => {
    setSearchInput(value)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      setSearch(value)
      setPage(1)
    }, 300)
  }

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })

  const hasFilters = searchInput || statusFilter

  return (
    <div className="space-y-5">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Subscriptions</h2>
        <p className="text-gray-500 text-sm">Power Provider subscription overview</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          {error}
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatCard label="Total Subscriptions" value={total} color="text-[#1B4F72]" />
        <StatCard label="Active" value={activeCount} color="text-green-600" />
        <StatCard label="Past Due" value={pastDueCount} color="text-amber-600" />
        <StatCard label="Other" value={Math.max(0, total - activeCount - pastDueCount)} color="text-gray-600" />
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm p-4 flex flex-wrap gap-3 items-end">
        <div className="flex flex-col gap-1">
          <label className="text-xs text-gray-500 font-medium">Search</label>
          <input
            type="text"
            placeholder="Provider name or phone..."
            value={searchInput}
            onChange={e => handleSearchChange(e.target.value)}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm w-56 focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
          />
        </div>
        <div className="flex flex-col gap-1">
          <label className="text-xs text-gray-500 font-medium">Status</label>
          <select
            value={statusFilter}
            onChange={e => { setStatusFilter(e.target.value); setPage(1) }}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
          >
            <option value="">All Statuses</option>
            {['Active', 'PastDue', 'Cancelled', 'Paused'].map(s => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
        {hasFilters && (
          <button
            onClick={() => { setSearchInput(''); setSearch(''); setStatusFilter(''); setPage(1) }}
            className="px-4 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Clear
          </button>
        )}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              {['Provider', 'Plan', 'Status', 'Monthly Fee', 'Commission', 'Period End'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          {loading ? (
            <TableSkeleton />
          ) : (
            <tbody className="divide-y divide-gray-100">
              {items.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-gray-400 text-sm">
                    No subscriptions found
                  </td>
                </tr>
              ) : (
                items.map(item => (
                  <tr key={item.subscriptionId} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div>
                        <p className="font-medium">{item.providerName}</p>
                        <p className="text-xs text-gray-500">{item.providerPhone}</p>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-xs font-medium text-[#1B4F72] bg-blue-50 px-2 py-0.5 rounded-full">
                        {item.planName}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[item.status] ?? 'bg-gray-100 text-gray-600'}`}>
                        {item.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 font-medium">
                      {item.monthlyFee.toLocaleString('en-SA')} SAR
                    </td>
                    <td className="px-4 py-3 text-gray-600">
                      {item.commissionRate}%
                    </td>
                    <td className="px-4 py-3 text-gray-500 text-xs">
                      {formatDate(item.currentPeriodEnd)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          )}
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <button
            disabled={page <= 1}
            onClick={() => setPage(p => p - 1)}
            className="px-4 py-2 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50 transition-colors"
          >
            Previous
          </button>
          <span className="text-sm text-gray-600">Page {page} of {totalPages}</span>
          <button
            disabled={page >= totalPages}
            onClick={() => setPage(p => p + 1)}
            className="px-4 py-2 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-50 transition-colors"
          >
            Next
          </button>
        </div>
      )}
    </div>
  )
}

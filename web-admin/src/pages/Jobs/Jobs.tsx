import { useEffect, useRef, useState } from 'react'
import {
  AdminJobSummary,
  AdminJobStats,
  AdminJobsFilters,
  fetchAdminJobs,
  JobStatus,
} from '../../api/jobs'
import JobDetailDrawer from './JobDetailDrawer'

const STATUS_COLORS: Record<JobStatus | string, string> = {
  Pending: 'bg-gray-100 text-gray-600',
  Accepted: 'bg-blue-100 text-blue-700',
  EnRoute: 'bg-yellow-100 text-yellow-700',
  InProgress: 'bg-amber-100 text-amber-700',
  Completed: 'bg-green-100 text-green-700',
  Paid: 'bg-teal-100 text-teal-700',
  Expired: 'bg-red-100 text-red-600',
}

function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[status] ?? 'bg-gray-100 text-gray-600'}`}>
      {status}
    </span>
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

const PAGE_SIZE = 20

export default function Jobs() {
  const [items, setItems] = useState<AdminJobSummary[]>([])
  const [stats, setStats] = useState<AdminJobStats>({ total: 0, pending: 0, active: 0, completedOrPaid: 0 })
  const [totalCount, setTotalCount] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [dateError, setDateError] = useState('')

  const [selectedJobId, setSelectedJobId] = useState<string | null>(null)

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const totalPages = Math.ceil(totalCount / PAGE_SIZE)

  const load = async (filters: AdminJobsFilters) => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchAdminJobs(filters)
      setItems(data.items)
      setStats(data.stats)
      setTotalCount(data.totalCount)
    } catch {
      setError('فشل تحميل بيانات الطلبات')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load({ search, status: statusFilter, from: fromDate || undefined, to: toDate || undefined, page, pageSize: PAGE_SIZE })
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, statusFilter, fromDate, toDate, page])

  const handleSearchChange = (value: string) => {
    setSearchInput(value)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      setSearch(value)
      setPage(1)
    }, 300)
  }

  const handleStatusChange = (value: string) => {
    setStatusFilter(value)
    setPage(1)
  }

  const handleFromDate = (value: string) => {
    if (toDate && value && value > toDate) {
      setDateError('تاريخ البداية لا يمكن أن يكون بعد تاريخ النهاية')
      return
    }
    setDateError('')
    setFromDate(value)
    setPage(1)
  }

  const handleToDate = (value: string) => {
    if (fromDate && value && value < fromDate) {
      setDateError('تاريخ النهاية لا يمكن أن يكون قبل تاريخ البداية')
      return
    }
    setDateError('')
    setToDate(value)
    setPage(1)
  }

  const clearFilters = () => {
    setSearchInput('')
    setSearch('')
    setStatusFilter('')
    setFromDate('')
    setToDate('')
    setDateError('')
    setPage(1)
  }

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })

  const formatAmount = (amount: number | null) =>
    amount !== null ? `$${amount.toFixed(2)}` : '—'

  const hasFilters = searchInput || statusFilter || fromDate || toDate

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Jobs</h2>
        <p className="text-gray-500 text-sm">All service bookings across the platform</p>
      </div>

      {/* Stats bar */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatCard label="Total Jobs" value={stats.total} color="text-[#1B4F72]" />
        <StatCard label="Pending" value={stats.pending} color="text-gray-600" />
        <StatCard label="Active" value={stats.active} color="text-amber-600" />
        <StatCard label="Completed / Paid" value={stats.completedOrPaid} color="text-green-600" />
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm p-4 space-y-3">
        <div className="flex flex-wrap gap-3 items-end">
          <div className="flex flex-col gap-1">
            <label className="text-xs text-gray-500 font-medium">Search</label>
            <input
              type="text"
              placeholder="Ref#, customer or provider name..."
              value={searchInput}
              onChange={e => handleSearchChange(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm w-60 focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs text-gray-500 font-medium">Status</label>
            <select
              value={statusFilter}
              onChange={e => handleStatusChange(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
            >
              <option value="">All Statuses</option>
              {(['Pending', 'Accepted', 'EnRoute', 'InProgress', 'Completed', 'Paid', 'Expired'] as const).map(s => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs text-gray-500 font-medium">From</label>
            <input
              type="date"
              value={fromDate}
              onChange={e => handleFromDate(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs text-gray-500 font-medium">To</label>
            <input
              type="date"
              value={toDate}
              onChange={e => handleToDate(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
            />
          </div>

          {hasFilters && (
            <button
              onClick={clearFilters}
              className="px-4 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Clear Filters
            </button>
          )}
        </div>
        {dateError && <p className="text-xs text-red-500">{dateError}</p>}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              {['Job Ref#', 'Customer', 'Provider', 'Category', 'Status', 'Created At', 'Amount'].map(h => (
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
              {items.map(job => (
                <tr
                  key={job.jobId}
                  onClick={() => setSelectedJobId(job.jobId)}
                  className="hover:bg-gray-50 transition-colors cursor-pointer"
                >
                  <td className="px-4 py-3 font-mono text-xs font-semibold text-[#1B4F72]">{job.referenceNumber}</td>
                  <td className="px-4 py-3 font-medium">{job.customerName}</td>
                  <td className="px-4 py-3 text-gray-600">{job.providerName ?? <span className="text-gray-400 italic">Unassigned</span>}</td>
                  <td className="px-4 py-3 text-gray-700">{job.categoryId}</td>
                  <td className="px-4 py-3"><StatusBadge status={job.status} /></td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{formatDate(job.createdAt)}</td>
                  <td className="px-4 py-3 font-semibold text-gray-800">{formatAmount(job.amount)}</td>
                </tr>
              ))}
            </tbody>
          )}
        </table>

        {!loading && items.length === 0 && (
          <div className="text-center py-16">
            <div className="text-4xl mb-3">📋</div>
            <p className="text-gray-500 font-medium">No jobs match your filters</p>
            {hasFilters && (
              <button onClick={clearFilters} className="mt-2 text-sm text-[#1B4F72] underline">
                Clear filters
              </button>
            )}
          </div>
        )}

        {error && (
          <div className="text-center py-8 text-red-500 text-sm">{error}</div>
        )}

        {/* Pagination */}
        {totalCount > 0 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 bg-gray-50">
            <span className="text-sm text-gray-500">
              Showing {((page - 1) * PAGE_SIZE) + 1}–{Math.min(page * PAGE_SIZE, totalCount)} of {totalCount.toLocaleString()}
            </span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage(p => Math.max(p - 1, 1))}
                disabled={page === 1}
                className="px-3 py-1 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-100 transition-colors"
              >
                ← Prev
              </button>
              <span className="text-sm font-medium text-gray-700">
                Page {page} of {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(p + 1, totalPages))}
                disabled={page >= totalPages}
                className="px-3 py-1 text-sm border border-gray-300 rounded-lg disabled:opacity-40 hover:bg-gray-100 transition-colors"
              >
                Next →
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Detail Drawer */}
      {selectedJobId && (
        <JobDetailDrawer
          jobId={selectedJobId}
          onClose={() => setSelectedJobId(null)}
          onForceCancelled={() => {
            setSelectedJobId(null)
            load({ search, status: statusFilter, from: fromDate || undefined, to: toDate || undefined, page, pageSize: PAGE_SIZE })
          }}
        />
      )}
    </div>
  )
}


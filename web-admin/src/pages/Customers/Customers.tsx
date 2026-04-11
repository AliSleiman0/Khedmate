import { useEffect, useRef, useState } from 'react'
import {
  AdminCustomerSummary,
  AdminCustomersFilters,
  fetchAdminCustomers,
  deactivateCustomer,
} from '../../api/customers'

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

export default function Customers() {
  const [items, setItems] = useState<AdminCustomerSummary[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [activeFilter, setActiveFilter] = useState<'' | 'true' | 'false'>('')

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const totalPages = Math.ceil(total / PAGE_SIZE)

  const load = async (filters: AdminCustomersFilters) => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchAdminCustomers(filters)
      setItems(data.customers)
      setTotal(data.total)
    } catch {
      setError('Failed to load customers')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load({
      search: search || undefined,
      isActive: activeFilter === '' ? undefined : activeFilter === 'true',
      page,
      pageSize: PAGE_SIZE,
    })
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, activeFilter, page])

  const handleSearchChange = (value: string) => {
    setSearchInput(value)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      setSearch(value)
      setPage(1)
    }, 300)
  }

  const handleDeactivate = async (id: string) => {
    if (!confirm('Deactivate this customer? They will no longer be able to log in.')) return
    setActionError(null)
    try {
      await deactivateCustomer(id)
      setItems(prev => prev.map(c => c.id === id ? { ...c, isActive: false } : c))
    } catch {
      setActionError('Failed to deactivate customer. Please try again.')
    }
  }

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })

  const hasFilters = searchInput || activeFilter

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Customers</h2>
        <p className="text-gray-500 text-sm">Registered customer accounts</p>
      </div>

      {actionError && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          {actionError}
        </div>
      )}

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm p-4 flex flex-wrap gap-3 items-end">
        <div className="flex flex-col gap-1">
          <label className="text-xs text-gray-500 font-medium">Search</label>
          <input
            type="text"
            placeholder="Name or phone..."
            value={searchInput}
            onChange={e => handleSearchChange(e.target.value)}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm w-56 focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
          />
        </div>
        <div className="flex flex-col gap-1">
          <label className="text-xs text-gray-500 font-medium">Status</label>
          <select
            value={activeFilter}
            onChange={e => { setActiveFilter(e.target.value as '' | 'true' | 'false'); setPage(1) }}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
          >
            <option value="">All</option>
            <option value="true">Active</option>
            <option value="false">Inactive</option>
          </select>
        </div>
        {hasFilters && (
          <button
            onClick={() => { setSearchInput(''); setSearch(''); setActiveFilter(''); setPage(1) }}
            className="px-4 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Clear
          </button>
        )}
        {!loading && (
          <span className="ml-auto text-xs text-gray-400 self-end pb-0.5">
            {total.toLocaleString()} total
          </span>
        )}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        {error ? (
          <div className="px-6 py-10 text-center text-red-500 text-sm">{error}</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Name', 'Phone', 'Total Bookings', 'Joined', 'Status', 'Actions'].map(h => (
                  <th
                    key={h}
                    className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider"
                  >
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
                      No customers found
                    </td>
                  </tr>
                ) : (
                  items.map(c => (
                    <tr key={c.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-amber-400 text-white flex items-center justify-center text-xs font-bold flex-shrink-0">
                            {c.fullName.charAt(0)}
                          </div>
                          <span className="font-medium">{c.fullName}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-gray-600">{c.phone}</td>
                      <td className="px-4 py-3">
                        <span className="font-medium text-[#1B4F72]">{c.totalBookings}</span>
                      </td>
                      <td className="px-4 py-3 text-gray-500 text-xs">{formatDate(c.createdAt)}</td>
                      <td className="px-4 py-3">
                        <span
                          className={`px-2 py-1 rounded-full text-xs font-medium ${
                            c.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'
                          }`}
                        >
                          {c.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        {c.isActive && (
                          <button
                            onClick={() => handleDeactivate(c.id)}
                            className="text-xs text-red-600 hover:underline font-medium"
                          >
                            Deactivate
                          </button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            )}
          </table>
        )}
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
          <span className="text-sm text-gray-600">
            Page {page} of {totalPages}
          </span>
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

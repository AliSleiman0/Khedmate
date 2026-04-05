import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { superAdminApi, FinancialTransaction } from '../../api/superadmin'

const STATUS_COLORS: Record<string, string> = {
  Released: 'bg-green-500/20 text-green-400',
  Held: 'bg-amber-500/20 text-amber-400',
  Pending: 'bg-gray-500/20 text-gray-400',
  Refunded: 'bg-red-500/20 text-red-400',
}

function toDateInput(d: Date) {
  return d.toISOString().split('T')[0]
}

function SkeletonRow() {
  return (
    <tr className="animate-pulse">
      {Array.from({ length: 8 }).map((_, i) => (
        <td key={i} className="px-4 py-3">
          <div className="h-3 bg-gray-700 rounded w-20" />
        </td>
      ))}
    </tr>
  )
}

export default function Financials() {
  const now = new Date()
  const [from, setFrom] = useState(toDateInput(new Date(now.getFullYear(), now.getMonth(), 1)))
  const [to, setTo] = useState(toDateInput(now))
  const [page, setPage] = useState(1)

  const { data, isLoading, isError } = useQuery({
    queryKey: ['financials', from, to, page],
    queryFn: () => superAdminApi.getFinancials({ from, to, page }),
    staleTime: 30_000,
  })

  const totalPages = data ? Math.ceil(data.total / data.pageSize) : 1

  function handleFromChange(v: string) { setFrom(v); setPage(1) }
  function handleToChange(v: string) { setTo(v); setPage(1) }

  const inputClass = 'bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-purple-500'

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-white">Financials</h2>
        <p className="text-gray-400 text-sm">Transaction ledger with date range filter</p>
      </div>

      {/* Date range filter */}
      <div className="flex items-center gap-4">
        <div>
          <label className="block text-xs text-gray-400 mb-1">From</label>
          <input type="date" value={from} onChange={e => handleFromChange(e.target.value)} className={inputClass} />
        </div>
        <div>
          <label className="block text-xs text-gray-400 mb-1">To</label>
          <input type="date" value={to} onChange={e => handleToChange(e.target.value)} className={inputClass} />
        </div>
      </div>

      {isError && (
        <p className="text-red-400 text-sm">Failed to load financials. Please retry.</p>
      )}

      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Total Settled', value: data?.summary.totalSettled, color: 'text-green-400' },
          { label: 'Total Pending / Held', value: data?.summary.totalPending, color: 'text-amber-400' },
          { label: 'Total Refunded', value: data?.summary.totalRefunded, color: 'text-red-400' },
        ].map(({ label, value, color }) => (
          <div key={label} className="bg-gray-800 border border-gray-700 rounded-xl p-5">
            <p className="text-gray-400 text-sm">{label}</p>
            {isLoading
              ? <div className="h-7 bg-gray-700 rounded w-1/2 mt-1 animate-pulse" />
              : <p className={`text-2xl font-bold mt-1 ${color}`}>
                  {(value ?? 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </p>
            }
          </div>
        ))}
      </div>

      {/* Transactions table */}
      <div className="bg-gray-800 border border-gray-700 rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-900 border-b border-gray-700">
            <tr>
              {['Reference', 'Customer', 'Provider', 'Gross', 'Commission', 'Net Payout', 'Status', 'Date'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700">
            {isLoading
              ? Array.from({ length: 5 }).map((_, i) => <SkeletonRow key={i} />)
              : data?.transactions.map((t: FinancialTransaction) => (
                <tr key={t.id} className="hover:bg-gray-750 transition-colors">
                  <td className="px-4 py-3 font-mono text-xs font-semibold text-purple-400">{t.referenceNumber}</td>
                  <td className="px-4 py-3 text-gray-300">{t.customerName}</td>
                  <td className="px-4 py-3 text-gray-300">{t.providerName}</td>
                  <td className="px-4 py-3 text-white font-medium">{t.grossAmount.toFixed(2)}</td>
                  <td className="px-4 py-3 text-amber-400">{t.commissionAmount.toFixed(2)}</td>
                  <td className="px-4 py-3 text-green-400">{t.netPayout.toFixed(2)}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[t.status] ?? 'bg-gray-500/20 text-gray-400'}`}>
                      {t.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-400 text-xs">{new Date(t.createdAt).toLocaleDateString()}</td>
                </tr>
              ))}
            {!isLoading && data?.transactions.length === 0 && (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-gray-500">No transactions in this date range.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {data && totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-gray-400">
          <span>{data.total} transactions total</span>
          <div className="flex gap-2">
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-3 py-1.5 rounded-lg bg-gray-800 hover:bg-gray-700 disabled:opacity-40"
            >
              ← Prev
            </button>
            <span className="px-3 py-1.5 text-white">Page {page} / {totalPages}</span>
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-3 py-1.5 rounded-lg bg-gray-800 hover:bg-gray-700 disabled:opacity-40"
            >
              Next →
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

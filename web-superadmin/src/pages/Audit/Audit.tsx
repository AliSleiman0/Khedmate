import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { superAdminApi, AuditEntry } from '../../api/superadmin'

const ACTION_TYPES = ['CREATE', 'UPDATE', 'DELETE', 'APPROVE', 'REJECT'] as const

const ACTION_BADGE: Record<string, string> = {
  CREATE: 'bg-green-500/20 text-green-400',
  UPDATE: 'bg-amber-500/20 text-amber-400',
  DELETE: 'bg-red-500/20 text-red-400',
  APPROVE: 'bg-blue-500/20 text-blue-400',
  REJECT: 'bg-red-500/20 text-red-400',
}

function toDateInput(d: Date) {
  return d.toISOString().split('T')[0]
}

function SkeletonRow() {
  return (
    <tr className="animate-pulse">
      {Array.from({ length: 5 }).map((_, i) => (
        <td key={i} className="px-4 py-3">
          <div className="h-3 bg-gray-700 rounded w-24" />
        </td>
      ))}
    </tr>
  )
}

export default function Audit() {
  const now = new Date()
  const [from, setFrom] = useState(toDateInput(new Date(now.getFullYear(), now.getMonth(), 1)))
  const [to, setTo] = useState(toDateInput(now))
  const [page, setPage] = useState(1)
  const [selectedTypes, setSelectedTypes] = useState<string[]>([])

  const actionTypeParam = selectedTypes.length > 0 ? selectedTypes.join(',') : undefined

  const { data, isLoading, isError } = useQuery({
    queryKey: ['audit', from, to, page, actionTypeParam],
    queryFn: () => superAdminApi.getAudit({ from, to, page, actionType: actionTypeParam }),
    staleTime: 30_000,
  })

  const totalPages = data ? Math.ceil(data.total / data.pageSize) : 1

  function handleFromChange(v: string) { setFrom(v); setPage(1) }
  function handleToChange(v: string) { setTo(v); setPage(1) }

  function toggleType(t: string) {
    setSelectedTypes(prev =>
      prev.includes(t) ? prev.filter(x => x !== t) : [...prev, t]
    )
    setPage(1)
  }

  const inputClass = 'bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-purple-500'

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-white">Audit Log</h2>
        <p className="text-gray-400 text-sm">All privileged admin actions — immutable record</p>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-end gap-4">
        <div>
          <label className="block text-xs text-gray-400 mb-1">From</label>
          <input type="date" value={from} onChange={e => handleFromChange(e.target.value)} className={inputClass} />
        </div>
        <div>
          <label className="block text-xs text-gray-400 mb-1">To</label>
          <input type="date" value={to} onChange={e => handleToChange(e.target.value)} className={inputClass} />
        </div>
        <div>
          <label className="block text-xs text-gray-400 mb-1">Action Type</label>
          <div className="flex gap-2">
            {ACTION_TYPES.map(t => (
              <button
                key={t}
                onClick={() => toggleType(t)}
                className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-colors ${
                  selectedTypes.includes(t)
                    ? `${ACTION_BADGE[t]} border-current`
                    : 'bg-gray-800 text-gray-400 border-gray-600 hover:border-gray-400'
                }`}
              >
                {t}
              </button>
            ))}
          </div>
        </div>
      </div>

      {isError && (
        <p className="text-red-400 text-sm">Failed to load audit log. Please retry.</p>
      )}

      {/* Table */}
      <div className="bg-gray-800 border border-gray-700 rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-900 border-b border-gray-700">
            <tr>
              {['Timestamp', 'Admin', 'Action', 'Description', 'Target'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700">
            {isLoading
              ? Array.from({ length: 5 }).map((_, i) => <SkeletonRow key={i} />)
              : data?.entries.map((entry: AuditEntry) => (
                <tr key={entry.id} className="hover:bg-gray-750 transition-colors">
                  <td className="px-4 py-3 text-gray-400 text-xs font-mono whitespace-nowrap">
                    {new Date(entry.createdAt).toLocaleString()}
                  </td>
                  <td className="px-4 py-3 text-gray-300 text-xs">{entry.adminEmail}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-1 rounded-full text-xs font-semibold ${ACTION_BADGE[entry.actionType] ?? 'bg-gray-500/20 text-gray-400'}`}>
                      {entry.actionType}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-300 text-xs max-w-xs truncate">{entry.description}</td>
                  <td className="px-4 py-3 text-gray-500 text-xs">
                    {entry.targetType ? `${entry.targetType}${entry.targetId ? ` #${entry.targetId}` : ''}` : '—'}
                  </td>
                </tr>
              ))}
            {!isLoading && data?.entries.length === 0 && (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-gray-500">No audit entries found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {data && totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-gray-400">
          <span>{data.total} entries total</span>
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

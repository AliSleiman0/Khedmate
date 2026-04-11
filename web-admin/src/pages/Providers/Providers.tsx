import { useEffect, useRef, useState } from 'react'
import {
  AdminProviderSummary,
  VerificationQueueItem,
  fetchAdminProviders,
  fetchVerificationQueue,
  verifyDocuments,
} from '../../api/providers'

const TIER_COLORS: Record<string, string> = {
  Unverified: 'bg-gray-100 text-gray-600',
  PhoneVerified: 'bg-blue-100 text-blue-700',
  IdVerified: 'bg-purple-100 text-purple-700',
  SkillTested: 'bg-amber-100 text-amber-700',
  Active: 'bg-green-100 text-green-700',
}

const PAGE_SIZE = 20

// ── Verification Queue Tab ───────────────────────────────────────────────────

interface ReviewDrawerProps {
  item: VerificationQueueItem
  onClose: () => void
  onAction: () => void
}

function ReviewDrawer({ item, onClose, onAction }: ReviewDrawerProps) {
  const [rejectionReason, setRejectionReason] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleApprove = async () => {
    setLoading(true)
    setError(null)
    try {
      await verifyDocuments(item.providerId, item.submissionId, 'approve')
      onAction()
      onClose()
    } catch {
      setError('Failed to approve. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleReject = async () => {
    if (!rejectionReason.trim()) {
      setError('Rejection reason is required.')
      return
    }
    setLoading(true)
    setError(null)
    try {
      await verifyDocuments(item.providerId, item.submissionId, 'reject', rejectionReason.trim())
      onAction()
      onClose()
    } catch {
      setError('Failed to reject. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <div className="absolute inset-0 bg-black/30" onClick={onClose} />
      <div className="relative w-full max-w-md bg-white shadow-xl flex flex-col h-full overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-lg font-semibold">Review Documents</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-2xl leading-none">×</button>
        </div>

        <div className="p-6 space-y-4 flex-1">
          <div className="space-y-1">
            <p className="text-sm text-gray-500">Provider</p>
            <p className="font-semibold">{item.fullName}</p>
            <p className="text-sm text-gray-600">{item.phone}</p>
          </div>
          <div className="space-y-1">
            <p className="text-sm text-gray-500">Document Type</p>
            <p className="font-medium">{item.documentType}</p>
          </div>
          <div className="space-y-1">
            <p className="text-sm text-gray-500">Submitted</p>
            <p className="font-medium">
              {new Date(item.submittedAt).toLocaleDateString('en-GB', {
                day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
              })}
            </p>
          </div>

          <div className="pt-2 border-t border-gray-100">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Rejection Reason <span className="text-gray-400 font-normal">(required to reject)</span>
            </label>
            <textarea
              value={rejectionReason}
              onChange={e => setRejectionReason(e.target.value)}
              rows={3}
              placeholder="Explain why the document is being rejected..."
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72] resize-none"
            />
          </div>

          {error && (
            <p className="text-sm text-red-600 bg-red-50 rounded-lg px-3 py-2">{error}</p>
          )}
        </div>

        <div className="p-6 border-t border-gray-200 flex gap-3">
          <button
            onClick={handleApprove}
            disabled={loading}
            className="flex-1 px-4 py-2.5 bg-green-600 text-white rounded-lg font-semibold text-sm hover:bg-green-700 disabled:opacity-50 transition-colors"
          >
            {loading ? 'Saving...' : 'Approve'}
          </button>
          <button
            onClick={handleReject}
            disabled={loading || !rejectionReason.trim()}
            className="flex-1 px-4 py-2.5 bg-red-600 text-white rounded-lg font-semibold text-sm hover:bg-red-700 disabled:opacity-50 transition-colors"
          >
            {loading ? 'Saving...' : 'Reject'}
          </button>
        </div>
      </div>
    </div>
  )
}

function VerificationQueueTab() {
  const [items, setItems] = useState<VerificationQueueItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selected, setSelected] = useState<VerificationQueueItem | null>(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchVerificationQueue()
      setItems(data)
    } catch {
      setError('Failed to load verification queue')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  return (
    <div className="space-y-4">
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        {error ? (
          <div className="px-6 py-10 text-center text-red-500 text-sm">{error}</div>
        ) : loading ? (
          <div className="px-6 py-10 text-center text-gray-400 text-sm animate-pulse">Loading...</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Provider', 'Phone', 'Document Type', 'Submitted', 'Action'].map(h => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {items.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-10 text-center text-gray-400 text-sm">
                    No pending verifications
                  </td>
                </tr>
              ) : (
                items.map(item => (
                  <tr key={item.submissionId} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-[#1B4F72] text-white flex items-center justify-center text-xs font-bold flex-shrink-0">
                          {item.fullName.charAt(0)}
                        </div>
                        <span className="font-medium">{item.fullName}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{item.phone}</td>
                    <td className="px-4 py-3 text-gray-600">{item.documentType}</td>
                    <td className="px-4 py-3 text-gray-500 text-xs">
                      {new Date(item.submittedAt).toLocaleDateString('en-GB', {
                        day: '2-digit', month: 'short', year: 'numeric'
                      })}
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => setSelected(item)}
                        className="text-xs text-[#1B4F72] hover:underline font-medium"
                      >
                        Review
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>

      {selected && (
        <ReviewDrawer
          item={selected}
          onClose={() => setSelected(null)}
          onAction={load}
        />
      )}
    </div>
  )
}

// ── All Providers Tab ────────────────────────────────────────────────────────

function AllProvidersTab() {
  const [items, setItems] = useState<AdminProviderSummary[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [tierFilter, setTierFilter] = useState('')
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const totalPages = Math.ceil(total / PAGE_SIZE)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchAdminProviders({ tier: tierFilter || undefined, page, pageSize: PAGE_SIZE })
      setItems(data.providers)
      setTotal(data.total)
    } catch {
      setError('Failed to load providers')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(load, 100)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tierFilter, page])

  return (
    <div className="space-y-4">
      <div className="bg-white rounded-xl shadow-sm p-4 flex flex-wrap gap-3 items-end">
        <div className="flex flex-col gap-1">
          <label className="text-xs text-gray-500 font-medium">Tier</label>
          <select
            value={tierFilter}
            onChange={e => { setTierFilter(e.target.value); setPage(1) }}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
          >
            <option value="">All Tiers</option>
            {['Unverified', 'PhoneVerified', 'IdVerified', 'SkillTested', 'Active'].map(t => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
        </div>
        {!loading && (
          <span className="ml-auto text-xs text-gray-400 self-end pb-0.5">
            {total.toLocaleString()} total
          </span>
        )}
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        {error ? (
          <div className="px-6 py-10 text-center text-red-500 text-sm">{error}</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Name', 'Phone', 'Tier', 'Rating', 'Jobs', 'Categories'].map(h => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="border-t border-gray-100">
                    {Array.from({ length: 6 }).map((_, j) => (
                      <td key={j} className="px-4 py-3">
                        <div className="h-4 bg-gray-200 rounded animate-pulse" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : items.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-gray-400 text-sm">
                    No providers found
                  </td>
                </tr>
              ) : (
                items.map(p => (
                  <tr key={p.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-[#1B4F72] text-white flex items-center justify-center text-xs font-bold flex-shrink-0">
                          {p.fullName.charAt(0)}
                        </div>
                        <span className="font-medium">{p.fullName}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{p.phone}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${TIER_COLORS[p.tier] ?? 'bg-gray-100 text-gray-600'}`}>
                        {p.tier}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      {p.rating > 0 ? (
                        <span className="flex items-center gap-1">
                          <span className="text-amber-400">★</span>
                          <span className="font-medium">{p.rating.toFixed(1)}</span>
                        </span>
                      ) : '—'}
                    </td>
                    <td className="px-4 py-3 font-medium text-[#1B4F72]">{p.jobsCompleted}</td>
                    <td className="px-4 py-3 text-gray-500 text-xs">
                      {p.serviceCategories.slice(0, 2).join(', ')}
                      {p.serviceCategories.length > 2 && ` +${p.serviceCategories.length - 2}`}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>

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

// ── Main Providers Page ──────────────────────────────────────────────────────

type Tab = 'all' | 'queue'

export default function Providers() {
  const [activeTab, setActiveTab] = useState<Tab>('all')

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Providers</h2>
        <p className="text-gray-500 text-sm">Manage service provider accounts</p>
      </div>

      <div className="flex gap-1 bg-gray-100 rounded-xl p-1 w-fit">
        {([['all', 'All Providers'], ['queue', 'Verification Queue']] as [Tab, string][]).map(([tab, label]) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              activeTab === tab
                ? 'bg-white text-[#1B4F72] shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {activeTab === 'all' ? <AllProvidersTab /> : <VerificationQueueTab />}
    </div>
  )
}

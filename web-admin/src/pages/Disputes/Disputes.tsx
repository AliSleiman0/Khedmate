import { useState, useEffect, useRef, useCallback } from 'react'
import {
  fetchAdminDisputes,
  fetchAdminDisputeDetail,
  resolveDispute,
  type AdminDisputeSummary,
  type AdminDisputeDetail,
  type DisputeStatus,
} from '../../api/disputes'

// ── helpers ───────────────────────────────────────────────────────────────────

const STATUS_BADGE: Record<DisputeStatus, string> = {
  Open: 'bg-red-100 text-red-700',
  Resolved: 'bg-green-100 text-green-700',
  Rejected: 'bg-gray-100 text-gray-600',
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('en-GB', {
    day: '2-digit', month: 'short', year: 'numeric',
  })
}

function formatCurrency(amount: number) {
  return `$${amount.toFixed(2)}`
}

// Detect Arabic content and apply RTL dir
function ComplaintText({ text }: { text: string }) {
  const arabic = /[\u0600-\u06FF]/.test(text)
  return (
    <p
      dir={arabic ? 'rtl' : 'ltr'}
      className="text-sm leading-relaxed whitespace-pre-wrap"
      style={{ textAlign: arabic ? 'right' : 'left' }}
    >
      {text}
    </p>
  )
}

// ── component ─────────────────────────────────────────────────────────────────

export default function Disputes() {
  const [disputes, setDisputes] = useState<AdminDisputeSummary[]>([])
  const [totalCount, setTotalCount] = useState(0)
  const [openCount, setOpenCount] = useState(0)
  const [resolvedCount, setResolvedCount] = useState(0)
  const [rejectedCount, setRejectedCount] = useState(0)
  const [listLoading, setListLoading] = useState(false)
  const [listError, setListError] = useState<string | null>(null)

  const [statusFilter, setStatusFilter] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const PAGE_SIZE = 20
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [detail, setDetail] = useState<AdminDisputeDetail | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)
  const [detailError, setDetailError] = useState<string | null>(null)

  const [adminNote, setAdminNote] = useState('')
  const [confirmAction, setConfirmAction] = useState<'approve_refund' | 'reject' | null>(null)
  const [resolving, setResolving] = useState(false)
  const [resolveError, setResolveError] = useState<string | null>(null)

  const loadList = useCallback(async () => {
    setListLoading(true)
    setListError(null)
    try {
      const data = await fetchAdminDisputes({
        status: statusFilter || undefined,
        search: search || undefined,
        page,
        pageSize: PAGE_SIZE,
      })
      setDisputes(data.items)
      setTotalCount(data.totalCount)
      setOpenCount(data.openCount)
      setResolvedCount(data.resolvedCount)
      setRejectedCount(data.rejectedCount)
    } catch {
      setListError('Failed to load disputes')
    } finally {
      setListLoading(false)
    }
  }, [statusFilter, search, page])

  useEffect(() => { void loadList() }, [loadList])

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      setSearch(searchInput)
      setPage(1)
    }, 300)
    return () => { if (debounceRef.current) clearTimeout(debounceRef.current) }
  }, [searchInput])

  useEffect(() => {
    if (!selectedId) return
    setDetail(null)
    setAdminNote('')
    setResolveError(null)
    setDetailLoading(true)
    setDetailError(null)
    fetchAdminDisputeDetail(selectedId)
      .then(setDetail)
      .catch(() => setDetailError('Failed to load dispute details'))
      .finally(() => setDetailLoading(false))
  }, [selectedId])

  async function handleResolve(action: 'approve_refund' | 'reject') {
    if (!selectedId || !detail) return
    setResolving(true)
    setResolveError(null)
    try {
      await resolveDispute(selectedId, action, adminNote)
      setConfirmAction(null)
      await loadList()
      const updated = await fetchAdminDisputeDetail(selectedId)
      setDetail(updated)
    } catch {
      setResolveError('Action failed. Please try again.')
    } finally {
      setResolving(false)
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Disputes</h2>
        <p className="text-gray-500 text-sm">{openCount} open disputes</p>
      </div>

      {/* Stats bar */}
      <div className="flex gap-3">
        <StatChip label="Open" count={openCount} color="red" />
        <StatChip label="Resolved" count={resolvedCount} color="green" />
        <StatChip label="Rejected" count={rejectedCount} color="gray" />
      </div>

      <div className="flex gap-4 h-[calc(100vh-280px)]">
        {/* Left panel */}
        <div className="w-80 flex-shrink-0 bg-white rounded-xl shadow-sm flex flex-col overflow-hidden">
          <div className="p-3 border-b border-gray-100 space-y-2">
            <input
              type="text"
              placeholder="Search by customer, provider, ref#..."
              value={searchInput}
              onChange={e => setSearchInput(e.target.value)}
              className="w-full border border-gray-200 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-[#1B4F72]"
            />
            <select
              value={statusFilter}
              onChange={e => { setStatusFilter(e.target.value); setPage(1) }}
              className="w-full border border-gray-200 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-[#1B4F72]"
            >
              <option value="">All Statuses</option>
              <option value="Open">Open</option>
              <option value="Resolved">Resolved</option>
              <option value="Rejected">Rejected</option>
            </select>
          </div>

          <div className="flex-1 overflow-auto">
            {listLoading && (
              <div className="p-4 space-y-3">
                {[...Array(6)].map((_, i) => (
                  <div key={i} className="animate-pulse space-y-2">
                    <div className="h-3 bg-gray-200 rounded w-3/4" />
                    <div className="h-3 bg-gray-100 rounded w-1/2" />
                  </div>
                ))}
              </div>
            )}
            {listError && (
              <div className="p-4 text-sm text-red-600 text-center">{listError}</div>
            )}
            {!listLoading && !listError && disputes.length === 0 && (
              <div className="p-8 text-center text-gray-400">
                <p className="text-3xl mb-2">📋</p>
                <p className="font-medium">No disputes match your filters</p>
                <p className="text-xs mt-1">لا توجد نزاعات مفتوحة</p>
              </div>
            )}
            {!listLoading && disputes.map(d => (
              <button
                key={d.disputeId}
                onClick={() => setSelectedId(d.disputeId)}
                className={`w-full text-left p-4 border-b border-gray-100 hover:bg-gray-50 transition-colors ${
                  selectedId === d.disputeId
                    ? 'bg-blue-50 border-l-4 border-l-[#1B4F72]'
                    : ''
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="font-mono text-xs font-semibold text-[#1B4F72] truncate">
                    {d.referenceNumber}
                  </span>
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ml-1 flex-shrink-0 ${STATUS_BADGE[d.status]}`}>
                    {d.status}
                  </span>
                </div>
                <p className="text-sm font-medium truncate">{d.customerName}</p>
                <p className="text-xs text-gray-500 truncate">{d.providerName}</p>
                <div className="flex justify-between text-xs text-gray-400 mt-1">
                  <span>{formatCurrency(d.amount)}</span>
                  <span>{formatDate(d.createdAt)}</span>
                </div>
              </button>
            ))}
          </div>

          {totalCount > PAGE_SIZE && (
            <div className="p-3 border-t flex justify-between items-center">
              <button
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
                className="text-xs px-3 py-1 rounded bg-gray-100 disabled:opacity-40"
              >
                Prev
              </button>
              <span className="text-xs text-gray-500">
                {page} / {Math.ceil(totalCount / PAGE_SIZE)}
              </span>
              <button
                disabled={page >= Math.ceil(totalCount / PAGE_SIZE)}
                onClick={() => setPage(p => p + 1)}
                className="text-xs px-3 py-1 rounded bg-gray-100 disabled:opacity-40"
              >
                Next
              </button>
            </div>
          )}
        </div>

        {/* Right panel */}
        {!selectedId && (
          <div className="flex-1 flex items-center justify-center text-gray-400 bg-white rounded-xl shadow-sm">
            <div className="text-center">
              <p className="text-4xl mb-2">⚖️</p>
              <p>Select a dispute to view details</p>
            </div>
          </div>
        )}

        {selectedId && detailLoading && (
          <div className="flex-1 flex items-center justify-center bg-white rounded-xl shadow-sm">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1B4F72]" />
          </div>
        )}

        {selectedId && detailError && (
          <div className="flex-1 flex items-center justify-center bg-white rounded-xl shadow-sm text-red-500">
            {detailError}
          </div>
        )}

        {selectedId && detail && !detailLoading && (
          <div className="flex-1 bg-white rounded-xl shadow-sm p-6 overflow-auto">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-xl font-bold">Dispute</h3>
                <p className="text-xs text-gray-400 font-mono mt-0.5">{detail.referenceNumber}</p>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-xs text-gray-400">{formatDate(detail.createdAt)}</span>
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${STATUS_BADGE[detail.status]}`}>
                  {detail.status}
                </span>
              </div>
            </div>

            {/* Job summary */}
            <Section title="Job Summary">
              <Grid2>
                <Field label="Reference #" value={detail.referenceNumber} />
                <Field label="Amount" value={formatCurrency(detail.amount)} />
                <Field label="Customer" value={`${detail.customerName} (${detail.customerId.slice(0, 8)})`} />
                <Field label="Provider" value={`${detail.providerName} (${detail.providerId.slice(0, 8)})`} />
                <Field label="Category" value={detail.categoryId} />
                <Field label="Created" value={formatDate(detail.jobCreatedAt)} />
                {detail.jobCompletedAt && (
                  <Field label="Completed" value={formatDate(detail.jobCompletedAt)} />
                )}
              </Grid2>
              <div className="mt-2">
                <Field label="Address" value={detail.address} />
              </div>
            </Section>

            {/* Complaint */}
            <Section title="Customer Complaint">
              <div className="bg-amber-50 border border-amber-100 rounded-lg p-4">
                <ComplaintText text={detail.complaint} />
              </div>
            </Section>

            {/* Evidence photos */}
            <Section title="Evidence Photos">
              {detail.photos.length === 0 ? (
                <p className="text-sm text-gray-400 italic">No evidence photos uploaded.</p>
              ) : (
                <div className="grid grid-cols-3 gap-2">
                  {detail.photos.map((url, i) => (
                    <a key={i} href={url} target="_blank" rel="noreferrer">
                      <img
                        src={url}
                        alt={`Evidence ${i + 1}`}
                        className="w-full h-28 object-cover rounded-lg border border-gray-200 hover:opacity-80 transition-opacity"
                      />
                    </a>
                  ))}
                </div>
              )}
            </Section>

            {/* Job timeline */}
            <Section title="Job Timeline">
              {detail.statusHistory.length === 0 ? (
                <p className="text-sm text-gray-400 italic">No status history available.</p>
              ) : (
                <ol className="relative border-l border-gray-200 ml-2 space-y-4">
                  {detail.statusHistory.map((h, i) => (
                    <li key={i} className="ml-4">
                      <div className="absolute -left-1.5 w-3 h-3 rounded-full bg-[#1B4F72]" />
                      <div className="flex items-center gap-2">
                        <span className="text-xs bg-gray-100 px-2 py-0.5 rounded font-medium">{h.previousStatus}</span>
                        <span className="text-gray-400">→</span>
                        <span className="text-xs bg-[#1B4F72] text-white px-2 py-0.5 rounded font-medium">{h.newStatus}</span>
                      </div>
                      <p className="text-xs text-gray-400 mt-0.5">{formatDate(h.changedAt)}</p>
                    </li>
                  ))}
                </ol>
              )}
            </Section>

            {/* Admin note field + action buttons — only for Open disputes */}
            {detail.status === 'Open' && (
              <Section title="Admin Note (required)">
                <textarea
                  value={adminNote}
                  onChange={e => setAdminNote(e.target.value)}
                  placeholder="Explain your decision (min 10 characters)..."
                  rows={3}
                  maxLength={500}
                  className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#1B4F72] resize-none"
                />
                <p className="text-xs text-gray-400 text-right mt-1">{adminNote.length} / 500</p>
                {resolveError && (
                  <p className="text-sm text-red-600 mt-1">{resolveError}</p>
                )}
                <div className="flex gap-3 mt-3">
                  <button
                    disabled={adminNote.trim().length < 10 || resolving}
                    onClick={() => setConfirmAction('approve_refund')}
                    className="flex-1 py-3 bg-green-500 hover:bg-green-600 disabled:opacity-40 text-white rounded-xl font-bold transition-colors"
                  >
                    ✅ Approve Refund
                  </button>
                  <button
                    disabled={adminNote.trim().length < 10 || resolving}
                    onClick={() => setConfirmAction('reject')}
                    className="flex-1 py-3 bg-red-500 hover:bg-red-600 disabled:opacity-40 text-white rounded-xl font-bold transition-colors"
                  >
                    ❌ Reject Dispute
                  </button>
                </div>
              </Section>
            )}

            {/* Resolved/Rejected note card */}
            {detail.status !== 'Open' && detail.adminNote && (
              <Section title="Admin Decision">
                <div className={`p-4 rounded-lg text-sm leading-relaxed ${
                  detail.status === 'Resolved'
                    ? 'bg-green-50 text-green-800 border border-green-100'
                    : 'bg-gray-50 text-gray-700 border border-gray-100'
                }`}>
                  <p className="font-semibold mb-1">
                    {detail.status === 'Resolved' ? 'Refund Approved' : 'Dispute Rejected'}
                    {detail.resolvedAt && ` — ${formatDate(detail.resolvedAt)}`}
                  </p>
                  <p>{detail.adminNote}</p>
                </div>
              </Section>
            )}
          </div>
        )}
      </div>

      {/* Confirmation modal */}
      {confirmAction && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-96 shadow-2xl">
            <h4 className="text-lg font-bold mb-2">
              {confirmAction === 'approve_refund' ? 'Approve Refund?' : 'Reject Dispute?'}
            </h4>
            <p className="text-sm text-gray-500 mb-4">
              {confirmAction === 'approve_refund'
                ? 'This will issue a full Stripe refund to the customer and mark the dispute as Resolved.'
                : 'This will release the payment to the provider and mark the dispute as Rejected.'}
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setConfirmAction(null)}
                className="flex-1 py-2 border border-gray-200 rounded-xl text-sm font-medium hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                disabled={resolving}
                onClick={() => void handleResolve(confirmAction)}
                className={`flex-1 py-2 rounded-xl text-sm font-medium text-white disabled:opacity-60 ${
                  confirmAction === 'approve_refund'
                    ? 'bg-green-500 hover:bg-green-600'
                    : 'bg-red-500 hover:bg-red-600'
                }`}
              >
                {resolving ? 'Processing…' : 'Confirm'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// ── sub-components ────────────────────────────────────────────────────────────

function StatChip({ label, count, color }: { label: string; count: number; color: 'red' | 'green' | 'gray' }) {
  const styles = { red: 'bg-red-100 text-red-700', green: 'bg-green-100 text-green-700', gray: 'bg-gray-100 text-gray-600' }
  return (
    <div className={`px-4 py-2 rounded-full text-sm font-semibold ${styles[color]}`}>
      {label}: {count}
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mb-6">
      <p className="text-xs text-gray-400 uppercase tracking-wider font-semibold mb-3">{title}</p>
      {children}
    </div>
  )
}

function Grid2({ children }: { children: React.ReactNode }) {
  return <div className="grid grid-cols-2 gap-3">{children}</div>
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-gray-400 uppercase tracking-wider">{label}</p>
      <p className="text-sm font-medium text-gray-800 mt-0.5">{value}</p>
    </div>
  )
}

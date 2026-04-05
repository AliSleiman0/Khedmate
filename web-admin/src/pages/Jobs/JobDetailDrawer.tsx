import { useEffect, useState } from 'react'
import type { ReactNode } from 'react'
import {
  AdminJobDetail,
  fetchAdminJobDetail,
  forceCancel,
  JobStatus,
} from '../../api/jobs'

const STATUS_COLORS: Record<JobStatus | string, string> = {
  Pending: 'bg-gray-100 text-gray-600',
  Accepted: 'bg-blue-100 text-blue-700',
  EnRoute: 'bg-yellow-100 text-yellow-700',
  InProgress: 'bg-amber-100 text-amber-700',
  Completed: 'bg-green-100 text-green-700',
  Paid: 'bg-teal-100 text-teal-700',
  Expired: 'bg-red-100 text-red-600',
}

interface Props {
  jobId: string
  onClose: () => void
  onForceCancelled: () => void
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="border-t border-gray-100 pt-4">
      <h4 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">{title}</h4>
      {children}
    </div>
  )
}

function InfoRow({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="flex justify-between items-start gap-4 py-1">
      <span className="text-sm text-gray-500 shrink-0">{label}</span>
      <span className="text-sm text-gray-800 text-right">{value}</span>
    </div>
  )
}

export default function JobDetailDrawer({ jobId, onClose, onForceCancelled }: Props) {
  const [job, setJob] = useState<AdminJobDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showConfirm, setShowConfirm] = useState(false)
  const [cancelling, setCancelling] = useState(false)
  const [cancelError, setCancelError] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    setError(null)
    fetchAdminJobDetail(jobId)
      .then(setJob)
      .catch(() => setError('Failed to load job details'))
      .finally(() => setLoading(false))
  }, [jobId])

  const handleForceCancel = async () => {
    setCancelling(true)
    setCancelError(null)
    try {
      await forceCancel(jobId)
      setToast('Job has been force-cancelled successfully.')
      setShowConfirm(false)
      setTimeout(() => {
        onForceCancelled()
      }, 1200)
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
      setCancelError(msg === 'CANNOT_CANCEL_JOB_IN_CURRENT_STATUS'
        ? 'This job cannot be cancelled in its current status.'
        : 'Failed to cancel job. Please try again.')
    } finally {
      setCancelling(false)
    }
  }

  const formatDateTime = (iso: string | null) =>
    iso ? new Date(iso).toLocaleString('en-GB', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit', hour12: false
    }) : '—'

  const canForceCancel = job?.status === 'Pending' || job?.status === 'Accepted'

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/30 z-40"
        onClick={onClose}
      />

      {/* Drawer */}
      <div className="fixed top-0 right-0 h-full w-full max-w-xl bg-white shadow-2xl z-50 flex flex-col overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-white shrink-0">
          {job ? (
            <div className="flex items-center gap-3">
              <span className="font-mono text-base font-bold text-[#1B4F72]">{job.referenceNumber}</span>
              <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_COLORS[job.status] ?? ''}`}>
                {job.status}
              </span>
            </div>
          ) : (
            <span className="font-semibold text-gray-700">Job Detail</span>
          )}
          <button
            onClick={onClose}
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-500"
            aria-label="Close"
          >
            ✕
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">
          {loading && (
            <div className="space-y-3 pt-4">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="h-4 bg-gray-200 rounded animate-pulse" style={{ width: `${60 + (i % 3) * 15}%` }} />
              ))}
            </div>
          )}

          {error && (
            <div className="text-center py-12 text-red-500 text-sm">{error}</div>
          )}

          {job && !loading && (
            <>
              {/* Summary */}
              <Section title="Summary">
                <div className="space-y-0.5">
                  <InfoRow label="Customer" value={`${job.customerName} (${job.customerId.slice(0, 8)}…)`} />
                  <InfoRow
                    label="Provider"
                    value={job.providerName
                      ? `${job.providerName} (${job.providerId?.slice(0, 8)}…)`
                      : <span className="italic text-gray-400">Unassigned</span>}
                  />
                  <InfoRow label="Category" value={job.categoryId} />
                  <InfoRow label="Address" value={job.address} />
                  <InfoRow label="Description" value={job.description} />
                  <InfoRow label="Created At" value={formatDateTime(job.createdAt)} />
                  <InfoRow label="Accepted At" value={formatDateTime(job.acceptedAt)} />
                  <InfoRow label="Paid At" value={formatDateTime(job.paidAt)} />
                  <InfoRow
                    label="Amount"
                    value={job.amount !== null
                      ? <span className="font-semibold">${job.amount.toFixed(2)}</span>
                      : <span className="text-gray-400">—</span>}
                  />
                </div>
              </Section>

              {/* Photos */}
              <Section title="Photos">
                {job.photoUrls.length === 0 ? (
                  <p className="text-sm text-gray-400 italic">No photos uploaded</p>
                ) : (
                  <div className="grid grid-cols-3 gap-2">
                    {job.photoUrls.map((url, i) => (
                      <a key={i} href={url} target="_blank" rel="noopener noreferrer">
                        <img
                          src={url}
                          alt={`Photo ${i + 1}`}
                          className="w-full h-24 object-cover rounded-lg border border-gray-200 hover:opacity-90 transition-opacity"
                        />
                      </a>
                    ))}
                  </div>
                )}
              </Section>

              {/* Status Timeline */}
              <Section title="Status Timeline">
                {job.statusHistory.length === 0 ? (
                  <p className="text-sm text-gray-400 italic">No history yet</p>
                ) : (
                  <div className="space-y-3">
                    {job.statusHistory.map((h, i) => (
                      <div key={i} className="flex items-start gap-3">
                        <div className="mt-1 w-2 h-2 rounded-full bg-[#1B4F72] shrink-0" />
                        <div>
                          <div className="text-sm">
                            <span className="text-gray-500">{h.previousStatus}</span>
                            <span className="mx-1 text-gray-400">→</span>
                            <span className="font-medium text-gray-800">{h.newStatus}</span>
                          </div>
                          <div className="text-xs text-gray-400 mt-0.5">
                            {formatDateTime(h.changedAt)} · by {h.changedBy.slice(0, 8)}…
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </Section>

              {/* Rating */}
              <Section title="Rating">
                {!job.rating ? (
                  <p className="text-sm text-gray-400 italic">Not yet rated</p>
                ) : (
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="text-2xl">{job.rating.isPositive ? '👍' : '👎'}</span>
                      <span className="text-sm font-medium text-gray-700">
                        {job.rating.isPositive ? 'Positive' : 'Negative'}
                      </span>
                    </div>
                    {job.rating.tags.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-1">
                        {job.rating.tags.map(tag => (
                          <span key={tag} className="px-2 py-0.5 bg-blue-50 text-blue-700 text-xs rounded-full">
                            {tag}
                          </span>
                        ))}
                      </div>
                    )}
                    <p className="text-xs text-gray-400 mt-1">
                      Submitted {formatDateTime(job.rating.submittedAt)} by {job.rating.raterType}
                    </p>
                  </div>
                )}
              </Section>
            </>
          )}
        </div>

        {/* Footer — Admin Actions */}
        {job && !loading && (
          <div className="shrink-0 px-6 py-4 border-t border-gray-200 bg-gray-50">
            {cancelError && (
              <p className="text-xs text-red-500 mb-2">{cancelError}</p>
            )}
            {toast && (
              <p className="text-xs text-green-600 mb-2">{toast}</p>
            )}
            {canForceCancel && !showConfirm && (
              <button
                onClick={() => setShowConfirm(true)}
                className="w-full px-4 py-2 bg-red-50 text-red-600 border border-red-200 rounded-lg text-sm font-medium hover:bg-red-100 transition-colors"
              >
                Force Cancel Job
              </button>
            )}
            {canForceCancel && showConfirm && (
              <div className="space-y-2">
                <p className="text-sm text-gray-700 font-medium">
                  Are you sure you want to force-cancel this job? This cannot be undone.
                </p>
                <div className="flex gap-2">
                  <button
                    onClick={handleForceCancel}
                    disabled={cancelling}
                    className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50 transition-colors"
                  >
                    {cancelling ? 'Cancelling…' : 'Yes, Force Cancel'}
                  </button>
                  <button
                    onClick={() => { setShowConfirm(false); setCancelError(null) }}
                    disabled={cancelling}
                    className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg text-sm font-medium hover:bg-gray-100 transition-colors"
                  >
                    No, Go Back
                  </button>
                </div>
              </div>
            )}
            {!canForceCancel && (
              <p className="text-xs text-gray-400 text-center italic">
                No admin actions available for jobs in {job.status} status
              </p>
            )}
          </div>
        )}
      </div>
    </>
  )
}

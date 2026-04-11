import { useEffect, useState } from 'react'
import { fetchPlatformConfig, PlatformConfigData } from '../../api/platformConfig'

function ConfigRow({ label, value, description }: { label: string; value: string | number; description: string }) {
  return (
    <div className="flex items-start justify-between py-4 border-b border-gray-100 last:border-0">
      <div>
        <p className="text-sm font-medium text-gray-900">{label}</p>
        <p className="text-xs text-gray-500 mt-0.5">{description}</p>
      </div>
      <span className="text-sm font-bold text-[#1B4F72] bg-blue-50 px-3 py-1 rounded-lg ml-4 flex-shrink-0">
        {value}
      </span>
    </div>
  )
}

export default function Settings() {
  const [config, setConfig] = useState<PlatformConfigData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchPlatformConfig()
      .then(setConfig)
      .catch(() => setError('Failed to load platform configuration'))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Settings</h2>
        <p className="text-gray-500 text-sm">Platform configuration (read-only — changes require Super Admin)</p>
      </div>

      <div className="bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 flex items-start gap-3">
        <span className="text-amber-500 text-lg flex-shrink-0">🔒</span>
        <p className="text-sm text-amber-800">
          These settings are managed by the Super Admin. To request a change, contact your Super Admin.
        </p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          {error}
        </div>
      )}

      <div className="bg-white rounded-xl shadow-sm p-6">
        <h3 className="text-lg font-semibold border-b border-gray-100 pb-3 mb-2">Operational Settings</h3>

        {loading ? (
          <div className="space-y-4 py-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="flex justify-between items-center py-4 border-b border-gray-100 last:border-0">
                <div className="space-y-1.5">
                  <div className="h-4 bg-gray-200 rounded w-40 animate-pulse" />
                  <div className="h-3 bg-gray-100 rounded w-56 animate-pulse" />
                </div>
                <div className="h-7 bg-gray-200 rounded w-16 animate-pulse" />
              </div>
            ))}
          </div>
        ) : config ? (
          <>
            <ConfigRow
              label="Commission Rate"
              value={`${config.commissionRate}%`}
              description="Platform cut from each completed job"
            />
            <ConfigRow
              label="Job Acceptance Timeout"
              value={`${config.jobTimeoutMinutes} min`}
              description="How long providers have to accept a job before it re-dispatches"
            />
            <ConfigRow
              label="Max Providers per Area"
              value={config.maxProvidersPerArea}
              description="Maximum providers broadcast to per new job"
            />
            <ConfigRow
              label="Min Rating to Remain Active"
              value={`${config.minRatingToRemain}%`}
              description="Minimum positive rating percentage for providers to stay Active tier"
            />
            <ConfigRow
              label="Auto-Refund Threshold"
              value={`${config.autoRefundThresholdDays} day${config.autoRefundThresholdDays !== 1 ? 's' : ''}`}
              description="Days after job completion before auto-refund is triggered for open disputes"
            />
          </>
        ) : null}

        {config && (
          <p className="text-xs text-gray-400 mt-4">
            Last updated:{' '}
            {new Date(config.updatedAt).toLocaleDateString('en-GB', {
              day: '2-digit', month: 'short', year: 'numeric',
              hour: '2-digit', minute: '2-digit'
            })}
          </p>
        )}
      </div>
    </div>
  )
}

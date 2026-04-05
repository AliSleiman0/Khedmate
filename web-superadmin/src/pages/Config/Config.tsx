import { useEffect, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { superAdminApi, PlatformConfigData } from '../../api/superadmin'

type ConfigForm = Omit<PlatformConfigData, 'updatedAt'>

function SkeletonField() {
  return (
    <div className="animate-pulse">
      <div className="h-3 bg-gray-700 rounded w-1/3 mb-2" />
      <div className="h-10 bg-gray-700 rounded" />
    </div>
  )
}

export default function Config() {
  const qc = useQueryClient()
  const [form, setForm] = useState<ConfigForm>({
    commissionRate: 15,
    jobTimeoutMinutes: 2,
    maxProvidersPerArea: 10,
    minRatingToRemain: 50,
    autoRefundThresholdDays: 1,
  })
  const [isDirty, setIsDirty] = useState(false)
  const [savedMsg, setSavedMsg] = useState(false)
  const [saveError, setSaveError] = useState('')

  const { data, isLoading, isError } = useQuery({
    queryKey: ['config'],
    queryFn: superAdminApi.getConfig,
    staleTime: 30_000,
  })

  useEffect(() => {
    if (data) {
      setForm({
        commissionRate: data.commissionRate,
        jobTimeoutMinutes: data.jobTimeoutMinutes,
        maxProvidersPerArea: data.maxProvidersPerArea,
        minRatingToRemain: data.minRatingToRemain,
        autoRefundThresholdDays: data.autoRefundThresholdDays,
      })
      setIsDirty(false)
    }
  }, [data])

  const saveMutation = useMutation({
    mutationFn: superAdminApi.saveConfig,
    onSuccess: (updated) => {
      qc.setQueryData(['config'], updated)
      setIsDirty(false)
      setSaveError('')
      setSavedMsg(true)
      setTimeout(() => setSavedMsg(false), 2000)
    },
    onError: (err: any) => {
      setSaveError(err?.response?.data?.error ?? 'UNKNOWN_ERROR')
    },
  })

  function update(field: keyof ConfigForm, value: number) {
    setForm(p => ({ ...p, [field]: value }))
    setIsDirty(true)
  }

  const inputClass = 'w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-white text-sm focus:outline-none focus:ring-2 focus:ring-purple-500'

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Platform Configuration</h2>
        <p className="text-gray-400 text-sm">Global settings that affect the entire platform</p>
      </div>

      <div className="bg-amber-900/20 border border-amber-700/50 rounded-xl p-4">
        <p className="text-amber-400 text-sm">
          ⚠️ Changes here affect all regions and are logged in the audit trail.
        </p>
      </div>

      {isError && (
        <p className="text-red-400 text-sm">Failed to load configuration. Please retry.</p>
      )}

      <div className="bg-gray-800 border border-gray-700 rounded-xl p-6 space-y-6">
        <h3 className="text-white font-semibold border-b border-gray-700 pb-3">Financial Settings</h3>

        {isLoading ? (
          <><SkeletonField /><SkeletonField /></>
        ) : (
          <>
            <div>
              <label className="block text-sm text-gray-400 mb-1">
                Commission Rate: <span className="text-amber-400 font-bold">{form.commissionRate}%</span>
              </label>
              <input
                type="number"
                min={1}
                max={50}
                value={form.commissionRate}
                onChange={e => update('commissionRate', +e.target.value)}
                className={inputClass}
              />
              <p className="text-xs text-gray-500 mt-1">Platform cut from each completed job payment (1–50%)</p>
            </div>

            <div>
              <label className="block text-sm text-gray-400 mb-2">Auto-Refund Window (days)</label>
              <input
                type="number"
                min={1}
                max={30}
                value={form.autoRefundThresholdDays}
                onChange={e => update('autoRefundThresholdDays', +e.target.value)}
                className={inputClass}
              />
              <p className="text-xs text-gray-500 mt-1">Disputes older than this window cannot auto-refund (1–30)</p>
            </div>
          </>
        )}
      </div>

      <div className="bg-gray-800 border border-gray-700 rounded-xl p-6 space-y-6">
        <h3 className="text-white font-semibold border-b border-gray-700 pb-3">Operational Settings</h3>

        {isLoading ? (
          <><SkeletonField /><SkeletonField /><SkeletonField /></>
        ) : (
          <>
            <div>
              <label className="block text-sm text-gray-400 mb-1">
                Job Acceptance Timeout: <span className="text-amber-400 font-bold">{form.jobTimeoutMinutes} min</span>
              </label>
              <input
                type="number"
                min={1}
                max={60}
                value={form.jobTimeoutMinutes}
                onChange={e => update('jobTimeoutMinutes', +e.target.value)}
                className={inputClass}
              />
              <p className="text-xs text-gray-500 mt-1">Provider countdown before auto-reject (1–60 min)</p>
            </div>

            <div>
              <label className="block text-sm text-gray-400 mb-2">Max Active Providers Per Area</label>
              <input
                type="number"
                min={1}
                max={100}
                value={form.maxProvidersPerArea}
                onChange={e => update('maxProvidersPerArea', +e.target.value)}
                className={inputClass}
              />
              <p className="text-xs text-gray-500 mt-1">Maximum concurrent providers in one area (1–100)</p>
            </div>

            <div>
              <label className="block text-sm text-gray-400 mb-2">Min Positive Rating to Remain Active (%)</label>
              <input
                type="number"
                min={0}
                max={100}
                value={form.minRatingToRemain}
                onChange={e => update('minRatingToRemain', +e.target.value)}
                className={inputClass}
              />
              <p className="text-xs text-gray-500 mt-1">% positive ratings required from last 20 jobs (0–100)</p>
            </div>
          </>
        )}
      </div>

      {saveError && (
        <p className="text-red-400 text-sm">Save failed: {saveError}</p>
      )}

      {data?.updatedAt && (
        <p className="text-gray-500 text-xs">Last saved: {new Date(data.updatedAt).toLocaleString()}</p>
      )}

      <button
        onClick={() => saveMutation.mutate(form)}
        disabled={!isDirty || saveMutation.isPending || isLoading}
        className={`px-8 py-3 rounded-xl font-bold text-white transition-colors ${
          savedMsg
            ? 'bg-green-600'
            : 'bg-purple-600 hover:bg-purple-700 disabled:opacity-40 disabled:cursor-not-allowed'
        }`}
      >
        {saveMutation.isPending ? 'Saving…' : savedMsg ? '✓ تم الحفظ' : 'Save Configuration'}
      </button>
    </div>
  )
}

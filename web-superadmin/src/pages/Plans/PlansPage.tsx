import { useEffect, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { superAdminApi, SubscriptionPlan } from '../../api/superadmin'

type PlanForm = {
  monthlyFee: number
  commissionRate: number
  priorityDelaySeconds: number
  stripePriceId: string
  isActive: boolean
}

function SkeletonCard() {
  return (
    <div className="bg-gray-800 border border-gray-700 rounded-xl p-6 animate-pulse space-y-4">
      <div className="h-4 bg-gray-700 rounded w-1/3" />
      <div className="space-y-3">
        <div className="h-10 bg-gray-700 rounded" />
        <div className="h-10 bg-gray-700 rounded" />
        <div className="h-10 bg-gray-700 rounded" />
      </div>
    </div>
  )
}

function PlanCard({ plan }: { plan: SubscriptionPlan }) {
  const qc = useQueryClient()
  const [form, setForm] = useState<PlanForm>({
    monthlyFee: plan.monthlyFee,
    commissionRate: plan.commissionRate,
    priorityDelaySeconds: plan.priorityDelaySeconds,
    stripePriceId: plan.stripePriceId ?? '',
    isActive: plan.isActive,
  })
  const [isDirty, setIsDirty] = useState(false)
  const [savedMsg, setSavedMsg] = useState(false)
  const [saveError, setSaveError] = useState('')

  useEffect(() => {
    setForm({
      monthlyFee: plan.monthlyFee,
      commissionRate: plan.commissionRate,
      priorityDelaySeconds: plan.priorityDelaySeconds,
      stripePriceId: plan.stripePriceId ?? '',
      isActive: plan.isActive,
    })
    setIsDirty(false)
  }, [plan])

  const saveMutation = useMutation({
    mutationFn: () =>
      superAdminApi.updateSubscriptionPlan(plan.id, {
        monthlyFee: form.monthlyFee,
        commissionRate: form.commissionRate,
        priorityDelaySeconds: form.priorityDelaySeconds,
        stripePriceId: form.stripePriceId || undefined,
        isActive: form.isActive,
      }),
    onSuccess: (updated) => {
      qc.setQueryData<SubscriptionPlan[]>(['plans'], (old) =>
        old ? old.map((p) => (p.id === updated.id ? updated : p)) : [updated]
      )
      setIsDirty(false)
      setSaveError('')
      setSavedMsg(true)
      setTimeout(() => setSavedMsg(false), 2000)
    },
    onError: (err: any) => {
      setSaveError(err?.response?.data?.error ?? 'UNKNOWN_ERROR')
    },
  })

  function update<K extends keyof PlanForm>(field: K, value: PlanForm[K]) {
    setForm((p) => ({ ...p, [field]: value }))
    setIsDirty(true)
  }

  const inputClass =
    'w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-white text-sm focus:outline-none focus:ring-2 focus:ring-purple-500'

  return (
    <div className="bg-gray-800 border border-gray-700 rounded-xl p-6 space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-white font-semibold text-lg">{plan.name}</h3>
          {plan.updatedAt && (
            <p className="text-gray-500 text-xs mt-0.5">
              Last updated: {new Date(plan.updatedAt).toLocaleString()}
            </p>
          )}
        </div>
        <span
          className={`text-xs px-2 py-1 rounded-full font-medium ${
            form.isActive
              ? 'bg-green-900/40 text-green-400 border border-green-700/50'
              : 'bg-gray-700 text-gray-400 border border-gray-600'
          }`}
        >
          {form.isActive ? 'Active' : 'Inactive'}
        </span>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="block text-sm text-gray-400 mb-1">
            Monthly Fee: <span className="text-amber-400 font-bold">{form.monthlyFee} SAR</span>
          </label>
          <input
            type="number"
            min={0}
            step={0.01}
            value={form.monthlyFee}
            onChange={(e) => update('monthlyFee', +e.target.value)}
            className={inputClass}
          />
          <p className="text-xs text-gray-500 mt-1">Recurring monthly charge in SAR</p>
        </div>

        <div>
          <label className="block text-sm text-gray-400 mb-1">
            Commission Rate: <span className="text-amber-400 font-bold">{form.commissionRate}%</span>
          </label>
          <input
            type="number"
            min={0}
            max={100}
            step={0.1}
            value={form.commissionRate}
            onChange={(e) => update('commissionRate', +e.target.value)}
            className={inputClass}
          />
          <p className="text-xs text-gray-500 mt-1">Platform cut per completed job (0–100%)</p>
        </div>

        <div>
          <label className="block text-sm text-gray-400 mb-1">
            Priority Head-start: <span className="text-amber-400 font-bold">{form.priorityDelaySeconds}s</span>
          </label>
          <input
            type="number"
            min={0}
            max={300}
            value={form.priorityDelaySeconds}
            onChange={(e) => update('priorityDelaySeconds', +e.target.value)}
            className={inputClass}
          />
          <p className="text-xs text-gray-500 mt-1">Seconds before job is broadcast to standard providers (0–300)</p>
        </div>

        <div>
          <label className="block text-sm text-gray-400 mb-1">Stripe Price ID</label>
          <input
            type="text"
            placeholder="price_..."
            value={form.stripePriceId}
            onChange={(e) => update('stripePriceId', e.target.value)}
            className={inputClass}
          />
          <p className="text-xs text-gray-500 mt-1">Stripe price object for recurring billing</p>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <label className="flex items-center gap-2 cursor-pointer select-none">
          <input
            type="checkbox"
            checked={form.isActive}
            onChange={(e) => update('isActive', e.target.checked)}
            className="w-4 h-4 accent-purple-600"
          />
          <span className="text-sm text-gray-300">
            Plan is active (controls subscribe button visibility in provider app)
          </span>
        </label>
      </div>

      {saveError && (
        <p className="text-red-400 text-sm">Save failed: {saveError}</p>
      )}

      <button
        onClick={() => saveMutation.mutate()}
        disabled={!isDirty || saveMutation.isPending}
        className={`px-8 py-3 rounded-xl font-bold text-white transition-colors ${
          savedMsg
            ? 'bg-green-600'
            : 'bg-purple-600 hover:bg-purple-700 disabled:opacity-40 disabled:cursor-not-allowed'
        }`}
      >
        {saveMutation.isPending ? 'Saving…' : savedMsg ? '✓ Saved' : 'Save Plan'}
      </button>
    </div>
  )
}

export default function PlansPage() {
  const { data: plans, isLoading, isError } = useQuery({
    queryKey: ['plans'],
    queryFn: superAdminApi.getSubscriptionPlans,
    staleTime: 30_000,
  })

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold text-white">Subscription Plans</h2>
        <p className="text-gray-400 text-sm">Configure Power Provider plan pricing and behaviour</p>
      </div>

      <div className="bg-amber-900/20 border border-amber-700/50 rounded-xl p-4">
        <p className="text-amber-400 text-sm">
          ⚠️ Changes to commission rate take effect on the next billing cycle. Stripe Price ID must match an active price in your Stripe dashboard.
        </p>
      </div>

      {isError && (
        <p className="text-red-400 text-sm">Failed to load subscription plans. Please retry.</p>
      )}

      {isLoading ? (
        <>
          <SkeletonCard />
          <SkeletonCard />
        </>
      ) : plans && plans.length > 0 ? (
        plans.map((plan) => <PlanCard key={plan.id} plan={plan} />)
      ) : (
        <div className="bg-gray-800 border border-gray-700 rounded-xl p-8 text-center">
          <p className="text-gray-400">No subscription plans found.</p>
          <p className="text-gray-500 text-sm mt-1">
            Run <code className="text-purple-400">add-subscription-plans.sql</code> to seed the default PowerProvider plan.
          </p>
        </div>
      )}
    </div>
  )
}

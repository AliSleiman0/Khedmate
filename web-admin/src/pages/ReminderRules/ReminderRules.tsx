import { useEffect, useState } from 'react'
import {
  ReminderRule,
  fetchReminderRules,
  updateReminderRule,
  createReminderRule,
} from '../../api/reminderRules'

interface EditState {
  id: string
  intervalDays: number
  isActive: boolean
}

interface Toast {
  message: string
  type: 'success' | 'error'
}

export default function ReminderRules() {
  const [rules, setRules] = useState<ReminderRule[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [editState, setEditState] = useState<EditState | null>(null)
  const [saving, setSaving] = useState(false)
  const [toast, setToast] = useState<Toast | null>(null)

  // New rule form
  const [showNewForm, setShowNewForm] = useState(false)
  const [newCategory, setNewCategory] = useState('')
  const [newInterval, setNewInterval] = useState(90)
  const [creating, setCreating] = useState(false)

  const showToast = (message: string, type: Toast['type']) => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 3000)
  }

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchReminderRules()
      setRules(data)
    } catch {
      setError('Failed to load reminder rules')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  const startEdit = (rule: ReminderRule) => {
    setEditState({ id: rule.id, intervalDays: rule.intervalDays, isActive: rule.isActive })
  }

  const cancelEdit = () => setEditState(null)

  const saveEdit = async () => {
    if (!editState) return
    if (editState.intervalDays < 1 || editState.intervalDays > 365) {
      showToast('Interval must be between 1 and 365 days', 'error')
      return
    }
    setSaving(true)
    try {
      const updated = await updateReminderRule(editState.id, editState.intervalDays, editState.isActive)
      setRules(prev => prev.map(r => r.id === updated.id ? updated : r))
      setEditState(null)
      showToast('Rule updated successfully', 'success')
    } catch {
      showToast('Failed to save changes', 'error')
    } finally {
      setSaving(false)
    }
  }

  const handleCreate = async () => {
    if (!newCategory.trim()) {
      showToast('Category name is required', 'error')
      return
    }
    if (newInterval < 1 || newInterval > 365) {
      showToast('Interval must be between 1 and 365 days', 'error')
      return
    }
    setCreating(true)
    try {
      const created = await createReminderRule(newCategory.trim(), newInterval)
      setRules(prev => [...prev, created].sort((a, b) => a.category.localeCompare(b.category)))
      setShowNewForm(false)
      setNewCategory('')
      setNewInterval(90)
      showToast(`Rule for "${created.category}" created`, 'success')
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : ''
      if (msg.includes('CATEGORY_ALREADY_EXISTS') || msg.includes('409')) {
        showToast('A rule for this category already exists', 'error')
      } else {
        showToast('Failed to create rule', 'error')
      }
    } finally {
      setCreating(false)
    }
  }

  const formatDate = (iso: string | null) =>
    iso
      ? new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
      : '—'

  return (
    <div className="space-y-5">
      {/* Toast */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 px-4 py-3 rounded-xl shadow-lg text-sm font-medium transition-all ${
            toast.type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
          }`}
        >
          {toast.message}
        </div>
      )}

      <div className="flex items-start justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Reminder Rules</h2>
          <p className="text-gray-500 text-sm">Configure maintenance reminder intervals per service category</p>
        </div>
        <button
          onClick={() => setShowNewForm(v => !v)}
          className="px-4 py-2 bg-[#1B4F72] text-white text-sm font-semibold rounded-lg hover:bg-[#154360] transition-colors"
        >
          {showNewForm ? 'Cancel' : '+ Add Rule'}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          {error}
        </div>
      )}

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              {['Category', 'Interval (days)', 'Active', 'Last Updated', 'Actions'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {loading ? (
              Array.from({ length: 4 }).map((_, i) => (
                <tr key={i} className="border-t border-gray-100">
                  {Array.from({ length: 5 }).map((_, j) => (
                    <td key={j} className="px-4 py-3">
                      <div className="h-4 bg-gray-200 rounded animate-pulse" />
                    </td>
                  ))}
                </tr>
              ))
            ) : rules.length === 0 && !showNewForm ? (
              <tr>
                <td colSpan={5} className="px-4 py-10 text-center text-gray-400 text-sm">
                  No reminder rules configured yet. Click "+ Add Rule" to create one.
                </td>
              </tr>
            ) : (
              rules.map(rule => {
                const isEditing = editState?.id === rule.id
                return (
                  <tr key={rule.id} className={`transition-colors ${isEditing ? 'bg-blue-50' : 'hover:bg-gray-50'}`}>
                    <td className="px-4 py-3 font-medium">{rule.category}</td>
                    <td className="px-4 py-3">
                      {isEditing ? (
                        <input
                          type="number"
                          min={1}
                          max={365}
                          value={editState.intervalDays}
                          onChange={e =>
                            setEditState(s => s ? { ...s, intervalDays: Number(e.target.value) } : s)
                          }
                          className="w-24 border border-gray-300 rounded-lg px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
                        />
                      ) : (
                        <span>{rule.intervalDays} days</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {isEditing ? (
                        <button
                          onClick={() =>
                            setEditState(s => s ? { ...s, isActive: !s.isActive } : s)
                          }
                          className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                            editState.isActive ? 'bg-green-500' : 'bg-gray-300'
                          }`}
                        >
                          <span
                            className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow transition-transform ${
                              editState.isActive ? 'translate-x-4' : 'translate-x-1'
                            }`}
                          />
                        </button>
                      ) : (
                        <span
                          className={`px-2 py-1 rounded-full text-xs font-medium ${
                            rule.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                          }`}
                        >
                          {rule.isActive ? 'Active' : 'Inactive'}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-gray-500 text-xs">{formatDate(rule.updatedAt ?? rule.createdAt)}</td>
                    <td className="px-4 py-3">
                      {isEditing ? (
                        <div className="flex items-center gap-2">
                          <button
                            onClick={saveEdit}
                            disabled={saving}
                            className="text-xs text-white bg-[#1B4F72] px-3 py-1.5 rounded-lg hover:bg-[#154360] disabled:opacity-50 font-medium transition-colors"
                          >
                            {saving ? 'Saving...' : 'Save'}
                          </button>
                          <button
                            onClick={cancelEdit}
                            disabled={saving}
                            className="text-xs text-gray-600 border border-gray-300 px-3 py-1.5 rounded-lg hover:bg-gray-50 font-medium transition-colors"
                          >
                            Cancel
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => startEdit(rule)}
                          className="text-xs text-[#1B4F72] hover:underline font-medium"
                        >
                          Edit
                        </button>
                      )}
                    </td>
                  </tr>
                )
              })
            )}

            {/* New rule form row */}
            {showNewForm && (
              <tr className="bg-amber-50">
                <td className="px-4 py-3">
                  <input
                    type="text"
                    placeholder="e.g. AC Service"
                    value={newCategory}
                    onChange={e => setNewCategory(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#F39C12]"
                  />
                </td>
                <td className="px-4 py-3">
                  <input
                    type="number"
                    min={1}
                    max={365}
                    value={newInterval}
                    onChange={e => setNewInterval(Number(e.target.value))}
                    className="w-24 border border-gray-300 rounded-lg px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#F39C12]"
                  />
                </td>
                <td className="px-4 py-3 text-xs text-gray-500">Active by default</td>
                <td className="px-4 py-3 text-xs text-gray-400">—</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={handleCreate}
                      disabled={creating}
                      className="text-xs text-white bg-[#F39C12] px-3 py-1.5 rounded-lg hover:bg-[#d68910] disabled:opacity-50 font-medium transition-colors"
                    >
                      {creating ? 'Creating...' : 'Create'}
                    </button>
                    <button
                      onClick={() => { setShowNewForm(false); setNewCategory(''); setNewInterval(90) }}
                      className="text-xs text-gray-600 border border-gray-300 px-3 py-1.5 rounded-lg hover:bg-gray-50 font-medium transition-colors"
                    >
                      Cancel
                    </button>
                  </div>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

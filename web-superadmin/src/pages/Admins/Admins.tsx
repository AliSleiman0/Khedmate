import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { superAdminApi, AdminRow } from '../../api/superadmin'
import { useAuthStore } from '../../store/authStore'

function SkeletonRow() {
  return (
    <tr className="animate-pulse">
      {Array.from({ length: 6 }).map((_, i) => (
        <td key={i} className="px-4 py-3">
          <div className="h-3 bg-gray-700 rounded w-24" />
        </td>
      ))}
    </tr>
  )
}

const PASSWORD_RULES = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/

export default function Admins() {
  const qc = useQueryClient()
  const currentAdminId = useAuthStore(s => s.adminId)

  const [page, setPage] = useState(1)
  const [showCreate, setShowCreate] = useState(false)
  const [createForm, setCreateForm] = useState({ email: '', password: '', role: 'admin' })
  const [showPassword, setShowPassword] = useState(false)
  const [createErrors, setCreateErrors] = useState<Record<string, string>>({})
  const [createApiError, setCreateApiError] = useState('')

  const [editRow, setEditRow] = useState<AdminRow | null>(null)
  const [editForm, setEditForm] = useState({ role: '', isActive: true })
  const [editApiError, setEditApiError] = useState('')

  const [confirmRevokeId, setConfirmRevokeId] = useState<string | null>(null)
  const [revokeApiError, setRevokeApiError] = useState('')

  const { data, isLoading, isError } = useQuery({
    queryKey: ['admins', page],
    queryFn: () => superAdminApi.getAdmins(page),
    staleTime: 30_000,
  })

  const createMutation = useMutation({
    mutationFn: superAdminApi.createAdmin,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admins'] })
      setShowCreate(false)
      setCreateForm({ email: '', password: '', role: 'admin' })
      setCreateErrors({})
      setCreateApiError('')
    },
    onError: (err: any) => {
      setCreateApiError(err?.response?.data?.error ?? 'UNKNOWN_ERROR')
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: string; body: { role: string; isActive: boolean } }) =>
      superAdminApi.updateAdmin(id, body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admins'] })
      setEditRow(null)
      setEditApiError('')
    },
    onError: (err: any) => {
      setEditApiError(err?.response?.data?.error ?? 'UNKNOWN_ERROR')
    },
  })

  const revokeMutation = useMutation({
    mutationFn: superAdminApi.revokeAdmin,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admins'] })
      setConfirmRevokeId(null)
      setRevokeApiError('')
    },
    onError: (err: any) => {
      setRevokeApiError(err?.response?.data?.error ?? 'UNKNOWN_ERROR')
    },
  })

  function validateCreate() {
    const errs: Record<string, string> = {}
    if (!createForm.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(createForm.email))
      errs.email = 'Valid email required'
    if (!PASSWORD_RULES.test(createForm.password))
      errs.password = 'Min 8 chars with uppercase, lowercase, and digit'
    if (!createForm.role) errs.role = 'Role required'
    setCreateErrors(errs)
    return Object.keys(errs).length === 0
  }

  function handleCreate() {
    if (!validateCreate()) return
    setCreateApiError('')
    createMutation.mutate(createForm)
  }

  function openEdit(row: AdminRow) {
    setEditRow(row)
    setEditForm({ role: row.role, isActive: row.isActive })
    setEditApiError('')
  }

  const totalPages = data ? Math.ceil(data.total / data.pageSize) : 1
  const inputClass = 'w-full bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-purple-500'

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white">Admin Users</h2>
          <p className="text-gray-400 text-sm">Platform admin accounts</p>
        </div>
        <button
          onClick={() => { setShowCreate(true); setCreateApiError('') }}
          className="bg-purple-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-purple-700 transition-colors"
        >
          + Create Admin
        </button>
      </div>

      {isError && (
        <p className="text-red-400 text-sm">Failed to load admins. Please retry.</p>
      )}

      {/* Create form */}
      {showCreate && (
        <div className="bg-gray-800 border border-purple-600/50 rounded-xl p-6 space-y-4">
          <h3 className="text-white font-semibold">Create Admin Account</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs text-gray-400 mb-1">Email</label>
              <input
                className={inputClass}
                placeholder="admin@example.com"
                value={createForm.email}
                onChange={e => setCreateForm(p => ({ ...p, email: e.target.value }))}
              />
              {createErrors.email && <p className="text-red-400 text-xs mt-1">{createErrors.email}</p>}
            </div>
            <div>
              <label className="block text-xs text-gray-400 mb-1">Password</label>
              <div className="relative">
                <input
                  className={inputClass}
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Min 8 chars, upper + lower + digit"
                  value={createForm.password}
                  onChange={e => setCreateForm(p => ({ ...p, password: e.target.value }))}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(v => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-xs"
                >
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>
              {createErrors.password && <p className="text-red-400 text-xs mt-1">{createErrors.password}</p>}
            </div>
            <div>
              <label className="block text-xs text-gray-400 mb-1">Role</label>
              <select
                className={inputClass}
                value={createForm.role}
                onChange={e => setCreateForm(p => ({ ...p, role: e.target.value }))}
              >
                <option value="admin">Admin</option>
                <option value="superadmin">Super Admin</option>
              </select>
            </div>
          </div>
          {createApiError && <p className="text-red-400 text-sm">Error: {createApiError}</p>}
          <div className="flex gap-3">
            <button
              onClick={handleCreate}
              disabled={createMutation.isPending}
              className="bg-purple-600 text-white px-6 py-2 rounded-lg text-sm font-medium hover:bg-purple-700 disabled:opacity-50"
            >
              {createMutation.isPending ? 'Creating…' : 'Create'}
            </button>
            <button
              onClick={() => { setShowCreate(false); setCreateErrors({}); setCreateApiError('') }}
              className="bg-gray-700 text-gray-300 px-6 py-2 rounded-lg text-sm hover:bg-gray-600"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="bg-gray-800 border border-gray-700 rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-900 border-b border-gray-700">
            <tr>
              {['Email', 'Role', 'Status', 'Created At', 'Actions'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700">
            {isLoading
              ? Array.from({ length: 5 }).map((_, i) => <SkeletonRow key={i} />)
              : data?.admins.map(row => (
                <>
                  <tr key={row.id} className="hover:bg-gray-750 transition-colors">
                    <td className="px-4 py-3 text-white">{row.email}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        row.role === 'superadmin' ? 'bg-purple-500/20 text-purple-400' : 'bg-blue-500/20 text-blue-400'
                      }`}>
                        {row.role}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        row.isActive ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'
                      }`}>
                        {row.isActive ? 'Active' : 'Revoked'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-400 text-xs">
                      {new Date(row.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3 space-x-3">
                      <button
                        onClick={() => openEdit(row)}
                        disabled={row.id === currentAdminId}
                        className="text-xs text-purple-400 hover:underline disabled:opacity-40 disabled:cursor-not-allowed"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => { setConfirmRevokeId(row.id); setRevokeApiError('') }}
                        disabled={row.id === currentAdminId || !row.isActive}
                        className="text-xs text-red-400 hover:underline disabled:opacity-40 disabled:cursor-not-allowed"
                      >
                        Revoke
                      </button>
                    </td>
                  </tr>

                  {/* Inline edit row */}
                  {editRow?.id === row.id && (
                    <tr key={`${row.id}-edit`} className="bg-gray-900 border-t border-purple-700/30">
                      <td colSpan={5} className="px-4 py-4">
                        <div className="flex items-end gap-4">
                          <div>
                            <label className="block text-xs text-gray-400 mb-1">Role</label>
                            <select
                              className="bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                              value={editForm.role}
                              onChange={e => setEditForm(p => ({ ...p, role: e.target.value }))}
                            >
                              <option value="admin">Admin</option>
                              <option value="superadmin">Super Admin</option>
                            </select>
                          </div>
                          <div>
                            <label className="block text-xs text-gray-400 mb-1">Status</label>
                            <select
                              className="bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                              value={editForm.isActive ? 'active' : 'revoked'}
                              onChange={e => setEditForm(p => ({ ...p, isActive: e.target.value === 'active' }))}
                            >
                              <option value="active">Active</option>
                              <option value="revoked">Revoked</option>
                            </select>
                          </div>
                          <button
                            onClick={() => updateMutation.mutate({ id: row.id, body: editForm })}
                            disabled={updateMutation.isPending}
                            className="bg-purple-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-purple-700 disabled:opacity-50"
                          >
                            {updateMutation.isPending ? 'Saving…' : 'Save'}
                          </button>
                          <button
                            onClick={() => { setEditRow(null); setEditApiError('') }}
                            className="bg-gray-700 text-gray-300 px-4 py-2 rounded-lg text-sm hover:bg-gray-600"
                          >
                            Cancel
                          </button>
                          {editApiError && <p className="text-red-400 text-sm">{editApiError}</p>}
                        </div>
                      </td>
                    </tr>
                  )}

                  {/* Inline revoke confirmation */}
                  {confirmRevokeId === row.id && (
                    <tr key={`${row.id}-revoke`} className="bg-red-900/10 border-t border-red-700/30">
                      <td colSpan={5} className="px-4 py-3">
                        <div className="flex items-center gap-4">
                          <span className="text-gray-300 text-sm">Are you sure you want to revoke <strong>{row.email}</strong>?</span>
                          <button
                            onClick={() => revokeMutation.mutate(row.id)}
                            disabled={revokeMutation.isPending}
                            className="bg-red-600 text-white px-4 py-1.5 rounded-lg text-sm hover:bg-red-700 disabled:opacity-50"
                          >
                            {revokeMutation.isPending ? 'Revoking…' : 'Confirm Revoke'}
                          </button>
                          <button
                            onClick={() => { setConfirmRevokeId(null); setRevokeApiError('') }}
                            className="bg-gray-700 text-gray-300 px-4 py-1.5 rounded-lg text-sm hover:bg-gray-600"
                          >
                            Cancel
                          </button>
                          {revokeApiError && <p className="text-red-400 text-sm">{revokeApiError}</p>}
                        </div>
                      </td>
                    </tr>
                  )}
                </>
              ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {data && totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-gray-400">
          <span>{data.total} admins total</span>
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

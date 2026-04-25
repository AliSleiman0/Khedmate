import { useEffect, useMemo, useState } from 'react'
import {
  Category,
  CreateCategoryInput,
  UpdateCategoryInput,
  createCategory,
  fetchCategories,
  setCategoryActive,
  updateCategory,
} from '../../api/categories'
import {
  CATEGORY_ICON_KEYS,
  CategoryIconKey,
  DEFAULT_CATEGORY_ICON,
} from '../../constants/categoryIcons'

interface Toast {
  message: string
  type: 'success' | 'error'
}

interface FormState {
  id: string | null
  slug: string
  nameEn: string
  nameAr: string
  iconKey: CategoryIconKey
  displayOrder: number
  requiresSkillTest: boolean
}

const blankForm: FormState = {
  id: null,
  slug: '',
  nameEn: '',
  nameAr: '',
  iconKey: DEFAULT_CATEGORY_ICON,
  displayOrder: 100,
  requiresSkillTest: true,
}

function MaterialIcon({ name, className }: { name: string; className?: string }) {
  return (
    <span className={`material-symbols-outlined select-none ${className ?? ''}`}>
      {name}
    </span>
  )
}

function isValidSlug(slug: string): boolean {
  return /^[a-z][a-z0-9_]*$/.test(slug) && slug.length <= 50
}

export default function Categories() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [toast, setToast] = useState<Toast | null>(null)
  const [busy, setBusy] = useState(false)

  const [form, setForm] = useState<FormState | null>(null)

  const showToast = (message: string, type: Toast['type']) => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 3000)
  }

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchCategories()
      setCategories(data)
    } catch {
      setError('Failed to load categories')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const sorted = useMemo(
    () =>
      [...categories].sort(
        (a, b) =>
          a.displayOrder - b.displayOrder ||
          a.nameEn.localeCompare(b.nameEn),
      ),
    [categories],
  )

  const openCreate = () => setForm({ ...blankForm })
  const openEdit = (c: Category) =>
    setForm({
      id: c.id,
      slug: c.slug,
      nameEn: c.nameEn,
      nameAr: c.nameAr,
      iconKey: (CATEGORY_ICON_KEYS as readonly string[]).includes(c.iconKey)
        ? (c.iconKey as CategoryIconKey)
        : DEFAULT_CATEGORY_ICON,
      displayOrder: c.displayOrder,
      requiresSkillTest: c.requiresSkillTest,
    })
  const closeForm = () => setForm(null)

  const errorCodeMessage = (err: unknown): string => {
    const raw = err instanceof Error ? err.message : ''
    if (raw.includes('SLUG_INVALID_FORMAT'))
      return 'Slug must start with a lowercase letter and contain only a–z, 0–9, _'
    if (raw.includes('SLUG_ALREADY_EXISTS') || raw.includes('409'))
      return 'A category with this slug already exists'
    if (raw.includes('NAME_EN_INVALID')) return 'English name is required (max 100 chars)'
    if (raw.includes('NAME_AR_INVALID')) return 'Arabic name is required (max 100 chars)'
    if (raw.includes('ICON_KEY_INVALID')) return 'Pick an icon'
    if (raw.includes('INSUFFICIENT_QUESTIONS'))
      return 'Activate is blocked: 10 published questions are required first'
    return 'Operation failed'
  }

  const submitForm = async () => {
    if (!form) return
    if (!form.id && !isValidSlug(form.slug)) {
      showToast('Slug must start with a lowercase letter and use a–z, 0–9, _', 'error')
      return
    }
    if (!form.nameEn.trim() || !form.nameAr.trim()) {
      showToast('Both English and Arabic names are required', 'error')
      return
    }
    setBusy(true)
    try {
      if (form.id) {
        const input: UpdateCategoryInput = {
          nameEn: form.nameEn.trim(),
          nameAr: form.nameAr.trim(),
          iconKey: form.iconKey,
          displayOrder: form.displayOrder,
          requiresSkillTest: form.requiresSkillTest,
        }
        const updated = await updateCategory(form.id, input)
        setCategories((prev) => prev.map((c) => (c.id === updated.id ? updated : c)))
        showToast('Category updated', 'success')
      } else {
        const input: CreateCategoryInput = {
          slug: form.slug.trim().toLowerCase(),
          nameEn: form.nameEn.trim(),
          nameAr: form.nameAr.trim(),
          iconKey: form.iconKey,
          displayOrder: form.displayOrder,
          requiresSkillTest: form.requiresSkillTest,
        }
        const created = await createCategory(input)
        setCategories((prev) => [...prev, created])
        showToast(`Category "${created.nameEn}" created — activate it once skill-test questions exist`, 'success')
      }
      closeForm()
    } catch (err) {
      showToast(errorCodeMessage(err), 'error')
    } finally {
      setBusy(false)
    }
  }

  const toggleActive = async (c: Category) => {
    setBusy(true)
    try {
      const updated = await setCategoryActive(c.id, !c.isActive)
      setCategories((prev) => prev.map((x) => (x.id === updated.id ? updated : x)))
      showToast(
        updated.isActive ? `Activated "${updated.nameEn}"` : `Deactivated "${updated.nameEn}"`,
        'success',
      )
    } catch (err) {
      showToast(errorCodeMessage(err), 'error')
    } finally {
      setBusy(false)
    }
  }

  const formatDate = (iso: string | null | undefined) =>
    iso
      ? new Date(iso).toLocaleDateString('en-GB', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
        })
      : '—'

  return (
    <div className="space-y-5">
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 px-4 py-3 rounded-xl shadow-lg text-sm font-medium ${
            toast.type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
          }`}
        >
          {toast.message}
        </div>
      )}

      <div className="flex items-start justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Service Categories</h2>
          <p className="text-gray-500 text-sm">
            Configure the categories shown to customers and providers in the unified mobile app
          </p>
        </div>
        <button
          onClick={openCreate}
          className="px-4 py-2 bg-[#1B4F72] text-white text-sm font-semibold rounded-lg hover:bg-[#154360] transition-colors"
        >
          + Add Category
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
              {['Order', 'Icon', 'Slug', 'Name (EN)', 'Name (AR)', 'Skill Test', 'Active', 'Updated', ''].map(
                (h) => (
                  <th
                    key={h}
                    className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider"
                  >
                    {h}
                  </th>
                ),
              )}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {loading ? (
              Array.from({ length: 6 }).map((_, i) => (
                <tr key={i}>
                  {Array.from({ length: 9 }).map((_, j) => (
                    <td key={j} className="px-4 py-3">
                      <div className="h-4 bg-gray-200 rounded animate-pulse" />
                    </td>
                  ))}
                </tr>
              ))
            ) : sorted.length === 0 ? (
              <tr>
                <td colSpan={9} className="px-4 py-10 text-center text-gray-400 text-sm">
                  No categories yet. Click "+ Add Category" to create one.
                </td>
              </tr>
            ) : (
              sorted.map((c) => {
                const requiresGate = c.requiresSkillTest
                const gateBlocked = requiresGate && c.publishedQuestionCount < 10
                const gateLabel = requiresGate
                  ? `${c.publishedQuestionCount} / 10 questions`
                  : 'Not required'
                return (
                  <tr key={c.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3 text-gray-500">{c.displayOrder}</td>
                    <td className="px-4 py-3">
                      {c.iconUrl ? (
                        <img
                          src={c.iconUrl}
                          alt={c.iconKey}
                          className="w-7 h-7 object-contain"
                        />
                      ) : (
                        <MaterialIcon
                          name={c.iconKey}
                          className="text-[#1B4F72] !text-2xl"
                        />
                      )}
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-600">{c.slug}</td>
                    <td className="px-4 py-3 font-medium">{c.nameEn}</td>
                    <td className="px-4 py-3 text-right" dir="rtl">
                      {c.nameAr}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                          gateBlocked
                            ? 'bg-amber-100 text-amber-700'
                            : 'bg-gray-100 text-gray-600'
                        }`}
                        title={
                          gateBlocked
                            ? 'Activate is blocked until 10 questions are published (PR 2 ships the editor)'
                            : undefined
                        }
                      >
                        {gateLabel}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => toggleActive(c)}
                        disabled={busy || (!c.isActive && gateBlocked)}
                        title={
                          !c.isActive && gateBlocked
                            ? `Activate is blocked: ${c.publishedQuestionCount}/10 questions published`
                            : undefined
                        }
                        className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
                          c.isActive ? 'bg-green-500' : 'bg-gray-300'
                        }`}
                      >
                        <span
                          className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow transition-transform ${
                            c.isActive ? 'translate-x-4' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </td>
                    <td className="px-4 py-3 text-gray-500 text-xs">
                      {formatDate(c.updatedAt ?? c.createdAt)}
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => openEdit(c)}
                        className="text-xs text-[#1B4F72] hover:underline font-medium"
                      >
                        Edit
                      </button>
                    </td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>

      {form && (
        <div className="fixed inset-0 bg-black/40 z-40 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
              <h3 className="text-lg font-bold text-gray-900">
                {form.id ? 'Edit Category' : 'New Category'}
              </h3>
              <button
                onClick={closeForm}
                className="text-gray-400 hover:text-gray-700 text-2xl leading-none"
              >
                ×
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">
                  Slug {!form.id && <span className="text-red-500">*</span>}
                </label>
                <input
                  type="text"
                  value={form.slug}
                  onChange={(e) =>
                    setForm((f) => f && { ...f, slug: e.target.value.toLowerCase() })
                  }
                  disabled={!!form.id}
                  placeholder="e.g. gardening"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-[#1B4F72] disabled:bg-gray-100 disabled:text-gray-500"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Lowercase letters, digits, underscores. Cannot be changed after creation.
                </p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">
                    Name (English) <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={form.nameEn}
                    onChange={(e) =>
                      setForm((f) => f && { ...f, nameEn: e.target.value })
                    }
                    placeholder="Plumbing"
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">
                    Name (Arabic) <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={form.nameAr}
                    onChange={(e) =>
                      setForm((f) => f && { ...f, nameAr: e.target.value })
                    }
                    placeholder="السباكة"
                    dir="rtl"
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-2">
                  Icon
                </label>
                <div className="grid grid-cols-6 gap-2">
                  {CATEGORY_ICON_KEYS.map((key) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setForm((f) => f && { ...f, iconKey: key })}
                      className={`flex flex-col items-center justify-center gap-1 py-2 rounded-lg border transition-colors ${
                        form.iconKey === key
                          ? 'border-[#1B4F72] bg-blue-50'
                          : 'border-gray-200 hover:bg-gray-50'
                      }`}
                      title={key}
                    >
                      <MaterialIcon
                        name={key}
                        className="!text-2xl text-[#1B4F72]"
                      />
                      <span className="text-[10px] text-gray-500 truncate w-full text-center px-1">
                        {key}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">
                    Display Order
                  </label>
                  <input
                    type="number"
                    value={form.displayOrder}
                    onChange={(e) =>
                      setForm((f) => f && { ...f, displayOrder: Number(e.target.value) })
                    }
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
                  />
                  <p className="text-xs text-gray-500 mt-1">Lower = shown first</p>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">
                    Requires Skill Test
                  </label>
                  <button
                    type="button"
                    onClick={() =>
                      setForm((f) => f && { ...f, requiresSkillTest: !f.requiresSkillTest })
                    }
                    className={`flex items-center gap-2 px-3 py-2 rounded-lg border w-full ${
                      form.requiresSkillTest
                        ? 'border-[#1B4F72] bg-blue-50 text-[#1B4F72]'
                        : 'border-gray-200 text-gray-600'
                    }`}
                  >
                    <span
                      className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                        form.requiresSkillTest ? 'bg-[#1B4F72]' : 'bg-gray-300'
                      }`}
                    >
                      <span
                        className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow transition-transform ${
                          form.requiresSkillTest ? 'translate-x-4' : 'translate-x-1'
                        }`}
                      />
                    </span>
                    <span className="text-sm font-medium">
                      {form.requiresSkillTest ? 'Required' : 'Not required'}
                    </span>
                  </button>
                  <p className="text-xs text-gray-500 mt-1">
                    Providers must pass a skill test for this category
                  </p>
                </div>
              </div>
            </div>
            <div className="flex items-center justify-end gap-2 px-6 py-4 border-t border-gray-100">
              <button
                onClick={closeForm}
                disabled={busy}
                className="px-4 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 font-medium disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={submitForm}
                disabled={busy}
                className="px-4 py-2 text-sm text-white bg-[#1B4F72] rounded-lg hover:bg-[#154360] font-medium disabled:opacity-50"
              >
                {busy ? 'Saving…' : form.id ? 'Save changes' : 'Create category'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

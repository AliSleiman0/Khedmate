import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'
import axios from 'axios'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const setAuth = useAuthStore(s => s.setAuth)
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      const response = await axios.post(
        `${import.meta.env.VITE_API_URL || 'http://localhost:5000/api'}/auth/admin/login`,
        { email, password }
      )
      const { accessToken, refreshToken, admin } = response.data.data
      setAuth(accessToken, admin.role, admin.id)
      localStorage.setItem('khudmati_admin_token', accessToken)
      localStorage.setItem('khudmati_admin_role', admin.role)
      localStorage.setItem('khudmati_admin_refresh_token', refreshToken)
      navigate('/dashboard')
    } catch (err: unknown) {
      if (axios.isAxiosError(err)) {
        const code = err.response?.data?.error
        if (code === 'INVALID_CREDENTIALS' || err.response?.status === 401) {
          setError('البريد الإلكتروني أو كلمة المرور غير صحيحة')
        } else if (!err.response) {
          setError('تحقق من اتصالك بالإنترنت')
        } else {
          setError('حدث خطأ. حاول مرة أخرى')
        }
      } else {
        setError('حدث خطأ غير متوقع')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-2xl shadow-lg w-full max-w-md">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-[#1B4F72]">خدمتي</h1>
          <p className="text-gray-500 text-sm mt-1">بوابة إدارة العمليات</p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm text-right">
              {error}
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1 text-right">البريد الإلكتروني</label>
            <input
              type="email"
              placeholder="admin@khudmati.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              className="w-full border border-gray-300 rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72] text-left"
              dir="ltr"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1 text-right">كلمة المرور</label>
            <input
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              className="w-full border border-gray-300 rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#1B4F72]"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#1B4F72] text-white py-3 rounded-lg font-semibold hover:bg-[#154360] transition-colors disabled:opacity-60"
          >
            {loading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول'}
          </button>
        </form>
      </div>
    </div>
  )
}

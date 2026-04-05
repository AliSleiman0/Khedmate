import { useNavigate } from 'react-router-dom'

export default function Forbidden() {
  const navigate = useNavigate()
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-100">
      <h1 className="text-6xl font-bold text-[#1B4F72]">403</h1>
      <p className="text-gray-600 mt-4 text-lg">ليس لديك صلاحية الوصول إلى هذه الصفحة</p>
      <button
        onClick={() => navigate(-1)}
        className="mt-6 px-6 py-2 bg-[#1B4F72] text-white rounded-lg hover:bg-[#154360]"
      >
        العودة
      </button>
    </div>
  )
}

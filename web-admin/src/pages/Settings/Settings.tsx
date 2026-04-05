import { useState } from 'react'

export default function Settings() {
  const [commissionRate, setCommissionRate] = useState(15)
  const [jobTimeout, setJobTimeout] = useState(2)
  const [saved, setSaved] = useState(false)

  const handleSave = () => {
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Settings</h2>
        <p className="text-gray-500 text-sm">Admin-level platform configuration</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm p-6 space-y-6">
        <h3 className="text-lg font-semibold border-b pb-3">Operational Settings</h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Commission Rate: <span className="text-[#1B4F72] font-bold">{commissionRate}%</span>
          </label>
          <input type="range" min={5} max={30} value={commissionRate}
            onChange={e => setCommissionRate(Number(e.target.value))}
            className="w-full accent-[#1B4F72]" />
          <p className="text-xs text-gray-500 mt-1">Platform cut from each completed job</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Job Acceptance Timeout: <span className="text-[#1B4F72] font-bold">{jobTimeout} min</span>
          </label>
          <input type="range" min={1} max={10} value={jobTimeout}
            onChange={e => setJobTimeout(Number(e.target.value))}
            className="w-full accent-[#1B4F72]" />
          <p className="text-xs text-gray-500 mt-1">How long providers have to accept a job before it re-dispatches</p>
        </div>

        <button
          onClick={handleSave}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            saved ? 'bg-green-500 text-white' : 'bg-[#1B4F72] text-white hover:bg-[#154360]'
          }`}
        >
          {saved ? '✓ Saved' : 'Save Changes'}
        </button>
      </div>
    </div>
  )
}

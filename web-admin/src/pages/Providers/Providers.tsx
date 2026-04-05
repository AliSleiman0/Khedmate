const TIER_COLORS: Record<string, string> = {
  Unverified: 'bg-gray-100 text-gray-600',
  PhoneVerified: 'bg-blue-100 text-blue-700',
  IdVerified: 'bg-purple-100 text-purple-700',
  SkillTested: 'bg-amber-100 text-amber-700',
  Active: 'bg-green-100 text-green-700',
}

const mockProviders = [
  { id: 'P-001', name: 'Khalid Al-Ahmadi', phone: '+966 50 123 4567', tier: 'Active', rating: 4.9, jobs: 142, online: true },
  { id: 'P-002', name: 'Faisal Hassan', phone: '+966 55 234 5678', tier: 'SkillTested', rating: 4.7, jobs: 88, online: true },
  { id: 'P-003', name: 'Nasser Saleh', phone: '+966 56 345 6789', tier: 'IdVerified', rating: 4.5, jobs: 45, online: false },
  { id: 'P-004', name: 'Ayman Gharib', phone: '+966 57 456 7890', tier: 'PhoneVerified', rating: 4.2, jobs: 12, online: false },
  { id: 'P-005', name: 'Walid Farid', phone: '+966 58 567 8901', tier: 'Unverified', rating: 0, jobs: 0, online: false },
]

export default function Providers() {
  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Providers</h2>
        <p className="text-gray-500 text-sm">Manage service provider accounts</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              {['ID', 'Name', 'Phone', 'Tier', 'Rating', 'Jobs', 'Online', 'Actions'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {mockProviders.map(p => (
              <tr key={p.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 font-mono text-xs font-semibold text-[#1B4F72]">{p.id}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-[#1B4F72] text-white flex items-center justify-center text-xs font-bold">
                      {p.name.charAt(0)}
                    </div>
                    <span className="font-medium">{p.name}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-gray-600">{p.phone}</td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${TIER_COLORS[p.tier]}`}>
                    {p.tier}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {p.rating > 0 ? (
                    <span className="flex items-center gap-1">
                      <span className="text-amber-400">★</span>
                      <span className="font-medium">{p.rating}</span>
                    </span>
                  ) : '—'}
                </td>
                <td className="px-4 py-3 font-medium">{p.jobs}</td>
                <td className="px-4 py-3">
                  <span className={`w-2 h-2 rounded-full inline-block ${p.online ? 'bg-green-500' : 'bg-gray-300'}`}></span>
                  <span className="ml-2 text-xs text-gray-500">{p.online ? 'Online' : 'Offline'}</span>
                </td>
                <td className="px-4 py-3">
                  <button className="text-xs text-[#1B4F72] hover:underline font-medium">View</button>
                  <span className="mx-2 text-gray-300">|</span>
                  <button className="text-xs text-amber-600 hover:underline font-medium">Upgrade Tier</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

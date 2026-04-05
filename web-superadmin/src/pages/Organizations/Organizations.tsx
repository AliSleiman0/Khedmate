const mockOrgs = [
  { id: 'ORG-001', name: 'Khudmati Riyadh', region: 'Riyadh', admins: 3, providers: 1240, revenue: '82,400 SAR', status: 'Active' },
  { id: 'ORG-002', name: 'Khudmati Jeddah', region: 'Jeddah', admins: 2, providers: 880, revenue: '61,200 SAR', status: 'Active' },
  { id: 'ORG-003', name: 'Khudmati Dammam', region: 'Dammam', admins: 2, providers: 540, revenue: '38,800 SAR', status: 'Active' },
  { id: 'ORG-004', name: 'Khudmati Mecca', region: 'Mecca', admins: 1, providers: 320, revenue: '21,600 SAR', status: 'Pending' },
  { id: 'ORG-005', name: 'Khudmati Kuwait', region: 'Kuwait City', admins: 0, providers: 0, revenue: '0 SAR', status: 'Setup' },
]

export default function Organizations() {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white">Organizations</h2>
          <p className="text-gray-400 text-sm">Regional tenants / franchise units</p>
        </div>
        <button className="bg-purple-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-purple-700 transition-colors">
          + Add Organization
        </button>
      </div>

      <div className="bg-gray-800 border border-gray-700 rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-750 border-b border-gray-700">
            <tr>
              {['ID', 'Name', 'Region', 'Admins', 'Providers', 'Revenue (MTD)', 'Status', 'Actions'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700">
            {mockOrgs.map(o => (
              <tr key={o.id} className="hover:bg-gray-750 transition-colors">
                <td className="px-4 py-3 font-mono text-xs font-semibold text-purple-400">{o.id}</td>
                <td className="px-4 py-3 text-white font-medium">{o.name}</td>
                <td className="px-4 py-3 text-gray-300">{o.region}</td>
                <td className="px-4 py-3 text-gray-300">{o.admins}</td>
                <td className="px-4 py-3 text-gray-300">{o.providers}</td>
                <td className="px-4 py-3 font-medium text-amber-400">{o.revenue}</td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    o.status === 'Active' ? 'bg-green-500/20 text-green-400' :
                    o.status === 'Pending' ? 'bg-amber-500/20 text-amber-400' :
                    'bg-gray-500/20 text-gray-400'
                  }`}>
                    {o.status}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <button className="text-xs text-purple-400 hover:underline font-medium">Manage</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

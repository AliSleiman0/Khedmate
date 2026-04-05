const mockCustomers = [
  { id: 'C-001', name: 'Ahmed Mohammed', phone: '+966 50 000 0001', bookings: 24, joined: '2023-03-12', active: true },
  { id: 'C-002', name: 'Sara Khalid', phone: '+966 55 000 0002', bookings: 8, joined: '2023-07-01', active: true },
  { id: 'C-003', name: 'Omar Faris', phone: '+966 56 000 0003', bookings: 3, joined: '2024-01-05', active: true },
  { id: 'C-004', name: 'Lina Rashid', phone: '+966 57 000 0004', bookings: 15, joined: '2023-05-20', active: true },
  { id: 'C-005', name: 'Tariq Badr', phone: '+966 58 000 0005', bookings: 1, joined: '2024-01-10', active: false },
]

export default function Customers() {
  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Customers</h2>
        <p className="text-gray-500 text-sm">Registered customer accounts</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              {['ID', 'Name', 'Phone', 'Total Bookings', 'Joined', 'Status', 'Actions'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {mockCustomers.map(c => (
              <tr key={c.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 font-mono text-xs font-semibold text-[#1B4F72]">{c.id}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-amber-400 text-white flex items-center justify-center text-xs font-bold">
                      {c.name.charAt(0)}
                    </div>
                    <span className="font-medium">{c.name}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-gray-600">{c.phone}</td>
                <td className="px-4 py-3">
                  <span className="font-medium text-[#1B4F72]">{c.bookings}</span>
                </td>
                <td className="px-4 py-3 text-gray-500">{c.joined}</td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${c.active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'}`}>
                    {c.active ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <button className="text-xs text-[#1B4F72] hover:underline font-medium">View</button>
                  {c.active && (
                    <>
                      <span className="mx-2 text-gray-300">|</span>
                      <button className="text-xs text-red-600 hover:underline font-medium">Deactivate</button>
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

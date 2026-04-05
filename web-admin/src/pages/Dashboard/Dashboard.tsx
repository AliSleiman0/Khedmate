const kpis = [
  { label: 'Jobs Today', value: '142', delta: '+12%', color: 'bg-blue-500', icon: '🔧' },
  { label: 'Active Providers', value: '38', delta: '+3', color: 'bg-green-500', icon: '👷' },
  { label: 'Open Disputes', value: '7', delta: '-2', color: 'bg-red-500', icon: '⚖️' },
  { label: "Today's Revenue", value: '12,400 SAR', delta: '+8%', color: 'bg-amber-500', icon: '💰' },
]

export default function Dashboard() {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Dashboard</h2>
        <p className="text-gray-500 text-sm mt-1">Operations overview for today</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {kpis.map(({ label, value, delta, color, icon }) => (
          <div key={label} className="bg-white rounded-xl shadow-sm p-6 flex items-start gap-4">
            <div className={`w-12 h-12 ${color} rounded-xl flex items-center justify-center text-2xl flex-shrink-0`}>
              {icon}
            </div>
            <div>
              <p className="text-sm text-gray-500">{label}</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
              <p className={`text-xs mt-1 font-medium ${delta.startsWith('+') ? 'text-green-600' : 'text-red-500'}`}>
                {delta} vs yesterday
              </p>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold mb-4">Recent Jobs</h3>
          <div className="space-y-3">
            {['Cleaning', 'Plumbing', 'Electrical', 'AC Service'].map((s, i) => (
              <div key={s} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-sm">
                    {['🧹', '🔧', '⚡', '❄️'][i]}
                  </div>
                  <div>
                    <p className="text-sm font-medium">Job #{2000 + i}</p>
                    <p className="text-xs text-gray-500">{s}</p>
                  </div>
                </div>
                <span className={`text-xs px-2 py-1 rounded-full font-medium ${
                  i === 0 ? 'bg-green-100 text-green-700' :
                  i === 1 ? 'bg-blue-100 text-blue-700' :
                  i === 2 ? 'bg-amber-100 text-amber-700' :
                  'bg-gray-100 text-gray-600'
                }`}>
                  {['Completed', 'InProgress', 'EnRoute', 'Pending'][i]}
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold mb-4">Pending Actions</h3>
          <div className="space-y-3">
            {[
              { icon: '⚖️', label: '7 disputes awaiting resolution', urgent: true },
              { icon: '👷', label: '12 providers pending verification', urgent: false },
              { icon: '💰', label: '3 refund requests', urgent: true },
              { icon: '⭐', label: '24 unread reviews', urgent: false },
            ].map(({ icon, label, urgent }) => (
              <div key={label} className="flex items-center gap-3 p-3 rounded-lg bg-gray-50">
                <span className="text-xl">{icon}</span>
                <span className="text-sm flex-1">{label}</span>
                {urgent && <span className="w-2 h-2 rounded-full bg-red-500 flex-shrink-0"></span>}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

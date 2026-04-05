const badges = [
  { icon: '🛡️', label: 'مزودون موثوقون' },
  { icon: '⭐', label: 'تقييم 4.8/5' },
  { icon: '✅', label: 'ضمان الجودة' },
  { icon: '🔒', label: 'دفع آمن' },
  { icon: '⚡', label: 'استجابة سريعة' },
]

export default function TrustBadges() {
  return (
    <section style={{
      background: 'var(--brand-blue)',
      display: 'flex',
      justifyContent: 'center',
      gap: 48,
      flexWrap: 'wrap',
      padding: '48px 24px',
    }}>
      {badges.map(({ icon, label }) => (
        <div key={label} style={{ textAlign: 'center', color: 'white' }}>
          <div style={{ fontSize: 40 }}>{icon}</div>
          <p style={{ fontWeight: 600, marginTop: 8, fontSize: 14 }}>{label}</p>
        </div>
      ))}
    </section>
  )
}

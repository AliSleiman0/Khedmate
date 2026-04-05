import { useTranslation } from 'react-i18next'

const SERVICE_ICONS: Record<string, string> = {
  cleaning: '🧹', plumbing: '🔧', electrical: '⚡',
  moving: '🚛', painting: '🎨', ac: '❄️'
}

export default function Services() {
  const { t } = useTranslation()
  const services = ['cleaning', 'plumbing', 'electrical', 'moving', 'painting', 'ac']
  return (
    <section style={{ textAlign: 'center' }}>
      <h2 style={{ fontSize: 36, marginBottom: 48, color: 'var(--brand-blue)' }}>
        {t('services')}
      </h2>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
        gap: 16,
        maxWidth: 900,
        margin: '0 auto',
      }}>
        {services.map(s => (
          <div key={s} style={{
            background: 'var(--surface)',
            borderRadius: 16,
            padding: '28px 16px',
            cursor: 'pointer',
            transition: 'transform 0.15s, box-shadow 0.15s',
          }}
            onMouseEnter={e => {
              (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-4px)'
              ;(e.currentTarget as HTMLDivElement).style.boxShadow = '0 8px 24px rgba(0,0,0,0.12)'
            }}
            onMouseLeave={e => {
              (e.currentTarget as HTMLDivElement).style.transform = 'none'
              ;(e.currentTarget as HTMLDivElement).style.boxShadow = 'none'
            }}
          >
            <div style={{ fontSize: 40 }}>{SERVICE_ICONS[s]}</div>
            <p style={{ marginTop: 10, fontWeight: 600, fontSize: 15 }}>{t(s)}</p>
          </div>
        ))}
      </div>
    </section>
  )
}

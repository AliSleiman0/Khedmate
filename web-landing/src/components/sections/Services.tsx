import { useState } from 'react'
import { useTranslation } from 'react-i18next'

const SERVICE_ICONS: Record<string, string> = {
  cleaning: '🧹', plumbing: '🔧', electrical: '⚡',
  moving: '🚛', painting: '🎨', ac: '❄️',
}

function ServiceCard({ serviceKey }: { serviceKey: string }) {
  const { t } = useTranslation()
  const [hovered, setHovered] = useState(false)

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: 'var(--surface-warm)',
        borderRadius: 'var(--radius-card)',
        padding: '32px 20px',
        cursor: 'pointer',
        transition: 'transform var(--transition-base), box-shadow var(--transition-base), border-color var(--transition-base)',
        transform: hovered ? 'translateY(-6px)' : 'none',
        boxShadow: hovered ? '0 12px 32px var(--shadow-brown-lg)' : '0 2px 8px var(--shadow-brown)',
        border: `3px solid ${hovered ? 'var(--brown-primary)' : 'transparent'}`,
        textAlign: 'center',
      }}
    >
      <div style={{
        width: 80,
        height: 80,
        borderRadius: '50%',
        background: hovered ? 'var(--brown-primary)' : 'var(--cream-warm)',
        border: '2px solid var(--cream-border)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        margin: '0 auto 16px',
        transition: 'background var(--transition-base)',
      }}>
        <span style={{
          fontSize: 36,
          filter: hovered ? 'brightness(0) invert(1)' : 'none',
          transition: 'filter var(--transition-base)',
        }}>
          {SERVICE_ICONS[serviceKey]}
        </span>
      </div>
      <p style={{
        marginTop: 4,
        fontWeight: 700,
        fontSize: 15,
        color: hovered ? 'var(--brown-primary)' : 'var(--text-primary)',
        transition: 'color var(--transition-base)',
      }}>
        {t(serviceKey)}
      </p>
    </div>
  )
}

export default function Services() {
  const { t } = useTranslation()
  const services = ['cleaning', 'plumbing', 'electrical', 'moving', 'painting', 'ac']

  return (
    <section id="services" style={{ background: 'white', textAlign: 'center' }}>
      <h2 style={{ fontSize: 38, fontWeight: 700, color: 'var(--brown-primary)', marginBottom: 12 }}>
        {t('services')}
      </h2>
      <div style={{ width: 60, height: 4, borderRadius: 2, background: 'var(--amber)', margin: '0 auto 52px' }} />
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
        gap: 20,
        maxWidth: 900,
        margin: '0 auto',
      }}>
        {services.map(s => <ServiceCard key={s} serviceKey={s} />)}
      </div>
    </section>
  )
}

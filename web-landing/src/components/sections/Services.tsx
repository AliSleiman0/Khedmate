import { Icon } from '../ui/Icons'
import { useIsMobile } from '../../hooks/useIsMobile'

type Service = {
  key: string
  icon: React.ReactNode
  title: string
  desc: string
  from: string
  popular?: boolean
}

const SERVICES: Service[] = [
  { key: 'cleaning', icon: <Icon.Cleaning size={28} />, title: 'Cleaning', desc: 'Deep, regular & post-renovation', from: '$25', popular: true },
  { key: 'plumbing', icon: <Icon.Plumbing size={28} />, title: 'Plumbing', desc: 'Leaks, blocked drains, fixtures', from: '$30' },
  { key: 'electrical', icon: <Icon.Electrical size={28} />, title: 'Electrical', desc: 'Wiring, outlets, lights, panels', from: '$35' },
  { key: 'ac', icon: <Icon.AC size={28} />, title: 'AC service', desc: 'Install, recharge, maintenance', from: '$40', popular: true },
  { key: 'carpentry', icon: <Icon.Carpentry size={28} />, title: 'Carpentry', desc: 'Furniture, doors, custom builds', from: '$30' },
  { key: 'painting', icon: <Icon.Painting size={28} />, title: 'Painting', desc: 'Interior, exterior, touch-ups', from: '$2/m²' },
  { key: 'moving', icon: <Icon.Moving size={28} />, title: 'Moving', desc: 'Apartments, offices, single items', from: '$50' },
]

export default function Services() {
  const isMobile = useIsMobile()
  return (
    <section id="services" style={{ padding: isMobile ? '56px 20px' : '112px 32px', background: '#fbfbfc' }}>
      <div style={{ maxWidth: 1200, margin: '0 auto' }}>
        <div style={{
          display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
          flexWrap: 'wrap', gap: 16, marginBottom: isMobile ? 28 : 48,
        }}>
          <div>
            <div className="kh-eyebrow" style={{ color: '#F39C12', marginBottom: 10 }}>Our services</div>
            <h2 className="kh-h1" style={{
              fontSize: isMobile ? 28 : 40, color: '#14181d', margin: 0, letterSpacing: '-0.025em',
            }}>
              Seven trades, one trusted app.
            </h2>
          </div>
          {!isMobile && (
            <a href="#contact" style={{
              color: '#1B4F72', fontSize: 14, fontWeight: 600,
              display: 'inline-flex', alignItems: 'center', gap: 6,
            }}>
              See all services <Icon.Arrow size={14} />
            </a>
          )}
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: isMobile ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)',
          gap: isMobile ? 12 : 20,
        }}>
          {SERVICES.map(s => (
            <div key={s.key} className="kh-card kh-card-hover"
              style={{
                padding: isMobile ? 16 : 22,
                position: 'relative', cursor: 'pointer', overflow: 'hidden',
                ...(s.key === 'cleaning' && !isMobile
                  ? { gridColumn: 'span 2', display: 'flex', gap: 18, alignItems: 'flex-start' }
                  : {}),
              }}>
              {s.popular && (
                <div style={{
                  position: 'absolute', top: 12, right: 12,
                  fontSize: 10, fontWeight: 600, padding: '3px 8px', borderRadius: 999,
                  background: '#fdf0d9', color: '#c97e08', letterSpacing: '.04em',
                }}>POPULAR</div>
              )}
              <div style={{
                width: 52, height: 52, borderRadius: 14,
                background: 'linear-gradient(135deg,#e8eef4 0%, #f4f7fa 100%)',
                color: '#1B4F72', display: 'grid', placeItems: 'center',
                marginBottom: (s.key === 'cleaning' && !isMobile) ? 0 : 16,
                position: 'relative', flexShrink: 0,
              }}>
                {s.icon}
                <span style={{
                  position: 'absolute', inset: 0, borderRadius: 14,
                  border: '1px solid rgba(255,255,255,.7)', pointerEvents: 'none',
                }} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{
                  fontSize: isMobile ? 15 : 17, fontWeight: 600, color: '#14181d', marginBottom: 4,
                }}>{s.title}</div>
                <div style={{
                  fontSize: isMobile ? 12 : 13, color: '#6b7682', marginBottom: 10, lineHeight: 1.5,
                }}>{s.desc}</div>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  paddingTop: 10, borderTop: '1px solid #e9ecef',
                }}>
                  <span style={{ fontSize: 12, color: '#6b7682' }}>From</span>
                  <span style={{ fontSize: 14, fontWeight: 700, color: '#1B4F72' }}>{s.from}</span>
                  <span style={{ flex: 1 }} />
                  <span className="kh-svc-arrow" style={{
                    width: 28, height: 28, borderRadius: '50%',
                    background: '#fbfbfc', border: '1px solid #e9ecef',
                    display: 'grid', placeItems: 'center', color: '#1B4F72',
                    transition: 'transform .2s var(--kh-ease), background .2s, color .2s',
                  }}>
                    <Icon.Arrow size={14} stroke="#1B4F72" />
                  </span>
                </div>
              </div>
              <span className="kh-svc-underline" style={{
                position: 'absolute', left: 14, right: 14, bottom: 0, height: 2,
                background: '#F39C12', borderRadius: 2, transform: 'scaleX(0)',
                transformOrigin: 'left center', transition: 'transform .25s var(--kh-ease)',
              }} />
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

import { Icon } from '../ui/Icons'
import { useIsMobile } from '../../hooks/useIsMobile'

const STEPS = [
  { n: '01', t: 'Pick a service', d: 'Browse seven trades or search what you need.', icon: <Icon.Search size={20} />, bg: '#fef9ee', fg: '#c97e08' },
  { n: '02', t: 'Set time & place', d: 'Now or later — choose a slot that suits you.', icon: <Icon.Calendar size={20} />, bg: '#e8eef4', fg: '#1B4F72' },
  { n: '03', t: 'Get matched', d: 'A verified provider accepts in under 2 minutes.', icon: <Icon.CheckCircle size={20} />, bg: '#e3f5ec', fg: '#1a7f47' },
  { n: '04', t: 'Sit back, pay in app', d: 'Track them in real time. Pay when the job is done.', icon: <Icon.Lock size={18} />, bg: '#fef9ee', fg: '#c97e08' },
]

export default function HowItWorks() {
  const isMobile = useIsMobile()
  return (
    <section id="how-it-works" style={{
      padding: isMobile ? '56px 20px' : '112px 32px',
      background: '#fff', position: 'relative',
    }}>
      <div style={{ maxWidth: 1200, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: isMobile ? 32 : 60 }}>
          <div className="kh-eyebrow" style={{ color: '#F39C12', marginBottom: 10 }}>How it works</div>
          <h2 className="kh-h1" style={{
            fontSize: isMobile ? 28 : 40, color: '#14181d', margin: 0,
            letterSpacing: '-0.025em',
          }}>
            Faster than calling someone you<br />kind of know.
          </h2>
        </div>

        <div style={{ position: 'relative' }}>
          {!isMobile && (
            <svg style={{
              position: 'absolute', top: 62, left: '12.5%', right: '12.5%',
              width: '75%', height: 40, zIndex: 0,
            }} viewBox="0 0 800 40" preserveAspectRatio="none">
              <path d="M0 20 Q 200 -10 400 20 T 800 20"
                fill="none" stroke="#F39C12" strokeWidth="2" strokeDasharray="4 6" strokeLinecap="round" />
            </svg>
          )}

          <div style={{
            display: 'grid',
            gridTemplateColumns: isMobile ? '1fr' : 'repeat(4, 1fr)',
            gap: isMobile ? 16 : 24, position: 'relative', zIndex: 1,
          }}>
            {STEPS.map((s, i) => (
              <div key={s.n} style={{
                display: 'flex',
                flexDirection: isMobile ? 'row' : 'column',
                gap: isMobile ? 14 : 0,
                alignItems: 'flex-start',
              }}>
                <div style={{
                  position: 'relative', width: 64, height: 64, borderRadius: '50%',
                  background: s.bg, color: s.fg,
                  display: 'grid', placeItems: 'center', flexShrink: 0,
                  marginBottom: isMobile ? 0 : 18,
                  border: '4px solid #fff', boxShadow: '0 1px 0 #e9ecef',
                }}>
                  {s.icon}
                  <span style={{
                    position: 'absolute', top: -6, right: -6,
                    width: 26, height: 26, borderRadius: '50%',
                    background: '#1B4F72', color: '#fff',
                    fontSize: 11, fontWeight: 700,
                    display: 'grid', placeItems: 'center',
                    border: '3px solid #fff',
                  }}>{i + 1}</span>
                </div>
                <div>
                  <div style={{
                    fontSize: 11, color: '#8b95a1', fontWeight: 600,
                    letterSpacing: '.08em', marginBottom: 6,
                  }}>STEP {s.n}</div>
                  <div style={{
                    fontSize: isMobile ? 16 : 18, fontWeight: 600,
                    color: '#14181d', marginBottom: 6,
                  }}>{s.t}</div>
                  <div style={{
                    fontSize: isMobile ? 13 : 14, color: '#6b7682', lineHeight: 1.5,
                  }}>{s.d}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {!isMobile && (
          <div style={{
            marginTop: 56, display: 'inline-flex', alignItems: 'center', gap: 14,
            padding: '12px 18px', borderRadius: 999, background: '#fbfbfc',
            border: '1px solid #e9ecef',
            position: 'relative', left: '50%', transform: 'translateX(-50%)',
          }}>
            <Icon.Clock size={16} stroke="#1B4F72" />
            <span style={{ fontSize: 13, color: '#4d5763' }}>Average time from open-app to booked:</span>
            <span style={{ fontSize: 14, fontWeight: 700, color: '#1B4F72' }}>54 seconds</span>
          </div>
        )}
      </div>
    </section>
  )
}

import { Icon } from '../ui/Icons'
import { Stars } from '../ui/Brand'
import { PhoneMock } from '../ui/PhoneMock'
import { useIsMobile } from '../../hooks/useIsMobile'

function HeroChip({ icon, children }: { icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '7px 12px', borderRadius: 999,
      background: 'rgba(255,255,255,.10)',
      border: '1px solid rgba(255,255,255,.18)',
      color: '#fff',
      fontSize: 13, fontWeight: 500,
      backdropFilter: 'blur(8px)',
    }}>
      {icon}{children}
    </div>
  )
}

export default function Hero() {
  const isMobile = useIsMobile()

  return (
    <section id="top" style={{
      position: 'relative', overflow: 'hidden',
      background: 'linear-gradient(160deg, #0d2f47 0%, #1B4F72 60%, #1d5a82 100%)',
      color: '#fff',
      // Pull header into the gradient so the dark transparent header reads as part of the hero.
      marginTop: -65,
      paddingTop: 65,
    }}>
      {/* Decorative glows */}
      <div style={{
        position: 'absolute', inset: 0, opacity: .18, pointerEvents: 'none',
        backgroundImage:
          'radial-gradient(circle at 20% 20%, rgba(243,156,18,.4) 0, transparent 40%), ' +
          'radial-gradient(circle at 80% 80%, rgba(70,130,180,.5) 0, transparent 50%)',
      }} />
      {/* Decorative grid */}
      <div style={{
        position: 'absolute', inset: 0, opacity: .10, pointerEvents: 'none',
        backgroundImage:
          'linear-gradient(rgba(255,255,255,.4) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.4) 1px, transparent 1px)',
        backgroundSize: '48px 48px',
      }} />

      <div style={{
        maxWidth: 1280, margin: '0 auto',
        padding: isMobile ? '40px 20px 60px' : '80px 32px 100px',
        display: 'grid',
        gridTemplateColumns: isMobile ? '1fr' : '1.05fr 1fr',
        gap: isMobile ? 36 : 48,
        alignItems: 'center', position: 'relative',
      }}>
        <div className="kh-fade-up kh-in">
          <HeroChip icon={
            <span style={{
              width: 6, height: 6, borderRadius: '50%', background: '#1f9d55',
              boxShadow: '0 0 0 4px rgba(31,157,85,.25)',
            }} />
          }>342 providers online in Beirut now</HeroChip>

          <h1 className="kh-display" style={{
            fontSize: isMobile ? 40 : 64,
            margin: '20px 0 18px', letterSpacing: '-0.03em',
          }}>
            Home help that<br />
            actually <span style={{ color: '#F39C12', fontStyle: 'italic', fontWeight: 600 }}>shows up</span>.
          </h1>
          <p style={{
            fontSize: isMobile ? 16 : 18, maxWidth: 480,
            color: 'rgba(255,255,255,.78)', lineHeight: 1.55, margin: '0 0 28px',
          }}>
            Book a verified plumber, electrician or cleaner in 60 seconds. Track them to your door. Pay through the app — no cash, no haggling.
          </p>
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 28 }}>
            <button className="kh-btn kh-btn-primary kh-btn-lg">
              <Icon.Apple size={18} fill="#1a1100" />Download for iOS
            </button>
            <button className="kh-btn kh-btn-ghost kh-btn-lg">
              <svg width="18" height="20" viewBox="0 0 24 26" fill="#fff"><path d="M3 1l13 12L3 25z" opacity=".95" /></svg>
              Get it on Android
            </button>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: isMobile ? 14 : 24, flexWrap: 'wrap',
            paddingTop: 18, borderTop: '1px solid rgba(255,255,255,.10)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ display: 'flex' }}>
                {['#F39C12', '#4682b4', '#1f9d55', '#c97e08'].map((c, i) => (
                  <div key={i} style={{
                    width: 28, height: 28, borderRadius: '50%', background: c,
                    border: '2px solid #1B4F72', marginLeft: i ? -8 : 0,
                  }} />
                ))}
              </div>
              <div style={{ lineHeight: 1.2 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>14,200+ jobs done</div>
                <div style={{ fontSize: 11, color: 'rgba(255,255,255,.6)' }}>across Lebanon</div>
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Stars rating={4.8} size={14} />
              <div style={{ lineHeight: 1.2 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>4.8 / 5</div>
                <div style={{ fontSize: 11, color: 'rgba(255,255,255,.6)' }}>App Store rating</div>
              </div>
            </div>
          </div>
        </div>

        <div style={{
          position: 'relative',
          display: 'flex', justifyContent: isMobile ? 'center' : 'flex-end', alignItems: 'center',
        }}>
          <PhoneMock motion scale={isMobile ? 0.85 : 1} />
        </div>
      </div>

      {/* Bottom curve into next section */}
      <svg viewBox="0 0 1440 80" preserveAspectRatio="none" style={{
        display: 'block', width: '100%', height: isMobile ? 40 : 64, marginBottom: -1,
      }}>
        <path d="M0 40 C 360 80 1080 0 1440 40 L 1440 80 L 0 80 Z" fill="#fbfbfc" />
      </svg>
    </section>
  )
}

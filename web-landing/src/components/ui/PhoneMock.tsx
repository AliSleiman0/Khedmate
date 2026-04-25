import { Icon } from './Icons'
import { Avatar, Stars } from './Brand'

function MapPaths({ scale = 1 }: { scale?: number }) {
  void scale
  return (
    <svg width="100%" height="100%" viewBox="0 0 320 220" style={{ position: 'absolute', inset: 0 }}>
      <defs>
        <pattern id="khRoads" patternUnits="userSpaceOnUse" width="40" height="40">
          <rect width="40" height="40" fill="#e8eef4" />
          <path d="M0 20h40M20 0v40" stroke="#fff" strokeWidth="2" />
        </pattern>
      </defs>
      <rect width="320" height="220" fill="url(#khRoads)" opacity=".7" />
      <path d="M0 60 Q 60 80 120 90 T 320 110" stroke="#b3bcc6" strokeWidth="3" fill="none" />
      <path d="M40 0 Q 80 60 140 100 T 280 220" stroke="#b3bcc6" strokeWidth="3" fill="none" />
      <path d="M96 88 Q 150 110 220 160" stroke="#F39C12" strokeWidth="3" strokeDasharray="6 4" fill="none" />
    </svg>
  )
}

export function PhoneMock({ motion = true, scale = 1 }: { motion?: boolean; scale?: number }) {
  return (
    <div style={{
      width: 320 * scale, height: 640 * scale, position: 'relative',
      transform: 'rotate(-3deg)', transformOrigin: 'center',
      filter: 'drop-shadow(0 30px 60px rgba(0,0,0,.35))',
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: 44 * scale,
        background: '#0a0d10', padding: 8 * scale, position: 'relative',
      }}>
        <div style={{
          width: '100%', height: '100%', borderRadius: 36 * scale,
          background: '#fbfbfc', position: 'relative', overflow: 'hidden',
        }}>
          {/* Status bar */}
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            padding: `${14 * scale}px ${24 * scale}px ${4 * scale}px`, fontSize: 13 * scale, fontWeight: 600,
          }}>
            <span>9:41</span>
            <span style={{ display: 'inline-flex', gap: 4 * scale, alignItems: 'center' }}>
              <span style={{ width: 14 * scale, height: 8 * scale, background: '#1f262e', borderRadius: 1 }} />
              <span style={{ width: 18 * scale, height: 10 * scale, border: '1.5px solid #1f262e', borderRadius: 2 }} />
            </span>
          </div>

          {/* Header */}
          <div style={{ padding: `${16 * scale}px ${20 * scale}px ${10 * scale}px`, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <button style={{ width: 36 * scale, height: 36 * scale, borderRadius: 18 * scale, background: '#f5f6f8', border: 'none', display: 'grid', placeItems: 'center' }}>
              <svg width={16 * scale} height={16 * scale} viewBox="0 0 24 24" fill="none" stroke="#1f262e" strokeWidth="2" strokeLinecap="round"><path d="M15 18l-6-6 6-6" /></svg>
            </button>
            <div style={{ fontWeight: 600, fontSize: 15 * scale }}>Booking #4827</div>
            <div style={{ width: 36 * scale }} />
          </div>

          {/* Map preview */}
          <div style={{
            margin: `0 ${16 * scale}px`, height: 220 * scale, borderRadius: 18 * scale,
            background: 'linear-gradient(180deg, #e8eef4 0%, #d5dae0 100%)', position: 'relative',
            overflow: 'hidden', border: '1px solid #e9ecef',
          }}>
            <MapPaths scale={scale} />
            <div style={{
              position: 'absolute', left: '30%', top: '40%',
              width: 32 * scale, height: 32 * scale, borderRadius: '50%',
              background: '#1B4F72', border: '3px solid #fff', boxShadow: '0 4px 12px rgba(0,0,0,.2)',
              display: 'grid', placeItems: 'center', color: '#fff', fontSize: 14 * scale, fontWeight: 600,
            }}>RH</div>
            <div style={{
              position: 'absolute', right: '22%', bottom: '25%',
              width: 24 * scale, height: 24 * scale, borderRadius: '50%',
              background: '#F39C12', border: '3px solid #fff',
              animation: motion ? 'khPulse 2.4s ease-out infinite' : 'none',
            }} />
          </div>

          {/* Provider card */}
          <div style={{ padding: `${18 * scale}px ${20 * scale}px` }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 * scale }}>
              <div style={{ position: 'relative' }}>
                <Avatar name="Rami Hajjar" size={44 * scale} bg="#1B4F72" />
                <span style={{ position: 'absolute', bottom: -2, right: -2 }}><Icon.Verified size={16 * scale} /></span>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15 * scale, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 * scale }}>
                  Rami H. <span style={{ fontSize: 11 * scale, padding: '2px 6px', background: '#fdf0d9', color: '#c97e08', borderRadius: 4, fontWeight: 600 }}>Pro</span>
                </div>
                <div style={{ fontSize: 12 * scale, color: '#6b7682', display: 'flex', alignItems: 'center', gap: 6 * scale }}>
                  <Stars rating={4.9} size={11 * scale} /> 4.9 · 312 jobs
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 11 * scale, color: '#6b7682' }}>Arriving in</div>
                <div style={{ fontSize: 18 * scale, fontWeight: 700, color: '#1B4F72' }}>8 min</div>
              </div>
            </div>

            <div style={{
              marginTop: 14 * scale, padding: 12 * scale, borderRadius: 12 * scale, background: '#f5f6f8',
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <div>
                <div style={{ fontSize: 12 * scale, color: '#6b7682' }}>Service</div>
                <div style={{ fontSize: 14 * scale, fontWeight: 600 }}>AC repair · split unit</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 12 * scale, color: '#6b7682' }}>Estimate</div>
                <div style={{ fontSize: 14 * scale, fontWeight: 600 }}>$45–60</div>
              </div>
            </div>

            <div style={{ marginTop: 12 * scale, display: 'flex', gap: 8 * scale }}>
              <button style={{ flex: 1, height: 42 * scale, borderRadius: 10 * scale, background: '#1B4F72', color: '#fff', border: 'none', fontWeight: 600, fontSize: 13 * scale, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
                <Icon.Phone size={13 * scale} stroke="#fff" /> Call provider
              </button>
              <button style={{ width: 42 * scale, height: 42 * scale, borderRadius: 10 * scale, background: '#fff', border: '1px solid #e9ecef', display: 'grid', placeItems: 'center' }}>
                <svg width={16 * scale} height={16 * scale} viewBox="0 0 24 24" fill="none" stroke="#1f262e" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

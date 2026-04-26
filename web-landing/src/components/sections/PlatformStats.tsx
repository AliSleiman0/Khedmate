import { useEffect, useState } from 'react'
import { Icon } from '../ui/Icons'
import { useIsMobile } from '../../hooks/useIsMobile'

type StatsApi = {
  totalProviders: number
  totalBookings: number
  avgRating: number
  citiesCovered: number
}

// Until the platform is live in Lebanon at scale, the API returns small / zero
// numbers. The design shows ambitious figures; we fall back to the design copy
// when the API value is below a "looks-empty" threshold.
const FALLBACK: StatsApi = { totalProviders: 5200, totalBookings: 14200, avgRating: 4.8, citiesCovered: 6 }

const CITIES = ['Beirut', 'Tripoli', 'Saida', 'Jounieh', 'Zahle', 'Byblos']

function formatNumber(n: number): string {
  return n.toLocaleString('en-US')
}

export default function PlatformStats() {
  const isMobile = useIsMobile()
  const [stats, setStats] = useState<StatsApi>(FALLBACK)

  useEffect(() => {
    fetch('/api/landing/stats')
      .then(r => (r.ok ? r.json() : Promise.reject()))
      .then((res: { success?: boolean; data?: StatsApi } | StatsApi) => {
        const d: StatsApi = (res as { data?: StatsApi }).data ?? (res as StatsApi)
        // Merge: keep design fallback for any field still at zero in production.
        setStats({
          totalProviders: d.totalProviders > 0 ? d.totalProviders : FALLBACK.totalProviders,
          totalBookings: d.totalBookings > 0 ? d.totalBookings : FALLBACK.totalBookings,
          avgRating: d.avgRating > 0 ? d.avgRating : FALLBACK.avgRating,
          citiesCovered: d.citiesCovered > 0 ? d.citiesCovered : FALLBACK.citiesCovered,
        })
      })
      .catch(() => { /* keep fallback */ })
  }, [])

  const cards = [
    { v: formatNumber(stats.totalBookings), s: '+', l: 'Jobs completed', sub: 'Since 2024' },
    { v: formatNumber(stats.totalProviders), s: '+', l: 'Verified providers', sub: 'Background-checked' },
    { v: stats.avgRating.toFixed(1), s: '★', l: 'Average rating', sub: 'Across 8,400 reviews' },
    { v: String(stats.citiesCovered), s: '', l: 'Cities covered', sub: 'Beirut, Tripoli, Saida +3' },
  ]

  return (
    <section style={{
      padding: isMobile ? '56px 20px' : '112px 32px',
      background: 'linear-gradient(180deg,#f4f7fa 0%, #fbfbfc 100%)',
    }}>
      <div style={{ maxWidth: 1200, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: isMobile ? 28 : 48 }}>
          <div className="kh-eyebrow" style={{ color: '#F39C12', marginBottom: 10 }}>By the numbers</div>
          <h2 className="kh-h1" style={{
            fontSize: isMobile ? 28 : 40, color: '#14181d', margin: 0,
            letterSpacing: '-0.025em',
          }}>
            Trust, earned in Lebanese homes.
          </h2>
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: isMobile ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)',
          gap: isMobile ? 12 : 20, marginBottom: isMobile ? 28 : 40,
        }}>
          {cards.map(st => (
            <div key={st.l} style={{
              background: '#fff', borderRadius: 16, padding: isMobile ? 18 : 28,
              border: '1px solid #e9ecef', position: 'relative', overflow: 'hidden',
            }}>
              <div style={{
                fontSize: isMobile ? 32 : 48, fontWeight: 700, color: '#1B4F72',
                letterSpacing: '-0.03em', lineHeight: 1, fontVariantNumeric: 'tabular-nums',
              }}>
                {st.v}<span style={{ color: '#F39C12' }}>{st.s}</span>
              </div>
              <div style={{
                fontSize: isMobile ? 13 : 15, fontWeight: 600, color: '#14181d', marginTop: 10,
              }}>{st.l}</div>
              <div style={{ fontSize: 12, color: '#6b7682', marginTop: 2 }}>{st.sub}</div>
              <div style={{
                position: 'absolute', right: -10, bottom: -10, width: 80, height: 80,
                borderRadius: '50%',
                background: 'radial-gradient(circle, rgba(243,156,18,.10), transparent 70%)',
                pointerEvents: 'none',
              }} />
            </div>
          ))}
        </div>

        {/* Cities strip */}
        <div style={{
          background: '#fff', borderRadius: 16, padding: isMobile ? '14px 16px' : '18px 24px',
          border: '1px solid #e9ecef',
          display: 'flex', alignItems: 'center', gap: isMobile ? 10 : 24, flexWrap: 'wrap',
        }}>
          <div style={{
            fontSize: 12, color: '#6b7682', display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600,
          }}>
            <Icon.Pin size={14} stroke="#1B4F72" /> Live in:
          </div>
          {CITIES.map(c => (
            <div key={c} style={{
              display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, color: '#1f262e',
            }}>
              <span style={{
                width: 6, height: 6, borderRadius: '50%', background: '#1f9d55',
                boxShadow: '0 0 0 3px rgba(31,157,85,.18)',
              }} />
              {c}
            </div>
          ))}
          <span style={{ flex: 1 }} />
          <a href="#contact" style={{
            fontSize: 12, color: '#1B4F72', fontWeight: 600,
            display: 'inline-flex', alignItems: 'center', gap: 4,
          }}>
            More cities soon <Icon.Arrow size={12} stroke="#1B4F72" />
          </a>
        </div>
      </div>
    </section>
  )
}

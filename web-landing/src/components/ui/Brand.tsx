import { Icon } from './Icons'

export function Logo({ size = 28, color = '#1B4F72', amber = '#F39C12', label = true, white = false }: {
  size?: number; color?: string; amber?: string; label?: boolean; white?: boolean
}) {
  const stroke = white ? '#fff' : color
  const accent = white ? '#F39C12' : amber
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 9 }}>
      <div style={{
        width: size, height: size, borderRadius: 8,
        background: white ? 'rgba(255,255,255,.12)' : '#fff',
        border: `1px solid ${white ? 'rgba(255,255,255,.2)' : '#e9ecef'}`,
        display: 'grid', placeItems: 'center', position: 'relative', overflow: 'hidden',
      }}>
        <svg width={size * 0.6} height={size * 0.6} viewBox="0 0 24 24" fill="none">
          <path d="M4 20l8-15 8 15z" stroke={stroke} strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
          <circle cx="12" cy="14" r="2" fill={accent} />
        </svg>
      </div>
      {label && (
        <span style={{ fontWeight: 700, fontSize: size * 0.62, color: white ? '#fff' : color, letterSpacing: '-0.02em' }}>
          khudmati<span style={{ color: accent }}>.</span>
        </span>
      )}
    </div>
  )
}

export function Stars({ rating = 4.8, size = 14 }: { rating?: number; size?: number }) {
  return (
    <div style={{ display: 'inline-flex', gap: 2, alignItems: 'center' }}>
      {[1, 2, 3, 4, 5].map(i => (
        <span key={i} style={{ color: '#F39C12' }}>
          <Icon.Star size={size} stroke={i <= Math.round(rating) ? '#F39C12' : '#d5dae0'} filled={i <= Math.round(rating)} />
        </span>
      ))}
    </div>
  )
}

export function Avatar({ name = '', size = 32, bg = '#1B4F72', color = '#fff' }: {
  name?: string; size?: number; bg?: string; color?: string
}) {
  const initials = name.split(' ').map(n => n[0]).slice(0, 2).join('').toUpperCase()
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%', background: bg, color,
      display: 'grid', placeItems: 'center', fontSize: size * 0.38, fontWeight: 600, letterSpacing: '.02em',
      border: '2px solid #fff',
    }}>{initials}</div>
  )
}

export function AppStoreBadge({ store = 'ios', dark = false }: { store?: 'ios' | 'android'; dark?: boolean }) {
  const bg = dark ? '#fff' : '#0d0d0d'
  const fg = dark ? '#0d0d0d' : '#fff'
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 10, background: bg, color: fg,
      padding: '8px 14px', borderRadius: 10, minWidth: 138, border: `1px solid ${dark ? '#0d0d0d' : 'transparent'}`,
    }}>
      {store === 'ios' ? (
        <Icon.Apple size={22} fill={fg} />
      ) : (
        <svg width="20" height="22" viewBox="0 0 24 26" fill={fg}>
          <path d="M3 1l13 12L3 25z" opacity=".9" />
          <path d="M3 1l8 7-8 7z" opacity=".75" />
        </svg>
      )}
      <div style={{ lineHeight: 1.05 }}>
        <div style={{ fontSize: 9, opacity: .75, letterSpacing: '.04em' }}>{store === 'ios' ? 'Download on the' : 'GET IT ON'}</div>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{store === 'ios' ? 'App Store' : 'Google Play'}</div>
      </div>
    </div>
  )
}

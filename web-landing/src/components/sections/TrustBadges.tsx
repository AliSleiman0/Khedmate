import { useTranslation } from 'react-i18next'

function ShieldIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
    </svg>
  )
}

function StarIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
    </svg>
  )
}

function BadgeCheckIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
      <polyline points="9 12 11 14 15 10"/>
    </svg>
  )
}

function LockIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
      <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
    </svg>
  )
}

function BoltIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
    </svg>
  )
}

const BADGES = [
  { icon: <ShieldIcon />, key: 'trust_badge_1', subKey: 'trust_badge_1_sub' },
  { icon: <StarIcon />,   key: 'trust_badge_2', subKey: 'trust_badge_2_sub' },
  { icon: <BadgeCheckIcon />, key: 'trust_badge_3', subKey: 'trust_badge_3_sub' },
  { icon: <LockIcon />,  key: 'trust_badge_4', subKey: 'trust_badge_4_sub' },
  { icon: <BoltIcon />,  key: 'trust_badge_5', subKey: 'trust_badge_5_sub' },
]

export default function TrustBadges() {
  const { t } = useTranslation()

  return (
    <section style={{
      background: 'linear-gradient(135deg, var(--brown-primary) 0%, var(--brown-mid) 100%)',
      textAlign: 'center',
    }}>
      <h2 style={{ fontSize: 28, fontWeight: 700, color: 'white', marginBottom: 40 }}>
        {t('trust_title')}
      </h2>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 20, flexWrap: 'wrap', maxWidth: 1000, margin: '0 auto' }}>
        {BADGES.map(({ icon, key, subKey }) => (
          <div key={key} style={{
            background: 'rgba(255,255,255,0.10)',
            borderRadius: 16,
            padding: '28px 28px',
            textAlign: 'center',
            minWidth: 150,
            border: '1px solid rgba(255,255,255,0.18)',
            backdropFilter: 'blur(8px)',
            flex: '1 1 140px',
            maxWidth: 180,
          }}>
            <div style={{ marginBottom: 14, display: 'flex', justifyContent: 'center' }}>{icon}</div>
            <p style={{ color: 'white', fontWeight: 700, fontSize: 15, margin: 0 }}>{t(key)}</p>
            <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12, marginTop: 6 }}>{t(subKey)}</p>
          </div>
        ))}
      </div>
    </section>
  )
}

import { useTranslation } from 'react-i18next'

export default function Hero() {
  const { t } = useTranslation()
  return (
    <section style={{
      background: 'linear-gradient(135deg, var(--brand-blue) 0%, #2980B9 100%)',
      color: 'white',
      textAlign: 'center',
      padding: '100px 24px',
    }}>
      <h1 style={{ fontSize: 52, fontWeight: 700, marginBottom: 16, lineHeight: 1.2 }}>
        {t('hero_title')}
      </h1>
      <p style={{ fontSize: 20, opacity: 0.9, marginBottom: 48, maxWidth: 600, margin: '0 auto 48px' }}>
        {t('hero_subtitle')}
      </p>
      <div style={{ display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
        <button style={{
          background: 'var(--amber)',
          color: 'white',
          border: 'none',
          padding: '16px 40px',
          borderRadius: 12,
          fontSize: 18,
          fontWeight: 700,
          cursor: 'pointer',
          fontFamily: 'inherit',
        }}>
          📱 {t('download_app')} (iOS)
        </button>
        <button style={{
          background: 'rgba(255,255,255,0.15)',
          color: 'white',
          border: '2px solid rgba(255,255,255,0.4)',
          padding: '16px 40px',
          borderRadius: 12,
          fontSize: 18,
          fontWeight: 700,
          cursor: 'pointer',
          fontFamily: 'inherit',
        }}>
          📱 {t('download_app')} (Android)
        </button>
      </div>
    </section>
  )
}

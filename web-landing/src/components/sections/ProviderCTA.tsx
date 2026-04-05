import { useTranslation } from 'react-i18next'

export default function ProviderCTA() {
  const { t } = useTranslation()
  return (
    <section style={{
      background: 'linear-gradient(135deg, var(--amber) 0%, #E67E22 100%)',
      color: 'white',
      textAlign: 'center',
    }}>
      <h2 style={{ fontSize: 36, marginBottom: 16 }}>{t('join_provider')}</h2>
      <p style={{ fontSize: 18, opacity: 0.9, marginBottom: 40, maxWidth: 500, margin: '0 auto 40px' }}>
        {t('join_provider_desc')}
      </p>
      <div style={{ display: 'flex', gap: 24, justifyContent: 'center', flexWrap: 'wrap' }}>
        <div style={{ textAlign: 'center', color: 'rgba(255,255,255,0.9)' }}>
          <div style={{ fontSize: 36, fontWeight: 700 }}>+5,000</div>
          <div style={{ fontSize: 14 }}>مزود نشط</div>
        </div>
        <div style={{ width: 1, background: 'rgba(255,255,255,0.3)' }} />
        <div style={{ textAlign: 'center', color: 'rgba(255,255,255,0.9)' }}>
          <div style={{ fontSize: 36, fontWeight: 700 }}>3,000 ر.س</div>
          <div style={{ fontSize: 14 }}>متوسط الدخل الشهري</div>
        </div>
        <div style={{ width: 1, background: 'rgba(255,255,255,0.3)' }} />
        <div style={{ textAlign: 'center', color: 'rgba(255,255,255,0.9)' }}>
          <div style={{ fontSize: 36, fontWeight: 700 }}>مرن</div>
          <div style={{ fontSize: 14 }}>اعمل بوقتك الخاص</div>
        </div>
      </div>
      <div style={{ marginTop: 40 }}>
        <button style={{
          background: 'white',
          color: 'var(--amber)',
          border: 'none',
          padding: '16px 48px',
          borderRadius: 12,
          fontSize: 18,
          fontWeight: 700,
          cursor: 'pointer',
          fontFamily: 'inherit',
        }}>
          {t('join_provider')} →
        </button>
      </div>
    </section>
  )
}

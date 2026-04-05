import { useTranslation } from 'react-i18next'

export default function Header() {
  const { t, i18n } = useTranslation()
  const toggle = () => i18n.changeLanguage(i18n.language === 'ar' ? 'en' : 'ar')

  return (
    <header style={{
      background: 'var(--brand-blue)',
      padding: '0 24px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      height: 64,
      position: 'sticky',
      top: 0,
      zIndex: 100,
    }}>
      <span style={{ color: 'white', fontSize: 24, fontWeight: 700 }}>خدمتي</span>
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <button
          onClick={toggle}
          style={{
            background: 'rgba(255,255,255,0.15)',
            color: 'white',
            border: '1px solid rgba(255,255,255,0.3)',
            padding: '6px 16px',
            borderRadius: 8,
            cursor: 'pointer',
            fontFamily: 'inherit',
          }}
        >
          {t('language')}
        </button>
        <button style={{
          background: 'var(--amber)',
          color: 'white',
          border: 'none',
          padding: '8px 20px',
          borderRadius: 8,
          cursor: 'pointer',
          fontWeight: 700,
          fontFamily: 'inherit',
        }}>
          {t('download_app')}
        </button>
      </div>
    </header>
  )
}

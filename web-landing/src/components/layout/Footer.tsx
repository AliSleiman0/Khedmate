import { useTranslation } from 'react-i18next'

export default function Footer() {
  const { t } = useTranslation()
  return (
    <footer style={{
      background: 'var(--brand-blue)',
      color: 'rgba(255,255,255,0.8)',
      textAlign: 'center',
      padding: '32px 24px',
    }}>
      <p style={{ fontSize: 20, fontWeight: 700, color: 'white', marginBottom: 8 }}>خدمتي</p>
      <p>© 2024 خدمتي. {t('footer_rights')}.</p>
    </footer>
  )
}

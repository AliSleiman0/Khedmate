import { useTranslation } from 'react-i18next'

export default function HowItWorks() {
  const { t } = useTranslation()
  const steps = [
    { num: 1, title: t('step1_title'), desc: t('step1_desc'), icon: '🔍' },
    { num: 2, title: t('step2_title'), desc: t('step2_desc'), icon: '📅' },
    { num: 3, title: t('step3_title'), desc: t('step3_desc'), icon: '✅' },
  ]
  return (
    <section style={{ background: 'var(--surface)', textAlign: 'center' }}>
      <h2 style={{ fontSize: 36, marginBottom: 56, color: 'var(--brand-blue)' }}>
        {t('how_it_works')}
      </h2>
      <div style={{ display: 'flex', gap: 32, justifyContent: 'center', flexWrap: 'wrap' }}>
        {steps.map(s => (
          <div key={s.num} style={{
            background: 'white',
            borderRadius: 20,
            padding: 36,
            width: 260,
            boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
            position: 'relative',
          }}>
            <div style={{
              position: 'absolute',
              top: -16,
              insetInlineStart: -16,
              width: 40,
              height: 40,
              borderRadius: '50%',
              background: 'var(--brand-blue)',
              color: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 700,
              fontSize: 18,
            }}>{s.num}</div>
            <div style={{ fontSize: 52 }}>{s.icon}</div>
            <h3 style={{ margin: '16px 0 8px', color: 'var(--brand-blue)', fontSize: 18 }}>
              {s.title}
            </h3>
            <p style={{ color: 'var(--text-secondary)' }}>{s.desc}</p>
          </div>
        ))}
      </div>
    </section>
  )
}

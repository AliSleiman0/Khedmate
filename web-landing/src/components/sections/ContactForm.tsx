import { useState } from 'react'
import { useTranslation } from 'react-i18next'

export default function ContactForm() {
  const { t } = useTranslation()
  const [form, setForm] = useState({ name: '', email: '', message: '' })
  const [sent, setSent] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setSent(true)
  }

  const inputStyle: React.CSSProperties = {
    padding: '12px 16px',
    borderRadius: 10,
    border: '1px solid #dde1e7',
    fontSize: 16,
    fontFamily: 'inherit',
    width: '100%',
    outline: 'none',
  }

  return (
    <section style={{ background: 'var(--surface)' }}>
      <div style={{ maxWidth: 600, margin: '0 auto' }}>
        <h2 style={{ fontSize: 36, marginBottom: 40, textAlign: 'center', color: 'var(--brand-blue)' }}>
          {t('contact_us')}
        </h2>
        {sent ? (
          <div style={{
            textAlign: 'center',
            padding: '48px 24px',
            background: 'white',
            borderRadius: 16,
            boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
          }}>
            <div style={{ fontSize: 56 }}>✅</div>
            <p style={{ fontSize: 20, marginTop: 16, fontWeight: 600 }}>تم إرسال رسالتك بنجاح!</p>
            <p style={{ color: 'var(--text-secondary)', marginTop: 8 }}>سنرد عليك خلال 24 ساعة</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 16,
            background: 'white',
            padding: 32,
            borderRadius: 16,
            boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
          }}>
            {(['name', 'email'] as const).map(f => (
              <input
                key={f}
                type={f === 'email' ? 'email' : 'text'}
                placeholder={t(f)}
                value={form[f]}
                onChange={e => setForm(p => ({ ...p, [f]: e.target.value }))}
                required
                style={inputStyle}
              />
            ))}
            <textarea
              placeholder={t('message')}
              value={form.message}
              onChange={e => setForm(p => ({ ...p, message: e.target.value }))}
              rows={5}
              required
              style={{ ...inputStyle, resize: 'vertical' }}
            />
            <button type="submit" style={{
              background: 'var(--brand-blue)',
              color: 'white',
              border: 'none',
              padding: '14px',
              borderRadius: 10,
              fontSize: 18,
              fontWeight: 700,
              cursor: 'pointer',
              fontFamily: 'inherit',
            }}>
              {t('send')}
            </button>
          </form>
        )}
      </div>
    </section>
  )
}

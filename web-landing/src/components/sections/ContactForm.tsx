import { useState } from 'react'
import { useTranslation } from 'react-i18next'

export default function ContactForm() {
  const { t } = useTranslation()
  const [form, setForm] = useState({ name: '', email: '', message: '' })
  const [sent, setSent] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const res = await fetch('/api/landing/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      })
      if (!res.ok) throw new Error('server')
      setSent(true)
    } catch {
      setError(t('contact_error'))
    } finally {
      setLoading(false)
    }
  }

  const baseInput: React.CSSProperties = {
    padding: '13px 16px',
    borderRadius: 12,
    border: '1px solid var(--cream-border)',
    fontSize: 16,
    fontFamily: 'inherit',
    width: '100%',
    outline: 'none',
    background: 'white',
    transition: 'border var(--transition-base)',
    color: 'var(--text-primary)',
  }

  const handleFocus = (e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    e.target.style.border = '2px solid var(--brown-primary)'
    e.target.style.padding = '12px 15px'
  }
  const handleBlur = (e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    e.target.style.border = '1px solid var(--cream-border)'
    e.target.style.padding = '13px 16px'
  }

  return (
    <section id="contact" style={{ background: 'var(--surface-warm)' }}>
      <div style={{ maxWidth: 600, margin: '0 auto' }}>
        <h2 style={{ fontSize: 38, fontWeight: 700, marginBottom: 12, textAlign: 'center', color: 'var(--brown-primary)' }}>
          {t('contact_us')}
        </h2>
        <div style={{ width: 60, height: 4, borderRadius: 2, background: 'var(--amber)', margin: '0 auto 48px' }} />

        {sent ? (
          <div style={{
            textAlign: 'center',
            padding: '56px 24px',
            background: 'white',
            borderRadius: 'var(--radius-card)',
            boxShadow: '0 4px 24px var(--shadow-brown)',
            border: '1px solid var(--cream-border)',
          }}>
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" style={{ margin: '0 auto 20px', display: 'block' }}>
              <circle cx="12" cy="12" r="10" stroke="var(--success)" strokeWidth="2"/>
              <polyline points="9 12 11 14 15 10" stroke="var(--success)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <p style={{ fontSize: 20, fontWeight: 700, color: 'var(--brown-primary)' }}>{t('contact_success_title')}</p>
            <p style={{ color: 'var(--text-secondary)', marginTop: 10 }}>{t('contact_success_desc')}</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 16,
            background: 'white',
            padding: 36,
            borderRadius: 'var(--radius-card)',
            boxShadow: '0 4px 24px var(--shadow-brown)',
            border: '1px solid var(--cream-border)',
          }}>
            {(['name', 'email'] as const).map(f => (
              <input
                key={f}
                type={f === 'email' ? 'email' : 'text'}
                placeholder={t(f)}
                value={form[f]}
                onChange={e => setForm(p => ({ ...p, [f]: e.target.value }))}
                onFocus={handleFocus}
                onBlur={handleBlur}
                required
                style={baseInput}
              />
            ))}
            <textarea
              placeholder={t('message')}
              value={form.message}
              onChange={e => setForm(p => ({ ...p, message: e.target.value }))}
              onFocus={handleFocus}
              onBlur={handleBlur}
              rows={5}
              required
              style={{ ...baseInput, resize: 'vertical' }}
            />
            {error && (
              <p style={{ color: 'var(--danger)', fontSize: 14, textAlign: 'center', margin: 0 }}>{error}</p>
            )}
            <button
              type="submit"
              disabled={loading}
              style={{
                background: loading ? 'var(--brown-mid)' : 'var(--brown-primary)',
                color: 'white',
                border: 'none',
                padding: '15px',
                borderRadius: 'var(--radius-pill)',
                fontSize: 17,
                fontWeight: 700,
                cursor: loading ? 'not-allowed' : 'pointer',
                fontFamily: 'inherit',
                opacity: loading ? 0.7 : 1,
                transition: 'background var(--transition-base), opacity var(--transition-base)',
              }}
            >
              {loading ? t('sending') : t('send')}
            </button>
          </form>
        )}
      </div>
    </section>
  )
}

import { useState } from 'react'
import { Icon } from '../ui/Icons'
import { useIsMobile } from '../../hooks/useIsMobile'

function ContactRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10, background: '#e8eef4',
        display: 'grid', placeItems: 'center', flexShrink: 0,
      }}>{icon}</div>
      <div>
        <div style={{
          fontSize: 11, color: '#8b95a1', fontWeight: 600,
          letterSpacing: '.04em', textTransform: 'uppercase',
        }}>{label}</div>
        <div style={{ fontSize: 14, color: '#14181d', fontWeight: 500 }}>{value}</div>
      </div>
    </div>
  )
}

export default function ContactForm() {
  const isMobile = useIsMobile()
  const [form, setForm] = useState({ name: '', email: '', message: '' })
  const [touched, setTouched] = useState<{ name?: boolean; email?: boolean }>({})
  const [submitting, setSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)
  const showEmailError = !!touched.email && !!form.email && !emailValid

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name || !emailValid || !form.message) {
      setTouched({ name: true, email: true })
      return
    }
    setSubmitting(true)
    setError(null)
    try {
      const res = await fetch('/api/landing/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      })
      if (!res.ok) throw new Error('server')
      setSubmitted(true)
    } catch {
      setError("We couldn't send your message — please try again in a moment.")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <section id="contact" style={{
      padding: isMobile ? '56px 20px' : '112px 32px', background: '#fbfbfc',
    }}>
      <div style={{
        maxWidth: 980, margin: '0 auto',
        display: 'grid', gridTemplateColumns: isMobile ? '1fr' : '1fr 1.2fr',
        gap: isMobile ? 28 : 48, alignItems: 'flex-start',
      }}>
        <div>
          <div className="kh-eyebrow" style={{ color: '#F39C12', marginBottom: 10 }}>Contact us</div>
          <h2 className="kh-h1" style={{
            fontSize: isMobile ? 28 : 36, color: '#14181d',
            margin: '0 0 14px', letterSpacing: '-0.025em',
          }}>
            Question, feedback, or partnership?
          </h2>
          <p style={{ fontSize: 15, color: '#4d5763', lineHeight: 1.6, margin: '0 0 24px' }}>
            We answer every message within one business day. No bots, no tickets — just our team in Beirut.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <ContactRow icon={<Icon.Mail size={16} stroke="#1B4F72" />} label="Email" value="info@khudmati.app" />
            <ContactRow icon={<Icon.Phone size={16} stroke="#1B4F72" />} label="Phone" value="+961 70 000 000" />
            <ContactRow icon={<Icon.Pin size={16} stroke="#1B4F72" />} label="Office" value="Hamra, Beirut · Lebanon" />
          </div>
        </div>

        <div className="kh-card" style={{
          padding: isMobile ? 20 : 32, background: '#fff', borderRadius: 18,
        }}>
          {submitted ? (
            <div style={{ textAlign: 'center', padding: '24px 0' }}>
              <div style={{
                width: 64, height: 64, borderRadius: '50%', margin: '0 auto 18px',
                background: '#e3f5ec', color: '#1a7f47',
                display: 'grid', placeItems: 'center',
              }}>
                <Icon.Check size={28} stroke="#1a7f47" />
              </div>
              <div style={{ fontSize: 20, fontWeight: 600, color: '#14181d', marginBottom: 6 }}>Message sent</div>
              <div style={{ fontSize: 14, color: '#6b7682' }}>We'll be in touch within one business day.</div>
            </div>
          ) : (
            <form onSubmit={submit}>
              <div style={{ marginBottom: 14 }}>
                <label className="kh-label">Your name</label>
                <input className="kh-input" placeholder="Layal Khoury"
                  value={form.name}
                  onChange={e => setForm(p => ({ ...p, name: e.target.value }))}
                  onBlur={() => setTouched(t => ({ ...t, name: true }))} />
              </div>
              <div style={{ marginBottom: 14 }}>
                <label className="kh-label">Email</label>
                <input className={`kh-input ${showEmailError ? 'kh-input-error' : ''}`}
                  placeholder="layal@example.com" type="email"
                  value={form.email}
                  onChange={e => setForm(p => ({ ...p, email: e.target.value }))}
                  onBlur={() => setTouched(t => ({ ...t, email: true }))} />
                {showEmailError && (
                  <div style={{ fontSize: 12, color: '#c53030', marginTop: 6 }}>
                    Please enter a valid email address.
                  </div>
                )}
              </div>
              <div style={{ marginBottom: 18 }}>
                <label className="kh-label">Message</label>
                <textarea className="kh-input kh-textarea" placeholder="How can we help?"
                  value={form.message}
                  onChange={e => setForm(p => ({ ...p, message: e.target.value }))} />
              </div>
              {error && (
                <div style={{
                  fontSize: 13, color: '#c53030', marginBottom: 12, textAlign: 'center',
                }}>{error}</div>
              )}
              <button type="submit" className="kh-btn kh-btn-dark"
                style={{ width: '100%', height: 48, opacity: submitting ? 0.7 : 1 }}
                disabled={submitting}>
                {submitting ? 'Sending…' : (<>Send message <Icon.Arrow size={14} stroke="#fff" /></>)}
              </button>
              <div style={{
                fontSize: 11, color: '#8b95a1', textAlign: 'center', marginTop: 12,
                display: 'inline-flex', justifyContent: 'center', alignItems: 'center', gap: 4, width: '100%',
              }}>
                <Icon.Lock size={11} stroke="#8b95a1" /> Your details are private. We never share or sell.
              </div>
            </form>
          )}
        </div>
      </div>
    </section>
  )
}

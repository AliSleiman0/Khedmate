import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { fadeInUp } from '../../animations/variants'

export default function ContactForm() {
  const { t } = useTranslation()
  const [form, setForm] = useState({ name: '', email: '', message: '' })
  const [sent, setSent] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [focusedField, setFocusedField] = useState<string | null>(null)

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
    border: 'none',
    fontSize: 16,
    fontFamily: 'inherit',
    width: '100%',
    outline: 'none',
    background: 'white',
    color: 'var(--text-primary)',
  }

  return (
    <section id="contact" style={{ background: 'var(--surface)' }}>
      <div style={{ maxWidth: 600, margin: '0 auto' }}>
        <motion.h2
          variants={fadeInUp}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          style={{ fontSize: 38, fontWeight: 700, marginBottom: 12, textAlign: 'center', color: 'var(--brand-blue)' }}
        >
          {t('contact_us')}
        </motion.h2>
        <motion.div
          variants={fadeInUp}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          style={{ width: 60, height: 4, borderRadius: 2, background: 'var(--amber)', margin: '0 auto 48px' }}
        />

        <AnimatePresence mode="wait">
          {sent ? (
            <motion.div
              key="success"
              initial={{ opacity: 0, scale: 0.85 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.85 }}
              transition={{ duration: 0.35 }}
              style={{
                textAlign: 'center',
                padding: '56px 24px',
                background: 'white',
                borderRadius: 'var(--radius-card)',
                boxShadow: '0 4px 24px rgba(27,79,114,0.08)',
                border: '1px solid rgba(27,79,114,0.10)',
              }}
            >
              <motion.svg
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: 'spring', stiffness: 400, damping: 15, delay: 0.15 }}
                width="64" height="64" viewBox="0 0 24 24" fill="none"
                style={{ margin: '0 auto 20px', display: 'block' }}
              >
                <circle cx="12" cy="12" r="10" stroke="var(--success)" strokeWidth="2"/>
                <polyline points="9 12 11 14 15 10" stroke="var(--success)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
              </motion.svg>
              <p style={{ fontSize: 20, fontWeight: 700, color: 'var(--brand-blue)' }}>{t('contact_success_title')}</p>
              <p style={{ color: 'var(--text-secondary)', marginTop: 10 }}>{t('contact_success_desc')}</p>
            </motion.div>
          ) : (
            <motion.form
              key="form"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
              onSubmit={handleSubmit}
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: 16,
                background: 'white',
                padding: 36,
                borderRadius: 'var(--radius-card)',
                boxShadow: '0 4px 24px rgba(27,79,114,0.08)',
                border: '1px solid rgba(27,79,114,0.10)',
              }}
            >
              {(['name', 'email'] as const).map(f => (
                <motion.div
                  key={f}
                  animate={{
                    boxShadow: focusedField === f
                      ? '0 0 0 2px var(--brand-blue)'
                      : '0 0 0 1px rgba(27,79,114,0.15)',
                  }}
                  transition={{ duration: 0.18 }}
                  style={{ borderRadius: 12 }}
                >
                  <input
                    type={f === 'email' ? 'email' : 'text'}
                    placeholder={t(f)}
                    value={form[f]}
                    onChange={e => setForm(p => ({ ...p, [f]: e.target.value }))}
                    onFocus={() => setFocusedField(f)}
                    onBlur={() => setFocusedField(null)}
                    required
                    style={baseInput}
                  />
                </motion.div>
              ))}
              <motion.div
                animate={{
                  boxShadow: focusedField === 'message'
                    ? '0 0 0 2px var(--brand-blue)'
                    : '0 0 0 1px rgba(27,79,114,0.15)',
                }}
                transition={{ duration: 0.18 }}
                style={{ borderRadius: 12 }}
              >
                <textarea
                  placeholder={t('message')}
                  value={form.message}
                  onChange={e => setForm(p => ({ ...p, message: e.target.value }))}
                  onFocus={() => setFocusedField('message')}
                  onBlur={() => setFocusedField(null)}
                  rows={5}
                  required
                  style={{ ...baseInput, resize: 'vertical', display: 'block' }}
                />
              </motion.div>
              {error && (
                <p style={{ color: 'var(--danger)', fontSize: 14, textAlign: 'center', margin: 0 }}>{error}</p>
              )}
              <motion.button
                type="submit"
                disabled={loading}
                whileHover={!loading ? { scale: 1.03, boxShadow: '0 6px 20px rgba(27,79,114,0.25)' } : {}}
                whileTap={!loading ? { scale: 0.97 } : {}}
                style={{
                  background: loading ? '#2E6B99' : 'var(--brand-blue)',
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
              </motion.button>
            </motion.form>
          )}
        </AnimatePresence>
      </div>
    </section>
  )
}

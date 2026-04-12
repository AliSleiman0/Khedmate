import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import AnimatedSection from '../ui/AnimatedSection'
import { fadeInUp, getDirectionalVariants } from '../../animations/variants'

function EnvelopeIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
      <polyline points="22,6 12,13 2,6"/>
    </svg>
  )
}

function PhoneIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
      <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 13a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 2.18h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6 6l.9-.9a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
    </svg>
  )
}

function MapPinIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
      <circle cx="12" cy="10" r="3"/>
    </svg>
  )
}

function InstagramIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="2" width="20" height="20" rx="5" ry="5"/>
      <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/>
      <line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/>
    </svg>
  )
}

function TwitterIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
  )
}

function LinkedInIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
      <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6zM2 9h4v12H2z"/>
      <circle cx="4" cy="4" r="2"/>
    </svg>
  )
}

export default function Footer() {
  const { t, i18n } = useTranslation()
  const dir = i18n.language === 'ar' ? 'rtl' : 'ltr'
  const dv = getDirectionalVariants(dir)
  const services = ['cleaning', 'plumbing', 'electrical', 'moving', 'painting', 'ac']
  const contactRows = [
    { icon: <EnvelopeIcon />, text: t('footer_email') },
    { icon: <PhoneIcon />,    text: t('footer_phone') },
    { icon: <MapPinIcon />,  text: t('footer_location') },
  ]
  const socialLinks = [
    { icon: <InstagramIcon />, href: '#' },
    { icon: <TwitterIcon />,   href: '#' },
    { icon: <LinkedInIcon />,  href: '#' },
  ]

  return (
    <footer style={{ background: 'var(--brown-primary)', color: 'rgba(255,255,255,0.85)' }}>
      {/* Main grid */}
      <AnimatedSection stagger="slow" style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 48,
        maxWidth: 1100,
        margin: '0 auto',
        padding: '64px 32px 48px',
      }}>
        {/* Col 1 — About */}
        <motion.div variants={fadeInUp}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
            <div style={{ background: 'white', borderRadius: 10, padding: '4px 6px', display: 'flex', alignItems: 'center' }}>
              <img src="/logo.webp" alt="خدمتي" style={{ height: 36 }} />
            </div>
            <span style={{ color: 'var(--amber)', fontWeight: 700, fontSize: 22 }}>خدمتي</span>
          </div>
          <p style={{ fontSize: 14, color: 'rgba(255,255,255,0.65)', lineHeight: 1.8 }}>
            {t('footer_about_desc')}
          </p>
          <div style={{ display: 'flex', gap: 14, marginTop: 20 }}>
            {socialLinks.map((s, i) => (
              <motion.a
                key={i}
                href={s.href}
                whileHover={{ scale: 1.2, background: 'rgba(255,255,255,0.22)' }}
                whileTap={{ scale: 0.88 }}
                transition={{ type: 'spring', stiffness: 450, damping: 14 }}
                style={{
                  width: 36, height: 36,
                  borderRadius: '50%',
                  background: 'rgba(255,255,255,0.10)',
                  border: '1px solid rgba(255,255,255,0.18)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  cursor: 'pointer',
                }}
              >
                {s.icon}
              </motion.a>
            ))}
          </div>
        </motion.div>

        {/* Col 2 — Services */}
        <motion.div variants={fadeInUp}>
          <h4 style={{ color: 'var(--amber)', fontWeight: 700, fontSize: 16, marginBottom: 20 }}>
            {t('services')}
          </h4>
          {services.map(s => (
            <motion.a
              key={s}
              href="#services"
              whileHover={{ color: 'white', x: dir === 'rtl' ? -3 : 3 }}
              style={{ display: 'block', color: 'rgba(255,255,255,0.7)', fontSize: 14, marginBottom: 12, cursor: 'pointer' }}
            >
              {t(s)}
            </motion.a>
          ))}
        </motion.div>

        {/* Col 3 — Contact */}
        <motion.div variants={fadeInUp}>
          <h4 style={{ color: 'var(--amber)', fontWeight: 700, fontSize: 16, marginBottom: 20 }}>
            {t('contact_us')}
          </h4>
          {contactRows.map((row, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
              {row.icon}
              <span style={{ fontSize: 14, color: 'rgba(255,255,255,0.75)' }}>{row.text}</span>
            </div>
          ))}
          <motion.a
            href="#contact"
            whileHover={{ color: 'var(--amber)' }}
            style={{ display: 'inline-block', marginTop: 8, color: 'var(--amber)', fontSize: 14, fontWeight: 600, textDecoration: 'underline', cursor: 'pointer' }}
          >
            {t('contact_us')} →
          </motion.a>
        </motion.div>
      </AnimatedSection>

      {/* Copyright bar */}
      <motion.div
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ delay: 0.3 }}
        style={{
          borderTop: '1px solid rgba(255,255,255,0.12)',
          maxWidth: 1100,
          margin: '0 auto',
          padding: '20px 32px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 12,
        }}
      >
        <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.5)' }}>
          © {new Date().getFullYear()} خدمتي. {t('footer_rights')}.
        </p>
        <div style={{ display: 'flex', gap: 20 }}>
          {[{ key: 'footer_privacy' }, { key: 'footer_terms' }].map(({ key }) => (
            <motion.a
              key={key}
              href="#"
              whileHover={{ color: 'rgba(255,255,255,0.85)' }}
              style={{ fontSize: 13, color: 'rgba(255,255,255,0.5)', cursor: 'pointer' }}
            >
              {t(key)}
            </motion.a>
          ))}
        </div>
      </motion.div>
    </footer>
  )
}

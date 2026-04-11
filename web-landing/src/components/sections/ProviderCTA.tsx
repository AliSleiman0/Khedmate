import { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import { fadeInUp, staggerContainer, getDirectionalVariants } from '../../animations/variants'

function HouseIllustration() {
  return (
    <svg viewBox="0 0 300 260" width="280" fill="none" xmlns="http://www.w3.org/2000/svg"
      style={{ opacity: 0.9 }}>
      {/* House body */}
      <rect x="70" y="130" width="160" height="110" rx="6" stroke="white" strokeWidth="3" fill="rgba(255,255,255,0.06)"/>
      {/* Roof */}
      <polyline points="55,135 150,55 245,135" stroke="white" strokeWidth="3" strokeLinejoin="round"/>
      {/* Chimney */}
      <rect x="185" y="70" width="22" height="42" rx="3" stroke="white" strokeWidth="2.5" fill="rgba(255,255,255,0.06)"/>
      {/* Door */}
      <rect x="126" y="175" width="48" height="65" rx="4" stroke="white" strokeWidth="2.5" fill="rgba(255,255,255,0.06)"/>
      <circle cx="167" cy="210" r="3" fill="white"/>
      {/* Window left */}
      <rect x="85" y="155" width="42" height="36" rx="4" stroke="white" strokeWidth="2" fill="rgba(255,255,255,0.06)"/>
      <line x1="106" y1="155" x2="106" y2="191" stroke="white" strokeWidth="1.5"/>
      <line x1="85" y1="173" x2="127" y2="173" stroke="white" strokeWidth="1.5"/>
      {/* Window right */}
      <rect x="173" y="155" width="42" height="36" rx="4" stroke="white" strokeWidth="2" fill="rgba(255,255,255,0.06)"/>
      <line x1="194" y1="155" x2="194" y2="191" stroke="white" strokeWidth="1.5"/>
      <line x1="173" y1="173" x2="215" y2="173" stroke="white" strokeWidth="1.5"/>
      {/* Sparkles */}
      <circle cx="40" cy="80" r="5" fill="var(--amber)" opacity="0.8"/>
      <circle cx="260" cy="90" r="4" fill="var(--amber)" opacity="0.7"/>
      <circle cx="30" cy="160" r="3" fill="white" opacity="0.5"/>
      <circle cx="272" cy="150" r="3.5" fill="white" opacity="0.5"/>
      <line x1="40" y1="60" x2="40" y2="72" stroke="var(--amber)" strokeWidth="1.5" opacity="0.8"/>
      <line x1="34" y1="66" x2="46" y2="66" stroke="var(--amber)" strokeWidth="1.5" opacity="0.8"/>
      <line x1="260" y1="72" x2="260" y2="82" stroke="var(--amber)" strokeWidth="1.5" opacity="0.7"/>
      <line x1="255" y1="77" x2="265" y2="77" stroke="var(--amber)" strokeWidth="1.5" opacity="0.7"/>
      {/* Ground line */}
      <line x1="40" y1="240" x2="260" y2="240" stroke="rgba(255,255,255,0.3)" strokeWidth="2" strokeLinecap="round"/>
    </svg>
  )
}

export default function ProviderCTA() {
  const { t, i18n } = useTranslation()
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768)
  const dir = i18n.language === 'ar' ? 'rtl' : 'ltr'
  const dv = getDirectionalVariants(dir)

  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth < 768)
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])

  const stats = [
    { val: t('provider_stat_1_val'), label: t('provider_stat_1_label') },
    { val: t('provider_stat_2_val'), label: t('provider_stat_2_label') },
    { val: t('provider_stat_3_val'), label: t('provider_stat_3_label') },
  ]

  return (
    <section style={{
      background: 'linear-gradient(135deg, var(--brown-primary) 0%, #5C2D0A 50%, var(--amber) 100%)',
      color: 'white',
    }}>
      <div style={{
        maxWidth: 1100,
        margin: '0 auto',
        display: 'flex',
        alignItems: 'center',
        gap: 48,
        flexDirection: isMobile ? 'column' : 'row',
      }}>
        {/* Text side */}
        <motion.div
          variants={dv.slideInStart}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.2 }}
          style={{ flex: 1 }}
        >
          <h2 style={{ fontSize: 38, fontWeight: 700, marginBottom: 16, lineHeight: 1.2 }}>
            {t('join_provider')}
          </h2>
          <p style={{ fontSize: 18, opacity: 0.9, lineHeight: 1.7, maxWidth: 460 }}>
            {t('join_provider_desc')}
          </p>

          <motion.div
            variants={staggerContainer}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, amount: 0.2 }}
            style={{ display: 'flex', gap: 40, marginTop: 36, marginBottom: 44, flexWrap: 'wrap' }}
          >
            {stats.map((s, i) => (
              <motion.div key={i} variants={fadeInUp} style={{
                textAlign: 'center',
                borderInlineEnd: i < stats.length - 1 ? '1px solid rgba(255,255,255,0.25)' : 'none',
                paddingInlineEnd: i < stats.length - 1 ? 40 : 0,
              }}>
                <div style={{ fontSize: 36, fontWeight: 700, color: 'white', lineHeight: 1.1 }}>{s.val}</div>
                <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.75)', marginTop: 6 }}>{s.label}</div>
              </motion.div>
            ))}
          </motion.div>

          <motion.button
            whileHover={{ y: -2, boxShadow: '0 8px 24px rgba(0,0,0,0.25)', scale: 1.02 }}
            whileTap={{ scale: 0.97 }}
            style={{
              background: 'white',
              color: 'var(--brown-primary)',
              border: 'none',
              padding: '15px 48px',
              borderRadius: 'var(--radius-pill)',
              fontSize: 18,
              fontWeight: 700,
              cursor: 'pointer',
              fontFamily: 'inherit',
            }}
          >
            {t('join_provider')} →
          </motion.button>
        </motion.div>

        {/* Decorative illustration */}
        {!isMobile && (
          <motion.div
            variants={dv.slideInEnd}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, amount: 0.2 }}
            style={{ flexShrink: 0 }}
          >
            <HouseIllustration />
          </motion.div>
        )}
      </div>
    </section>
  )
}

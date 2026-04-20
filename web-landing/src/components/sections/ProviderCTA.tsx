import { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import { fadeInUp, staggerContainer, getDirectionalVariants } from '../../animations/variants'

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
      background: 'linear-gradient(135deg, #1B4F72 0%, #0D3050 100%)',
      color: 'white',
    }}>
      <div style={{
        maxWidth: 1100,
        margin: '0 auto',
        display: 'flex',
        alignItems: 'center',
        gap: 64,
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
              color: 'var(--brand-blue)',
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

        {/* Provider photo — desktop only */}
        {!isMobile && (
          <motion.div
            variants={dv.slideInEnd}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, amount: 0.2 }}
            style={{ flexShrink: 0 }}
          >
            <img
              src="/provider.jpg"
              alt="Service provider"
              style={{
                width: 300,
                height: 380,
                objectFit: 'cover',
                borderRadius: 20,
                boxShadow: '0 24px 48px rgba(0,0,0,0.35)',
                display: 'block',
              }}
            />
          </motion.div>
        )}
      </div>
    </section>
  )
}

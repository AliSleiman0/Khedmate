import { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, useScroll, useTransform } from 'framer-motion'

export default function Header() {
  const { t, i18n } = useTranslation()
  const toggle = () => i18n.changeLanguage(i18n.language === 'ar' ? 'en' : 'ar')
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768)

  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth < 768)
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])

  const { scrollY } = useScroll()
  const headerBg = useTransform(scrollY, [0, 60], ['rgba(59,23,4,1)', 'rgba(59,23,4,0.92)'])
  const headerBlur = useTransform(scrollY, [0, 60], ['blur(0px) saturate(100%)', 'blur(16px) saturate(180%)'])
  const headerShadow = useTransform(scrollY, [0, 60], ['0 2px 20px rgba(59,23,4,0)', '0 2px 20px rgba(59,23,4,0.20)'])

  const navLinks = [
    { href: '#how-it-works', label: t('how_it_works') },
    { href: '#services', label: t('services') },
    { href: '#contact', label: t('contact_us') },
  ]

  return (
    <motion.header style={{
      background: headerBg,
      backdropFilter: headerBlur,
      boxShadow: headerShadow,
      padding: '0 32px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      height: 72,
      position: 'sticky',
      top: 0,
      zIndex: 100,
    }}>
      {/* Logo + brand name */}
      <motion.div
        style={{ display: 'flex', alignItems: 'center', gap: 12 }}
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: 'easeOut' }}
      >
        <div style={{ background: 'white', borderRadius: 10, padding: '4px 6px', display: 'flex', alignItems: 'center' }}>
          <img src="/logo.png" alt="خدمتي" style={{ height: 36 }} />
        </div>
        <span style={{ color: 'var(--amber)', fontWeight: 700, fontSize: 22, letterSpacing: '-0.3px' }}>
          خدمتي
        </span>
      </motion.div>

      {/* Desktop nav */}
      {!isMobile && (
        <nav style={{ display: 'flex', gap: 32, alignItems: 'center' }}>
          {navLinks.map((link, index) => (
            <motion.a
              key={link.href}
              href={link.href}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.06 + index * 0.06, ease: 'easeOut' }}
              whileHover={{ color: 'white' }}
              style={{ color: 'rgba(255,255,255,0.8)', fontSize: 15, fontWeight: 500, cursor: 'pointer' }}
            >
              {link.label}
            </motion.a>
          ))}
        </nav>
      )}

      {/* Actions */}
      <motion.div
        style={{ display: 'flex', gap: 10, alignItems: 'center' }}
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.24, ease: 'easeOut' }}
      >
        <motion.button
          onClick={toggle}
          whileHover={{ scale: 1.04, background: 'rgba(255,255,255,0.22)' }}
          whileTap={{ scale: 0.96 }}
          style={{
            background: 'rgba(255,255,255,0.12)',
            color: 'white',
            border: '1px solid rgba(255,255,255,0.25)',
            padding: '7px 18px',
            borderRadius: 'var(--radius-pill)',
            cursor: 'pointer',
            fontFamily: 'inherit',
            fontSize: 14,
          }}
        >
          {t('language')}
        </motion.button>
        <motion.button
          whileHover={{ scale: 1.04, background: 'var(--amber-dark)' }}
          whileTap={{ scale: 0.96 }}
          style={{
            background: 'var(--amber)',
            color: 'white',
            border: 'none',
            padding: '9px 22px',
            borderRadius: 'var(--radius-pill)',
            cursor: 'pointer',
            fontWeight: 700,
            fontFamily: 'inherit',
            fontSize: 14,
          }}
        >
          {t('download_app')}
        </motion.button>
      </motion.div>
    </motion.header>
  )
}

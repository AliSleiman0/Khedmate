import { useRef } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, useScroll, useTransform } from 'framer-motion'
import { fadeInUp, staggerContainer } from '../../animations/variants'

function AppleIcon() {
  return (
    <svg width="18" height="20" viewBox="0 0 814 1000" fill="white" xmlns="http://www.w3.org/2000/svg"
      style={{ display: 'inline', verticalAlign: 'middle', marginInlineEnd: 8 }}>
      <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105.3-57.6-155.5-127.4C46 696.3 0 591.8 0 492.5 0 307.1 113.4 209.4 224.6 209.4c61 0 111.6 40.2 149.4 40.2 36 0 92.7-42.4 161.3-42.4 25.8 0 108.2 2.6 168.4 74.9zm-126.7-93.6c-28.2 33.3-76.2 59.3-124.2 59.3-5.8 0-11.6-.6-17.4-1.9 1.3-53.4 30.2-108.1 59.4-143.4 31.5-37.2 83.2-65.8 127.4-67.1 3.8 53.5-15 105-45.2 153.1z"/>
    </svg>
  )
}

function AndroidIcon() {
  return (
    <svg width="18" height="20" viewBox="0 0 24 24" fill="white" xmlns="http://www.w3.org/2000/svg"
      style={{ display: 'inline', verticalAlign: 'middle', marginInlineEnd: 8 }}>
      <path d="M17.523 15.341A5 5 0 0 0 17 13V9a5 5 0 0 0-10 0v4a5 5 0 0 0-.523 2.341A2 2 0 0 0 5 17v1a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-1a2 2 0 0 0-1.477-1.659zM8.5 7.5a.5.5 0 1 1 1 0 .5.5 0 0 1-1 0zm6 0a.5.5 0 1 1 1 0 .5.5 0 0 1-1 0zM3 11v2a1 1 0 0 0 2 0v-2a1 1 0 0 0-2 0zm16 0v2a1 1 0 0 0 2 0v-2a1 1 0 0 0-2 0z"/>
    </svg>
  )
}

export default function Hero() {
  const { t } = useTranslation()
  const sectionRef = useRef<HTMLElement>(null)

  const { scrollYProgress } = useScroll({ target: sectionRef, offset: ['start start', 'end start'] })
  const isMobile = window.matchMedia('(max-width: 768px)').matches
  const bgY = useTransform(scrollYProgress, [0, 1], isMobile ? [0, 0] : [0, -80])

  const heroTitle = t('hero_title')
  const highlight = t('hero_title_highlight')
  const parts = heroTitle.split(highlight)
  const beforeWords = parts[0].split(' ').filter(Boolean)
  const afterWords = (parts[1] || '').split(' ').filter(Boolean)

  return (
    <section ref={sectionRef} style={{ position: 'relative', overflow: 'hidden', textAlign: 'center' }}>
      {/* Parallax background layer */}
      <motion.div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(150deg, var(--brown-primary) 0%, var(--brown-deep) 60%, #1A0800 100%)',
        y: bgY,
        willChange: 'transform',
        zIndex: 0,
      }} />

      {/* Ambient floating dots */}
      <motion.div
        aria-hidden="true"
        animate={{ y: [0, -18, 0] }}
        transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
        style={{
          position: 'absolute', top: '15%', insetInlineStart: '8%',
          width: 12, height: 12, borderRadius: '50%',
          background: 'var(--amber)', opacity: 0.35, zIndex: 0,
        }}
      />
      <motion.div
        aria-hidden="true"
        animate={{ y: [0, 12, 0] }}
        transition={{ duration: 5.5, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
        style={{
          position: 'absolute', top: '35%', insetInlineEnd: '10%',
          width: 8, height: 8, borderRadius: '50%',
          background: 'rgba(255,255,255,0.4)', opacity: 0.4, zIndex: 0,
        }}
      />
      <motion.div
        aria-hidden="true"
        animate={{ y: [0, -10, 0] }}
        transition={{ duration: 6.5, repeat: Infinity, ease: 'easeInOut', delay: 2.5 }}
        style={{
          position: 'absolute', top: '60%', insetInlineStart: '15%',
          width: 6, height: 6, borderRadius: '50%',
          background: 'var(--amber)', opacity: 0.25, zIndex: 0,
        }}
      />

      {/* Content */}
      <motion.div
        style={{ position: 'relative', zIndex: 1, padding: '120px 24px 0', color: 'white' }}
        variants={staggerContainer}
        initial="hidden"
        animate="visible"
      >
        {/* Logo badge */}
        <motion.div variants={fadeInUp} style={{ display: 'flex', justifyContent: 'center', marginBottom: 32 }}>
          <div style={{
            background: 'white',
            borderRadius: 20,
            padding: '10px 20px',
            display: 'inline-flex',
            alignItems: 'center',
            gap: 12,
            boxShadow: '0 8px 32px rgba(0,0,0,0.30)',
          }}>
            <img src="/logo.webp" alt="خدمتي" style={{ height: 48 }} />
            <span style={{ color: 'var(--brown-primary)', fontWeight: 800, fontSize: 26, letterSpacing: '-0.5px' }}>
              خدمتي
            </span>
          </div>
        </motion.div>

        {/* Word-split headline */}
        <motion.h1 style={{
          fontSize: 'clamp(38px, 6vw, 58px)',
          fontWeight: 700,
          lineHeight: 1.15,
          marginBottom: 24,
        }}>
          {beforeWords.map((word, i) => (
            <motion.span key={`b${i}`} variants={fadeInUp}
              style={{ display: 'inline-block', marginInlineEnd: '0.28em' }}>
              {word}
            </motion.span>
          ))}
          <motion.span variants={fadeInUp}
            style={{ display: 'inline-block', color: 'var(--amber)', marginInlineEnd: '0.28em' }}>
            {highlight}
          </motion.span>
          {afterWords.map((word, i) => (
            <motion.span key={`a${i}`} variants={fadeInUp}
              style={{ display: 'inline-block', marginInlineStart: i === 0 ? 0 : '0.28em' }}>
              {word}
            </motion.span>
          ))}
        </motion.h1>

        <motion.p variants={fadeInUp} style={{
          fontSize: 20, opacity: 0.88, maxWidth: 620,
          margin: '0 auto 48px', lineHeight: 1.7,
        }}>
          {t('hero_subtitle')}
        </motion.p>

        <motion.div variants={staggerContainer} style={{ display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
          <motion.button
            variants={fadeInUp}
            whileHover={{ scale: 1.05, background: 'var(--amber-dark)' }}
            whileTap={{ scale: 0.97 }}
            transition={{ type: 'spring', stiffness: 350, damping: 18 }}
            style={{
              background: 'var(--amber)', color: 'white', border: 'none',
              padding: '15px 40px', borderRadius: 'var(--radius-pill)',
              fontSize: 17, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
              display: 'flex', alignItems: 'center',
            }}
          >
            <AppleIcon />{t('download_ios')}
          </motion.button>

          <motion.button
            variants={fadeInUp}
            whileHover={{ scale: 1.05, background: 'rgba(255,255,255,0.18)' }}
            whileTap={{ scale: 0.97 }}
            transition={{ type: 'spring', stiffness: 350, damping: 18 }}
            style={{
              background: 'rgba(255,255,255,0.10)', color: 'white',
              border: '1.5px solid rgba(255,255,255,0.35)',
              padding: '15px 40px', borderRadius: 'var(--radius-pill)',
              fontSize: 17, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
              display: 'flex', alignItems: 'center',
            }}
          >
            <AndroidIcon />{t('download_android')}
          </motion.button>
        </motion.div>
      </motion.div>

      {/* Floating wave separator */}
      <motion.div
        initial={{ y: 0 }}
        animate={{ y: [0, -10, 0] }}
        transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
        style={{ marginTop: 64, lineHeight: 0, position: 'relative', zIndex: 1 }}
      >
        <svg viewBox="0 0 1440 80" preserveAspectRatio="none" style={{ width: '100%', height: 80, display: 'block' }}>
          <path d="M0,40 C360,80 1080,0 1440,40 L1440,80 L0,80 Z" fill="var(--surface-warm)" />
        </svg>
      </motion.div>
    </section>
  )
}

import { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
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
  const [isMobile, setIsMobile] = useState(window.innerWidth < 900)

  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth < 900)
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])

  const heroTitle = t('hero_title')
  const highlight = t('hero_title_highlight')
  const parts = heroTitle.split(highlight)
  const beforeWords = parts[0].split(' ').filter(Boolean)
  const afterWords = (parts[1] || '').split(' ').filter(Boolean)

  return (
    <section style={{
      position: 'relative',
      overflow: 'hidden',
      background: 'linear-gradient(135deg, #1B4F72 0%, #0D3050 100%)',
      padding: 0,
    }}>
      <div style={{
        maxWidth: 1200,
        margin: '0 auto',
        padding: isMobile ? '80px 24px 0' : '100px 48px 0',
        display: 'flex',
        alignItems: 'center',
        gap: 64,
        flexDirection: 'row',
      }}>
        {/* Text column */}
        <motion.div
          style={{ flex: 1, color: 'white', textAlign: isMobile ? 'center' : 'start', zIndex: 1 }}
          variants={staggerContainer}
          initial="hidden"
          animate="visible"
        >
          {/* Logo badge */}
          <motion.div variants={fadeInUp} style={{ display: 'flex', justifyContent: isMobile ? 'center' : 'flex-start', marginBottom: 32 }}>
            <div style={{
              background: 'white',
              borderRadius: 20,
              padding: '8px 18px',
              display: 'inline-flex',
              alignItems: 'center',
              gap: 12,
              boxShadow: '0 8px 32px rgba(0,0,0,0.25)',
            }}>
              <img src="/logo.webp" alt="خدمتي" style={{ height: 44 }} />
              <span style={{ color: '#1B4F72', fontWeight: 800, fontSize: 24, letterSpacing: '-0.5px' }}>
                خدمتي
              </span>
            </div>
          </motion.div>

          {/* Headline */}
          <motion.h1 style={{
            fontSize: 'clamp(34px, 5vw, 56px)',
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
            fontSize: 19, opacity: 0.88, maxWidth: 500,
            margin: isMobile ? '0 auto 40px' : '0 0 40px', lineHeight: 1.7,
          }}>
            {t('hero_subtitle')}
          </motion.p>

          <motion.div variants={staggerContainer} style={{
            display: 'flex', gap: 14, flexWrap: 'wrap',
            justifyContent: isMobile ? 'center' : 'flex-start',
          }}>
            <motion.button
              variants={fadeInUp}
              whileHover={{ scale: 1.05, background: 'var(--amber-dark)' }}
              whileTap={{ scale: 0.97 }}
              transition={{ type: 'spring', stiffness: 350, damping: 18 }}
              style={{
                background: 'var(--amber)', color: 'white', border: 'none',
                padding: '14px 36px', borderRadius: 'var(--radius-pill)',
                fontSize: 16, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
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
                padding: '14px 36px', borderRadius: 'var(--radius-pill)',
                fontSize: 16, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
                display: 'flex', alignItems: 'center',
              }}
            >
              <AndroidIcon />{t('download_android')}
            </motion.button>
          </motion.div>
        </motion.div>

        {/* Image column — desktop only */}
        {!isMobile && (
          <motion.div
            initial={{ opacity: 0, x: 60 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1], delay: 0.2 }}
            style={{ flexShrink: 0, width: 440 }}
          >
            <img
              src="/hero.jpg"
              alt="Professional home service"
              style={{
                width: '100%',
                height: 480,
                objectFit: 'cover',
                borderRadius: 24,
                boxShadow: '0 32px 64px rgba(0,0,0,0.35)',
                display: 'block',
              }}
            />
          </motion.div>
        )}
      </div>

      {/* Wave separator */}
      <div style={{ marginTop: 72, lineHeight: 0, position: 'relative', zIndex: 1 }}>
        <svg viewBox="0 0 1440 80" preserveAspectRatio="none" style={{ width: '100%', height: 80, display: 'block' }}>
          <path d="M0,40 C360,80 1080,0 1440,40 L1440,80 L0,80 Z" fill="white" />
        </svg>
      </div>
    </section>
  )
}

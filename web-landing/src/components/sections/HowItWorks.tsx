import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import AnimatedSection from '../ui/AnimatedSection'
import { fadeInUp, fadeIn, scaleIn, springBounce } from '../../animations/variants'

function SearchIcon() {
  return (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
    </svg>
  )
}

function CalendarIcon() {
  return (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
      <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
      <line x1="3" y1="10" x2="21" y2="10"/>
    </svg>
  )
}

function CheckCircleIcon() {
  return (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
      <polyline points="22 4 12 14.01 9 11.01"/>
    </svg>
  )
}

function ChevronIcon({ flip }: { flip: boolean }) {
  return (
    <motion.span
      variants={fadeIn}
      transition={{ delay: 0.5 }}
      style={{ flexShrink: 0, alignSelf: 'center', display: 'flex' }}
    >
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="rgba(27,79,114,0.35)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
        style={{ transform: flip ? 'scaleX(-1)' : 'none' }}>
        <polyline points="9 18 15 12 9 6"/>
      </svg>
    </motion.span>
  )
}

const STEP_ICONS = [<SearchIcon />, <CalendarIcon />, <CheckCircleIcon />]

export default function HowItWorks() {
  const { t, i18n } = useTranslation()
  const steps = [
    { num: 1, title: t('step1_title'), desc: t('step1_desc') },
    { num: 2, title: t('step2_title'), desc: t('step2_desc') },
    { num: 3, title: t('step3_title'), desc: t('step3_desc') },
  ]
  const isLtr = i18n.language !== 'ar'

  return (
    <section id="how-it-works" style={{ background: 'var(--surface)' }}>
      <motion.h2
        variants={fadeInUp}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        style={{ fontSize: 38, fontWeight: 700, color: 'var(--brand-blue)', textAlign: 'center', marginBottom: 12 }}
      >
        {t('how_it_works')}
      </motion.h2>
      <motion.div
        variants={scaleIn}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        style={{ width: 60, height: 4, borderRadius: 2, background: 'var(--amber)', margin: '0 auto 52px' }}
      />

      <AnimatedSection stagger="slow" style={{ display: 'flex', gap: 0, justifyContent: 'center', flexWrap: 'wrap', alignItems: 'center' }}>
        {steps.flatMap((s, i) => {
          const card = (
            <motion.div key={s.num} variants={fadeInUp} style={{
              background: 'white',
              borderRadius: 'var(--radius-card)',
              padding: '40px 28px',
              width: 280,
              boxShadow: '0 4px 24px rgba(27,79,114,0.08)',
              position: 'relative',
              margin: '8px 0',
            }}>
              <motion.div
                variants={springBounce}
                style={{
                  position: 'absolute',
                  top: -22,
                  insetInlineStart: -22,
                  width: 44,
                  height: 44,
                  borderRadius: '50%',
                  background: 'var(--brand-blue)',
                  color: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 700,
                  fontSize: 20,
                  boxShadow: '0 4px 12px rgba(27,79,114,0.30)',
                }}
              >{s.num}</motion.div>

              <motion.div
                whileHover={{ rotate: 15, scale: 1.1 }}
                transition={{ type: 'spring', stiffness: 400, damping: 12 }}
                style={{
                  width: 72,
                  height: 72,
                  borderRadius: '50%',
                  background: '#EBF3FB',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  margin: '0 auto 20px',
                }}
              >
                {STEP_ICONS[i]}
              </motion.div>

              <h3 style={{ margin: '0 0 10px', color: 'var(--brand-blue)', fontSize: 18, fontWeight: 700, textAlign: 'center' }}>
                {s.title}
              </h3>
              <p style={{ color: 'var(--text-secondary)', textAlign: 'center', lineHeight: 1.6 }}>{s.desc}</p>
            </motion.div>
          )
          if (i < steps.length - 1) {
            return [card, <ChevronIcon key={`arrow-${i}`} flip={!isLtr} />]
          }
          return [card]
        })}
      </AnimatedSection>
    </section>
  )
}

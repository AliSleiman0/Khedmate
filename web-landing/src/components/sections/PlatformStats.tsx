import { useState, useEffect, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, useInView } from 'framer-motion'
import AnimatedSection from '../ui/AnimatedSection'
import { fadeInUp } from '../../animations/variants'

interface StatsData {
  totalBookings: number
  totalProviders: number
  avgRating: number
  citiesCovered: number
}

function useCountUp(target: number, duration: number, started: boolean) {
  const [count, setCount] = useState(0)
  const rafRef = useRef<number>(0)

  useEffect(() => {
    if (!started || target === 0) return
    const start = performance.now()
    const easeOutQuart = (t: number) => 1 - Math.pow(1 - t, 4)

    const tick = (now: number) => {
      const elapsed = now - start
      const progress = Math.min(elapsed / duration, 1)
      setCount(Math.round(easeOutQuart(progress) * target))
      if (progress < 1) {
        rafRef.current = requestAnimationFrame(tick)
      }
    }
    rafRef.current = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(rafRef.current)
  }, [target, duration, started])

  return count
}

function StatCard({
  value,
  suffix,
  label,
  started,
  isDecimal,
}: {
  value: number
  suffix: string
  label: string
  started: boolean
  isDecimal?: boolean
}) {
  const { i18n } = useTranslation()
  const count = useCountUp(isDecimal ? Math.round(value * 10) : value, 1500, started)
  const display = isDecimal
    ? new Intl.NumberFormat(i18n.language, { minimumFractionDigits: 1, maximumFractionDigits: 1 }).format(count / 10)
    : new Intl.NumberFormat(i18n.language).format(count)

  return (
    <motion.div
      variants={fadeInUp}
      style={{
        background: 'white',
        borderRadius: 'var(--radius-card)',
        padding: '36px 24px',
        textAlign: 'center',
        boxShadow: '0 4px 20px var(--shadow-brown)',
        border: '1px solid var(--cream-border)',
      }}
    >
      <div style={{ fontSize: 48, fontWeight: 700, color: 'var(--brown-primary)', lineHeight: 1 }}>
        {display}
        <span style={{ color: 'var(--amber)', fontSize: 32 }}>{suffix}</span>
      </div>
      <p style={{ fontSize: 15, color: 'var(--text-secondary)', marginTop: 10 }}>{label}</p>
    </motion.div>
  )
}

const FALLBACK: StatsData = { totalBookings: 1200, totalProviders: 350, avgRating: 4.8, citiesCovered: 6 }

export default function PlatformStats() {
  const { t } = useTranslation()
  const [stats, setStats] = useState<StatsData>(FALLBACK)
  const sectionRef = useRef<HTMLElement>(null)
  const inView = useInView(sectionRef, { once: true, amount: 0.2 })

  useEffect(() => {
    fetch('/api/landing/stats')
      .then(r => r.ok ? r.json() : Promise.reject())
      .then((data: { success: boolean; data: StatsData }) => setStats(data.data ?? data))
      .catch(() => { /* keep fallback values */ })
  }, [])

  return (
    <section ref={sectionRef} style={{ background: 'var(--cream-warm)' }}>
      <motion.h2
        variants={fadeInUp}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        style={{ fontSize: 38, fontWeight: 700, color: 'var(--brown-primary)', textAlign: 'center', marginBottom: 12 }}
      >
        {t('stats_title')}
      </motion.h2>
      <motion.div
        variants={fadeInUp}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        style={{ width: 60, height: 4, borderRadius: 2, background: 'var(--amber)', margin: '0 auto 52px' }}
      />
      <AnimatedSection stagger="normal" style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 24,
        maxWidth: 900,
        margin: '0 auto',
      }}>
        <StatCard value={stats.totalBookings} suffix="+" label={t('stats_bookings')} started={inView} />
        <StatCard value={stats.totalProviders} suffix="+" label={t('stats_providers')} started={inView} />
        <StatCard value={stats.avgRating} suffix="⭐" label={t('stats_rating')} started={inView} isDecimal />
        <StatCard value={stats.citiesCovered} suffix="+" label={t('stats_cities')} started={inView} />
      </AnimatedSection>
    </section>
  )
}

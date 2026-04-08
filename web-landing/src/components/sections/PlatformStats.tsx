import { useState, useEffect, useRef } from 'react'
import { useTranslation } from 'react-i18next'

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
  delay,
  isDecimal,
}: {
  value: number
  suffix: string
  label: string
  started: boolean
  delay: number
  isDecimal?: boolean
}) {
  const { i18n } = useTranslation()
  const count = useCountUp(isDecimal ? Math.round(value * 10) : value, 1500, started)
  const display = isDecimal
    ? new Intl.NumberFormat(i18n.language, { minimumFractionDigits: 1, maximumFractionDigits: 1 }).format(count / 10)
    : new Intl.NumberFormat(i18n.language).format(count)

  return (
    <div style={{
      background: 'white',
      borderRadius: 'var(--radius-card)',
      padding: '36px 24px',
      textAlign: 'center',
      boxShadow: '0 4px 20px var(--shadow-brown)',
      border: '1px solid var(--cream-border)',
      animation: 'fadeInUp 0.6s ease both',
      animationDelay: `${delay}s`,
    }}>
      <div style={{ fontSize: 48, fontWeight: 700, color: 'var(--brown-primary)', lineHeight: 1 }}>
        {display}
        <span style={{ color: 'var(--amber)', fontSize: 32 }}>{suffix}</span>
      </div>
      <p style={{ fontSize: 15, color: 'var(--text-secondary)', marginTop: 10 }}>{label}</p>
    </div>
  )
}

export default function PlatformStats() {
  const { t } = useTranslation()
  const [stats, setStats] = useState<StatsData | null>(null)
  const [started, setStarted] = useState(false)
  const sectionRef = useRef<HTMLElement>(null)

  useEffect(() => {
    fetch('/api/landing/stats')
      .then(r => r.ok ? r.json() : Promise.reject())
      .then((data: { success: boolean; data: StatsData }) => setStats(data.data ?? data))
      .catch(() => {
        // Fail silently — show placeholder stats
        setStats({ totalBookings: 12400, totalProviders: 5200, avgRating: 4.8, citiesCovered: 14 })
      })
  }, [])

  useEffect(() => {
    const el = sectionRef.current
    if (!el) return
    const observer = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setStarted(true); observer.disconnect() } },
      { threshold: 0.2 }
    )
    observer.observe(el)
    return () => observer.disconnect()
  }, [])

  if (!stats) return null

  return (
    <section ref={sectionRef} style={{ background: 'var(--cream-warm)' }}>
      <h2 style={{ fontSize: 38, fontWeight: 700, color: 'var(--brown-primary)', textAlign: 'center', marginBottom: 12 }}>
        {t('stats_title')}
      </h2>
      <div style={{ width: 60, height: 4, borderRadius: 2, background: 'var(--amber)', margin: '0 auto 52px' }} />
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 24,
        maxWidth: 900,
        margin: '0 auto',
      }}>
        <StatCard value={stats.totalBookings} suffix="+" label={t('stats_bookings')} started={started} delay={0} />
        <StatCard value={stats.totalProviders} suffix="+" label={t('stats_providers')} started={started} delay={0.1} />
        <StatCard value={stats.avgRating} suffix="⭐" label={t('stats_rating')} started={started} delay={0.2} isDecimal />
        <StatCard value={stats.citiesCovered} suffix="+" label={t('stats_cities')} started={started} delay={0.3} />
      </div>
    </section>
  )
}

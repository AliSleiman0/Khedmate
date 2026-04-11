import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import AnimatedSection from '../ui/AnimatedSection'
import { fadeInUp } from '../../animations/variants'

const SERVICE_ICONS: Record<string, string> = {
  cleaning: '🧹', plumbing: '🔧', electrical: '⚡',
  moving: '🚛', painting: '🎨', ac: '❄️',
}

function ServiceCard({ serviceKey }: { serviceKey: string }) {
  const { t } = useTranslation()

  return (
    <motion.div
      variants={fadeInUp}
      whileHover={{ y: -6, boxShadow: '0 12px 32px var(--shadow-brown-lg)', borderColor: 'var(--brown-primary)' }}
      whileTap={{ scale: 0.97 }}
      transition={{ type: 'spring', stiffness: 300, damping: 20 }}
      style={{
        background: 'var(--surface-warm)',
        borderRadius: 'var(--radius-card)',
        padding: '32px 20px',
        cursor: 'pointer',
        boxShadow: '0 2px 8px var(--shadow-brown)',
        border: '3px solid transparent',
        textAlign: 'center',
        willChange: 'transform',
      }}
    >
      <motion.div
        whileHover={{ background: 'var(--brown-primary)', scale: 1.08 }}
        transition={{ duration: 0.18 }}
        style={{
          width: 80,
          height: 80,
          borderRadius: '50%',
          background: 'var(--cream-warm)',
          border: '2px solid var(--cream-border)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto 16px',
        }}
      >
        <motion.span
          whileHover={{ filter: 'brightness(0) invert(1)' }}
          transition={{ duration: 0.15 }}
          style={{ fontSize: 36 }}
        >
          {SERVICE_ICONS[serviceKey]}
        </motion.span>
      </motion.div>
      <motion.p
        whileHover={{ color: 'var(--brown-primary)' }}
        style={{ marginTop: 4, fontWeight: 700, fontSize: 15, color: 'var(--text-primary)' }}
      >
        {t(serviceKey)}
      </motion.p>
    </motion.div>
  )
}

export default function Services() {
  const { t } = useTranslation()
  const services = ['cleaning', 'plumbing', 'electrical', 'moving', 'painting', 'ac']

  return (
    <section id="services" style={{ background: 'white', textAlign: 'center' }}>
      <motion.h2
        variants={fadeInUp}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        style={{ fontSize: 38, fontWeight: 700, color: 'var(--brown-primary)', marginBottom: 12 }}
      >
        {t('services')}
      </motion.h2>
      <motion.div
        variants={fadeInUp}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        style={{ width: 60, height: 4, borderRadius: 2, background: 'var(--amber)', margin: '0 auto 52px' }}
      />
      <AnimatedSection stagger="fast" style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
        gap: 20,
        maxWidth: 900,
        margin: '0 auto',
      }}>
        {services.map(s => <ServiceCard key={s} serviceKey={s} />)}
      </AnimatedSection>
    </section>
  )
}

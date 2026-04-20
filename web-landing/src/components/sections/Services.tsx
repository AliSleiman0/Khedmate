import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import AnimatedSection from '../ui/AnimatedSection'
import { fadeInUp } from '../../animations/variants'

function CleaningIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 3H5a2 2 0 0 0-2 2v4m6-6h10a2 2 0 0 1 2 2v4M9 3v18m0 0h10a2 2 0 0 0 2-2v-4M9 21H5a2 2 0 0 1-2-2v-4m0 0h18"/>
      <path d="M12 12h.01"/>
    </svg>
  )
}

function PlumbingIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>
    </svg>
  )
}

function ElectricalIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
    </svg>
  )
}

function MovingIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <rect x="1" y="3" width="15" height="13" rx="2"/>
      <path d="M16 8h4l3 5v3h-7V8z"/>
      <circle cx="5.5" cy="18.5" r="2.5"/>
      <circle cx="18.5" cy="18.5" r="2.5"/>
    </svg>
  )
}

function PaintingIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 13.5V19a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-5.5"/>
      <path d="M12 2a4 4 0 0 0-4 4v1h8V6a4 4 0 0 0-4-4z"/>
      <path d="M8 7v6a4 4 0 0 0 8 0V7"/>
    </svg>
  )
}

function AcIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--brand-blue)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="2" x2="12" y2="6"/>
      <line x1="12" y1="18" x2="12" y2="22"/>
      <line x1="4.93" y1="4.93" x2="7.76" y2="7.76"/>
      <line x1="16.24" y1="16.24" x2="19.07" y2="19.07"/>
      <line x1="2" y1="12" x2="6" y2="12"/>
      <line x1="18" y1="12" x2="22" y2="12"/>
      <line x1="4.93" y1="19.07" x2="7.76" y2="16.24"/>
      <line x1="16.24" y1="7.76" x2="19.07" y2="4.93"/>
      <circle cx="12" cy="12" r="4"/>
    </svg>
  )
}

const SERVICE_ICONS: Record<string, JSX.Element> = {
  cleaning: <CleaningIcon />,
  plumbing: <PlumbingIcon />,
  electrical: <ElectricalIcon />,
  moving: <MovingIcon />,
  painting: <PaintingIcon />,
  ac: <AcIcon />,
}

function ServiceCard({ serviceKey }: { serviceKey: string }) {
  const { t } = useTranslation()

  return (
    <motion.div
      variants={fadeInUp}
      whileHover={{ y: -6, boxShadow: '0 12px 32px rgba(27,79,114,0.16)', borderColor: 'var(--brand-blue)' }}
      whileTap={{ scale: 0.97 }}
      transition={{ type: 'spring', stiffness: 300, damping: 20 }}
      style={{
        background: 'white',
        borderRadius: 'var(--radius-card)',
        padding: '32px 20px',
        cursor: 'pointer',
        boxShadow: '0 2px 8px rgba(27,79,114,0.08)',
        border: '2px solid transparent',
        textAlign: 'center',
        willChange: 'transform',
      }}
    >
      <div style={{
        width: 80,
        height: 80,
        borderRadius: '50%',
        background: '#EBF3FB',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        margin: '0 auto 16px',
      }}>
        {SERVICE_ICONS[serviceKey]}
      </div>
      <p style={{ marginTop: 4, fontWeight: 700, fontSize: 15, color: 'var(--text-primary)' }}>
        {t(serviceKey)}
      </p>
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
        style={{ fontSize: 38, fontWeight: 700, color: 'var(--brand-blue)', marginBottom: 12 }}
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

import { motion } from 'framer-motion'
import { staggerContainer, staggerContainerFast, staggerContainerSlow } from '../../animations/variants'

interface AnimatedSectionProps {
  children: React.ReactNode
  stagger?: 'fast' | 'normal' | 'slow'
  amount?: number
  style?: React.CSSProperties
  as?: 'div' | 'ul' | 'ol'
}

const STAGGER_MAP = {
  fast: staggerContainerFast,
  normal: staggerContainer,
  slow: staggerContainerSlow,
}

export default function AnimatedSection({
  children,
  stagger = 'normal',
  amount = 0.15,
  style,
  as = 'div',
}: AnimatedSectionProps) {
  const MotionEl = motion[as]
  return (
    <MotionEl
      variants={STAGGER_MAP[stagger]}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, amount }}
      style={style}
    >
      {children}
    </MotionEl>
  )
}

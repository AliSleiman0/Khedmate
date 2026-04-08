import type { Variants } from 'framer-motion'

const EASE_OUT_EXPO = [0.22, 1, 0.36, 1] as const

// ─── Core reveal variants ─────────────────────────────────────────────────────

export const fadeInUp: Variants = {
  hidden: { opacity: 0, y: 28 },
  visible: {
    opacity: 1, y: 0,
    transition: { duration: 0.6, ease: EASE_OUT_EXPO },
  },
}

export const fadeIn: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { duration: 0.5, ease: 'easeOut' },
  },
}

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.85 },
  visible: {
    opacity: 1, scale: 1,
    transition: { duration: 0.5, ease: EASE_OUT_EXPO },
  },
}

export const slideInLeft: Variants = {
  hidden: { opacity: 0, x: -60 },
  visible: {
    opacity: 1, x: 0,
    transition: { duration: 0.6, ease: EASE_OUT_EXPO },
  },
}

export const slideInRight: Variants = {
  hidden: { opacity: 0, x: 60 },
  visible: {
    opacity: 1, x: 0,
    transition: { duration: 0.6, ease: EASE_OUT_EXPO },
  },
}

// ─── Spring variants ──────────────────────────────────────────────────────────

export const springBounce: Variants = {
  hidden: { opacity: 0, scale: 0 },
  visible: {
    opacity: 1, scale: 1,
    transition: { type: 'spring', stiffness: 400, damping: 15 },
  },
}

export const springScaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.6 },
  visible: {
    opacity: 1, scale: 1,
    transition: { type: 'spring', stiffness: 350, damping: 20 },
  },
}

// ─── Stagger containers ───────────────────────────────────────────────────────

export const staggerContainer: Variants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.1, delayChildren: 0.05 },
  },
}

export const staggerContainerFast: Variants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.07, delayChildren: 0 },
  },
}

export const staggerContainerSlow: Variants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.15, delayChildren: 0.1 },
  },
}

// ─── Looping / ambient (used in motion.div animate prop directly) ─────────────

export const floatY = {
  y: [0, -14, 0],
  transition: { duration: 3.5, repeat: Infinity, ease: 'easeInOut' as const },
}

export const waveFloat = {
  y: [0, -6, 0],
  transition: { duration: 4, repeat: Infinity, ease: 'easeInOut' as const },
}

// ─── RTL-aware directional helper ────────────────────────────────────────────

export function getDirectionalVariants(dir: 'ltr' | 'rtl') {
  return {
    slideInStart: {
      hidden: { x: dir === 'rtl' ? 60 : -60, opacity: 0 },
      visible: {
        x: 0, opacity: 1,
        transition: { duration: 0.6, ease: EASE_OUT_EXPO },
      },
    } as Variants,
    slideInEnd: {
      hidden: { x: dir === 'rtl' ? -60 : 60, opacity: 0 },
      visible: {
        x: 0, opacity: 1,
        transition: { duration: 0.6, ease: EASE_OUT_EXPO },
      },
    } as Variants,
  }
}

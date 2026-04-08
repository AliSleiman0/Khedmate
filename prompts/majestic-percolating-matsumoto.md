# Plan: Framer Motion Animation System — web-landing

## Context
The landing page has basic CSS `@keyframes` animations and manual `onMouseEnter/Leave` hover state via `useState`. This is a full upgrade to a Framer Motion v11 animation system — replacing all manual animation code with a shared variants library, a reusable stagger wrapper, and per-section premium animations including Hero parallax, word-split headline, scroll-triggered stagger reveals, `AnimatePresence` form transitions, and `useMotionValue`-based header scroll effects.

---

## Library Choice: `framer-motion@^11`

Over alternatives:
- **`motion` (standalone)** — too new, React integration (`motion/react`) not production-stable yet
- **`@react-spring/web`** — lacks `whileInView`, `AnimatePresence`, `useScroll`/`useTransform`
- **GSAP** — paid licence for ScrollTrigger; overkill for a marketing page
- **Framer Motion v11** ✓ — exact API surface needed, ~30-40KB gzipped, tree-shakeable

Install: `npm install framer-motion@^11`

---

## New Files to Create

### `src/animations/variants.ts`
Shared animation variant definitions used by all components:

```ts
const EASE_OUT_EXPO = [0.22, 1, 0.36, 1]

export const fadeInUp    // { hidden: { opacity:0, y:28 }, visible: { opacity:1, y:0, duration:0.6 } }
export const fadeIn      // { hidden: { opacity:0 }, visible: { opacity:1, duration:0.5 } }
export const scaleIn     // { hidden: { opacity:0, scale:0.85 }, visible: { opacity:1, scale:1 } }
export const slideInLeft // { hidden: { opacity:0, x:-60 }, visible: { opacity:1, x:0 } }
export const slideInRight// { hidden: { opacity:0, x:60 }, visible: { opacity:1, x:0 } }
export const springBounce// { hidden: { opacity:0, scale:0 }, visible spring: stiffness:400, damping:15 }
export const springScaleIn// { hidden: { opacity:0, scale:0.6 }, visible spring: stiffness:350, damping:20 }
export const staggerContainer     // { visible: { staggerChildren:0.1, delayChildren:0.05 } }
export const staggerContainerFast // staggerChildren:0.07
export const staggerContainerSlow // staggerChildren:0.15, delayChildren:0.1
export const floatY      // animate prop: y:[0,-14,0], repeat:Infinity, 3.5s (for ambient dots)
export const waveFloat   // animate prop: y:[0,-6,0], repeat:Infinity, 4s (for wave SVG)

// RTL-aware directional helper
export function getDirectionalVariants(dir: 'ltr' | 'rtl') {
  // slideInStart: x = rtl ? +60 : -60 (slide from visual start)
  // slideInEnd:   x = rtl ? -60 : +60 (slide from visual end)
}
```

All easings use `EASE_OUT_EXPO = [0.22, 1, 0.36, 1]` for a premium feel.

### `src/components/ui/AnimatedSection.tsx`
Reusable scroll-triggered stagger container. Used in 6 sections:

```tsx
// Props: stagger: 'fast'|'normal'|'slow', amount: number (threshold), style, as: 'div'|'ul'|'ol'
// Renders: motion[as] with variants=STAGGER_MAP[stagger], initial="hidden",
//          whileInView="visible", viewport={{ once:true, amount }}
// Children: supply their own variants (e.g. fadeInUp) — stagger cascades automatically
```

---

## Modified Files

### `src/App.tsx`
- Wrap entire return in `<MotionConfig reducedMotion="user">` from `framer-motion`
- `reducedMotion="user"` reads OS `prefers-reduced-motion` — zero-cost accessibility

### `src/styles/globals.css`
- **Remove** the `@keyframes fadeInUp { ... }` block
- **Remove** the `@keyframes pulse { ... }` block
- Keep `--transition-base: 0.18s ease` (still used by base link styles)

### `src/components/layout/Header.tsx`
**Remove:** `useState(scrolled)`, `useEffect` scroll listener, `transition: background 0.3s ease, box-shadow 0.3s ease'` in inline style, all `onMouseEnter/Leave` handlers.

**Add:**
- `const { scrollY } = useScroll()` — tracks window scroll, **zero React re-renders** (compositor thread)
- `const headerBg = useTransform(scrollY, [0, 60], ['rgba(59,23,4,1)', 'rgba(59,23,4,0.92)'])`
- `const headerBlur = useTransform(scrollY, [0, 60], ['blur(0px) saturate(100%)', 'blur(16px) saturate(180%)'])`
- `const headerShadow = useTransform(scrollY, [0, 60], ['0 2px 20px rgba(59,23,4,0)', '0 2px 20px rgba(59,23,4,0.20)'])`
- `<motion.header style={{ background: headerBg, backdropFilter: headerBlur, boxShadow: headerShadow }}>` — driven entirely by motion values
- Logo div + nav links: mount animation `initial={{ opacity:0, y:-10 }} animate={{ opacity:1, y:0 }}` with stagger via index delay `transition={{ delay: index * 0.06 }}`
- Nav `<motion.a>` links: `whileHover={{ color:'white' }}` replaces `onMouseEnter/Leave`
- Buttons: `<motion.button whileHover={{ scale:1.04 }} whileTap={{ scale:0.97 }}>` + set `background` change via `whileHover` on amber button

### `src/components/sections/Hero.tsx`
**Remove:** All `animation: 'fadeInUp...'` inline style properties. `onMouseEnter/Leave` on buttons.

**Add (complex — most novel section):**

**Parallax background:**
```tsx
const sectionRef = useRef<HTMLElement>(null)
const { scrollYProgress } = useScroll({ target: sectionRef, offset: ['start start', 'end start'] })
const isMobile = window.matchMedia('(max-width: 768px)').matches
const bgY = useTransform(scrollYProgress, [0, 1], isMobile ? [0, 0] : [0, -80])

// Render as position:absolute div with y={bgY}, willChange:'transform'
// Content div position:relative zIndex:1 — not affected by parallax, no layout shift
```

**Word-split headline:**
```tsx
// Split hero_title string on the highlight word
// Render each word of parts[0] and parts[1] as <motion.span variants={fadeInUp} style={{ display:'inline-block' }}>
// Highlight word also motion.span with fadeInUp + color:var(--amber)
// All inside a staggerContainer motion.div with initial="hidden" animate="visible"
// Filter empty strings with .filter(Boolean) after split(' ')
```

**Ambient floating dots (aria-hidden):**
```tsx
// 2 position:absolute motion.div circles, animate={{ y:[0,-18,0] }}, repeat:Infinity
// Positioned at top:15% insetInlineStart:8% (amber dot) and top:35% insetInlineEnd:10% (white dot)
// zIndex:0, opacity:0.35/0.4 — purely decorative
```

**Buttons:** `<motion.button variants={fadeInUp} whileHover={{ scale:1.05 }} whileTap={{ scale:0.97 }}>` for both iOS and Android. Background color change via `whileHover={{ background: '...' }}`.

**Wave SVG:** Wrap in `<motion.div animate={waveFloat}>` for a subtle perpetual float.

**RTL:** `marginInlineStart/End` for word spacing in split headline — direction-aware automatically.

### `src/components/sections/HowItWorks.tsx`
**Remove:** `animation` + `animationDelay` from card `style` props.

**Add:**
- Section title: `<motion.h2 variants={fadeInUp} initial="hidden" whileInView="visible" viewport={{ once:true }}>`
- Amber underline bar: `<motion.div variants={scaleIn} ...>`
- Cards container: `<AnimatedSection stagger="slow" style={{ display:'flex', ... }}>`
- Each card: `<motion.div variants={fadeInUp}>` — stagger cascades from AnimatedSection
- Step number badge: `<motion.div variants={springBounce}>` — spring-bounces in after card appears
- Icon circle: `<motion.div whileHover={{ rotate:15, scale:1.1 }} transition={{ type:'spring', stiffness:400, damping:12 }}>` — rotates on hover
- Connector chevrons: wrapped in `<motion.span variants={fadeIn} transition={{ delay:0.5 }}>` — appear after cards settle

### `src/components/sections/Services.tsx`
**Remove:** Entire `useState(hovered)` pattern in `ServiceCard`, all `onMouseEnter/Leave`, all conditional style properties.

**Replace `ServiceCard`:**
```tsx
// Outer card: motion.div variants={fadeInUp} whileHover={{ y:-6, boxShadow:'...', borderColor:'var(--brown-primary)' }}
//             whileTap={{ scale:0.97 }} transition={{ type:'spring', stiffness:300, damping:20 }}
// Icon circle: motion.div whileHover={{ background:'var(--brown-primary)', scale:1.08 }} — independent zone
// Emoji span:  motion.span whileHover={{ filter:'brightness(0) invert(1)' }} transition={{ duration:0.15 }}
// Label p:     motion.p whileHover={{ color:'var(--brown-primary)' }}
```
- Grid container: `<AnimatedSection stagger="fast" style={{ display:'grid', ... }}>`
- Note: nested `whileHover` on child `motion.div` fires independently from parent — gives a two-zone hover effect (whole card lifts when anything hovered; icon scales more when mouse directly over icon)

### `src/components/sections/TrustBadges.tsx`
**Remove:** Nothing (section had no animation).

**Add:**
- Section title: `whileInView` `fadeInUp`, `viewport={{ once:true, amount:0.3 }}`
- Badge container: `<AnimatedSection stagger="fast">`
- Each badge: `<motion.div variants={fadeInUp} whileHover={{ scale:1.06, filter:'brightness(1.15)' }} whileTap={{ scale:0.96 }}>`

### `src/components/sections/PlatformStats.tsx`
**Remove:** `useRef(sectionRef)` for IntersectionObserver, `useEffect` with IntersectionObserver, `useState(started)` and `setStarted`, `animation` + `animationDelay` CSS on `StatCard`.

**Replace IntersectionObserver with `useInView`:**
```tsx
const sectionRef = useRef<HTMLElement>(null)
const inView = useInView(sectionRef, { once: true, amount: 0.2 })  // from framer-motion
// Pass inView directly as `started` prop to each StatCard — drop started/setStarted entirely
```
- `useCountUp` hook preserved exactly as-is (only trigger source changes)
- StatCard: `<motion.div variants={fadeInUp}>` — no `animationDelay` needed, stagger handles it
- Grid container: `<AnimatedSection stagger="normal">`
- Remove `delay` prop from `StatCard`

### `src/components/sections/ProviderCTA.tsx`
**Remove:** `useState(btnHovered)`, `onMouseEnter/Leave` on button.

**Add:**
```tsx
const dir = i18n.language === 'ar' ? 'rtl' : 'ltr'
const dv = getDirectionalVariants(dir)  // from variants.ts

// Text column: motion.div variants={dv.slideInStart} initial="hidden" whileInView="visible" viewport={{ once:true, amount:0.2 }}
// Stats row: motion.div variants={staggerContainer} initial="hidden" whileInView="visible" — each stat: motion.div variants={fadeInUp}
// CTA button: motion.button whileHover={{ y:-2, boxShadow:'...', scale:1.02 }} whileTap={{ scale:0.97 }}
// Illustration column: motion.div variants={dv.slideInEnd} — slides in from opposite direction
```

Footer service links `whileHover={{ x: dir === 'rtl' ? -3 : 3 }}` — RTL-aware nudge.

### `src/components/sections/ContactForm.tsx`
**Remove:** `handleFocus`/`handleBlur` direct DOM style mutation functions, individual `onFocus`/`onBlur` style changes on inputs.

**Add:**
- `useState<string|null>(focusedField)` to track active input
- Each input wrapped in `<motion.div animate={{ boxShadow: focused ? '0 0 0 2px var(--brown-primary)' : '0 0 0 1px var(--cream-border)' }} transition={{ duration:0.18 }} style={{ borderRadius:12 }}>` — inputs use `border:'none'`, wrapper animates the ring
- Form card: `<motion.form variants={fadeInUp} initial="hidden" whileInView="visible" viewport={{ once:true, amount:0.2 }}>`
- Submit button: `<motion.button whileHover={!loading ? { scale:1.03, boxShadow:'...' } : {}} whileTap={!loading ? { scale:0.97 } : {}}>`
- **`AnimatePresence mode="wait"`** wrapping the form/success toggle:
  - Form: `<motion.form key="form" initial={{ opacity:0, y:20 }} animate={{ opacity:1, y:0 }} exit={{ opacity:0, y:-20 }}>`
  - Success: `<motion.div key="success" initial={{ opacity:0, scale:0.85 }} animate={{ opacity:1, scale:1 }} exit={{ opacity:0, scale:0.85 }}>`
  - Success SVG checkmark: its own spring bounce `initial={{ scale:0 }} animate={{ scale:1 }} transition={{ type:'spring', delay:0.15 }}`
  - `mode="wait"` ensures form fully exits before success enters — prevents overlap flash

### `src/components/layout/Footer.tsx`
**Remove:** All `onMouseEnter/Leave` handlers.

**Add:**
- 3 columns: `<AnimatedSection stagger="slow">` — each column `<motion.div variants={fadeInUp}>`
- Social icons: `<motion.a whileHover={{ scale:1.2, background:'rgba(255,255,255,0.22)' }} whileTap={{ scale:0.88 }} transition={{ type:'spring', stiffness:450, damping:14 }}>`
- Service links: `<motion.a whileHover={{ color:'white', x: dir==='rtl' ? -3 : 3 }}>` — RTL-aware nudge
- Copyright/policy links: `<motion.a whileHover={{ color:'rgba(255,255,255,0.85)' }}>`
- Copyright bar: `<motion.div initial={{ opacity:0 }} whileInView={{ opacity:1 }} transition={{ delay:0.3 }}>`

---

## RTL Handling Strategy

**Problem:** `x` offset animations (slideInLeft/Right) are direction-dependent. In RTL layout, "start" is visually the right side.

**Solution:** `getDirectionalVariants(dir)` in `variants.ts` returns direction-aware variants:
- `slideInStart` — `x = dir==='rtl' ? +60 : -60` (from visual start)
- `slideInEnd` — `x = dir==='rtl' ? -60 : +60` (from visual end)

Used in: ProviderCTA (text vs illustration), Footer service link nudge.

**Language toggle mid-session:** Already-animated elements stay at `visible` state (once:true). Direction flip on visible elements has no effect — correct behaviour, no extra handling needed.

---

## Performance Notes

- **`useTransform` in Header** — reactive motion values on compositor thread. Zero React re-renders on scroll. The single biggest performance improvement vs current `useState(scrolled)`.
- **`will-change: 'transform'`** — apply only to: Hero parallax bg layer, ServiceCard outer div, floating dots. NOT globally — promotes GPU layers and causes memory pressure on mobile with 30+ elements.
- **`layout` prop** — do NOT use anywhere. CSS auto-fit grid columns + `layout` = FLIP recalculation on every resize = jank. Add only if explicit reorder/expand features are added later.
- **`viewport={{ once: true }}`** — all viewport triggers fire once per load. Correct — no re-triggering on scroll back.
- **`AnimatePresence mode="wait"`** in ContactForm — slight delay on success render acceptable (user just submitted form). SVG is 64px — trivial render time.

---

## Implementation Sequence

1. `npm install framer-motion@^11`
2. Create `src/animations/variants.ts`
3. Create `src/components/ui/AnimatedSection.tsx`
4. Modify `src/App.tsx` — add MotionConfig
5. Modify `src/styles/globals.css` — remove @keyframes blocks
6. `Header.tsx` — useScroll + useTransform, mount stagger, whileHover/Tap
7. `Hero.tsx` — parallax, word-split, ambient dots, wave float
8. `HowItWorks.tsx` — AnimatedSection stagger, springBounce badge, icon rotate hover
9. `Services.tsx` — AnimatedSection grid stagger, full whileHover ServiceCard
10. `TrustBadges.tsx` — AnimatedSection stagger, badge whileHover
11. `PlatformStats.tsx` — useInView replaces IntersectionObserver, AnimatedSection grid
12. `ProviderCTA.tsx` — directional slide-in, stats stagger, button spring
13. `ContactForm.tsx` — AnimatePresence form/success, animated focus ring, button spring
14. `Footer.tsx` — AnimatedSection columns, social icon spring, link nudge

---

## Verification
1. `npm run dev` → http://localhost:3000
2. Header: smooth bg blur interpolation on slow scroll (not snap)
3. Hero: headline words cascade in one by one, buttons bounce-scale on hover/tap, dots float, wave gently oscillates
4. Scroll through all sections: each reveals smoothly from below as it enters viewport
5. Services: card lifts + icon bg changes on hover, independent two-zone hover behaviour
6. PlatformStats: counters only start counting when section scrolls into view
7. ProviderCTA: text and illustration slide in from opposite sides
8. ContactForm: submit → form slides up and out, success card springs in with bouncing checkmark
9. Toggle EN↔AR: page re-renders, already-visible sections stay in place, directional animations respected on fresh page load
10. OS `prefers-reduced-motion` ON: all animation states jump to final value instantly — no motion

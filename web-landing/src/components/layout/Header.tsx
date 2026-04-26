import { useEffect, useState } from 'react'
import { Logo } from '../ui/Brand'
import { Icon } from '../ui/Icons'
import { useIsMobile } from '../../hooks/useIsMobile'

const NAV_ITEMS: { label: string; href: string }[] = [
  { label: 'How it works', href: '#how-it-works' },
  { label: 'Services', href: '#services' },
  { label: 'For Providers', href: '#providers' },
  { label: 'Contact', href: '#contact' },
]

export default function Header() {
  const isMobile = useIsMobile()
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 100)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const isDark = !scrolled
  const bg = isDark ? 'rgba(13,47,71,.55)' : 'rgba(255,255,255,.94)'
  const border = isDark ? 'rgba(255,255,255,.08)' : 'rgba(20,24,29,.06)'
  const ink = isDark ? '#fff' : '#1f262e'
  const muted = isDark ? 'rgba(255,255,255,.78)' : '#4d5763'

  return (
    <header style={{
      position: 'sticky', top: 0, zIndex: 50,
      background: bg, backdropFilter: 'blur(14px) saturate(160%)', WebkitBackdropFilter: 'blur(14px) saturate(160%)',
      borderBottom: `1px solid ${border}`,
      transition: 'background .25s var(--kh-ease), border-color .25s var(--kh-ease)',
    }}>
      <div style={{
        maxWidth: 1280, margin: '0 auto',
        padding: isMobile ? '12px 16px' : '14px 32px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 24,
      }}>
        <a href="#top" style={{ display: 'inline-flex' }}>
          <Logo size={isMobile ? 26 : 30} white={isDark} />
        </a>

        {!isMobile && (
          <nav style={{ display: 'flex', gap: 28 }}>
            {NAV_ITEMS.map(item => (
              <a key={item.href} href={item.href} style={{
                color: muted, fontSize: 14, fontWeight: 500, textDecoration: 'none',
                position: 'relative', padding: '4px 0',
                transition: 'color .15s var(--kh-ease)',
              }}
                onMouseEnter={e => (e.currentTarget.style.color = ink)}
                onMouseLeave={e => (e.currentTarget.style.color = muted)}
              >{item.label}</a>
            ))}
          </nav>
        )}

        <div style={{ display: 'flex', alignItems: 'center', gap: isMobile ? 8 : 12 }}>
          {!isMobile && (
            <span style={{
              color: muted, fontSize: 13, fontWeight: 600,
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '8px 12px', borderRadius: 999, border: `1px solid ${border}`,
            }}>
              <Icon.Pin size={14} stroke={muted} />
              Beirut
            </span>
          )}
          <a href="#contact" className="kh-btn kh-btn-primary" style={{
            height: isMobile ? 38 : 44, padding: isMobile ? '0 14px' : '0 18px',
            fontSize: isMobile ? 13 : 14, textDecoration: 'none',
          }}>
            {isMobile ? 'Get app' : 'Download the App'}
          </a>
          {isMobile && (
            <button aria-label="Menu" onClick={() => setMenuOpen(o => !o)} style={{
              background: 'transparent', border: 'none', padding: 8, color: ink, cursor: 'pointer',
            }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M3 6h18M3 12h18M3 18h18" />
              </svg>
            </button>
          )}
        </div>
      </div>

      {isMobile && menuOpen && (
        <nav style={{
          background: scrolled ? '#fff' : '#0d2f47',
          borderTop: `1px solid ${border}`,
          padding: '8px 16px 16px',
          display: 'flex', flexDirection: 'column', gap: 4,
        }}>
          {NAV_ITEMS.map(item => (
            <a key={item.href} href={item.href} onClick={() => setMenuOpen(false)} style={{
              color: ink, fontSize: 15, fontWeight: 500, padding: '12px 4px',
              borderBottom: `1px solid ${border}`,
            }}>{item.label}</a>
          ))}
        </nav>
      )}
    </header>
  )
}

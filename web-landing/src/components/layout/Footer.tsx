import { Icon } from '../ui/Icons'
import { Logo, AppStoreBadge } from '../ui/Brand'
import { useIsMobile } from '../../hooks/useIsMobile'

const FOOTER_COLS = [
  { title: 'Services', items: ['Cleaning', 'Plumbing', 'Electrical', 'AC service', 'Carpentry', 'Painting', 'Moving'] },
  { title: 'Company', items: ['About', 'Careers', 'Press', 'Blog', 'Become a provider'] },
  { title: 'Support', items: ['Help center', 'Safety', 'Trust & verification', 'Cancellation policy', 'Contact us'] },
]

const TRUST_BADGES = [
  'Stripe payments',
  'Visa · Mastercard',
  'OMT · Whish',
  'SSL secured',
  'Background-checked pros',
]

function FooterCol({ title, items }: { title: string; items: string[] }) {
  return (
    <div>
      <div style={{ fontSize: 13, fontWeight: 600, color: '#fff', marginBottom: 14 }}>{title}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {items.map(it => (
          <a key={it} href="#" style={{
            fontSize: 13, color: 'rgba(255,255,255,.7)', textDecoration: 'none',
          }}>{it}</a>
        ))}
      </div>
    </div>
  )
}

function TrustBadge({ label }: { label: string }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      fontSize: 12, color: 'rgba(255,255,255,.75)', fontWeight: 500,
    }}>
      <Icon.CheckCircle size={14} stroke="#F39C12" /> {label}
    </div>
  )
}

function SocialBtn({ children }: { children: React.ReactNode }) {
  return (
    <a href="#" style={{
      width: 36, height: 36, borderRadius: 10,
      background: 'rgba(255,255,255,.08)', border: '1px solid rgba(255,255,255,.14)',
      display: 'grid', placeItems: 'center', textDecoration: 'none',
    }}>{children}</a>
  )
}

export default function Footer() {
  const isMobile = useIsMobile()
  const year = new Date().getFullYear()
  return (
    <footer style={{
      background: '#0d2f47', color: '#cdd9e4',
      padding: isMobile ? '40px 20px 20px' : '72px 32px 28px',
    }}>
      <div style={{ maxWidth: 1200, margin: '0 auto' }}>

        {/* Trust bar */}
        <div style={{
          display: 'flex', flexWrap: 'wrap', gap: isMobile ? 12 : 20,
          alignItems: 'center', justifyContent: 'space-between',
          padding: isMobile ? '14px 0' : '18px 0',
          borderBottom: '1px solid rgba(255,255,255,.10)',
          marginBottom: isMobile ? 28 : 48,
        }}>
          <div style={{
            fontSize: 11, color: 'rgba(255,255,255,.6)', letterSpacing: '.08em',
            textTransform: 'uppercase', fontWeight: 600,
          }}>Secure & trusted</div>
          <div style={{
            display: 'flex', gap: isMobile ? 14 : 24,
            flexWrap: 'wrap', alignItems: 'center', opacity: .85,
          }}>
            {TRUST_BADGES.map(t => <TrustBadge key={t} label={t} />)}
          </div>
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: isMobile ? '1fr' : '1.4fr repeat(3, 1fr) 1.2fr',
          gap: isMobile ? 32 : 36,
        }}>
          <div>
            <Logo white />
            <p style={{
              fontSize: 13, color: 'rgba(255,255,255,.7)', lineHeight: 1.6,
              margin: '14px 0 18px', maxWidth: 320,
            }}>
              Khudmati connects homeowners with trusted service providers across Lebanon.
              Built in Beirut, available everywhere from Tripoli to Saida.
            </p>
            <div style={{ display: 'flex', gap: 10 }}>
              <SocialBtn><Icon.Instagram size={16} stroke="#fff" /></SocialBtn>
              <SocialBtn><Icon.X size={14} fill="#fff" /></SocialBtn>
              <SocialBtn><Icon.LinkedIn size={16} fill="#fff" /></SocialBtn>
            </div>
          </div>

          {FOOTER_COLS.map(col => <FooterCol key={col.title} title={col.title} items={col.items} />)}

          <div>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#fff', marginBottom: 14 }}>Get the app</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 18 }}>
              <AppStoreBadge store="ios" />
              <AppStoreBadge store="android" />
            </div>
          </div>
        </div>

        <div style={{
          marginTop: isMobile ? 28 : 56, paddingTop: isMobile ? 18 : 24,
          borderTop: '1px solid rgba(255,255,255,.10)',
          display: 'flex', flexWrap: 'wrap', gap: 12,
          justifyContent: 'space-between', alignItems: 'center',
          fontSize: 12, color: 'rgba(255,255,255,.55)',
        }}>
          <div>© {year} Khudmati SAL · Beirut, Lebanon · All rights reserved</div>
          <div style={{ display: 'flex', gap: 18 }}>
            <a href="/privacy.html" style={{ color: 'inherit' }}>Privacy</a>
            <a href="/terms.html" style={{ color: 'inherit' }}>Terms</a>
            <a href="#" style={{ color: 'inherit' }}>Cookies</a>
          </div>
        </div>
      </div>
    </footer>
  )
}

import { useEffect, useMemo, useState } from 'react'
import { Icon } from '../ui/Icons'
import { Avatar } from '../ui/Brand'
import { useIsMobile } from '../../hooks/useIsMobile'

const JOBS = [
  { who: 'Rami H.', city: 'Achrafieh', svc: 'AC repair', amt: 78, t: 'just now' },
  { who: 'Carla S.', city: 'Hamra', svc: 'Deep clean', amt: 120, t: '2 min ago' },
  { who: 'Tarek M.', city: 'Verdun', svc: 'Wiring fix', amt: 95, t: '3 min ago' },
  { who: 'Nour K.', city: 'Jounieh', svc: 'Pipe leak', amt: 64, t: '5 min ago' },
  { who: 'Bassam Z.', city: 'Tripoli', svc: 'Wall paint', amt: 210, t: '7 min ago' },
  { who: 'Lina F.', city: 'Saida', svc: 'AC install', amt: 340, t: '9 min ago' },
]

export default function ProviderCTA() {
  const isMobile = useIsMobile()
  const [jobIdx, setJobIdx] = useState(0)
  const [count, setCount] = useState(842)

  useEffect(() => {
    const id = window.setInterval(() => setJobIdx(i => (i + 1) % JOBS.length), 1800)
    return () => window.clearInterval(id)
  }, [])

  useEffect(() => {
    const id = window.setInterval(() => setCount(c => c + Math.floor(Math.random() * 40) + 10), 1800)
    return () => window.clearInterval(id)
  }, [])

  const time = useMemo(() => new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' }), [])

  return (
    <section id="providers" style={{
      position: 'relative', overflow: 'hidden',
      background: '#0a0d10', color: '#fff',
      padding: isMobile ? '56px 20px' : '120px 32px',
    }}>
      {/* Grid */}
      <div style={{
        position: 'absolute', inset: 0, opacity: .10, pointerEvents: 'none',
        backgroundImage:
          'linear-gradient(rgba(243,156,18,.5) 1px, transparent 1px), linear-gradient(90deg, rgba(243,156,18,.4) 1px, transparent 1px)',
        backgroundSize: '40px 40px',
      }} />
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background:
          'radial-gradient(ellipse at 70% 30%, rgba(243,156,18,.18), transparent 60%), radial-gradient(ellipse at 20% 70%, rgba(27,79,114,.4), transparent 60%)',
      }} />

      <div style={{ maxWidth: 1280, margin: '0 auto', position: 'relative' }}>
        {/* Top eyebrow + ticker */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 14,
          marginBottom: isMobile ? 20 : 32, flexWrap: 'wrap',
        }}>
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 8,
            padding: '6px 12px', borderRadius: 999,
            background: 'rgba(243,156,18,.15)', color: '#F39C12',
            fontSize: 11, fontWeight: 600, letterSpacing: '.08em', textTransform: 'uppercase',
          }}>
            <span style={{
              width: 6, height: 6, borderRadius: '50%', background: '#F39C12',
              boxShadow: '0 0 0 4px rgba(243,156,18,.25)',
            }} />
            LIVE · For providers
          </div>
          {!isMobile && (
            <div style={{ flex: 1, height: 1, background: 'linear-gradient(90deg, rgba(243,156,18,.4), transparent)' }} />
          )}
          <div style={{
            fontSize: 11, color: 'rgba(255,255,255,.5)',
            fontFamily: 'ui-monospace,Menlo,monospace', letterSpacing: '.05em',
          }}>
            BEY · {time}
          </div>
        </div>

        <div style={{
          display: 'grid', gridTemplateColumns: isMobile ? '1fr' : '1.1fr 1fr',
          gap: isMobile ? 32 : 60, alignItems: 'flex-start',
        }}>
          {/* Left: headline + counter */}
          <div>
            <h2 style={{
              fontSize: isMobile ? 40 : 84, lineHeight: .95, letterSpacing: '-0.04em',
              fontWeight: 700, margin: '0 0 24px',
            }}>
              Earn while<br />
              Beirut <span style={{
                background: 'linear-gradient(120deg, #F39C12, #f5b347)',
                WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
                fontFamily: 'Fraunces, serif', fontStyle: 'italic', fontWeight: 600,
              }}>sleeps</span>.
            </h2>
            <p style={{
              fontSize: isMobile ? 15 : 18, color: 'rgba(255,255,255,.72)',
              maxWidth: 480, lineHeight: 1.55, margin: '0 0 36px',
            }}>
              Set your hours. Set your rates. We pay out daily — no chasing customers, no awkward invoices, no 30-day waits.
            </p>

            <div style={{
              padding: isMobile ? '18px 20px' : '24px 28px',
              border: '1px solid rgba(243,156,18,.25)',
              borderRadius: 18, background: 'rgba(243,156,18,.05)',
              position: 'relative', overflow: 'hidden', marginBottom: 24,
            }}>
              <div style={{
                position: 'absolute', top: 14, right: 14,
                fontSize: 10, color: '#F39C12', letterSpacing: '.08em',
                fontFamily: 'ui-monospace,monospace',
              }}>
                EARNED · TODAY
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <span style={{
                  fontSize: isMobile ? 40 : 64, fontWeight: 700,
                  fontVariantNumeric: 'tabular-nums', color: '#F39C12',
                  letterSpacing: '-0.03em', lineHeight: 1,
                }}>
                  ${count.toLocaleString()}
                </span>
                <span style={{
                  fontSize: 14, color: 'rgba(255,255,255,.6)',
                  fontFamily: 'ui-monospace,monospace',
                }}>+ {Math.floor(count * 0.02)} pending</span>
              </div>
              <div style={{
                fontSize: 12, color: 'rgba(255,255,255,.6)', marginTop: 8,
                display: 'flex', gap: 14, flexWrap: 'wrap',
              }}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#1f9d55' }} /> 142 jobs accepted today
                </span>
                <span>·</span>
                <span>Avg ticket $61</span>
                <span>·</span>
                <span>0% chargebacks</span>
              </div>
              <svg viewBox="0 0 600 60" style={{ width: '100%', height: 50, marginTop: 12 }}>
                <defs>
                  <linearGradient id="khLineG" x1="0" x2="1">
                    <stop offset="0" stopColor="rgba(243,156,18,.0)" />
                    <stop offset=".5" stopColor="rgba(243,156,18,.6)" />
                    <stop offset="1" stopColor="rgba(243,156,18,1)" />
                  </linearGradient>
                </defs>
                <path d="M0 50 L 30 44 L 60 48 L 90 38 L 120 42 L 150 32 L 180 36 L 210 28 L 240 32 L 270 22 L 300 28 L 330 18 L 360 22 L 390 14 L 420 18 L 450 10 L 480 14 L 510 8 L 540 12 L 570 4 L 600 8"
                  fill="none" stroke="url(#khLineG)" strokeWidth="2" />
                <circle cx="600" cy="8" r="4" fill="#F39C12" />
              </svg>
            </div>

            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
              <button className="kh-btn kh-btn-primary kh-btn-lg">
                Start earning today <Icon.Arrow size={16} stroke="#1a1100" />
              </button>
              <button className="kh-btn kh-btn-ghost kh-btn-lg">View pay rates</button>
            </div>
          </div>

          {/* Right: live job feed */}
          <div style={{ position: 'relative' }}>
            <div style={{
              border: '1px solid rgba(255,255,255,.08)', borderRadius: 18,
              background: 'rgba(255,255,255,.03)', backdropFilter: 'blur(12px)',
              padding: 18,
            }}>
              <div style={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                marginBottom: 14, paddingBottom: 14,
                borderBottom: '1px solid rgba(255,255,255,.08)',
              }}>
                <div style={{
                  fontSize: 11, color: 'rgba(255,255,255,.6)',
                  letterSpacing: '.08em', fontFamily: 'ui-monospace,monospace',
                  textTransform: 'uppercase',
                }}>Live job feed</div>
                <div style={{
                  fontSize: 10, color: '#1f9d55',
                  display: 'flex', alignItems: 'center', gap: 6,
                }}>
                  <span style={{
                    width: 6, height: 6, borderRadius: '50%', background: '#1f9d55',
                    boxShadow: '0 0 0 3px rgba(31,157,85,.25)',
                  }} /> connected
                </div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {JOBS.map((j, i) => {
                  const active = i === jobIdx
                  return (
                    <div key={j.who + i} style={{
                      display: 'flex', alignItems: 'center', gap: 12,
                      padding: '10px 12px', borderRadius: 10,
                      background: active ? 'rgba(243,156,18,.10)' : 'rgba(255,255,255,.02)',
                      border: `1px solid ${active ? 'rgba(243,156,18,.4)' : 'rgba(255,255,255,.05)'}`,
                      transition: 'background .25s, border-color .25s, transform .25s',
                      transform: active ? 'translateX(2px)' : 'none',
                    }}>
                      <Avatar name={j.who} size={32} bg={active ? '#F39C12' : '#1B4F72'} color={active ? '#1a1100' : '#fff'} />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{
                          fontSize: 13, fontWeight: 600,
                          display: 'flex', gap: 6, alignItems: 'baseline',
                        }}>
                          {j.who}{' '}
                          <span style={{ fontSize: 11, color: 'rgba(255,255,255,.5)', fontWeight: 400 }}>· {j.city}</span>
                        </div>
                        <div style={{ fontSize: 11, color: 'rgba(255,255,255,.65)' }}>{j.svc}</div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{
                          fontSize: 14, fontWeight: 700,
                          color: active ? '#F39C12' : '#fff',
                          fontVariantNumeric: 'tabular-nums',
                        }}>+${j.amt}</div>
                        <div style={{
                          fontSize: 10, color: 'rgba(255,255,255,.4)',
                          fontFamily: 'ui-monospace,monospace',
                        }}>{j.t}</div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            <div style={{
              position: 'absolute', right: isMobile ? -4 : -14, bottom: -26,
              padding: '12px 14px', borderRadius: 12, background: '#F39C12', color: '#1a1100',
              boxShadow: '0 16px 32px rgba(243,156,18,.4)',
              transform: 'rotate(-3deg)', maxWidth: 200,
            }}>
              <div style={{
                fontSize: 10, fontWeight: 700, letterSpacing: '.08em',
                textTransform: 'uppercase', opacity: .7,
              }}>Daily payout</div>
              <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>
                Money in your account by 11pm — every night.
              </div>
            </div>
          </div>
        </div>

        {/* Bottom credentials strip */}
        <div style={{
          marginTop: isMobile ? 40 : 60, paddingTop: 24,
          borderTop: '1px solid rgba(255,255,255,.08)',
          display: 'flex', flexWrap: 'wrap', gap: isMobile ? 14 : 32, alignItems: 'center',
          fontSize: 12, color: 'rgba(255,255,255,.55)',
        }}>
          <span style={{ color: 'rgba(255,255,255,.85)', fontWeight: 600 }}>5,200+ providers earning across Lebanon</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <Icon.CheckCircle size={14} stroke="#F39C12" /> Free to join
          </span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <Icon.CheckCircle size={14} stroke="#F39C12" /> Same-day approval
          </span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <Icon.CheckCircle size={14} stroke="#F39C12" /> Insurance included
          </span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <Icon.CheckCircle size={14} stroke="#F39C12" /> 12% flat fee — never more
          </span>
        </div>
      </div>
    </section>
  )
}

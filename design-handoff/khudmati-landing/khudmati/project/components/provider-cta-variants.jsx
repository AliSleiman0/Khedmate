// Khudmati — Provider CTA · creative variants
// Three takes that go well beyond a portrait card.

// ─────────────────────────────────────────────────────────────
// V2 — "Live earnings cinema" — looping ticker of provider stats,
// cash counter, pulsing job feed. Like a Bloomberg terminal for tradesmen.
// ─────────────────────────────────────────────────────────────
function KhProviderCtaV2({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  const [jobIdx, setJobIdx] = React.useState(0);
  const jobs = [
    {who:'Rami H.', city:'Achrafieh', svc:'AC repair', amt:78, t:'just now'},
    {who:'Carla S.', city:'Hamra', svc:'Deep clean', amt:120, t:'2 min ago'},
    {who:'Tarek M.', city:'Verdun', svc:'Wiring fix', amt:95, t:'3 min ago'},
    {who:'Nour K.', city:'Jounieh', svc:'Pipe leak', amt:64, t:'5 min ago'},
    {who:'Bassam Z.', city:'Tripoli', svc:'Wall paint', amt:210, t:'7 min ago'},
    {who:'Lina F.', city:'Saida', svc:'AC install', amt:340, t:'9 min ago'},
  ];
  React.useEffect(()=>{
    if (!motion) return;
    const id = setInterval(()=>setJobIdx(i=>(i+1)%jobs.length), 1800);
    return ()=>clearInterval(id);
  },[motion]);

  // Counter
  const [count, setCount] = React.useState(842);
  React.useEffect(()=>{
    if (!motion) return;
    const id = setInterval(()=>setCount(c=>c + Math.floor(Math.random()*40)+10), 1800);
    return ()=>clearInterval(id);
  },[motion]);

  return (
    <section style={{position:'relative', overflow:'hidden',
      background:'#0a0d10', color:'#fff', padding: isMobile?'56px 20px':'120px 32px'}}>

      {/* Grid bg */}
      <div style={{position:'absolute', inset:0, opacity:.10, pointerEvents:'none',
        backgroundImage:'linear-gradient(rgba(243,156,18,.5) 1px, transparent 1px), linear-gradient(90deg, rgba(243,156,18,.4) 1px, transparent 1px)',
        backgroundSize:'40px 40px'}}/>
      <div style={{position:'absolute', inset:0, pointerEvents:'none',
        background:'radial-gradient(ellipse at 70% 30%, rgba(243,156,18,.18), transparent 60%), radial-gradient(ellipse at 20% 70%, rgba(27,79,114,.4), transparent 60%)'}}/>

      <div style={{maxWidth:1280, margin:'0 auto', position:'relative'}}>
        {/* Top eyebrow + ticker */}
        <div style={{display:'flex', alignItems:'center', gap:14, marginBottom: isMobile?20:32, flexWrap:'wrap'}}>
          <div style={{display:'inline-flex', alignItems:'center', gap:8, padding:'6px 12px', borderRadius:999,
            background:'rgba(243,156,18,.15)', color:'#F39C12', fontSize:11, fontWeight:600, letterSpacing:.08, textTransform:'uppercase'}}>
            <span style={{width:6,height:6,borderRadius:'50%',background:'#F39C12', boxShadow:motion?'0 0 0 4px rgba(243,156,18,.25)':'none'}}/>
            LIVE · For providers
          </div>
          {!isMobile && (
            <div style={{flex:1, height:1, background:'linear-gradient(90deg, rgba(243,156,18,.4), transparent)'}}/>
          )}
          <div style={{fontSize:11, color:'rgba(255,255,255,.5)', fontFamily:'ui-monospace,Menlo,monospace', letterSpacing:.05}}>
            BEY · {new Date().toLocaleTimeString('en-GB',{hour:'2-digit', minute:'2-digit'})}
          </div>
        </div>

        <div style={{display:'grid', gridTemplateColumns: isMobile?'1fr':'1.1fr 1fr', gap: isMobile?32:60, alignItems:'flex-start'}}>
          {/* Left — headline + giant counter */}
          <div>
            <h2 style={{
              fontSize: isMobile?40:84, lineHeight:.95, letterSpacing:'-0.04em',
              fontWeight:700, margin:'0 0 24px', textWrap:'balance',
            }}>
              Earn while<br/>
              Beirut <span style={{
                background:'linear-gradient(120deg, #F39C12, #f5b347)',
                WebkitBackgroundClip:'text', backgroundClip:'text', color:'transparent',
                fontFamily:'Fraunces, serif', fontStyle:'italic', fontWeight:600,
              }}>sleeps</span>.
            </h2>
            <p style={{fontSize: isMobile?15:18, color:'rgba(255,255,255,.72)', maxWidth:480, lineHeight:1.55, margin:'0 0 36px'}}>
              Set your hours. Set your rates. We pay out daily — no chasing customers, no awkward invoices, no 30-day waits.
            </p>

            {/* The counter — giant cash readout */}
            <div style={{
              padding: isMobile?'18px 20px':'24px 28px',
              border:'1px solid rgba(243,156,18,.25)',
              borderRadius:18, background:'rgba(243,156,18,.05)',
              position:'relative', overflow:'hidden', marginBottom:24,
            }}>
              <div style={{position:'absolute', top:14, right:14, fontSize:10, color:'#F39C12', letterSpacing:.08, fontFamily:'ui-monospace,monospace'}}>
                EARNED · TODAY
              </div>
              <div style={{display:'flex', alignItems:'baseline', gap:8}}>
                <span style={{fontSize: isMobile?40:64, fontWeight:700, fontVariantNumeric:'tabular-nums', color:'#F39C12', letterSpacing:'-0.03em', lineHeight:1}}>
                  ${count.toLocaleString()}
                </span>
                <span style={{fontSize:14, color:'rgba(255,255,255,.6)', fontFamily:'ui-monospace,monospace'}}>+ {Math.floor(count*0.02)} pending</span>
              </div>
              <div style={{fontSize:12, color:'rgba(255,255,255,.6)', marginTop:8, display:'flex', gap:14, flexWrap:'wrap'}}>
                <span style={{display:'inline-flex', alignItems:'center', gap:6}}>
                  <span style={{width:6,height:6,borderRadius:'50%',background:'#1f9d55'}}/> 142 jobs accepted today
                </span>
                <span>·</span>
                <span>Avg ticket $61</span>
                <span>·</span>
                <span>0% chargebacks</span>
              </div>
              {/* mini sparkline */}
              <svg viewBox="0 0 600 60" style={{width:'100%', height:50, marginTop:12}}>
                <defs>
                  <linearGradient id="khLineG" x1="0" x2="1">
                    <stop offset="0" stopColor="rgba(243,156,18,.0)"/>
                    <stop offset=".5" stopColor="rgba(243,156,18,.6)"/>
                    <stop offset="1" stopColor="rgba(243,156,18,1)"/>
                  </linearGradient>
                </defs>
                <path d="M0 50 L 30 44 L 60 48 L 90 38 L 120 42 L 150 32 L 180 36 L 210 28 L 240 32 L 270 22 L 300 28 L 330 18 L 360 22 L 390 14 L 420 18 L 450 10 L 480 14 L 510 8 L 540 12 L 570 4 L 600 8"
                  fill="none" stroke="url(#khLineG)" strokeWidth="2"/>
                <circle cx="600" cy="8" r="4" fill="#F39C12"/>
              </svg>
            </div>

            <div style={{display:'flex', gap:12, flexWrap:'wrap'}}>
              <button className="kh-btn kh-btn-primary kh-btn-lg">
                Start earning today <KhIcon.Arrow size={16} stroke="#1a1100"/>
              </button>
              <button className="kh-btn kh-btn-ghost kh-btn-lg">View pay rates</button>
            </div>
          </div>

          {/* Right — live job feed */}
          <div style={{position:'relative'}}>
            <div style={{
              border:'1px solid rgba(255,255,255,.08)', borderRadius:18,
              background:'rgba(255,255,255,.03)', backdropFilter:'blur(12px)',
              padding:18,
            }}>
              <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:14, paddingBottom:14, borderBottom:'1px solid rgba(255,255,255,.08)'}}>
                <div style={{fontSize:11, color:'rgba(255,255,255,.6)', letterSpacing:.08, fontFamily:'ui-monospace,monospace', textTransform:'uppercase'}}>Live job feed</div>
                <div style={{fontSize:10, color:'#1f9d55', display:'flex', alignItems:'center', gap:6}}>
                  <span style={{width:6,height:6,borderRadius:'50%',background:'#1f9d55', boxShadow:motion?'0 0 0 3px rgba(31,157,85,.25)':'none'}}/> connected
                </div>
              </div>
              <div style={{display:'flex', flexDirection:'column', gap:10}}>
                {jobs.map((j,i)=>{
                  const active = i===jobIdx;
                  return (
                    <div key={j.who+i} style={{
                      display:'flex', alignItems:'center', gap:12, padding:'10px 12px', borderRadius:10,
                      background: active?'rgba(243,156,18,.10)':'rgba(255,255,255,.02)',
                      border: `1px solid ${active?'rgba(243,156,18,.4)':'rgba(255,255,255,.05)'}`,
                      transition:'background .25s, border-color .25s, transform .25s',
                      transform: active?'translateX(2px)':'none',
                    }}>
                      <KhAvatar name={j.who} size={32} bg={active?'#F39C12':'#1B4F72'} color={active?'#1a1100':'#fff'}/>
                      <div style={{flex:1, minWidth:0}}>
                        <div style={{fontSize:13, fontWeight:600, display:'flex', gap:6, alignItems:'baseline'}}>
                          {j.who} <span style={{fontSize:11, color:'rgba(255,255,255,.5)', fontWeight:400}}>· {j.city}</span>
                        </div>
                        <div style={{fontSize:11, color:'rgba(255,255,255,.65)'}}>{j.svc}</div>
                      </div>
                      <div style={{textAlign:'right'}}>
                        <div style={{fontSize:14, fontWeight:700, color:active?'#F39C12':'#fff', fontVariantNumeric:'tabular-nums'}}>+${j.amt}</div>
                        <div style={{fontSize:10, color:'rgba(255,255,255,.4)', fontFamily:'ui-monospace,monospace'}}>{j.t}</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Floating pay-out card */}
            <div style={{
              position:'absolute', right: isMobile?-4:-14, bottom:-26,
              padding:'12px 14px', borderRadius:12, background:'#F39C12', color:'#1a1100',
              boxShadow:'0 16px 32px rgba(243,156,18,.4)',
              transform:'rotate(-3deg)', maxWidth:200,
            }}>
              <div style={{fontSize:10, fontWeight:700, letterSpacing:.08, textTransform:'uppercase', opacity:.7}}>Daily payout</div>
              <div style={{fontSize:13, fontWeight:600, marginTop:2}}>Money in your account by 11pm — every night.</div>
            </div>
          </div>
        </div>

        {/* Bottom strip — credentials */}
        <div style={{
          marginTop: isMobile?40:60, paddingTop:24, borderTop:'1px solid rgba(255,255,255,.08)',
          display:'flex', flexWrap:'wrap', gap: isMobile?14:32, alignItems:'center',
          fontSize:12, color:'rgba(255,255,255,.55)',
        }}>
          <span style={{color:'rgba(255,255,255,.85)', fontWeight:600}}>5,200+ providers earning across Lebanon</span>
          <span style={{display:'inline-flex',alignItems:'center',gap:6}}><KhIcon.CheckCircle size={14} stroke="#F39C12"/> Free to join</span>
          <span style={{display:'inline-flex',alignItems:'center',gap:6}}><KhIcon.CheckCircle size={14} stroke="#F39C12"/> Same-day approval</span>
          <span style={{display:'inline-flex',alignItems:'center',gap:6}}><KhIcon.CheckCircle size={14} stroke="#F39C12"/> Insurance included</span>
          <span style={{display:'inline-flex',alignItems:'center',gap:6}}><KhIcon.CheckCircle size={14} stroke="#F39C12"/> 12% flat fee — never more</span>
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// V3 — Editorial magazine spread — kinetic typography poster
// Massive type, framed quote, big serial number, tools-as-marginalia
// ─────────────────────────────────────────────────────────────
function KhProviderCtaV3({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  return (
    <section style={{
      position:'relative', overflow:'hidden',
      background:'#fef9ee',
      color:'#1a1100',
      padding: isMobile?'56px 20px':'120px 32px',
      borderTop:'1px solid #1a1100',
      borderBottom:'1px solid #1a1100',
    }}>
      {/* Issue ticker */}
      <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', fontSize:11, letterSpacing:.12, textTransform:'uppercase', fontFamily:'ui-monospace,monospace', marginBottom: isMobile?20:48, paddingBottom:14, borderBottom:'1px solid #1a1100'}}>
        <span>Khudmati Quarterly · Vol. III</span>
        <span>For Providers — Issue 04</span>
        <span>{!isMobile && 'Beirut · '}Free</span>
      </div>

      <div style={{maxWidth:1280, margin:'0 auto', position:'relative'}}>
        {/* Massive headline */}
        <div style={{position:'relative', marginBottom: isMobile?32:60}}>
          <div style={{
            fontSize: isMobile?13:14, fontWeight:600, color:'#c97e08',
            letterSpacing:.06, marginBottom:14, fontFamily:'ui-monospace,monospace',
          }}>
            №&nbsp;004 — A WORK ALMANAC
          </div>
          <h2 style={{
            fontFamily:'Fraunces, Georgia, serif',
            fontSize: isMobile?64:180, fontWeight:600, fontStyle:'italic',
            lineHeight:.85, letterSpacing:'-0.045em',
            margin:0, textWrap:'balance',
          }}>
            The trade <br/>
            <span style={{fontStyle:'normal', fontWeight:700, fontFamily:'Inter,sans-serif', fontSize: isMobile?52:160, letterSpacing:'-0.06em'}}>
              has changed.
            </span>
          </h2>

          {/* Tools doodled into margins */}
          {!isMobile && (
            <>
              <svg width="100" height="100" viewBox="0 0 100 100" style={{position:'absolute', top:20, right:'8%', transform:'rotate(15deg)'}}>
                <path d="M20 70 L 35 55 L 75 15 Q 85 5 90 10 Q 95 15 85 25 L 45 65 L 30 80 Z" stroke="#1a1100" strokeWidth="1.5" fill="none" strokeLinejoin="round"/>
                <path d="M30 80 L 20 90" stroke="#1a1100" strokeWidth="1.5"/>
              </svg>
              <svg width="80" height="80" viewBox="0 0 80 80" style={{position:'absolute', bottom:-10, right:'25%', transform:'rotate(-12deg)'}}>
                <path d="M15 65 L 65 15" stroke="#1a1100" strokeWidth="2.5" strokeLinecap="round"/>
                <path d="M10 60 Q 5 60 5 65 Q 5 70 10 70 L 18 70 L 18 62 Z" stroke="#1a1100" strokeWidth="1.5" fill="#F39C12"/>
                <circle cx="65" cy="15" r="6" stroke="#1a1100" strokeWidth="1.5" fill="none"/>
              </svg>
            </>
          )}
        </div>

        <div style={{display:'grid', gridTemplateColumns: isMobile?'1fr':'1fr 1fr 1fr', gap: isMobile?28:40, paddingBottom: isMobile?32:60, borderBottom:'1px solid #1a1100'}}>
          {/* Drop cap intro */}
          <p style={{
            fontSize: isMobile?17:18, lineHeight:1.55, color:'#1a1100',
            margin:0, columnCount:1, fontFamily:'Fraunces, Georgia, serif',
          }}>
            <span style={{
              float:'left', fontFamily:'Fraunces, Georgia, serif', fontWeight:700,
              fontSize: isMobile?72:96, lineHeight:.85, marginRight:8, marginTop:4,
              color:'#F39C12',
            }}>F</span>
            or sixty years your father's plumber ran on missed calls and shouted addresses. Today, <em>your phone</em> is the dispatcher, the bookkeeper, and the bank teller. Khudmati just makes sure it pays.
          </p>

          {/* The pull quote */}
          <div style={{
            padding: isMobile?'18px 4px':'24px 8px',
            borderTop:'2px solid #1a1100', borderBottom:'2px solid #1a1100',
          }}>
            <div style={{fontSize:11, fontWeight:600, letterSpacing:.1, fontFamily:'ui-monospace,monospace', marginBottom:14}}>FROM THE FIELD</div>
            <blockquote style={{
              margin:0, fontFamily:'Fraunces, Georgia, serif', fontStyle:'italic', fontWeight:500,
              fontSize: isMobile?22:28, lineHeight:1.2, letterSpacing:'-0.01em',
            }}>
              "I doubled what I made calling around. I stopped chasing money. I started doing my job."
            </blockquote>
            <div style={{display:'flex', alignItems:'center', gap:10, marginTop:18}}>
              <KhAvatar name="Tarek Mansour" size={36} bg="#1a1100"/>
              <div style={{fontSize:12, lineHeight:1.3}}>
                <div style={{fontWeight:600}}>Tarek Mansour</div>
                <div style={{color:'#6b5a30'}}>Electrician · 8 yrs · Verdun</div>
              </div>
            </div>
          </div>

          {/* The numbers — newspaper style */}
          <div>
            <div style={{fontSize:11, fontWeight:600, letterSpacing:.1, fontFamily:'ui-monospace,monospace', marginBottom:14, color:'#c97e08'}}>BY THE NUMBERS, 2026</div>
            <div style={{display:'flex', flexDirection:'column', gap:12}}>
              {[
                {n:'$3,000', l:'Median monthly earnings'},
                {n:'12%', l:'Platform fee — flat'},
                {n:'48 hrs', l:'Background check turnaround'},
                {n:'24/7', l:'Direct support in Arabic & English'},
              ].map((s,i)=>(
                <div key={s.l} style={{
                  display:'flex', justifyContent:'space-between', alignItems:'baseline',
                  borderBottom:i<3?'1px dotted #1a1100':'none', paddingBottom:8, gap:14,
                }}>
                  <div style={{fontSize:13, fontFamily:'Fraunces, Georgia, serif', fontStyle:'italic', flex:1}}>{s.l}</div>
                  <div style={{fontSize: isMobile?22:26, fontWeight:700, fontVariantNumeric:'tabular-nums', letterSpacing:'-0.02em'}}>{s.n}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* CTA strip — like a magazine front cover bottom */}
        <div style={{
          paddingTop:32, display:'flex', flexWrap:'wrap', gap: isMobile?20:32, alignItems:'center', justifyContent:'space-between',
        }}>
          <div style={{maxWidth:520}}>
            <div style={{fontSize: isMobile?22:28, fontFamily:'Fraunces, Georgia, serif', fontStyle:'italic', fontWeight:600, lineHeight:1.2, marginBottom:6}}>
              Apply in three minutes. <br/>Approved by tomorrow.
            </div>
            <div style={{fontSize:13, color:'#6b5a30'}}>Bring your trade license, an ID, and a phone with a camera. We'll do the rest.</div>
          </div>
          <div style={{display:'flex', gap:12, flexWrap:'wrap'}}>
            <button className="kh-btn" style={{height:52, padding:'0 24px', background:'#1a1100', color:'#fef9ee', borderRadius:6, fontSize:15, border:'2px solid #1a1100'}}>
              Become a provider →
            </button>
            <button className="kh-btn" style={{height:52, padding:'0 24px', background:'transparent', color:'#1a1100', border:'2px solid #1a1100', borderRadius:6, fontSize:15}}>
              Read the handbook
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// V4 — Tools poster — type breaks the grid, big typographic mark,
// horizontal scroll provider strip with names, vertical brand mark
// ─────────────────────────────────────────────────────────────
function KhProviderCtaV4({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  const providers = [
    {n:'Rami H.', s:'Electrician', c:'Achrafieh', y:'8y', e:'$842', r:4.9},
    {n:'Carla S.', s:'Cleaner', c:'Hamra', y:'4y', e:'$610', r:5.0},
    {n:'Tarek M.', s:'Plumber', c:'Verdun', y:'12y', e:'$1,120', r:4.8},
    {n:'Nour K.', s:'AC tech', c:'Jounieh', y:'6y', e:'$905', r:4.9},
    {n:'Bassam Z.', s:'Painter', c:'Tripoli', y:'15y', e:'$540', r:4.7},
    {n:'Lina F.', s:'Mover', c:'Saida', y:'3y', e:'$720', r:4.8},
  ];
  return (
    <section style={{
      position:'relative', overflow:'hidden', color:'#fff',
      background:'linear-gradient(180deg, #1B4F72 0%, #0d2f47 100%)',
    }}>
      {/* Big watermark mark */}
      <div aria-hidden="true" style={{
        position:'absolute', right: isMobile?-20:-40, top: isMobile?20:60,
        fontSize: isMobile?260:520, fontWeight:700, lineHeight:.78,
        color:'rgba(243,156,18,.10)',
        fontFamily:'Fraunces, Georgia, serif', fontStyle:'italic',
        letterSpacing:'-0.06em', pointerEvents:'none', userSelect:'none',
      }}>
        Pro.
      </div>

      <div style={{maxWidth:1280, margin:'0 auto', padding: isMobile?'56px 20px 0':'120px 32px 0', position:'relative'}}>
        {/* Vertical label */}
        {!isMobile && (
          <div style={{position:'absolute', left:-12, top:140, transform:'rotate(-90deg)', transformOrigin:'left top', fontSize:11, letterSpacing:.18, fontWeight:600, color:'rgba(255,255,255,.55)', textTransform:'uppercase', fontFamily:'ui-monospace,monospace'}}>
            Khudmati × Providers · 2026
          </div>
        )}

        {/* Headline */}
        <div style={{display:'grid', gridTemplateColumns: isMobile?'1fr':'1.4fr 1fr', gap: isMobile?28:60, alignItems:'flex-end', paddingBottom: isMobile?40:80}}>
          <div>
            <div style={{display:'inline-flex', alignItems:'center', gap:8, padding:'5px 10px', borderRadius:4,
              background:'#F39C12', color:'#1a1100', fontSize:10, fontWeight:700, letterSpacing:.12, textTransform:'uppercase', marginBottom:24}}>
              Now hiring · 7 trades
            </div>
            <h2 style={{
              fontSize: isMobile?52:140, fontWeight:700, lineHeight:.88, letterSpacing:'-0.045em',
              margin:0, textWrap:'balance',
            }}>
              <span style={{display:'block'}}>The best</span>
              <span style={{display:'block', fontFamily:'Fraunces, Georgia, serif', fontStyle:'italic', fontWeight:500, color:'#F39C12', letterSpacing:'-0.04em'}}>tradespeople</span>
              <span style={{display:'block'}}>in Lebanon —</span>
              <span style={{display:'block', position:'relative'}}>
                use Khudmati.
                <svg style={{position:'absolute', left:0, bottom:-6, width: isMobile?180:380, height:14}} viewBox="0 0 380 14" preserveAspectRatio="none">
                  <path d="M2 10 Q 80 -4 200 6 T 378 4" stroke="#F39C12" strokeWidth="3" fill="none" strokeLinecap="round"/>
                </svg>
              </span>
            </h2>
          </div>
          <div>
            <p style={{fontSize: isMobile?15:17, color:'rgba(255,255,255,.78)', lineHeight:1.55, margin:'0 0 24px'}}>
              You bring the skill. We bring the customers, the bookings, the payments, the protection. <strong style={{color:'#fff'}}>You keep 88% of every job</strong> — paid the same day.
            </p>
            <div style={{display:'flex', gap:12, flexWrap:'wrap', marginBottom:24}}>
              <button className="kh-btn kh-btn-primary kh-btn-lg">
                Apply now <KhIcon.Arrow size={16} stroke="#1a1100"/>
              </button>
              <button className="kh-btn kh-btn-ghost kh-btn-lg">Calculate earnings</button>
            </div>
            <div style={{display:'flex', gap:18, fontSize:11, color:'rgba(255,255,255,.55)', flexWrap:'wrap'}}>
              <span>↳ Free signup</span>
              <span>↳ 48h approval</span>
              <span>↳ 12% flat</span>
              <span>↳ Insured</span>
            </div>
          </div>
        </div>

        {/* Provider strip — kinetic */}
        <div style={{position:'relative', marginLeft: isMobile?-20:-32, marginRight: isMobile?-20:-32}}>
          <div style={{display:'flex', justifyContent:'space-between', alignItems:'center',
            padding: isMobile?'0 20px 16px':'0 32px 20px', fontSize:11, fontFamily:'ui-monospace,monospace',
            color:'rgba(255,255,255,.5)', letterSpacing:.08, textTransform:'uppercase'}}>
            <span>↓ Top earners · this week</span>
            <span>{!isMobile && 'auto-updates · '}live</span>
          </div>
          <div style={{display:'flex', gap:0, overflowX:'auto', scrollbarWidth:'none', borderTop:'1px solid rgba(255,255,255,.12)'}}>
            <style>{`.khps::-webkit-scrollbar{display:none}`}</style>
            <div className="khps" style={{display:'flex', gap:0}}>
              {providers.map((p,i)=>(
                <div key={p.n} style={{
                  flex:'0 0 auto', minWidth: isMobile?240:300,
                  padding:'24px 28px',
                  borderRight:'1px solid rgba(255,255,255,.12)',
                  position:'relative',
                }}>
                  <div style={{display:'flex', justifyContent:'space-between', fontSize:10, color:'rgba(255,255,255,.5)', fontFamily:'ui-monospace,monospace', letterSpacing:.06, textTransform:'uppercase', marginBottom:18}}>
                    <span>№ {String(i+1).padStart(2,'0')}</span>
                    <span style={{color:'#F39C12'}}>{p.e}/wk</span>
                  </div>
                  <div style={{fontSize: isMobile?28:36, fontWeight:700, letterSpacing:'-0.02em', marginBottom:6}}>{p.n}</div>
                  <div style={{fontFamily:'Fraunces, Georgia, serif', fontStyle:'italic', fontSize:18, color:'#F39C12', marginBottom:14}}>{p.s}</div>
                  <div style={{fontSize:12, color:'rgba(255,255,255,.6)', display:'flex', justifyContent:'space-between', paddingTop:14, borderTop:'1px solid rgba(255,255,255,.10)'}}>
                    <span>{p.c}</span>
                    <span>{p.y} on platform</span>
                    <span>★ {p.r}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom strip */}
        <div style={{
          marginTop: isMobile?32:48, paddingBottom: isMobile?40:60,
          display:'flex', justifyContent:'space-between', alignItems:'center',
          fontSize:11, fontFamily:'ui-monospace,monospace', color:'rgba(255,255,255,.5)', letterSpacing:.06, textTransform:'uppercase', flexWrap:'wrap', gap:12,
        }}>
          <span>5,200+ verified providers · 6 cities · 14,200 jobs done</span>
          <span>khudmati.app/join →</span>
        </div>
      </div>
    </section>
  );
}

Object.assign(window, { KhProviderCtaV2, KhProviderCtaV3, KhProviderCtaV4 });

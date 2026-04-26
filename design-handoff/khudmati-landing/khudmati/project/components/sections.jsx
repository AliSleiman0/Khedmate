// Khudmati — Body sections: Services, How it works, Stats, Provider CTA, Contact, Footer

// ─────────────────────────────────────────────────────────────
// Services Grid
// ─────────────────────────────────────────────────────────────
function KhServicesGrid({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  const services = [
    {key:'cleaning', icon:<KhIcon.Cleaning size={28}/>, title:'Cleaning', desc:'Deep, regular & post-renovation', from:'$25', popular:true},
    {key:'plumbing', icon:<KhIcon.Plumbing size={28}/>, title:'Plumbing', desc:'Leaks, blocked drains, fixtures', from:'$30'},
    {key:'electrical', icon:<KhIcon.Electrical size={28}/>, title:'Electrical', desc:'Wiring, outlets, lights, panels', from:'$35'},
    {key:'ac', icon:<KhIcon.AC size={28}/>, title:'AC service', desc:'Install, recharge, maintenance', from:'$40', popular:true},
    {key:'carpentry', icon:<KhIcon.Carpentry size={28}/>, title:'Carpentry', desc:'Furniture, doors, custom builds', from:'$30'},
    {key:'painting', icon:<KhIcon.Painting size={28}/>, title:'Painting', desc:'Interior, exterior, touch-ups', from:'$2/m²'},
    {key:'moving', icon:<KhIcon.Moving size={28}/>, title:'Moving', desc:'Apartments, offices, single items', from:'$50'},
  ];
  return (
    <section style={{padding: isMobile?'56px 20px':'112px 32px', background:'#fbfbfc'}}>
      <div style={{maxWidth:1200, margin:'0 auto'}}>
        <div style={{display:'flex', alignItems:'flex-end', justifyContent:'space-between', flexWrap:'wrap', gap:16, marginBottom: isMobile?28:48}}>
          <div>
            <div className="kh-eyebrow" style={{color:'#F39C12', marginBottom:10}}>Our services</div>
            <h2 className="kh-h1" style={{fontSize: isMobile?28:40, color:'#14181d', margin:0, letterSpacing:'-0.025em'}}>
              Seven trades, one trusted app.
            </h2>
          </div>
          {!isMobile && (
            <a href="#" style={{color:'#1B4F72', fontSize:14, fontWeight:600, textDecoration:'none', display:'inline-flex', alignItems:'center', gap:6}}>
              See all services <KhIcon.Arrow size={14}/>
            </a>
          )}
        </div>

        <div style={{
          display:'grid',
          gridTemplateColumns: isMobile ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)',
          gap: isMobile?12:20,
        }}>
          {services.map((s, i) => (
            <div key={s.key} className="kh-card kh-card-hover"
              style={{
                padding: isMobile?16:22,
                position:'relative', cursor:'pointer',
                ...(s.key==='cleaning' && !isMobile ? {gridColumn:'span 2', gridRow:'span 1', display:'flex', gap:18, alignItems:'flex-start'} : {})
              }}>
              {s.popular && (
                <div style={{position:'absolute', top:12, right:12,
                  fontSize:10, fontWeight:600, padding:'3px 8px', borderRadius:999,
                  background:'#fdf0d9', color:'#c97e08', letterSpacing:.04}}>POPULAR</div>
              )}
              <div style={{
                width:52, height:52, borderRadius:14,
                background:'linear-gradient(135deg,#e8eef4 0%, #f4f7fa 100%)',
                color:'#1B4F72', display:'grid', placeItems:'center',
                marginBottom: (s.key==='cleaning' && !isMobile) ? 0 : 16,
                position:'relative', flexShrink:0,
              }}>
                {s.icon}
                <span style={{position:'absolute', inset:0, borderRadius:14, border:'1px solid rgba(255,255,255,.7)', pointerEvents:'none'}}/>
              </div>
              <div>
                <div style={{fontSize: isMobile?15:17, fontWeight:600, color:'#14181d', marginBottom:4}}>{s.title}</div>
                <div style={{fontSize: isMobile?12:13, color:'#6b7682', marginBottom:10, lineHeight:1.5}}>{s.desc}</div>
                <div style={{display:'flex',alignItems:'center',gap:10, paddingTop:10, borderTop:'1px solid #e9ecef'}}>
                  <span style={{fontSize:12, color:'#6b7682'}}>From</span>
                  <span style={{fontSize:14, fontWeight:700, color:'#1B4F72'}}>{s.from}</span>
                  <span style={{flex:1}}/>
                  <span className="kh-svc-arrow" style={{
                    width:28, height:28, borderRadius:'50%', background:'#fbfbfc', border:'1px solid #e9ecef',
                    display:'grid', placeItems:'center', color:'#1B4F72',
                    transition:'transform .2s var(--kh-ease), background .2s, color .2s',
                  }}>
                    <KhIcon.Arrow size={14} stroke="#1B4F72"/>
                  </span>
                </div>
              </div>
              <span className="kh-svc-underline" style={{
                position:'absolute', left:14, right:14, bottom:0, height:2,
                background:'#F39C12', borderRadius:2, transform:'scaleX(0)',
                transformOrigin:'left center', transition:'transform .25s var(--kh-ease)',
              }}/>
            </div>
          ))}
        </div>

        <style>{`
          .kh-card-hover:hover .kh-svc-underline { transform: scaleX(1); }
          .kh-card-hover:hover .kh-svc-arrow { background:#F39C12; color:#fff; transform:translateX(2px); }
          .kh-card-hover:hover .kh-svc-arrow svg { stroke:#1a1100 !important; }
        `}</style>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// How it works — visual timeline
// ─────────────────────────────────────────────────────────────
function KhHowItWorks({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  const steps = [
    {n:'01', t:'Pick a service', d:'Browse seven trades or search what you need.', icon:<KhIcon.Search size={20}/>, bg:'#fef9ee', fg:'#c97e08'},
    {n:'02', t:'Set time & place', d:'Now or later — choose a slot that suits you.', icon:<KhIcon.Calendar size={20}/>, bg:'#e8eef4', fg:'#1B4F72'},
    {n:'03', t:'Get matched', d:'A verified provider accepts in under 2 minutes.', icon:<KhIcon.CheckCircle size={20}/>, bg:'#e3f5ec', fg:'#1a7f47'},
    {n:'04', t:'Sit back, pay in app', d:'Track them in real time. Pay when the job is done.', icon:<KhIcon.Lock size={18}/>, bg:'#fef9ee', fg:'#c97e08'},
  ];
  return (
    <section style={{padding: isMobile?'56px 20px':'112px 32px', background:'#fff', position:'relative'}}>
      <div style={{maxWidth:1200, margin:'0 auto'}}>
        <div style={{textAlign:'center', marginBottom: isMobile?32:60}}>
          <div className="kh-eyebrow" style={{color:'#F39C12', marginBottom:10}}>How it works</div>
          <h2 className="kh-h1" style={{fontSize: isMobile?28:40, color:'#14181d', margin:0, letterSpacing:'-0.025em', textWrap:'balance'}}>
            Faster than calling someone you<br/>kind of know.
          </h2>
        </div>

        <div style={{position:'relative'}}>
          {/* Connecting line */}
          {!isMobile && (
            <svg style={{position:'absolute', top:62, left:'12.5%', right:'12.5%', width:'75%', height:40, zIndex:0}} viewBox="0 0 800 40" preserveAspectRatio="none">
              <path d="M0 20 Q 200 -10 400 20 T 800 20" fill="none" stroke="#F39C12" strokeWidth="2" strokeDasharray="4 6" strokeLinecap="round"/>
            </svg>
          )}

          <div style={{
            display:'grid',
            gridTemplateColumns: isMobile?'1fr':'repeat(4, 1fr)',
            gap: isMobile?16:24, position:'relative', zIndex:1,
          }}>
            {steps.map((s, i) => (
              <div key={s.n} style={{
                display:'flex', flexDirection: isMobile?'row':'column', gap: isMobile?14:0, alignItems: isMobile?'flex-start':'flex-start',
              }}>
                <div style={{
                  position:'relative', width: 64, height:64, borderRadius:'50%',
                  background:s.bg, color:s.fg,
                  display:'grid', placeItems:'center',
                  flexShrink:0, marginBottom: isMobile?0:18,
                  border:'4px solid #fff', boxShadow:'0 1px 0 #e9ecef',
                }}>
                  {s.icon}
                  <span style={{
                    position:'absolute', top:-6, right:-6,
                    width:26, height:26, borderRadius:'50%',
                    background:'#1B4F72', color:'#fff',
                    fontSize:11, fontWeight:700, display:'grid', placeItems:'center',
                    border:'3px solid #fff',
                  }}>{i+1}</span>
                </div>
                <div>
                  <div style={{fontSize:11, color:'#8b95a1', fontWeight:600, letterSpacing:.08, marginBottom:6}}>STEP {s.n}</div>
                  <div style={{fontSize: isMobile?16:18, fontWeight:600, color:'#14181d', marginBottom:6}}>{s.t}</div>
                  <div style={{fontSize: isMobile?13:14, color:'#6b7682', lineHeight:1.5}}>{s.d}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Time-to-book pill */}
        {!isMobile && (
          <div style={{
            marginTop:56, display:'inline-flex', alignItems:'center', gap:14,
            padding:'12px 18px', borderRadius:999, background:'#fbfbfc',
            border:'1px solid #e9ecef', position:'relative', left:'50%', transform:'translateX(-50%)',
          }}>
            <KhIcon.Clock size={16} stroke="#1B4F72"/>
            <span style={{fontSize:13, color:'#4d5763'}}>Average time from open-app to booked:</span>
            <span style={{fontSize:14, fontWeight:700, color:'#1B4F72'}}>54 seconds</span>
          </div>
        )}
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// Stats — earned numbers + city strip
// ─────────────────────────────────────────────────────────────
function KhStats({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  const stats = [
    {v:'14,200', s:'+', l:'Jobs completed', sub:'Since 2024'},
    {v:'5,200', s:'+', l:'Verified providers', sub:'Background-checked'},
    {v:'4.8', s:'★', l:'Average rating', sub:'Across 8,400 reviews'},
    {v:'6', s:'', l:'Cities covered', sub:'Beirut, Tripoli, Saida +3'},
  ];
  const cities = ['Beirut','Tripoli','Saida','Jounieh','Zahle','Byblos'];
  return (
    <section style={{
      padding: isMobile?'56px 20px':'112px 32px',
      background:'linear-gradient(180deg,#f4f7fa 0%, #fbfbfc 100%)',
    }}>
      <div style={{maxWidth:1200, margin:'0 auto'}}>
        <div style={{textAlign:'center', marginBottom: isMobile?28:48}}>
          <div className="kh-eyebrow" style={{color:'#F39C12', marginBottom:10}}>By the numbers</div>
          <h2 className="kh-h1" style={{fontSize: isMobile?28:40, color:'#14181d', margin:0, letterSpacing:'-0.025em'}}>
            Trust, earned in Lebanese homes.
          </h2>
        </div>

        <div style={{
          display:'grid',
          gridTemplateColumns: isMobile?'repeat(2, 1fr)':'repeat(4, 1fr)',
          gap: isMobile?12:20, marginBottom: isMobile?28:40,
        }}>
          {stats.map(st => (
            <div key={st.l} style={{
              background:'#fff', borderRadius:16, padding: isMobile?18:28,
              border:'1px solid #e9ecef', position:'relative', overflow:'hidden',
            }}>
              <div style={{
                fontSize: isMobile?32:48, fontWeight:700, color:'#1B4F72',
                letterSpacing:'-0.03em', lineHeight:1,
                fontVariantNumeric:'tabular-nums',
              }}>
                {st.v}<span style={{color:'#F39C12'}}>{st.s}</span>
              </div>
              <div style={{fontSize: isMobile?13:15, fontWeight:600, color:'#14181d', marginTop:10}}>{st.l}</div>
              <div style={{fontSize:12, color:'#6b7682', marginTop:2}}>{st.sub}</div>
              <div style={{
                position:'absolute', right:-10, bottom:-10, width:80, height:80,
                borderRadius:'50%', background:'radial-gradient(circle, rgba(243,156,18,.10), transparent 70%)',
                pointerEvents:'none',
              }}/>
            </div>
          ))}
        </div>

        {/* Cities strip */}
        <div style={{
          background:'#fff', borderRadius:16, padding: isMobile?'14px 16px':'18px 24px',
          border:'1px solid #e9ecef',
          display:'flex', alignItems:'center', gap: isMobile?10:24, flexWrap:'wrap',
        }}>
          <div style={{fontSize:12, color:'#6b7682', display:'flex', alignItems:'center', gap:6, fontWeight:600}}>
            <KhIcon.Pin size={14} stroke="#1B4F72"/> Live in:
          </div>
          {cities.map(c => (
            <div key={c} style={{display:'flex', alignItems:'center', gap:6, fontSize:13, color:'#1f262e'}}>
              <span style={{width:6, height:6, borderRadius:'50%', background:'#1f9d55', boxShadow:'0 0 0 3px rgba(31,157,85,.18)'}}/>
              {c}
            </div>
          ))}
          <span style={{flex:1}}/>
          <a href="#" style={{fontSize:12, color:'#1B4F72', fontWeight:600, textDecoration:'none', display:'inline-flex', alignItems:'center', gap:4}}>
            More cities soon <KhIcon.Arrow size={12} stroke="#1B4F72"/>
          </a>
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// Provider CTA — full-bleed dark band
// ─────────────────────────────────────────────────────────────
function KhProviderCta({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  return (
    <section style={{position:'relative', overflow:'hidden',
      background:'linear-gradient(120deg, #14181d 0%, #1B4F72 60%, #133e5d 100%)',
      color:'#fff', padding: isMobile?'56px 20px':'120px 32px'}}>
      {/* deco */}
      <div style={{position:'absolute', inset:0, opacity:.18, pointerEvents:'none',
        background:'radial-gradient(circle at 80% 30%, rgba(243,156,18,.5), transparent 50%)'}}/>
      <div style={{position:'absolute', inset:0, opacity:.10, pointerEvents:'none',
        backgroundImage:'linear-gradient(rgba(255,255,255,.3) 1px, transparent 1px)',
        backgroundSize:'40px 40px'}}/>

      <div style={{maxWidth:1200, margin:'0 auto', display:'grid',
        gridTemplateColumns: isMobile?'1fr':'1.1fr 1fr', gap: isMobile?32:60, alignItems:'center', position:'relative'}}>

        <div>
          <div style={{display:'inline-flex',alignItems:'center',gap:8, padding:'6px 12px',borderRadius:999,
            background:'rgba(243,156,18,.18)', color:'#F39C12', fontSize:12, fontWeight:600, marginBottom:18}}>
            <KhIcon.Bolt size={12} stroke="#F39C12"/> For Providers
          </div>
          <h2 style={{fontSize: isMobile?32:48, fontWeight:700, margin:'0 0 18px', letterSpacing:'-0.03em', textWrap:'balance', lineHeight:1.05}}>
            Your trade, on <span style={{color:'#F39C12'}}>your terms</span>.
          </h2>
          <p style={{fontSize: isMobile?15:18, color:'rgba(255,255,255,.78)', maxWidth:520, lineHeight:1.55, marginBottom:28}}>
            Set your hours, set your rates. We bring the customers, handle the payments, and never take more than 12% per job.
          </p>

          <div style={{display:'grid', gridTemplateColumns: isMobile?'1fr 1fr':'repeat(3, 1fr)', gap:16, marginBottom:32}}>
            {[
              {v:'5,200+', l:'Active providers'},
              {v:'$3,000', l:'Avg monthly income'},
              {v:'12%', l:'Flat platform fee'},
            ].map((s, i) => (
              <div key={i} style={{
                padding:'14px 16px', borderRadius:12,
                background:'rgba(255,255,255,.06)', border:'1px solid rgba(255,255,255,.10)',
              }}>
                <div style={{fontSize: isMobile?20:24, fontWeight:700, color:'#F39C12', letterSpacing:'-0.02em'}}>{s.v}</div>
                <div style={{fontSize:12, color:'rgba(255,255,255,.7)'}}>{s.l}</div>
              </div>
            ))}
          </div>

          <div style={{display:'flex', gap:12, flexWrap:'wrap'}}>
            <button className="kh-btn kh-btn-primary kh-btn-lg">
              Become a provider <KhIcon.Arrow size={16} stroke="#1a1100"/>
            </button>
            <button className="kh-btn kh-btn-ghost kh-btn-lg">Learn more</button>
          </div>

          <div style={{marginTop:24, display:'inline-flex', alignItems:'center', gap:10, color:'rgba(255,255,255,.65)', fontSize:12}}>
            <KhIcon.Shield size={14} stroke="rgba(255,255,255,.65)"/>
            Free to join · Same-day approval · Insured jobs
          </div>
        </div>

        {/* Provider portrait card */}
        {!isMobile && (
          <div style={{position:'relative'}}>
            <KhProviderCard/>
          </div>
        )}
      </div>
    </section>
  );
}

function KhProviderCard() {
  // Stylized portrait card: silhouette + earnings tile + reviews
  return (
    <div style={{position:'relative', width:'100%', maxWidth:440, marginLeft:'auto'}}>
      {/* Main portrait */}
      <div style={{
        aspectRatio:'4/5', borderRadius:24, overflow:'hidden',
        background:'linear-gradient(180deg,#2c6494 0%, #1B4F72 100%)',
        position:'relative', boxShadow:'0 24px 60px rgba(0,0,0,.4)',
      }}>
        {/* Abstract background pattern */}
        <svg width="100%" height="100%" viewBox="0 0 400 500" preserveAspectRatio="xMidYMid slice" style={{position:'absolute', inset:0}}>
          <defs>
            <radialGradient id="khPg" cx="50%" cy="40%" r="60%">
              <stop offset="0" stopColor="#4682b4" stopOpacity=".7"/>
              <stop offset="1" stopColor="#0d2f47" stopOpacity="1"/>
            </radialGradient>
          </defs>
          <rect width="400" height="500" fill="url(#khPg)"/>
          {/* Tools as decoration */}
          <g opacity=".18" stroke="#F39C12" strokeWidth="1.5" fill="none">
            <path d="M50 80 L 80 110 L 70 120 L 40 90 Z"/>
            <path d="M340 60 q 20 10 0 30"/>
            <circle cx="350" cy="200" r="20"/>
            <path d="M40 380 h 60 v 12 h -60 z"/>
          </g>
          {/* Silhouette */}
          <circle cx="200" cy="200" r="62" fill="#1f262e"/>
          <path d="M120 460 Q 200 300 280 460 Z" fill="#1f262e"/>
          {/* Apron */}
          <path d="M155 280 L 245 280 L 230 460 L 170 460 Z" fill="#F39C12" opacity=".9"/>
          <rect x="180" y="320" width="40" height="44" fill="#1B4F72" opacity=".4"/>
        </svg>

        {/* Verified badge */}
        <div style={{position:'absolute', top:18, left:18,
          padding:'6px 12px', borderRadius:999, background:'rgba(0,0,0,.4)',
          backdropFilter:'blur(10px)', display:'inline-flex', alignItems:'center', gap:6,
          fontSize:12, fontWeight:600,
        }}>
          <KhIcon.Verified size={14}/> ID Verified
        </div>

        {/* Name plate */}
        <div style={{position:'absolute', left:18, right:18, bottom:18,
          padding:'14px 16px', borderRadius:14, background:'rgba(20,24,29,.7)',
          backdropFilter:'blur(14px)', border:'1px solid rgba(255,255,255,.10)',
        }}>
          <div style={{fontSize:11, color:'rgba(255,255,255,.6)', letterSpacing:.08, textTransform:'uppercase', fontWeight:600}}>Top earner this week</div>
          <div style={{fontSize:18, fontWeight:700, marginTop:2}}>Rami H. — Electrician</div>
          <div style={{fontSize:12, color:'rgba(255,255,255,.7)', marginTop:4, display:'flex', gap:8, alignItems:'center'}}>
            <KhStars rating={4.9} size={11}/> 4.9 · 312 jobs · Achrafieh
          </div>
        </div>
      </div>

      {/* Earnings card overlay */}
      <div style={{
        position:'absolute', right:-14, top:60,
        background:'#fff', color:'#14181d', padding:14, borderRadius:14,
        boxShadow:'0 12px 32px rgba(0,0,0,.25)', minWidth:180,
        transform:'rotate(3deg)',
      }}>
        <div style={{fontSize:11, color:'#6b7682', fontWeight:600}}>This week</div>
        <div style={{fontSize:24, fontWeight:700, color:'#1B4F72', letterSpacing:'-0.02em'}}>$842</div>
        <div style={{fontSize:11, color:'#1a7f47', display:'flex', alignItems:'center', gap:4, marginTop:2}}>
          <svg width="10" height="10" viewBox="0 0 12 12" fill="#1a7f47"><path d="M6 1l5 5h-3v5h-4V6h-3z"/></svg>
          18% vs last week
        </div>
        <div style={{height:30, marginTop:8}}>
          <svg width="100%" height="30" viewBox="0 0 140 30">
            <path d="M0 22 L 20 18 L 40 24 L 60 14 L 80 18 L 100 8 L 120 12 L 140 4" stroke="#F39C12" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            <path d="M0 22 L 20 18 L 40 24 L 60 14 L 80 18 L 100 8 L 120 12 L 140 4 L 140 30 L 0 30 Z" fill="rgba(243,156,18,.12)"/>
          </svg>
        </div>
      </div>

      {/* Review card */}
      <div style={{
        position:'absolute', left:-18, bottom:80,
        background:'#fff', color:'#14181d', padding:'12px 14px', borderRadius:14,
        boxShadow:'0 12px 32px rgba(0,0,0,.25)', maxWidth:200,
        transform:'rotate(-2deg)',
      }}>
        <KhStars rating={5} size={11}/>
        <div style={{fontSize:12, color:'#1f262e', marginTop:6, lineHeight:1.45}}>
          "On time, fair price. He even cleaned up after."
        </div>
        <div style={{fontSize:10, color:'#6b7682', marginTop:6}}>— Layal K., Hamra</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Contact form
// ─────────────────────────────────────────────────────────────
function KhContact({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  const [state, setState] = React.useState({ name:'', email:'', message:'' });
  const [touched, setTouched] = React.useState({});
  const [submitted, setSubmitted] = React.useState(false);

  const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(state.email);
  const showEmailError = touched.email && state.email && !emailValid;
  const submit = (e) => { e.preventDefault(); if (state.name && emailValid && state.message) setSubmitted(true); };

  return (
    <section style={{padding: isMobile?'56px 20px':'112px 32px', background:'#fbfbfc'}}>
      <div style={{maxWidth:980, margin:'0 auto', display:'grid', gridTemplateColumns: isMobile?'1fr':'1fr 1.2fr', gap: isMobile?28:48, alignItems:'flex-start'}}>
        <div>
          <div className="kh-eyebrow" style={{color:'#F39C12', marginBottom:10}}>Contact us</div>
          <h2 className="kh-h1" style={{fontSize: isMobile?28:36, color:'#14181d', margin:'0 0 14px', letterSpacing:'-0.025em'}}>
            Question, feedback, or partnership?
          </h2>
          <p style={{fontSize:15, color:'#4d5763', lineHeight:1.6, margin:'0 0 24px'}}>
            We answer every message within one business day. No bots, no tickets — just our team in Beirut.
          </p>
          <div style={{display:'flex', flexDirection:'column', gap:12}}>
            <ContactRow icon={<KhIcon.Mail size={16} stroke="#1B4F72"/>} label="Email" value="info@khudmati.app"/>
            <ContactRow icon={<KhIcon.Phone size={16} stroke="#1B4F72"/>} label="Phone" value="+961 70 000 000"/>
            <ContactRow icon={<KhIcon.Pin size={16} stroke="#1B4F72"/>} label="Office" value="Hamra, Beirut · Lebanon"/>
          </div>
        </div>

        <div className="kh-card" style={{padding: isMobile?20:32, background:'#fff', borderRadius:18}}>
          {submitted ? (
            <div style={{textAlign:'center', padding:'24px 0'}}>
              <div style={{
                width:64, height:64, borderRadius:'50%', margin:'0 auto 18px',
                background:'#e3f5ec', color:'#1a7f47', display:'grid', placeItems:'center'
              }}>
                <KhIcon.Check size={28} stroke="#1a7f47"/>
              </div>
              <div style={{fontSize:20, fontWeight:600, color:'#14181d', marginBottom:6}}>Message sent</div>
              <div style={{fontSize:14, color:'#6b7682'}}>We'll be in touch within one business day.</div>
            </div>
          ) : (
            <form onSubmit={submit}>
              <div style={{marginBottom:14}}>
                <label className="kh-label">Your name</label>
                <input className="kh-input" placeholder="Layal Khoury"
                  value={state.name} onChange={e=>setState({...state, name:e.target.value})}
                  onBlur={()=>setTouched({...touched, name:true})}/>
              </div>
              <div style={{marginBottom:14}}>
                <label className="kh-label">Email</label>
                <input className={`kh-input ${showEmailError?'kh-input-error':''}`} placeholder="layal@example.com" type="email"
                  value={state.email} onChange={e=>setState({...state, email:e.target.value})}
                  onBlur={()=>setTouched({...touched, email:true})}/>
                {showEmailError && <div style={{fontSize:12, color:'#c53030', marginTop:6}}>Please enter a valid email address.</div>}
              </div>
              <div style={{marginBottom:18}}>
                <label className="kh-label">Message</label>
                <textarea className="kh-input kh-textarea" placeholder="How can we help?"
                  value={state.message} onChange={e=>setState({...state, message:e.target.value})}/>
              </div>
              <button type="submit" className="kh-btn kh-btn-dark" style={{width:'100%', height:48}}>
                Send message <KhIcon.Arrow size={14} stroke="#fff"/>
              </button>
              <div style={{fontSize:11, color:'#8b95a1', textAlign:'center', marginTop:12}}>
                <KhIcon.Lock size={11} stroke="#8b95a1"/> Your details are private. We never share or sell.
              </div>
            </form>
          )}
        </div>
      </div>
    </section>
  );
}

function ContactRow({icon, label, value}) {
  return (
    <div style={{display:'flex', gap:12, alignItems:'center'}}>
      <div style={{width:36, height:36, borderRadius:10, background:'#e8eef4', display:'grid', placeItems:'center', flexShrink:0}}>{icon}</div>
      <div>
        <div style={{fontSize:11, color:'#8b95a1', fontWeight:600, letterSpacing:.04, textTransform:'uppercase'}}>{label}</div>
        <div style={{fontSize:14, color:'#14181d', fontWeight:500}}>{value}</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────
function KhFooter({ viewport='desktop' }) {
  const isMobile = viewport === 'mobile';
  return (
    <footer style={{background:'#0d2f47', color:'#cdd9e4', padding: isMobile?'40px 20px 20px':'72px 32px 28px'}}>
      <div style={{maxWidth:1200, margin:'0 auto'}}>

        {/* Trust bar */}
        <div style={{
          display:'flex', flexWrap:'wrap', gap: isMobile?12:20, alignItems:'center', justifyContent:'space-between',
          padding: isMobile?'14px 0':'18px 0', borderBottom:'1px solid rgba(255,255,255,.10)', marginBottom: isMobile?28:48,
        }}>
          <div style={{fontSize:11, color:'rgba(255,255,255,.6)', letterSpacing:.08, textTransform:'uppercase', fontWeight:600}}>Secure & trusted</div>
          <div style={{display:'flex', gap: isMobile?14:24, flexWrap:'wrap', alignItems:'center', opacity:.85}}>
            <TrustBadge label="Stripe payments"/>
            <TrustBadge label="Visa · Mastercard"/>
            <TrustBadge label="OMT · Whish"/>
            <TrustBadge label="SSL secured"/>
            <TrustBadge label="Background-checked pros"/>
          </div>
        </div>

        <div style={{display:'grid',
          gridTemplateColumns: isMobile?'1fr':'1.4fr repeat(3, 1fr) 1.2fr',
          gap: isMobile?32:36,
        }}>
          <div>
            <KhLogo white/>
            <p style={{fontSize:13, color:'rgba(255,255,255,.7)', lineHeight:1.6, margin:'14px 0 18px', maxWidth:320}}>
              Khudmati connects homeowners with trusted service providers across Lebanon. Built in Beirut, available everywhere from Tripoli to Saida.
            </p>
            <div style={{display:'flex', gap:10}}>
              <SocialBtn><KhIcon.Instagram size={16} stroke="#fff"/></SocialBtn>
              <SocialBtn><KhIcon.X size={14} fill="#fff"/></SocialBtn>
              <SocialBtn><KhIcon.LinkedIn size={16} fill="#fff"/></SocialBtn>
            </div>
          </div>

          <FooterCol title="Services" items={['Cleaning','Plumbing','Electrical','AC service','Carpentry','Painting','Moving']}/>
          <FooterCol title="Company" items={['About','Careers','Press','Blog','Become a provider']}/>
          <FooterCol title="Support" items={['Help center','Safety','Trust & verification','Cancellation policy','Contact us']}/>

          <div>
            <div style={{fontSize:13, fontWeight:600, color:'#fff', marginBottom:14}}>Get the app</div>
            <div style={{display:'flex', flexDirection:'column', gap:10, marginBottom:18}}>
              <KhAppStoreBadge store="ios"/>
              <KhAppStoreBadge store="android"/>
            </div>
          </div>
        </div>

        <div style={{
          marginTop: isMobile?28:56, paddingTop: isMobile?18:24, borderTop:'1px solid rgba(255,255,255,.10)',
          display:'flex', flexWrap:'wrap', gap:12, justifyContent:'space-between', alignItems:'center',
          fontSize:12, color:'rgba(255,255,255,.55)',
        }}>
          <div>© 2026 Khudmati SAL · Beirut, Lebanon · All rights reserved</div>
          <div style={{display:'flex', gap:18}}>
            <a href="#" style={{color:'inherit', textDecoration:'none'}}>Privacy</a>
            <a href="#" style={{color:'inherit', textDecoration:'none'}}>Terms</a>
            <a href="#" style={{color:'inherit', textDecoration:'none'}}>Cookies</a>
          </div>
        </div>
      </div>
    </footer>
  );
}

function FooterCol({title, items}) {
  return (
    <div>
      <div style={{fontSize:13, fontWeight:600, color:'#fff', marginBottom:14}}>{title}</div>
      <div style={{display:'flex', flexDirection:'column', gap:8}}>
        {items.map(it => (
          <a key={it} href="#" style={{fontSize:13, color:'rgba(255,255,255,.7)', textDecoration:'none'}}>{it}</a>
        ))}
      </div>
    </div>
  );
}

function TrustBadge({label}) {
  return (
    <div style={{display:'inline-flex', alignItems:'center', gap:6, fontSize:12, color:'rgba(255,255,255,.75)', fontWeight:500}}>
      <KhIcon.CheckCircle size={14} stroke="#F39C12"/> {label}
    </div>
  );
}
function SocialBtn({children}) {
  return (
    <a href="#" style={{
      width:36, height:36, borderRadius:10,
      background:'rgba(255,255,255,.08)', border:'1px solid rgba(255,255,255,.14)',
      display:'grid', placeItems:'center', textDecoration:'none',
    }}>{children}</a>
  );
}

Object.assign(window, { KhServicesGrid, KhHowItWorks, KhStats, KhProviderCta, KhContact, KhFooter });

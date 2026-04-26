// Khudmati — Hero variants
// Three approaches; selected via tweak.

// Shared hero chrome
function KhHeroChip({ icon, children, white=true }) {
  return (
    <div style={{
      display:'inline-flex', alignItems:'center', gap:8,
      padding:'7px 12px', borderRadius:999,
      background: white ? 'rgba(255,255,255,.10)' : '#fff',
      border: white ? '1px solid rgba(255,255,255,.18)' : '1px solid #e9ecef',
      color: white ? '#fff' : '#1f262e',
      fontSize:13, fontWeight:500,
      backdropFilter:'blur(8px)',
    }}>
      {icon}{children}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Variant A — Split editorial: Headline + booking-state phone mockup
// ─────────────────────────────────────────────────────────────
function KhHeroSplit({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  return (
    <section style={{
      position:'relative', overflow:'hidden',
      background:'linear-gradient(160deg, #0d2f47 0%, #1B4F72 60%, #1d5a82 100%)',
      color:'#fff',
    }}>
      {/* Decorative grid */}
      <div style={{position:'absolute', inset:0, opacity:.18, pointerEvents:'none',
        backgroundImage:'radial-gradient(circle at 20% 20%, rgba(243,156,18,.4) 0, transparent 40%), radial-gradient(circle at 80% 80%, rgba(70,130,180,.5) 0, transparent 50%)'}} />
      <div style={{position:'absolute', inset:0, opacity:.10, pointerEvents:'none',
        backgroundImage:"linear-gradient(rgba(255,255,255,.4) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.4) 1px, transparent 1px)",
        backgroundSize:'48px 48px'}} />

      <div style={{
        maxWidth:1280, margin:'0 auto',
        padding: isMobile ? '40px 20px 60px' : '80px 32px 100px',
        display:'grid',
        gridTemplateColumns: isMobile ? '1fr' : '1.05fr 1fr',
        gap: isMobile ? 36 : 48,
        alignItems:'center', position:'relative',
      }}>
        <div className={motion?'kh-fade-up kh-in':''}>
          <KhHeroChip icon={<span style={{
            width:6,height:6,borderRadius:'50%',background:'#1f9d55',boxShadow:'0 0 0 4px rgba(31,157,85,.25)'
          }}/>}>
            342 providers online in Beirut now
          </KhHeroChip>

          <h1 className="kh-display" style={{
            fontSize: isMobile ? 40 : 64,
            margin:'20px 0 18px', letterSpacing:'-0.03em', textWrap:'balance',
          }}>
            Home help that<br/>
            actually <span style={{color:'#F39C12', fontStyle:'italic', fontWeight:600}}>shows up</span>.
          </h1>
          <p style={{fontSize: isMobile?16:18, maxWidth:480, color:'rgba(255,255,255,.78)', lineHeight:1.55, margin:'0 0 28px'}}>
            Book a verified plumber, electrician or cleaner in 60 seconds. Track them to your door. Pay through the app — no cash, no haggling.
          </p>
          <div style={{display:'flex', gap:12, flexWrap:'wrap', marginBottom:28}}>
            <button className="kh-btn kh-btn-primary kh-btn-lg">
              <KhIcon.Apple size={18} fill="#1a1100" />Download for iOS
            </button>
            <button className="kh-btn kh-btn-ghost kh-btn-lg">
              <svg width="18" height="20" viewBox="0 0 24 26" fill="#fff"><path d="M3 1l13 12L3 25z" opacity=".95"/></svg>
              Get it on Android
            </button>
          </div>
          <div style={{display:'flex', alignItems:'center', gap: isMobile?14:24, flexWrap:'wrap',
            paddingTop:18, borderTop:'1px solid rgba(255,255,255,.10)'}}>
            <div style={{display:'flex', alignItems:'center', gap:8}}>
              <div style={{display:'flex'}}>
                {['#F39C12','#4682b4','#1f9d55','#c97e08'].map((c,i)=>(
                  <div key={i} style={{width:28,height:28,borderRadius:'50%',background:c,border:'2px solid #1B4F72', marginLeft:i?-8:0}} />
                ))}
              </div>
              <div style={{lineHeight:1.2}}>
                <div style={{fontSize:13,fontWeight:600}}>14,200+ jobs done</div>
                <div style={{fontSize:11, color:'rgba(255,255,255,.6)'}}>across Lebanon</div>
              </div>
            </div>
            <div style={{display:'flex', alignItems:'center', gap:8}}>
              <KhStars rating={4.8} size={14} />
              <div style={{lineHeight:1.2}}>
                <div style={{fontSize:13,fontWeight:600}}>4.8 / 5</div>
                <div style={{fontSize:11, color:'rgba(255,255,255,.6)'}}>App Store rating</div>
              </div>
            </div>
          </div>
        </div>

        {/* Phone mockup */}
        <div style={{position:'relative', display:'flex', justifyContent: isMobile?'center':'flex-end', alignItems:'center'}}>
          <KhPhoneMock state="enroute" motion={motion} scale={isMobile?0.85:1} />
        </div>
      </div>

      {/* Bottom curve */}
      <svg viewBox="0 0 1440 80" preserveAspectRatio="none" style={{display:'block', width:'100%', height: isMobile?40:64, marginBottom:-1}}>
        <path d="M0 40 C 360 80 1080 0 1440 40 L 1440 80 L 0 80 Z" fill="#fbfbfc"/>
      </svg>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// Variant B — Service-icon collage hero
// ─────────────────────────────────────────────────────────────
function KhHeroCollage({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  const items = [
    {icon:<KhIcon.Cleaning size={28}/>, label:'Cleaning', x:'8%', y:'22%', delay:0, color:'#F39C12'},
    {icon:<KhIcon.Plumbing size={28}/>, label:'Plumbing', x:'18%', y:'62%', delay:.1, color:'#4682b4'},
    {icon:<KhIcon.Electrical size={28}/>, label:'Electrical', x:'78%', y:'18%', delay:.2, color:'#F39C12'},
    {icon:<KhIcon.AC size={28}/>, label:'AC repair', x:'85%', y:'58%', delay:.15, color:'#1B4F72'},
    {icon:<KhIcon.Painting size={28}/>, label:'Painting', x:'72%', y:'78%', delay:.25, color:'#4682b4'},
    {icon:<KhIcon.Carpentry size={28}/>, label:'Carpentry', x:'14%', y:'82%', delay:.3, color:'#1B4F72'},
  ];
  return (
    <section style={{
      position:'relative', overflow:'hidden',
      background:'linear-gradient(180deg, #fbfbfc 0%, #f4f7fa 100%)',
      color:'#1f262e',
    }}>
      {/* Floating service tiles */}
      {!isMobile && items.map((it, i) => (
        <div key={i} className={motion?'kh-fade-up kh-in':''}
          style={{
            position:'absolute', left:it.x, top:it.y,
            transition:`transform .6s var(--kh-ease-out) ${it.delay}s, opacity .6s ease ${it.delay}s`,
            zIndex:1,
            transform: `rotate(${(i%2?1:-1)*4}deg)`,
          }}>
          <div className="kh-card kh-card-hover" style={{
            padding:'14px 16px', display:'flex', alignItems:'center', gap:10,
            boxShadow:'0 12px 32px rgba(20,24,29,.08), 0 1px 0 rgba(255,255,255,.6) inset',
          }}>
            <div style={{
              width:42,height:42, borderRadius:10,
              background: it.color==='#F39C12'?'#fef9ee':'#e8eef4',
              color:it.color,
              display:'grid', placeItems:'center'
            }}>{it.icon}</div>
            <div>
              <div style={{fontSize:14, fontWeight:600}}>{it.label}</div>
              <div style={{fontSize:11, color:'#6b7682'}}>from $25 · 25 min</div>
            </div>
          </div>
        </div>
      ))}

      <div style={{
        maxWidth:780, margin:'0 auto',
        padding: isMobile ? '60px 20px 80px' : '120px 32px 140px',
        position:'relative', zIndex:2, textAlign:'center',
      }}>
        <KhHeroChip white={false} icon={<KhIcon.Pin size={13} stroke="#1B4F72"/>}>
          <span style={{color:'#1B4F72'}}>Available across Lebanon</span>
        </KhHeroChip>
        <h1 className="kh-display" style={{
          fontSize: isMobile?40:72, margin:'22px auto 18px',
          letterSpacing:'-0.035em', maxWidth:680, textWrap:'balance',
        }}>
          Seven trades.<br/>One tap.{' '}
          <span style={{
            background:'linear-gradient(120deg, #F39C12 0%, #c97e08 100%)',
            WebkitBackgroundClip:'text', backgroundClip:'text', color:'transparent',
          }}>Zero hassle.</span>
        </h1>
        <p style={{fontSize: isMobile?16:19, color:'#4d5763', maxWidth:540, margin:'0 auto 32px', lineHeight:1.55}}>
          Verified pros for plumbing, electrical, cleaning, AC, carpentry, painting and moving — booked in seconds, paid in app.
        </p>

        {/* Inline service search */}
        <div style={{
          maxWidth:540, margin:'0 auto', background:'#fff',
          border:'1px solid #e9ecef', borderRadius:14, padding:6,
          display:'flex', alignItems:'center', gap:6,
          boxShadow:'0 16px 40px rgba(20,24,29,.08)',
        }}>
          <div style={{padding:'0 10px', color:'#8b95a1'}}><KhIcon.Search size={18}/></div>
          <input placeholder="What do you need fixed?"
            style={{flex:1, border:'none', outline:'none', height:44, fontSize:15, background:'transparent', fontFamily:'inherit'}} />
          <button className="kh-btn kh-btn-primary">Find a pro</button>
        </div>

        <div style={{marginTop:22, display:'inline-flex',gap:10,flexWrap:'wrap',justifyContent:'center', color:'#6b7682', fontSize:13}}>
          <span>Popular:</span>
          {['AC service','Pipe leak','Deep clean','Wall paint'].map(t=>(
            <a key={t} href="#" style={{color:'#1B4F72', textDecoration:'underline', textDecorationThickness:1, textUnderlineOffset:3}}>{t}</a>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// Variant C — Map-led / live ETA
// ─────────────────────────────────────────────────────────────
function KhHeroMap({ viewport='desktop', motion=true }) {
  const isMobile = viewport === 'mobile';
  return (
    <section style={{
      position:'relative', overflow:'hidden',
      background:'#0d2f47', color:'#fff',
    }}>
      <div style={{
        maxWidth:1280, margin:'0 auto',
        padding: isMobile ? '32px 20px 0' : '64px 32px 0',
        display:'grid',
        gridTemplateColumns: isMobile ? '1fr' : '1fr 1.1fr',
        gap: isMobile ? 24 : 56,
        alignItems:'center', position:'relative',
      }}>
        <div className={motion?'kh-fade-up kh-in':''}>
          <KhHeroChip icon={<KhIcon.Pin size={13}/>}>Now serving Beirut, Tripoli, Saida</KhHeroChip>
          <h1 className="kh-display" style={{
            fontSize: isMobile ? 38 : 60, margin:'18px 0 18px',
            letterSpacing:'-0.03em', textWrap:'balance',
          }}>
            Track your tradesman<br/>like a taxi.
          </h1>
          <p style={{fontSize: isMobile?15:18, color:'rgba(255,255,255,.78)', maxWidth:480, lineHeight:1.55, marginBottom:28}}>
            See your provider's ETA the moment they accept. Average response in Beirut: <b style={{color:'#F39C12'}}>13 minutes</b>.
          </p>
          <div style={{display:'flex', gap:12, flexWrap:'wrap'}}>
            <button className="kh-btn kh-btn-primary kh-btn-lg">Book a service</button>
            <button className="kh-btn kh-btn-ghost kh-btn-lg">
              <KhIcon.Play size={14} fill="#fff"/>How it works
            </button>
          </div>

          <div style={{marginTop:32, display:'flex', gap:24, flexWrap:'wrap'}}>
            {[
              {n:'13 min', l:'Avg response'},
              {n:'4.8 ★', l:'Provider rating'},
              {n:'5,200+', l:'Verified pros'},
            ].map(s => (
              <div key={s.l}>
                <div style={{fontSize:24,fontWeight:700, color:'#F39C12', letterSpacing:'-0.02em'}}>{s.n}</div>
                <div style={{fontSize:12, color:'rgba(255,255,255,.6)'}}>{s.l}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{position:'relative', minHeight: isMobile?320:480}}>
          <KhMapMock motion={motion}/>
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────────────────────
// Phone mockup (used in Hero A)
// ─────────────────────────────────────────────────────────────
function KhPhoneMock({ state='enroute', motion=true, scale=1 }) {
  return (
    <div style={{
      width: 320*scale, height: 640*scale, position:'relative',
      transform:`rotate(-3deg)`, transformOrigin:'center',
      filter:'drop-shadow(0 30px 60px rgba(0,0,0,.35))',
    }}>
      <div style={{
        width:'100%', height:'100%', borderRadius: 44*scale,
        background:'#0a0d10',
        padding: 8*scale, position:'relative',
      }}>
        <div style={{
          width:'100%', height:'100%', borderRadius: 36*scale,
          background:'#fbfbfc', position:'relative', overflow:'hidden',
        }}>
          {/* Status bar */}
          <div style={{
            display:'flex', justifyContent:'space-between', alignItems:'center',
            padding: `${14*scale}px ${24*scale}px ${4*scale}px`, fontSize: 13*scale, fontWeight:600,
          }}>
            <span>9:41</span>
            <span style={{display:'inline-flex',gap:4*scale,alignItems:'center'}}>
              <span style={{width:14*scale,height:8*scale,background:'#1f262e',borderRadius:1}}></span>
              <span style={{width:18*scale,height:10*scale,border:'1.5px solid #1f262e',borderRadius:2}}></span>
            </span>
          </div>

          {/* Header */}
          <div style={{padding:`${16*scale}px ${20*scale}px ${10*scale}px`, display:'flex', alignItems:'center', justifyContent:'space-between'}}>
            <button style={{width:36*scale,height:36*scale,borderRadius:18*scale,background:'#f5f6f8',border:'none',display:'grid',placeItems:'center'}}>
              <svg width={16*scale} height={16*scale} viewBox="0 0 24 24" fill="none" stroke="#1f262e" strokeWidth="2" strokeLinecap="round"><path d="M15 18l-6-6 6-6"/></svg>
            </button>
            <div style={{fontWeight:600, fontSize:15*scale}}>Booking #4827</div>
            <div style={{width:36*scale}}/>
          </div>

          {/* Map preview */}
          <div style={{
            margin:`0 ${16*scale}px`, height: 220*scale, borderRadius:18*scale,
            background:'linear-gradient(180deg, #e8eef4 0%, #d5dae0 100%)', position:'relative',
            overflow:'hidden', border:'1px solid #e9ecef',
          }}>
            <KhMapPaths scale={scale}/>
            <div style={{
              position:'absolute', left:'30%', top:'40%',
              width:32*scale, height:32*scale, borderRadius:'50%',
              background:'#1B4F72', border:`3px solid #fff`, boxShadow:'0 4px 12px rgba(0,0,0,.2)',
              display:'grid', placeItems:'center', color:'#fff', fontSize:14*scale, fontWeight:600,
            }}>RH</div>
            <div style={{
              position:'absolute', right:'22%', bottom:'25%',
              width:24*scale, height:24*scale, borderRadius:'50%',
              background:'#F39C12', border:`3px solid #fff`,
              animation: motion?'khPulse 2.4s ease-out infinite':'none',
            }}/>
          </div>

          {/* Provider card */}
          <div style={{padding:`${18*scale}px ${20*scale}px`}}>
            <div style={{display:'flex', alignItems:'center', gap:12*scale}}>
              <div style={{position:'relative'}}>
                <KhAvatar name="Rami Hajjar" size={44*scale} bg="#1B4F72"/>
                <span style={{position:'absolute', bottom:-2, right:-2}}><KhIcon.Verified size={16*scale}/></span>
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:15*scale, fontWeight:600, display:'flex', alignItems:'center', gap:6*scale}}>
                  Rami H. <span style={{fontSize:11*scale,padding:'2px 6px',background:'#fdf0d9',color:'#c97e08',borderRadius:4,fontWeight:600}}>Pro</span>
                </div>
                <div style={{fontSize:12*scale, color:'#6b7682', display:'flex', alignItems:'center', gap:6*scale}}>
                  <KhStars rating={4.9} size={11*scale}/> 4.9 · 312 jobs
                </div>
              </div>
              <div style={{textAlign:'right'}}>
                <div style={{fontSize:11*scale, color:'#6b7682'}}>Arriving in</div>
                <div style={{fontSize:18*scale, fontWeight:700, color:'#1B4F72'}}>8 min</div>
              </div>
            </div>

            <div style={{marginTop:14*scale, padding:12*scale, borderRadius:12*scale, background:'#f5f6f8',
              display:'flex', justifyContent:'space-between', alignItems:'center'}}>
              <div>
                <div style={{fontSize:12*scale, color:'#6b7682'}}>Service</div>
                <div style={{fontSize:14*scale, fontWeight:600}}>AC repair · split unit</div>
              </div>
              <div style={{textAlign:'right'}}>
                <div style={{fontSize:12*scale, color:'#6b7682'}}>Estimate</div>
                <div style={{fontSize:14*scale, fontWeight:600}}>$45–60</div>
              </div>
            </div>

            <div style={{marginTop:12*scale, display:'flex', gap:8*scale}}>
              <button style={{flex:1, height:42*scale, borderRadius:10*scale, background:'#1B4F72', color:'#fff', border:'none', fontWeight:600, fontSize:13*scale}}>
                <KhIcon.Phone size={13*scale} stroke="#fff"/> Call provider
              </button>
              <button style={{width:42*scale, height:42*scale, borderRadius:10*scale, background:'#fff', border:'1px solid #e9ecef', display:'grid', placeItems:'center'}}>
                <svg width={16*scale} height={16*scale} viewBox="0 0 24 24" fill="none" stroke="#1f262e" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
              </button>
            </div>
          </div>
        </div>
      </div>
      <style>{`@keyframes khPulse{0%{box-shadow:0 0 0 0 rgba(243,156,18,.45)}80%{box-shadow:0 0 0 18px rgba(243,156,18,0)}100%{box-shadow:0 0 0 0 rgba(243,156,18,0)}}`}</style>
    </div>
  );
}

function KhMapPaths({scale=1}) {
  return (
    <svg width="100%" height="100%" viewBox="0 0 320 220" style={{position:'absolute', inset:0}}>
      <defs>
        <pattern id="khRoads" patternUnits="userSpaceOnUse" width="40" height="40">
          <rect width="40" height="40" fill="#e8eef4"/>
          <path d="M0 20h40M20 0v40" stroke="#fff" strokeWidth="2"/>
        </pattern>
      </defs>
      <rect width="320" height="220" fill="url(#khRoads)" opacity=".7"/>
      <path d="M0 60 Q 60 80 120 90 T 320 110" stroke="#b3bcc6" strokeWidth="3" fill="none"/>
      <path d="M40 0 Q 80 60 140 100 T 280 220" stroke="#b3bcc6" strokeWidth="3" fill="none"/>
      <path d="M96 88 Q 150 110 220 160" stroke="#F39C12" strokeWidth="3" strokeDasharray="6 4" fill="none"/>
    </svg>
  );
}

// Map mock for Hero C — Beirut-ish abstract map
function KhMapMock({motion=true}) {
  return (
    <div style={{
      position:'relative', height:'100%', minHeight:480,
      borderRadius:'24px 24px 0 0', overflow:'hidden',
      background:'linear-gradient(180deg, #e8eef4 0%, #d5dae0 100%)',
      boxShadow:'0 20px 60px rgba(0,0,0,.4)',
      marginTop:24,
    }}>
      <svg width="100%" height="100%" viewBox="0 0 600 480" preserveAspectRatio="xMidYMid slice" style={{position:'absolute', inset:0}}>
        {/* Sea */}
        <rect width="600" height="480" fill="#cdd9e4"/>
        {/* Coastline */}
        <path d="M0 220 Q 80 200 180 230 Q 280 260 360 240 Q 440 220 520 250 L 600 240 L 600 480 L 0 480 Z"
          fill="#f4f7fa"/>
        {/* Roads */}
        {Array.from({length:6}).map((_,i)=>(
          <path key={i} d={`M${20+i*100} 480 Q ${100+i*80} ${300-i*15} ${600-i*30} ${260+i*20}`}
            stroke="#b3bcc6" strokeWidth={i%2?1.5:2.5} fill="none"/>
        ))}
        {Array.from({length:5}).map((_,i)=>(
          <path key={'h'+i} d={`M0 ${260+i*40} Q 200 ${250+i*40} 600 ${280+i*30}`}
            stroke="#b3bcc6" strokeWidth="1.5" fill="none" opacity=".7"/>
        ))}
        {/* Districts */}
        <text x="180" y="320" fill="#6b7682" fontSize="11" fontWeight="600" fontFamily="Inter">Hamra</text>
        <text x="340" y="360" fill="#6b7682" fontSize="11" fontWeight="600" fontFamily="Inter">Ashrafieh</text>
        <text x="240" y="430" fill="#6b7682" fontSize="11" fontWeight="600" fontFamily="Inter">Verdun</text>
        <text x="60" y="240" fill="#8b95a1" fontSize="10" fontStyle="italic" fontFamily="Inter">Mediterranean</text>
        {/* Route */}
        <path d="M150 380 Q 240 340 320 360 T 460 320" stroke="#F39C12" strokeWidth="4" fill="none" strokeLinecap="round" strokeDasharray="8 5"/>
      </svg>

      {/* Pins */}
      <div style={{position:'absolute', left:'24%', top:'72%'}}>
        <div style={{position:'relative'}}>
          <div style={{width:38,height:38,borderRadius:'50%', background:'#1B4F72', border:'3px solid #fff', boxShadow:'0 4px 14px rgba(0,0,0,.25)', display:'grid', placeItems:'center', color:'#fff'}}>
            <KhIcon.Pin size={18} stroke="#fff"/>
          </div>
          <div style={{position:'absolute', top:46, left:-30, background:'#fff', padding:'6px 10px', borderRadius:8, boxShadow:'0 4px 12px rgba(0,0,0,.12)', fontSize:11, fontWeight:600, whiteSpace:'nowrap'}}>You · Hamra</div>
        </div>
      </div>
      <div style={{position:'absolute', right:'22%', top:'58%'}}>
        <div style={{position:'relative'}}>
          <div style={{width:42,height:42,borderRadius:'50%', background:'#F39C12', border:'3px solid #fff', boxShadow:'0 4px 14px rgba(0,0,0,.3)', display:'grid', placeItems:'center', overflow:'hidden'}}>
            <span style={{fontSize:13,fontWeight:700,color:'#1a1100'}}>RH</span>
          </div>
          {motion && <span style={{position:'absolute', inset:-4, borderRadius:'50%', border:'2px solid #F39C12', animation:'khPing 2s ease-out infinite'}}/>}
        </div>
      </div>

      {/* ETA card */}
      <div style={{
        position:'absolute', left:20, right:20, bottom:20,
        background:'#fff', borderRadius:16, padding:16,
        boxShadow:'0 12px 32px rgba(0,0,0,.18)',
        display:'flex', alignItems:'center', gap:14,
      }}>
        <div style={{position:'relative'}}>
          <KhAvatar name="Rami Hajjar" size={44} bg="#1B4F72"/>
          <span style={{position:'absolute', bottom:-2, right:-2}}><KhIcon.Verified/></span>
        </div>
        <div style={{flex:1}}>
          <div style={{fontSize:14, fontWeight:600, color:'#1f262e'}}>Rami is on the way</div>
          <div style={{fontSize:12, color:'#6b7682', display:'flex', alignItems:'center', gap:6}}>
            <KhStars rating={4.9} size={11}/> 4.9 · AC repair specialist
          </div>
        </div>
        <div style={{textAlign:'right'}}>
          <div style={{fontSize:11, color:'#6b7682', textTransform:'uppercase', letterSpacing:.5}}>ETA</div>
          <div style={{fontSize:22, fontWeight:700, color:'#1B4F72', lineHeight:1}}>8<span style={{fontSize:13, color:'#6b7682', fontWeight:500}}> min</span></div>
        </div>
      </div>

      <style>{`@keyframes khPing{0%{transform:scale(1);opacity:.8}80%{transform:scale(2.2);opacity:0}100%{transform:scale(2.2);opacity:0}}`}</style>
    </div>
  );
}

Object.assign(window, { KhHeroSplit, KhHeroCollage, KhHeroMap, KhPhoneMock, KhMapMock });

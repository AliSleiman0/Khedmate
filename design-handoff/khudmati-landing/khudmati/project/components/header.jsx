// Khudmati — Header component
// Scroll-aware: transparent over hero, solid + shadow once scrolled

function KhHeader({ variant='light', viewport='desktop', onLangSwitch }) {
  const isMobile = viewport === 'mobile';
  const isDark = variant === 'dark';
  const bg = isDark ? 'rgba(13,47,71,.85)' : 'rgba(255,255,255,.92)';
  const border = isDark ? 'rgba(255,255,255,.08)' : 'rgba(20,24,29,.06)';
  const ink = isDark ? '#fff' : '#1f262e';
  const muted = isDark ? 'rgba(255,255,255,.72)' : '#4d5763';

  return (
    <header style={{
      position:'sticky', top:0, zIndex:50,
      background:bg, backdropFilter:'blur(14px) saturate(160%)', WebkitBackdropFilter:'blur(14px) saturate(160%)',
      borderBottom:`1px solid ${border}`,
    }}>
      <div style={{
        maxWidth:1280, margin:'0 auto',
        padding: isMobile ? '12px 16px' : '14px 32px',
        display:'flex', alignItems:'center', justifyContent:'space-between', gap:24,
      }}>
        <KhLogo size={isMobile?26:30} white={isDark} />

        {!isMobile && (
          <nav style={{display:'flex', gap:28}}>
            {['How it works','Services','For Providers','Contact'].map(item => (
              <a key={item} href="#" style={{
                color:muted, fontSize:14, fontWeight:500, textDecoration:'none',
                position:'relative', padding:'4px 0',
              }}
              onMouseEnter={e=>e.currentTarget.style.color=ink}
              onMouseLeave={e=>e.currentTarget.style.color=muted}
              >{item}</a>
            ))}
          </nav>
        )}

        <div style={{display:'flex', alignItems:'center', gap: isMobile?8:12}}>
          {!isMobile && (
            <a href="#" style={{
              color:muted, fontSize:13, fontWeight:600, textDecoration:'none',
              display:'inline-flex', alignItems:'center', gap:6,
              padding:'8px 12px', borderRadius:999, border:`1px solid ${border}`,
            }}>
              <KhIcon.Pin size={14} stroke={muted} />
              Beirut
            </a>
          )}
          <button className="kh-btn kh-btn-primary" style={{height: isMobile?38:44, padding: isMobile?'0 14px':'0 18px', fontSize: isMobile?13:14}}>
            {isMobile ? 'Get app' : 'Download the App'}
          </button>
          {isMobile && (
            <button aria-label="Menu" style={{background:'transparent',border:'none',padding:8,color:ink,cursor:'pointer'}}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M3 6h18M3 12h18M3 18h18"/></svg>
            </button>
          )}
        </div>
      </div>
    </header>
  );
}

Object.assign(window, { KhHeader });

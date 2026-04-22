// Direction A — "Editorial Concierge"
// A magazine-style home. Big muhallat-style serif headline in Arabic, amber "Book a pro" CTA card at the top,
// categories laid out as a structured list with counts + pricing from, and a single ongoing-booking strip.
// Feels premium and calm. The amber does ONE job: the primary CTA.

function DirA({ rtl = true }) {
  const dir = rtl ? 'rtl' : 'ltr';
  const startSide = rtl ? 'right' : 'left';

  return (
    <div dir={dir} style={{
      width: '100%', height: '100%', background: KH.cream, color: KH.ink,
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: rtl ? 'Cairo, system-ui' : 'Inter, system-ui',
    }}>
      {/* Status bar spacer */}
      <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 20px', fontSize: 14, fontWeight: 600, color: KH.ink }}>
        <span>9:41</span>
        <span style={{ display: 'flex', gap: 4, alignItems: 'center', fontSize: 12 }}>
          <span>●●●●</span><span>5G</span>
        </span>
      </div>

      {/* Scroll area */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 100 }}>
        {/* Header — minimal, only name + bell */}
        <div style={{ padding: '8px 20px 4px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 12, color: KH.inkSoft, letterSpacing: rtl ? 0 : 1, textTransform: rtl ? 'none' : 'uppercase', fontWeight: 500 }}>
              <T ar="مساء الخير" en="Good evening" rtl={rtl} />
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, marginTop: 2, lineHeight: 1.1 }}>
              <T ar="رامي" en="Rami" rtl={rtl} />
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <IconBtn><Glyph name="chat" size={20}/></IconBtn>
            <IconBtn badge><Glyph name="bell" size={20}/></IconBtn>
          </div>
        </div>

        {/* Location pill */}
        <div style={{ padding: '10px 20px 0' }}>
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 6, padding: '6px 12px',
            background: '#fff', border: `1px solid ${KH.line}`, borderRadius: 999,
            fontSize: 12, color: KH.inkMid, fontWeight: 500,
          }}>
            <Glyph name="pin" size={14} />
            <T ar="الأشرفية، بيروت" en="Achrafieh, Beirut" rtl={rtl} />
            <Glyph name="chevron" size={12} />
          </div>
        </div>

        {/* HERO — amber wash, single strong CTA */}
        <div style={{ padding: '16px 20px 0' }}>
          <div style={{
            background: `linear-gradient(135deg, ${KH.amber} 0%, ${KH.amberDeep} 100%)`,
            borderRadius: 24, padding: '22px 22px 20px', color: '#fff',
            position: 'relative', overflow: 'hidden',
            boxShadow: '0 12px 30px -12px rgba(243,156,18,0.6)',
          }}>
            {/* big decorative glyph bleeding to edge */}
            <div style={{
              position: 'absolute', top: -30, [startSide === 'right' ? 'left' : 'right']: -20,
              color: 'rgba(255,255,255,0.18)',
            }}>
              <Glyph name="spark" size={180} stroke={1.2}/>
            </div>
            <div style={{ position: 'relative' }}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase', opacity: 0.85 }}>
                <T ar="الأكثر طلباً" en="Most booked" rtl={rtl} />
              </div>
              <div style={{
                fontSize: 28, fontWeight: 800, lineHeight: 1.15, marginTop: 8,
                fontFamily: rtl ? 'Cairo, system-ui' : 'Inter, system-ui',
                letterSpacing: rtl ? 0 : -0.4,
              }}>
                <T
                  ar="فني موثوق خلال ٦٠ دقيقة"
                  en="A trusted pro in 60 minutes"
                  rtl={rtl}
                />
              </div>
              <div style={{ fontSize: 13, opacity: 0.92, marginTop: 6, maxWidth: 260 }}>
                <T
                  ar="من ٢٠ د.أ. · ضمان الخدمة · دفع كاش أو بطاقة"
                  en="From $20 · Service guarantee · Cash or card"
                  rtl={rtl}
                />
              </div>
              <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
                <button style={{
                  background: KH.ink, color: '#fff', border: 'none', padding: '12px 18px',
                  borderRadius: 999, fontSize: 14, fontWeight: 700, fontFamily: 'inherit',
                  display: 'flex', alignItems: 'center', gap: 8,
                }}>
                  <T ar="احجز الآن" en="Book now" rtl={rtl} />
                  <Glyph name="arrow" size={14}/>
                </button>
                <button style={{
                  background: 'rgba(255,255,255,0.18)', color: '#fff', border: '1px solid rgba(255,255,255,0.4)',
                  padding: '12px 16px', borderRadius: 999, fontSize: 13, fontWeight: 600, fontFamily: 'inherit',
                }}>
                  <T ar="كيف تعمل؟" en="How it works" rtl={rtl} />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Search — slim */}
        <div style={{ padding: '14px 20px 0' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px',
            background: '#fff', border: `1px solid ${KH.line}`, borderRadius: 14,
          }}>
            <Glyph name="search" size={18} />
            <span style={{ flex: 1, fontSize: 14, color: KH.inkSoft }}>
              <T ar="ابحث عن خدمة أو فني…" en="Search a service or pro…" rtl={rtl} />
            </span>
            <Glyph name="mic" size={18} />
          </div>
        </div>

        {/* Ongoing booking strip */}
        <div style={{ padding: '16px 20px 0' }}>
          <div style={{
            background: KH.blue, color: '#fff', borderRadius: 16, padding: '12px 14px',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 12,
              background: 'rgba(255,255,255,0.15)', display: 'grid', placeItems: 'center',
            }}>
              <Glyph name="clock" size={20}/>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 11, opacity: 0.8, fontWeight: 600 }}>
                <T ar="الحجز الحالي · يصل بعد ١٢ د." en="Ongoing · arrives in 12 min" rtl={rtl} />
              </div>
              <div style={{ fontSize: 14, fontWeight: 700, marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                <T ar="كريم ع. · تنظيف شامل" en="Kareem A. · Deep cleaning" rtl={rtl} />
              </div>
            </div>
            <button style={{
              background: '#fff', color: KH.blue, border: 'none',
              padding: '8px 12px', borderRadius: 999, fontSize: 12, fontWeight: 700,
              fontFamily: 'inherit', display: 'flex', alignItems: 'center', gap: 4,
            }}>
              <Glyph name="phone" size={14}/>
              <T ar="اتصال" en="Call" rtl={rtl} />
            </button>
          </div>
        </div>

        {/* Section: categories as editorial list */}
        <div style={{ padding: '28px 20px 0' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11, color: KH.amberDeep, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase' }}>
                <T ar="الخدمات" en="Services" rtl={rtl} />
              </div>
              <div style={{
                fontSize: 22, fontWeight: 800, marginTop: 4,
                letterSpacing: rtl ? 0 : -0.5, lineHeight: 1.1,
              }}>
                <T ar="ماذا تحتاج اليوم؟" en="What do you need today?" rtl={rtl} />
              </div>
            </div>
            <span style={{ fontSize: 12, color: KH.inkSoft, fontWeight: 600 }}>
              <T ar="عرض الكل" en="See all" rtl={rtl} />
            </span>
          </div>

          {/* Editorial list rows */}
          <div style={{ background: '#fff', border: `1px solid ${KH.line}`, borderRadius: 18, overflow: 'hidden' }}>
            {[
              { cat: CATS[0], count: 142, from: 25 },
              { cat: CATS[1], count: 89,  from: 30, hot: true },
              { cat: CATS[2], count: 67,  from: 35 },
              { cat: CATS[3], count: 54,  from: 60 },
              { cat: CATS[5], count: 48,  from: 40 },
            ].map((row, i, arr) => (
              <div key={row.cat.key} style={{
                display: 'flex', alignItems: 'center', gap: 14, padding: '14px 14px',
                borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${KH.lineSoft}`,
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 12, background: KH.cream,
                  display: 'grid', placeItems: 'center', color: KH.blue, flexShrink: 0,
                  border: `1px solid ${KH.line}`,
                }}>
                  <Glyph name={row.cat.glyph} size={22}/>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ fontSize: 15, fontWeight: 700 }}>
                      <T ar={row.cat.ar} en={row.cat.en} rtl={rtl} />
                    </span>
                    {row.hot && (
                      <span style={{
                        fontSize: 10, fontWeight: 700, color: KH.amberDeep,
                        background: KH.amberSoft, padding: '2px 6px', borderRadius: 4,
                        display: 'inline-flex', alignItems: 'center', gap: 3,
                      }}>
                        <Glyph name="flame" size={10} stroke={2}/>
                        <T ar="طلب مرتفع" en="Hot" rtl={rtl} />
                      </span>
                    )}
                  </div>
                  <div style={{ fontSize: 12, color: KH.inkSoft, marginTop: 2 }}>
                    <T
                      ar={`من ${row.from} د.أ. · ${row.count} فني متاح`}
                      en={`From $${row.from} · ${row.count} pros available`}
                      rtl={rtl}
                    />
                  </div>
                </div>
                <Glyph name="chevron" size={16} stroke={2}/>
              </div>
            ))}
          </div>
        </div>

        {/* Trust strip */}
        <div style={{ padding: '22px 20px 0' }}>
          <div style={{
            background: '#fff', border: `1px solid ${KH.line}`, borderRadius: 16,
            padding: '14px 16px', display: 'flex', gap: 18, alignItems: 'center',
          }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, color: KH.inkSoft, fontWeight: 600, letterSpacing: 0.6, textTransform: 'uppercase' }}>
                <T ar="خدمتي يضمن" en="Khudmati guarantee" rtl={rtl} />
              </div>
              <div style={{ fontSize: 13, fontWeight: 700, marginTop: 2 }}>
                <T ar="فنيون موثقون ومؤمّنون" en="Verified & insured pros" rtl={rtl} />
              </div>
            </div>
            <div style={{ display: 'flex', gap: 10, color: KH.blue }}>
              <Glyph name="shield" size={22}/>
              <Glyph name="check" size={22}/>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom nav — minimal, no FAB */}
      <BottomNav rtl={rtl} variant="minimal" active="home"/>
    </div>
  );
}

function IconBtn({ children, badge }) {
  return (
    <div style={{
      width: 38, height: 38, borderRadius: 12, background: '#fff',
      border: `1px solid ${KH.line}`, display: 'grid', placeItems: 'center',
      color: KH.ink, position: 'relative',
    }}>
      {children}
      {badge && <span style={{
        position: 'absolute', top: 7, right: 7, width: 7, height: 7,
        background: KH.amber, borderRadius: '50%', border: '1.5px solid #fff',
      }}/>}
    </div>
  );
}

function BottomNav({ rtl, variant = 'minimal', active }) {
  const items = [
    { key: 'home',     icon: 'home',     ar: 'الرئيسية',  en: 'Home' },
    { key: 'bookings', icon: 'calendar', ar: 'حجوزاتي',  en: 'Bookings' },
    { key: 'chat',     icon: 'chat',     ar: 'المحادثات', en: 'Chat' },
    { key: 'profile',  icon: 'user',     ar: 'حسابي',    en: 'Profile' },
  ];
  const ordered = rtl ? [...items].reverse() : items;
  return (
    <div style={{
      height: 72, background: '#fff', borderTop: `1px solid ${KH.line}`,
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      paddingBottom: 8,
    }}>
      {ordered.map(it => (
        <div key={it.key} style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
          color: active === it.key ? KH.blue : KH.inkSoft,
          fontWeight: active === it.key ? 700 : 500,
        }}>
          <Glyph name={it.icon} size={22} stroke={active === it.key ? 2.2 : 1.8}/>
          <span style={{ fontSize: 10, fontFamily: rtl ? 'Cairo' : 'Inter' }}>
            <T ar={it.ar} en={it.en} rtl={rtl} />
          </span>
        </div>
      ))}
    </div>
  );
}

Object.assign(window, { DirA, BottomNav, IconBtn });

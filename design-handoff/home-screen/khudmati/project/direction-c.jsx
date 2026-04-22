// Direction C — "Ask Khudmati"
// A conversational, time-aware home. The header is a single question:
// "What's broken?" / "ما الذي تحتاجه؟" with amber voice-input CTA.
// Below it: smart suggestions chips (context-aware), then a masonry-ish
// category panel where one primary category (current season's top) is
// a 2x-wide feature tile, the rest a tight grid. Recent bookings as
// horizontal re-book pills.

function DirC({ rtl = true }) {
  const dir = rtl ? 'rtl' : 'ltr';

  return (
    <div dir={dir} style={{
      width: '100%', height: '100%', background: '#FAF7F2', color: KH.ink,
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: rtl ? 'Cairo, system-ui' : 'Inter, system-ui',
    }}>
      {/* Status bar */}
      <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 20px', fontSize: 14, fontWeight: 600 }}>
        <span>9:41</span>
        <span style={{ fontSize: 12 }}>●●●● 5G</span>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 100 }}>
        {/* Top bar: avatar + addr + bell */}
        <div style={{ padding: '4px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{
            width: 36, height: 36, borderRadius: 12, background: KH.blue,
            color: '#fff', fontWeight: 800, fontSize: 14, display: 'grid', placeItems: 'center',
          }}>R</div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 10, color: KH.inkSoft, fontWeight: 600 }}>
              <T ar="الموقع" en="Location" rtl={rtl} />
            </div>
            <div style={{ fontSize: 13, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 4 }}>
              <Glyph name="pin" size={12}/>
              <T ar="الأشرفية" en="Achrafieh" rtl={rtl} />
            </div>
          </div>
          <div style={{
            width: 36, height: 36, borderRadius: 12, background: '#fff',
            border: `1px solid ${KH.line}`, display: 'grid', placeItems: 'center', position: 'relative',
          }}>
            <Glyph name="bell" size={18}/>
            <span style={{
              position: 'absolute', top: 6, right: 6, width: 7, height: 7,
              borderRadius: 4, background: KH.amber, border: '1.5px solid #fff',
            }}/>
          </div>
        </div>

        {/* Big ask */}
        <div style={{ padding: '24px 20px 0' }}>
          <div style={{
            fontSize: 30, fontWeight: 800, letterSpacing: rtl ? 0 : -0.8,
            lineHeight: 1.1, color: KH.ink,
          }}>
            <T ar="ما الذي يحتاج إصلاح؟" en="What needs fixing?" rtl={rtl} />
          </div>
          <div style={{ fontSize: 14, color: KH.inkMid, marginTop: 8, lineHeight: 1.45 }}>
            <T
              ar="اكتب، تكلم، أو اختر من الأسفل. سنجد لك فنياً مناسباً."
              en="Type, speak, or pick below. We'll match you to a trusted pro."
              rtl={rtl}
            />
          </div>

          {/* Ask bar */}
          <div style={{
            marginTop: 16, background: '#fff', borderRadius: 20, padding: '6px 6px 6px 16px',
            display: 'flex', alignItems: 'center', gap: 10,
            border: `1px solid ${KH.line}`,
            boxShadow: '0 12px 24px -18px rgba(0,0,0,0.2)',
          }}>
            <Glyph name="search" size={18}/>
            <span style={{ flex: 1, fontSize: 14, color: KH.inkSoft, padding: rtl ? '0 0 0 8px' : '0 8px 0 0' }}>
              <T ar="مثلاً: الحنفية تسرّب…" en="e.g. The tap is leaking…" rtl={rtl} />
            </span>
            <button style={{
              height: 44, padding: '0 16px', borderRadius: 16, border: 'none',
              background: `linear-gradient(135deg, ${KH.amber}, ${KH.amberDeep})`,
              color: '#fff', fontWeight: 800, fontSize: 13, display: 'flex', alignItems: 'center', gap: 6,
              fontFamily: 'inherit',
              boxShadow: `0 6px 14px -4px ${KH.amber}99`,
            }}>
              <Glyph name="mic" size={16}/>
              <T ar="تكلم" en="Speak" rtl={rtl} />
            </button>
          </div>

          {/* Smart chips */}
          <div style={{
            display: 'flex', gap: 8, marginTop: 12, overflowX: 'auto', scrollbarWidth: 'none',
            paddingBottom: 4,
          }}>
            {[
              { ar: '🚨 طارئ', en: '🚨 Emergency', tone: 'amber' },
              { ar: 'تنظيف قبل الضيوف', en: 'Pre-guest clean' },
              { ar: 'فحص التكييف', en: 'AC check-up' },
              { ar: 'سباكة سريعة', en: 'Quick plumbing' },
            ].map((chip, i) => (
              <div key={i} style={{
                flexShrink: 0, padding: '9px 14px', borderRadius: 999,
                background: chip.tone === 'amber' ? KH.amberSoft : '#fff',
                color: chip.tone === 'amber' ? KH.amberDeep : KH.ink,
                border: `1px solid ${chip.tone === 'amber' ? KH.amber : KH.line}`,
                fontSize: 12, fontWeight: 700,
                fontFamily: rtl ? 'Cairo' : 'Inter',
              }}>
                <T ar={chip.ar} en={chip.en} rtl={rtl} />
              </div>
            ))}
          </div>
        </div>

        {/* Mixed category panel */}
        <div style={{ padding: '24px 20px 0' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontSize: 15, fontWeight: 800 }}>
              <T ar="تصفّح حسب الخدمة" en="Browse by service" rtl={rtl} />
            </div>
            <span style={{ fontSize: 11, color: KH.inkSoft, fontWeight: 600 }}>
              <T ar="٢٤ فئة" en="24 categories" rtl={rtl} />
            </span>
          </div>

          {/* Feature + 3-up grid */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            {/* Feature: AC (season-relevant) — spans full width */}
            <div style={{
              gridColumn: '1 / -1',
              background: KH.blue, color: '#fff',
              borderRadius: 20, padding: 16,
              position: 'relative', overflow: 'hidden', minHeight: 120,
            }}>
              <div style={{
                position: 'absolute', bottom: -20, [rtl ? 'left' : 'right']: -20,
                color: 'rgba(255,255,255,0.15)',
              }}>
                <Glyph name="ac" size={160} stroke={1.2}/>
              </div>
              <div style={{ position: 'relative', maxWidth: '65%' }}>
                <div style={{
                  display: 'inline-block', fontSize: 10, fontWeight: 800,
                  background: KH.amber, color: KH.blueDeep, padding: '3px 8px',
                  borderRadius: 999, letterSpacing: 0.5, textTransform: 'uppercase',
                }}>
                  <T ar="موسم الصيف" en="Summer pick" rtl={rtl} />
                </div>
                <div style={{ fontSize: 18, fontWeight: 800, marginTop: 8, lineHeight: 1.2 }}>
                  <T ar="صيانة وتنظيف التكييف" en="AC service & clean" rtl={rtl} />
                </div>
                <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
                  <T ar="من ٤٠ د.أ. · ٤٨ فنياً متاحاً" en="From $40 · 48 pros available" rtl={rtl} />
                </div>
              </div>
            </div>

            {/* Remaining 2x3 grid (6 cats) */}
            {CATS.filter(c => c.key !== 'ac').slice(0,6).map((c, i) => (
              <div key={c.key} style={{
                background: '#fff', borderRadius: 16, padding: 14,
                border: `1px solid ${KH.line}`,
                display: 'flex', flexDirection: 'column', gap: 10, minHeight: 98,
                position: 'relative',
              }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10, background: KH.cream,
                  display: 'grid', placeItems: 'center', color: KH.blue,
                }}>
                  <Glyph name={c.glyph} size={20}/>
                </div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 800, lineHeight: 1.2 }}>
                    <T ar={c.ar} en={c.en} rtl={rtl} />
                  </div>
                  <div style={{ fontSize: 10, color: KH.inkSoft, fontWeight: 600, marginTop: 2 }}>
                    <T ar={`من ${20 + i*5} د.أ.`} en={`from $${20 + i*5}`} rtl={rtl} />
                  </div>
                </div>
                {i === 0 && (
                  <span style={{
                    position: 'absolute', top: 10, [rtl ? 'left' : 'right']: 10,
                    fontSize: 9, fontWeight: 800, color: KH.amberDeep,
                    background: KH.amberSoft, padding: '2px 6px', borderRadius: 4,
                    letterSpacing: 0.4, textTransform: 'uppercase',
                  }}>
                    <T ar="الأشهر" en="Popular" rtl={rtl} />
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Recent / rebook */}
        <div style={{ padding: '24px 0 0' }}>
          <div style={{ padding: '0 20px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontSize: 15, fontWeight: 800 }}>
              <T ar="احجز مجدداً" en="Book again" rtl={rtl} />
            </div>
            <span style={{ fontSize: 11, color: KH.inkSoft, fontWeight: 600 }}>
              <T ar="سجل الحجوزات" en="History" rtl={rtl} />
            </span>
          </div>
          <div style={{
            display: 'flex', gap: 10, padding: '0 20px', overflowX: 'auto',
            scrollbarWidth: 'none',
          }}>
            {[
              { ar: 'كريم ع.', en: 'Kareem A.', svc_ar: 'تنظيف شامل', svc_en: 'Deep clean', when_ar: 'قبل ٣ أيام', when_en: '3 days ago', rating: 4.9 },
              { ar: 'هاشم ر.', en: 'Hashem R.', svc_ar: 'إصلاح حنفية', svc_en: 'Tap repair',  when_ar: 'الأسبوع الماضي', when_en: 'Last week',  rating: 5.0 },
              { ar: 'ليلى م.', en: 'Layla M.', svc_ar: 'تنظيف أسبوعي', svc_en: 'Weekly clean', when_ar: 'قبل شهر',       when_en: '1 month ago', rating: 4.8 },
            ].map((b, i) => (
              <div key={i} style={{
                width: 220, flexShrink: 0, background: '#fff', borderRadius: 16,
                border: `1px solid ${KH.line}`, padding: 12,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{
                    width: 38, height: 38, borderRadius: 12,
                    background: `repeating-linear-gradient(135deg, ${KH.blue} 0 2px, ${KH.blueSoft} 2px 9px)`,
                  }}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 800 }}>
                      <T ar={b.ar} en={b.en} rtl={rtl} />
                    </div>
                    <div style={{ fontSize: 11, color: KH.inkSoft, marginTop: 1, display: 'flex', alignItems: 'center', gap: 4 }}>
                      <Glyph name="star" size={10} stroke={0}/>
                      <span style={{ color: KH.ink, fontWeight: 700 }}>{b.rating}</span>
                      <span>·</span>
                      <T ar={b.when_ar} en={b.when_en} rtl={rtl} />
                    </div>
                  </div>
                </div>
                <div style={{ fontSize: 11, color: KH.inkMid, marginTop: 10, fontWeight: 600 }}>
                  <T ar={b.svc_ar} en={b.svc_en} rtl={rtl} />
                </div>
                <button style={{
                  width: '100%', marginTop: 10, background: KH.amberSoft, color: KH.amberDeep,
                  border: 'none', padding: 10, borderRadius: 10, fontSize: 12, fontWeight: 800,
                  fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                }}>
                  <T ar="احجز مجدداً" en="Book again" rtl={rtl} />
                  <Glyph name="arrow" size={12} stroke={2.2}/>
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Refer strip */}
        <div style={{ padding: '24px 20px 0' }}>
          <div style={{
            background: '#fff', border: `1px dashed ${KH.amber}`, borderRadius: 14,
            padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center',
          }}>
            <div style={{ width: 34, height: 34, borderRadius: 10, background: KH.amberSoft, color: KH.amberDeep, display: 'grid', placeItems: 'center' }}>
              <Glyph name="spark" size={18}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 800 }}>
                <T ar="ادعُ صديقاً واربح ١٠ د.أ." en="Invite a friend, earn $10" rtl={rtl} />
              </div>
            </div>
            <Glyph name="chevron" size={14}/>
          </div>
        </div>
      </div>

      {/* Bottom nav — 4 items, pill-highlighted active */}
      <PillNav rtl={rtl}/>
    </div>
  );
}

function PillNav({ rtl }) {
  const items = [
    { k: 'home', i: 'home', ar: 'الرئيسية', en: 'Home' },
    { k: 'b', i: 'calendar', ar: 'حجوزاتي', en: 'Bookings' },
    { k: 'c', i: 'chat', ar: 'محادثة', en: 'Chat' },
    { k: 'd', i: 'user', ar: 'حسابي', en: 'Profile' },
  ];
  const ordered = rtl ? [...items].reverse() : items;
  return (
    <div style={{
      padding: '10px 16px 18px', background: '#FAF7F2',
    }}>
      <div style={{
        background: '#fff', borderRadius: 22, padding: 6,
        border: `1px solid ${KH.line}`,
        boxShadow: '0 10px 24px -16px rgba(0,0,0,0.2)',
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 4,
      }}>
        {ordered.map(it => {
          const active = it.k === 'home';
          return (
            <div key={it.k} style={{
              padding: '10px 6px', borderRadius: 16,
              background: active ? KH.blue : 'transparent',
              color: active ? '#fff' : KH.inkMid,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
              transition: 'all .15s',
            }}>
              <Glyph name={it.i} size={20} stroke={active ? 2.2 : 1.8}/>
              <span style={{
                fontSize: 10, fontWeight: active ? 800 : 600,
                fontFamily: rtl ? 'Cairo' : 'Inter',
              }}>
                <T ar={it.ar} en={it.en} rtl={rtl} />
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

Object.assign(window, { DirC, PillNav });

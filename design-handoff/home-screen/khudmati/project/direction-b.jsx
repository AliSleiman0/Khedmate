// Direction B — "Live & Tactile"
// Category tiles are BIG and tactile with amber-tinted active tile.
// Top carries a live-tracking card (primary activity), then a 2x4 tile grid, then quick re-book row.
// Amber is used as the filled selection / "primary action" accent and the gradient for the CTA tile.

function DirB({ rtl = true }) {
  const dir = rtl ? 'rtl' : 'ltr';

  return (
    <div dir={dir} style={{
      width: '100%', height: '100%', background: KH.blue, color: KH.ink,
      display: 'flex', flexDirection: 'column', overflow: 'hidden',
      fontFamily: rtl ? 'Cairo, system-ui' : 'Inter, system-ui',
      position: 'relative',
    }}>
      {/* Blue top section (extends behind status bar) */}
      <div style={{ background: KH.blue, color: '#fff', paddingBottom: 18 }}>
        {/* Status bar */}
        <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 20px', fontSize: 14, fontWeight: 600 }}>
          <span>9:41</span>
          <span style={{ fontSize: 12 }}>●●●● 5G</span>
        </div>
        {/* Header */}
        <div style={{ padding: '4px 20px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 12, background: KH.amber,
              display: 'grid', placeItems: 'center', color: KH.blueDeep, fontWeight: 800, fontSize: 16,
            }}>R</div>
            <div>
              <div style={{ fontSize: 11, opacity: 0.75, fontWeight: 500 }}>
                <T ar="التوصيل إلى" en="Deliver to" rtl={rtl} />
              </div>
              <div style={{ fontSize: 14, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 4 }}>
                <Glyph name="pin" size={14}/>
                <T ar="المنزل · الأشرفية" en="Home · Achrafieh" rtl={rtl} />
                <Glyph name="chevron" size={12}/>
              </div>
            </div>
          </div>
          <div style={{
            width: 38, height: 38, borderRadius: 12, background: 'rgba(255,255,255,0.1)',
            display: 'grid', placeItems: 'center', position: 'relative',
          }}>
            <Glyph name="bell" size={18}/>
            <span style={{
              position: 'absolute', top: 8, right: 8, minWidth: 14, height: 14, padding: '0 3px',
              background: KH.amber, borderRadius: 7, fontSize: 9, fontWeight: 800,
              display: 'grid', placeItems: 'center', color: KH.blueDeep,
            }}>3</span>
          </div>
        </div>

        {/* Search — inside blue zone */}
        <div style={{ padding: '0 20px' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10, padding: '14px 16px',
            background: '#fff', borderRadius: 16, color: KH.ink,
            boxShadow: '0 8px 20px -10px rgba(0,0,0,0.35)',
          }}>
            <Glyph name="search" size={20}/>
            <span style={{ flex: 1, fontSize: 14, color: KH.inkSoft }}>
              <T ar="تنظيف، سباكة، كهرباء…" en="Cleaning, plumbing, electrical…" rtl={rtl} />
            </span>
            <div style={{ width: 1, height: 20, background: KH.line }}/>
            <Glyph name="filter" size={18}/>
          </div>
        </div>
      </div>

      {/* Curved sheet */}
      <div style={{
        flex: 1, background: KH.cream, borderTopLeftRadius: 28, borderTopRightRadius: 28,
        marginTop: -4, paddingTop: 8, overflowY: 'auto', paddingBottom: 90,
      }}>
        {/* Live tracker — hero card */}
        <div style={{ padding: '18px 20px 0' }}>
          <LiveTrackCard rtl={rtl}/>
        </div>

        {/* Promo banner — thin amber strip */}
        <div style={{ padding: '14px 20px 0' }}>
          <div style={{
            background: '#fff', borderRadius: 14, padding: '10px 14px',
            display: 'flex', alignItems: 'center', gap: 12, border: `1px solid ${KH.line}`,
          }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10, background: KH.amberSoft,
              display: 'grid', placeItems: 'center', color: KH.amberDeep,
            }}>
              <Glyph name="tag" size={18}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700 }}>
                <T ar="خصم ٢٠٪ على أول حجز تنظيف" en="20% off your first cleaning" rtl={rtl} />
              </div>
              <div style={{ fontSize: 11, color: KH.inkSoft, marginTop: 1 }}>
                <T ar="الكود: KH20 · ينتهي اليوم" en="Code KH20 · ends tonight" rtl={rtl} />
              </div>
            </div>
            <Glyph name="chevron" size={14}/>
          </div>
        </div>

        {/* Category grid — section header */}
        <div style={{ padding: '22px 20px 0' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontSize: 17, fontWeight: 800 }}>
              <T ar="كل الخدمات" en="All services" rtl={rtl} />
            </div>
          </div>

          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10,
          }}>
            {CATS.map((c, i) => (
              <CategoryTile key={c.key} cat={c} rtl={rtl} highlight={i === 1}/>
            ))}
          </div>
        </div>

        {/* Recommended pros row */}
        <div style={{ padding: '24px 0 0 0' }}>
          <div style={{ padding: '0 20px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontSize: 17, fontWeight: 800 }}>
              <T ar="فنيون لك" en="Pros for you" rtl={rtl} />
            </div>
            <span style={{ fontSize: 12, color: KH.blue, fontWeight: 700 }}>
              <T ar="عرض الكل" en="See all" rtl={rtl} />
            </span>
          </div>
          <div style={{
            display: 'flex', gap: 12, padding: '0 20px', overflowX: 'auto',
            scrollbarWidth: 'none',
          }}>
            {[
              { name: 'Hussein K.', ar: 'حسين ك.', rating: 4.9, jobs: 312, craft: 'Plumbing', arCraft: 'سباكة', price: 30 },
              { name: 'Layla M.',   ar: 'ليلى م.', rating: 4.8, jobs: 198, craft: 'Cleaning', arCraft: 'تنظيف',  price: 25 },
              { name: 'Omar S.',    ar: 'عمر س.', rating: 5.0, jobs: 87,  craft: 'Electrical',arCraft: 'كهرباء', price: 35 },
            ].map((p, i) => (
              <ProCard key={i} p={p} rtl={rtl}/>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom nav with amber FAB */}
      <BottomNavB rtl={rtl}/>
    </div>
  );
}

function LiveTrackCard({ rtl }) {
  return (
    <div style={{
      background: '#fff', borderRadius: 20, padding: 14,
      border: `1px solid ${KH.line}`,
      boxShadow: '0 8px 24px -16px rgba(27,79,114,0.3)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
        <span style={{ width: 8, height: 8, borderRadius: '50%', background: KH.success, boxShadow: `0 0 0 4px ${KH.success}22` }}/>
        <span style={{ fontSize: 11, fontWeight: 800, color: KH.success, letterSpacing: 1, textTransform: 'uppercase' }}>
          <T ar="مباشر" en="Live" rtl={rtl} />
        </span>
        <span style={{ fontSize: 11, color: KH.inkSoft, fontWeight: 600 }}>
          · <T ar="حجز #4821" en="Job #4821" rtl={rtl} />
        </span>
      </div>

      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <div style={{
          width: 54, height: 54, borderRadius: 16,
          background: `repeating-linear-gradient(135deg, ${KH.blue} 0 2px, ${KH.blueSoft} 2px 10px)`,
          flexShrink: 0,
        }}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 15, fontWeight: 800, lineHeight: 1.2 }}>
            <T ar="كريم العلي" en="Kareem Ali" rtl={rtl} />
          </div>
          <div style={{ fontSize: 12, color: KH.inkSoft, marginTop: 2, display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ color: KH.amberDeep, display: 'inline-flex', alignItems: 'center', gap: 2 }}>
              <Glyph name="star" size={11} stroke={0}/>
              <span style={{ color: KH.ink, fontWeight: 700 }}>4.9</span>
            </span>
            <span>·</span>
            <T ar="تنظيف شامل" en="Deep cleaning" rtl={rtl} />
          </div>
        </div>
        <div style={{ textAlign: rtl ? 'left' : 'right' }}>
          <div style={{ fontSize: 22, fontWeight: 800, color: KH.blue, lineHeight: 1 }}>12</div>
          <div style={{ fontSize: 10, color: KH.inkSoft, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            <T ar="دقيقة" en="min" rtl={rtl} />
          </div>
        </div>
      </div>

      {/* Progress segments */}
      <div style={{ display: 'flex', gap: 4, marginTop: 14 }}>
        {[1,1,1,0.4,0,0].map((v,i) => (
          <div key={i} style={{
            flex: 1, height: 4, borderRadius: 2,
            background: v >= 1 ? KH.amber : v > 0
              ? `linear-gradient(${rtl ? 'to left' : 'to right'}, ${KH.amber} ${v*100}%, ${KH.lineSoft} ${v*100}%)`
              : KH.lineSoft,
          }}/>
        ))}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 10, color: KH.inkSoft, fontWeight: 600 }}>
        <span><T ar="مؤكد" en="Confirmed" rtl={rtl} /></span>
        <span style={{ color: KH.amberDeep }}><T ar="في الطريق" en="On the way" rtl={rtl} /></span>
        <span><T ar="وصل" en="Arrived" rtl={rtl} /></span>
        <span><T ar="اكتمل" en="Done" rtl={rtl} /></span>
      </div>

      <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
        <button style={{
          flex: 1, background: KH.blue, color: '#fff', border: 'none',
          padding: '11px', borderRadius: 12, fontSize: 13, fontWeight: 700, fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        }}>
          <Glyph name="chat" size={15}/>
          <T ar="محادثة" en="Chat" rtl={rtl} />
        </button>
        <button style={{
          width: 44, background: KH.cream, color: KH.blue, border: `1px solid ${KH.line}`,
          padding: '11px', borderRadius: 12,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Glyph name="phone" size={16}/>
        </button>
      </div>
    </div>
  );
}

function CategoryTile({ cat, rtl, highlight }) {
  const bg = highlight ? KH.amber : '#fff';
  const icColor = highlight ? KH.blueDeep : KH.blue;
  const textColor = highlight ? KH.blueDeep : KH.ink;
  return (
    <div style={{
      background: bg, borderRadius: 16, padding: '12px 8px',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
      border: `1px solid ${highlight ? KH.amber : KH.line}`,
      boxShadow: highlight ? '0 8px 18px -10px rgba(243,156,18,0.55)' : 'none',
      aspectRatio: '1 / 1.1',
      justifyContent: 'center',
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: highlight ? 'rgba(27,52,73,0.1)' : KH.cream,
        display: 'grid', placeItems: 'center', color: icColor,
      }}>
        <Glyph name={cat.glyph} size={20}/>
      </div>
      <div style={{
        fontSize: 11, fontWeight: 700, color: textColor, textAlign: 'center', lineHeight: 1.15,
        fontFamily: rtl ? 'Cairo' : 'Inter',
      }}>
        <T ar={cat.ar} en={cat.en} rtl={rtl} />
      </div>
    </div>
  );
}

function ProCard({ p, rtl }) {
  return (
    <div style={{
      width: 180, background: '#fff', borderRadius: 16, padding: 12,
      border: `1px solid ${KH.line}`, flexShrink: 0,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 42, height: 42, borderRadius: 12,
          background: `repeating-linear-gradient(135deg, ${KH.blue} 0 2px, ${KH.blueSoft} 2px 9px)`,
        }}/>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 800, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            <T ar={p.ar} en={p.name} rtl={rtl} />
          </div>
          <div style={{ fontSize: 11, color: KH.inkSoft, fontWeight: 600, marginTop: 1 }}>
            <T ar={p.arCraft} en={p.craft} rtl={rtl} />
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: KH.inkMid, fontWeight: 700 }}>
          <Glyph name="star" size={12} stroke={0}/>
          <span style={{ color: KH.ink }}>{p.rating}</span>
          <span style={{ color: KH.inkSoft, fontWeight: 500 }}>({p.jobs})</span>
        </div>
        <div style={{
          fontSize: 11, fontWeight: 800, color: KH.amberDeep,
          background: KH.amberSoft, padding: '3px 8px', borderRadius: 999,
        }}>
          <T ar={`${p.price} د.أ.`} en={`$${p.price}`} rtl={rtl} />
        </div>
      </div>
    </div>
  );
}

function BottomNavB({ rtl }) {
  const leftItems  = [{ k: 'home', i: 'home', ar: 'الرئيسية', en: 'Home', active: true }, { k: 'b', i: 'calendar', ar: 'حجوزاتي', en: 'Bookings' }];
  const rightItems = [{ k: 'c', i: 'chat', ar: 'محادثة', en: 'Chat' }, { k: 'd', i: 'user', ar: 'حسابي', en: 'Profile' }];
  const L = rtl ? rightItems : leftItems;
  const R = rtl ? leftItems : rightItems;

  const renderItem = (it) => (
    <div key={it.k} style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
      color: it.active ? KH.blue : KH.inkSoft,
      fontWeight: it.active ? 700 : 500, width: 58,
    }}>
      <Glyph name={it.i} size={22} stroke={it.active ? 2.2 : 1.8}/>
      <span style={{ fontSize: 10, fontFamily: rtl ? 'Cairo' : 'Inter' }}>
        <T ar={it.ar} en={it.en} rtl={rtl} />
      </span>
    </div>
  );

  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, height: 80,
      background: '#fff', borderTop: `1px solid ${KH.line}`,
      display: 'flex', alignItems: 'center', padding: '0 16px 18px', paddingTop: 8,
    }}>
      <div style={{ flex: 1, display: 'flex', justifyContent: 'space-around' }}>{L.map(renderItem)}</div>
      <div style={{ position: 'relative', width: 70 }}>
        <div style={{
          position: 'absolute', top: -28, left: '50%', transform: 'translateX(-50%)',
          width: 56, height: 56, borderRadius: '50%',
          background: `linear-gradient(135deg, ${KH.amber}, ${KH.amberDeep})`,
          display: 'grid', placeItems: 'center', color: '#fff',
          boxShadow: `0 10px 24px -6px ${KH.amber}aa`,
          border: '4px solid #fff',
        }}>
          <Glyph name="plus" size={24} stroke={2.5}/>
        </div>
        <div style={{ fontSize: 10, color: KH.amberDeep, fontWeight: 800, textAlign: 'center', marginTop: 34 }}>
          <T ar="حجز جديد" en="Book" rtl={rtl} />
        </div>
      </div>
      <div style={{ flex: 1, display: 'flex', justifyContent: 'space-around' }}>{R.map(renderItem)}</div>
    </div>
  );
}

Object.assign(window, { DirB });

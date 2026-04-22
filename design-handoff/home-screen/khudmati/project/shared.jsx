// Shared tokens, icons, and reusable bits for Khudmati directions

const KH = {
  blue: '#1B4F72',
  blueDeep: '#123449',
  blueSoft: '#2A6A95',
  amber: '#F39C12',
  amberDeep: '#D6860A',
  amberSoft: '#FCE7C3',
  cream: '#FBF7F1',
  paper: '#FFFFFF',
  ink: '#1C1713',
  inkMid: '#5D534A',
  inkSoft: '#8E857B',
  line: '#E8E2D7',
  lineSoft: '#F1EBE0',
  success: '#2E7D57',
};

// Category metadata (ar label, en label)
const CATS = [
  { key: 'cleaning',   ar: 'تنظيف',     en: 'Cleaning',    glyph: 'broom' },
  { key: 'plumbing',   ar: 'سباكة',      en: 'Plumbing',    glyph: 'wrench' },
  { key: 'electrical', ar: 'كهرباء',     en: 'Electrical',  glyph: 'bolt' },
  { key: 'moving',     ar: 'نقل عفش',    en: 'Moving',      glyph: 'truck' },
  { key: 'painting',   ar: 'دهانات',     en: 'Painting',    glyph: 'brush' },
  { key: 'ac',         ar: 'تكييف',      en: 'AC & Cooling',glyph: 'ac' },
  { key: 'pest',       ar: 'مكافحة حشرات',en: 'Pest',       glyph: 'pest' },
  { key: 'carpentry',  ar: 'نجارة',      en: 'Carpentry',   glyph: 'saw' },
];

// Minimal stroke icons — 24 viewbox, currentColor
function Glyph({ name, size = 24, stroke = 1.8 }) {
  const c = { fill: 'none', stroke: 'currentColor', strokeWidth: stroke, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const paths = {
    broom: <><path d="M14 4l6 6-3 3-6-6 3-3z" {...c}/><path d="M11 7L4 14v4l4 2 4-4 3-3" {...c}/><path d="M4 18l-2 3" {...c}/></>,
    wrench: <><path d="M14.7 6.3a4 4 0 005.5 5.5L21 11l-8 8-8 0 0-2 8-8 .7-1.7a4 4 0 011-3z" {...c}/><circle cx="7" cy="17" r="1" fill="currentColor"/></>,
    bolt: <path d="M13 3L5 14h5l-1 7 8-11h-5l1-7z" {...c}/>,
    truck: <><rect x="2" y="8" width="11" height="9" rx="1" {...c}/><path d="M13 11h5l3 3v3h-8" {...c}/><circle cx="7" cy="18" r="1.6" {...c}/><circle cx="17" cy="18" r="1.6" {...c}/></>,
    brush: <><path d="M3 20l6-3 5-5-3-3-5 5-3 6z" {...c}/><path d="M11 9l4-4a2 2 0 013 3l-4 4" {...c}/></>,
    ac: <><rect x="2" y="5" width="20" height="7" rx="1" {...c}/><path d="M6 15v2M10 15v3M14 15v3M18 15v2" {...c}/><path d="M5 9h14" {...c}/></>,
    pest: <><ellipse cx="12" cy="13" rx="4" ry="5" {...c}/><path d="M12 8V5M9 6l-2-2M15 6l2-2M8 13H4M16 13h4M8 17l-3 2M16 17l3 2" {...c}/></>,
    saw: <><path d="M3 14l3-3 2 2 3-3 2 2 3-3 2 2 3-3v6H3z" {...c}/><path d="M21 14v4a2 2 0 01-2 2H5" {...c}/></>,
    search: <><circle cx="11" cy="11" r="7" {...c}/><path d="M21 21l-4.5-4.5" {...c}/></>,
    mic: <><rect x="9" y="3" width="6" height="12" rx="3" {...c}/><path d="M5 11a7 7 0 0014 0M12 18v3" {...c}/></>,
    bell: <><path d="M6 9a6 6 0 0112 0v5l2 3H4l2-3V9z" {...c}/><path d="M10 20a2 2 0 004 0" {...c}/></>,
    pin: <><path d="M12 2a7 7 0 017 7c0 5-7 13-7 13S5 14 5 9a7 7 0 017-7z" {...c}/><circle cx="12" cy="9" r="2.5" {...c}/></>,
    chevron: <path d="M9 6l6 6-6 6" {...c}/>,
    plus: <><path d="M12 5v14M5 12h14" {...c}/></>,
    home: <><path d="M4 11l8-7 8 7v9a1 1 0 01-1 1h-4v-6h-6v6H5a1 1 0 01-1-1v-9z" {...c}/></>,
    calendar: <><rect x="3" y="5" width="18" height="16" rx="2" {...c}/><path d="M3 10h18M8 3v4M16 3v4" {...c}/></>,
    user: <><circle cx="12" cy="8" r="4" {...c}/><path d="M4 21a8 8 0 0116 0" {...c}/></>,
    spark: <><path d="M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2 2-6z" {...c}/></>,
    chat: <><path d="M4 5h16v11H8l-4 4V5z" {...c}/></>,
    shield: <><path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6l8-3z" {...c}/><path d="M9 12l2 2 4-4" {...c}/></>,
    star: <path d="M12 3l2.6 6 6.4.6-4.8 4.4 1.4 6.4L12 17l-5.6 3.4L7.8 14 3 9.6l6.4-.6L12 3z" {...c}/>,
    clock: <><circle cx="12" cy="12" r="9" {...c}/><path d="M12 7v5l3 2" {...c}/></>,
    filter: <><path d="M4 5h16l-6 7v6l-4 2v-8L4 5z" {...c}/></>,
    arrow: <path d="M5 12h14M13 6l6 6-6 6" {...c}/>,
    check: <path d="M5 12l4 4 10-10" {...c}/>,
    flame: <><path d="M12 3s5 4 5 9a5 5 0 01-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3 1-5 1-8z" {...c}/></>,
    phone: <><path d="M5 3h3l2 5-2 1a10 10 0 005 5l1-2 5 2v3a2 2 0 01-2 2A15 15 0 013 5a2 2 0 012-2z" {...c}/></>,
    tag: <><path d="M3 13V4h9l9 9-9 9-9-9z" {...c}/><circle cx="8" cy="8" r="1.2" fill="currentColor"/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      {paths[name] ?? null}
    </svg>
  );
}

// RTL-aware text component
function T({ ar, en, rtl, style, as = 'span', ...rest }) {
  const Tag = as;
  const text = rtl ? ar : en;
  const font = rtl ? 'Cairo, "Noto Sans Arabic", system-ui, sans-serif' : 'Inter, system-ui, sans-serif';
  return <Tag style={{ fontFamily: font, ...style }} {...rest}>{text}</Tag>;
}

// Placeholder striped imagery — monospace caption inside
function Placeholder({ h = 120, label = 'image', tone = 'blue' }) {
  const bg = tone === 'blue'
    ? `repeating-linear-gradient(135deg, #1B4F72 0 2px, #2A6A95 2px 12px)`
    : `repeating-linear-gradient(135deg, #F39C12 0 2px, #FCE7C3 2px 12px)`;
  return (
    <div style={{
      height: h, borderRadius: 14, background: bg, position: 'relative',
      overflow: 'hidden', color: '#fff',
    }}>
      <div style={{
        position: 'absolute', inset: 6, border: '1px dashed rgba(255,255,255,.5)',
        borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace', fontSize: 11,
        letterSpacing: 0.5, textTransform: 'uppercase', color: 'rgba(255,255,255,.9)',
      }}>{label}</div>
    </div>
  );
}

Object.assign(window, { KH, CATS, Glyph, T, Placeholder });

# web-landing — Public Marketing Site

## Run
```bash
npm install
npm run dev   # http://localhost:3000
```

## Purpose
Public-facing landing page for Khudmati. No authentication required.
Targets both customers (homeowners) and potential providers in **Lebanon**.

## Stack
React 18 + TypeScript + Vite. **Inline styles + CSS variables — no Tailwind, no i18n, no framer-motion.**

## Design system
- Built from a Claude Design handoff (April 2026 — see `design-handoff/khudmati-landing/` at the repo root).
- Hero direction: **A · Split editorial** — phone mockup on right showing live booking state.
- Provider CTA direction: **V2 · Live earnings cinema** — Bloomberg-terminal aesthetic with live job feed and ticking earnings counter.
- Tokens: full design-token system in `src/styles/globals.css` (CSS variables — `--kh-primary-700`, `--kh-amber-500`, type/spacing/radius/shadow scales) + a small set of utility classes (`kh-btn`, `kh-card`, `kh-badge`, `kh-input`, `kh-fade-up`, `kh-eyebrow`, etc.). Do not modify token values; do not introduce a separate styling layer.
- Fonts: **Inter** (UI) + **Fraunces italic** (display accent — used inline via `<em>` or `font-family: Fraunces`). Loaded once from Google Fonts in `index.html`.
- Brand colors: primary blue `#1B4F72`, accent amber `#F39C12`.

## Language
**English only.** Lebanon-based; copy references Beirut + Tripoli, Saida, Jounieh, Zahle, Byblos. Western numerals throughout.
The legacy AR/EN i18next setup has been removed — there is no language toggle, no RTL.

The bilingual `public/privacy.html` + `public/terms.html` legal pages remain (Apple/Google compliance) — they are static HTML untouched by this redesign.

## Structure
```
src/
├── App.tsx                    # Composition: Hero → Services → HowItWorks → PlatformStats → ProviderCTA → ContactForm
├── main.tsx                   # ReactDOM.render — no providers
├── hooks/
│   └── useIsMobile.ts         # window.matchMedia('(max-width: 768px)')
├── components/
│   ├── ui/
│   │   ├── Icons.tsx          # KhIcon set (Cleaning, Plumbing, …, Verified)
│   │   ├── Brand.tsx          # Logo, Stars, Avatar, AppStoreBadge
│   │   └── PhoneMock.tsx      # Hero phone mockup (booking #4827, EnRoute state)
│   ├── layout/
│   │   ├── Header.tsx         # Sticky, scroll-aware: dark+transparent over hero, light+solid past 100px
│   │   └── Footer.tsx         # Trust bar + 4 columns + app store badges + /privacy.html + /terms.html
│   └── sections/
│       ├── Hero.tsx            # id="top" — gradient + phone mockup
│       ├── Services.tsx        # id="services" — 7 cards, "Cleaning" spans 2 cols on desktop
│       ├── HowItWorks.tsx      # id="how-it-works" — 4-step numbered timeline + "54 seconds" pill
│       ├── PlatformStats.tsx   # 4 stat cards + 6-city strip — wired to GET /api/landing/stats
│       ├── ProviderCTA.tsx     # id="providers" — V2 Live earnings cinema (live counter, job feed)
│       └── ContactForm.tsx     # id="contact" — 2-col layout, wired to POST /api/landing/contact
└── styles/
    └── globals.css            # All design tokens + utility classes
```

## Section order in App.tsx
```
Hero → Services → HowItWorks → PlatformStats → ProviderCTA → ContactForm
```

## API calls (public, no auth)
| Method | URL | Purpose |
|---|---|---|
| GET | `/api/landing/stats` | Live platform stats (totalProviders / totalBookings / avgRating / citiesCovered). PlatformStats falls back to design figures when the API returns 0 (early-launch). |
| POST | `/api/landing/contact` | Contact form → `public.contact_inquiries`. Backend also sends a bilingual acknowledgement email + admin notification with Reply-To = user. |

- Use native `fetch` — no Axios.
- `PlatformStats`: keep design fallback values on error or zero.
- `ContactForm`: inline error message on failure; disabled button + "Sending…" label while in-flight.

## Conventions
- Mobile breakpoint: 768 px (use `useIsMobile()` hook, not media queries in JS).
- Anchor navigation: header items link to `#how-it-works`, `#services`, `#providers`, `#contact`.
- The hero pulls the (transparent) sticky header into its dark gradient via `marginTop: -65; paddingTop: 65` so the header reads as part of the hero on first paint.
- Motion: respects `prefers-reduced-motion` via the `.kh-fade-up` utility + a global rule in `globals.css`.

## SEO
- `index.html` has `<title>`, `<meta name="description">`, Open Graph tags (`og:title` / `og:description` / `og:type` / `og:locale=en_LB`), and `<link rel="canonical">`.

## No auth needed
This is the only platform in the project with no authentication. Do not add protected routes.

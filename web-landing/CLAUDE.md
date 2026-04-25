# web-landing — Public Marketing Site

## Run
```bash
npm install
npm run dev   # http://localhost:3000
```

## Purpose
Public-facing landing page for Khudmati. No authentication required. Targets both customers and potential providers.

## Stack
React 18 + TypeScript + Vite + **no Tailwind** (inline styles / CSS variables only) + i18next (AR/EN)

## i18n
- Default language: Arabic (`ar`)
- Fallback: English (`en`)
- Translation files: `src/i18n/ar.json`, `src/i18n/en.json`
- Config: `src/i18n/config.ts` — do not modify
- Language direction switches between RTL (AR) and LTR (EN) via `dir` on `<html>`

## CSS conventions
- CSS variables defined in `src/styles/globals.css`: `--brand-blue: #1B4F72`, `--amber: #F39C12`, `--surface: #F5F7FA`, `--text-primary: #2C3E50`, `--text-secondary: #7F8C8D`
- Do not modify `src/styles/globals.css`
- Use inline styles or component-scoped CSS; no Tailwind classes

## Structure
```
src/
├── components/
│   ├── layout/
│   │   ├── Header.tsx         # Scroll-aware shadow (> 10px), anchor nav links (desktop only)
│   │   └── Footer.tsx         # Dynamic year, Privacy Policy + Terms links, social icons
│   └── sections/
│       ├── Hero.tsx            # Full-width hero (do not modify)
│       ├── HowItWorks.tsx      # id="how-it-works" anchor (do not modify)
│       ├── Services.tsx        # id="services" anchor (do not modify)
│       ├── TrustBadges.tsx     # i18n-aware badge list (5 badges)
│       ├── PlatformStats.tsx   # 4 live stat cards fetched from GET /api/landing/stats
│       ├── ProviderCTA.tsx     # i18n-aware provider pitch + "Join as Provider" CTA
│       └── ContactForm.tsx     # id="contact" anchor; wired to POST /api/landing/contact
└── i18n/
    ├── ar.json                 # Arabic translations (RTL)
    └── en.json                 # English translations (LTR)
```

## Section order in App.tsx
```
Hero → HowItWorks → Services → TrustBadges → PlatformStats → ProviderCTA → ContactForm
```

## API calls (public, no auth)
| Method | URL | Purpose |
|---|---|---|
| GET | `/api/landing/stats` | Fetch live platform stats for PlatformStats section |
| POST | `/api/landing/contact` | Submit contact form → `public.contact_inquiries` |

- Use native `fetch` — no Axios
- `PlatformStats`: fail silently (hide section on error)
- `ContactForm`: show inline error message on failure; disable button during in-flight request

## SEO
- `index.html` has `<title>`, `<meta name="description">`, Open Graph tags (`og:title`, `og:description`, `og:type`, `og:locale`), and `<link rel="canonical">`

## No auth needed
This is the only platform in the project with no authentication. Do not add protected routes.

## Static legal pages (Phase 12)
- `public/privacy.html` — bilingual (EN + AR) Khudmati privacy policy.
  Served at `/privacy.html` in dev and (with clean-URL hosting at
  `/privacy`) in production. Effective 2026-04-24; pending legal
  review before the first Apple / Google submission.
- `public/terms.html` — bilingual terms of service. Same serving
  model; same review pending.
- Both files are plain static HTML with inline CSS — no React, no
  i18next integration, no router. Each page has a brand-blue header,
  a language-toggle strip linking to `#english` and `#arabic`, and
  the same CSS variables as the rest of the site.
- `components/layout/Footer.tsx` — the "Privacy Policy" and "Terms
  of Service" footer links now point at `/privacy.html` and
  `/terms.html` (previously `href="#"`).
- Why static: Apple and Google reviewers expect these URLs to return
  200 OK with valid HTML. Building them in as separate React routes
  would require adding React Router (and rebuilding the landing
  page's section-based SPA structure). Static pages are faster to
  ship and don't touch the existing SPA.

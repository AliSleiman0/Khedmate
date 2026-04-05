# Feature: Web Landing Page — Phase 4 Platform

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith (`C:\Khedmate - ANJU_Context\backend\`)
  - Entity config lives in `Program.cs` via `AppDbContext.AdditionalModelConfiguration` — never in `Khudmati.Shared`
  - Repositories use `_context.Set<T>()` — no DbSet properties on AppDbContext
  - CQRS via MediatR: commands + queries live inside the relevant module's `Application/` folder
  - Public endpoints (no auth) live in `Khudmati.API/Controllers/`
- Database: PostgreSQL — schema-per-module convention
  - `public.*` — shared tables (notifications already here; contact_inquiries will be added here)
- Frontend: React 18 + TypeScript + Vite — **no Tailwind** (plain CSS-in-JS / inline styles only)
  - Landing page: `C:\Khedmate - ANJU_Context\web-landing\`
  - Runs on port 3000
  - i18n via `react-i18next` — AR (RTL, default) / EN (LTR fallback)
  - Translation files: `src/i18n/ar.json` and `src/i18n/en.json`
  - CSS variables defined in `src/styles/globals.css`: `--brand-blue: #1B4F72`, `--amber: #F39C12`, `--surface: #F5F7FA`, `--text-primary: #2C3E50`, `--text-secondary: #7F8C8D`
  - No Axios installed — use native `fetch`
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`

---

## Goal
Complete the web landing page to production quality: add a live platform stats section backed by a real backend endpoint, wire the contact form to actually submit to the backend, fix all missing i18n keys, make the header scroll-aware, expand the footer, and add SEO meta tags — replacing all hardcoded and fake-submit behaviour.

---

## Platforms Affected
- [x] Web Landing Page (`web-landing/`)
- [x] Backend API (`backend/`)

---

## User Story
As a visitor to the Khudmati landing page, I want to see real platform statistics, trust signals, and a working contact form — so that I can make an informed decision to download the app or sign up as a provider.

---

## What Is Already Scaffolded (do not recreate)

| File | Status |
|---|---|
| `web-landing/src/main.tsx` | ✅ Entry point — do not modify |
| `web-landing/src/App.tsx` | ⚠️ Needs PlatformStats added to section order |
| `web-landing/src/styles/globals.css` | ✅ CSS variables defined — do not modify |
| `web-landing/src/i18n/config.ts` | ✅ i18next config — do not modify |
| `web-landing/src/components/layout/Header.tsx` | ⚠️ Missing scroll-aware shadow + anchor nav |
| `web-landing/src/components/layout/Footer.tsx` | ⚠️ Hardcoded 2024 copyright, no links |
| `web-landing/src/components/sections/Hero.tsx` | ✅ Good — do not modify |
| `web-landing/src/components/sections/HowItWorks.tsx` | ✅ Fully i18n — do not modify |
| `web-landing/src/components/sections/Services.tsx` | ✅ Fully i18n — do not modify |
| `web-landing/src/components/sections/TrustBadges.tsx` | ❌ Hardcoded Arabic, no i18n |
| `web-landing/src/components/sections/ProviderCTA.tsx` | ❌ Hardcoded Arabic stats, no i18n |
| `web-landing/src/components/sections/ContactForm.tsx` | ❌ Fake submit — sets `sent = true` only |
| `web-landing/index.html` | ⚠️ Missing SEO meta tags |

---

## Sections / Components to Build or Fix

### New: `PlatformStats` section
- Purpose: Show live platform numbers fetched from the backend (providers, jobs, rating, cities)
- Position in page: between `TrustBadges` and `ProviderCTA`
- Layout: 4 stat cards in a row (wrapping on mobile), each card shows number + label
- Data fetched from: `GET /api/landing/stats` (public, no auth)
- Loading state: show skeleton/placeholder cards
- Error state: hide section silently (do not show error to visitor)
- All labels must use i18n keys

### Fix: `TrustBadges` section
- Replace hardcoded Arabic strings with proper i18n keys
- Add the 5 badge labels to both `ar.json` and `en.json`
- Keep existing layout and visual design

### Fix: `ProviderCTA` section
- The 3 stats ("+5,000 مزود", "3,000 ر.س متوسط الدخل", "مرن") are hardcoded Arabic — replace with i18n keys
- Add the "Join as Provider" CTA button link: open the provider app download page (use `#` placeholder for now and leave a `// TODO: replace with real provider app store link` comment)
- Add provider stat keys to both translation files

### Fix: `ContactForm` section
- Wire the submit handler to `POST /api/landing/contact`
- Request body: `{ name: string, email: string, message: string }`
- On success (HTTP 200/201): show existing success state (`sent = true`)
- On error: show an inline Arabic/English error message using an i18n key
- Add loading state to submit button (disabled + "جاري الإرسال..." / "Sending...")
- Do not add any new libraries — use `fetch`

### Fix: `Header` component
- Add scroll listener: when page scrolls > 10px, add a box shadow `0 2px 12px rgba(0,0,0,0.15)` to the header
- Add smooth anchor navigation links (horizontal, small text) between logo and right-side buttons: "كيف يعمل" → `#how-it-works`, "خدماتنا" → `#services`, "تواصل معنا" → `#contact` — hidden on mobile (< 768px)
- Add i18n keys for the nav labels

### Fix: `Footer` component
- Replace hardcoded `2024` copyright year with `new Date().getFullYear()`
- Add link row: "سياسة الخصوصية" | "الشروط والأحكام" (both `href="#"` with TODO comments)
- Add social media row with placeholder icon buttons (Twitter/X and Instagram)
- All new text must use i18n keys

### Fix: `index.html`
- Add `<title>خدمتي — خدمات منزلية موثوقة</title>`
- Add `<meta name="description">` in Arabic
- Add Open Graph tags: `og:title`, `og:description`, `og:type` (website), `og:locale` (ar_SA)
- Add `<link rel="canonical">` with `https://khudmati.com` placeholder
- Do not change anything else in the HTML

---

## New i18n Keys Required

Add all of the following to **both** `src/i18n/ar.json` and `src/i18n/en.json`:

```
// TrustBadges
"badge_verified_providers": "مزودون موثوقون" / "Verified Providers"
"badge_rating": "تقييم 4.8/5" / "Rating 4.8/5"
"badge_quality_guarantee": "ضمان الجودة" / "Quality Guarantee"
"badge_secure_payment": "دفع آمن" / "Secure Payment"
"badge_fast_response": "استجابة سريعة" / "Fast Response"

// ProviderCTA
"active_providers_count": "+5,000" / "+5,000"
"active_providers_label": "مزود نشط" / "Active Providers"
"avg_monthly_income": "3,000 ر.س" / "SAR 3,000"
"avg_monthly_income_label": "متوسط الدخل الشهري" / "Avg. Monthly Income"
"flexible_work": "مرن" / "Flexible"
"flexible_work_label": "اعمل بوقتك الخاص" / "Work on Your Schedule"

// PlatformStats
"stats_title": "أرقامنا تتحدث" / "Our Numbers Speak"
"stat_providers": "مزودو خدمة موثّقون" / "Verified Providers"
"stat_jobs": "مهمة مكتملة" / "Jobs Completed"
"stat_rating": "تقييم المنصة" / "Platform Rating"
"stat_cities": "مدينة نخدمها" / "Cities Covered"

// Header nav
"nav_how_it_works": "كيف يعمل؟" / "How It Works"
"nav_services": "خدماتنا" / "Services"
"nav_contact": "تواصل معنا" / "Contact Us"

// ContactForm
"sending": "جاري الإرسال..." / "Sending..."
"send_error": "حدث خطأ، حاول مرة أخرى" / "Something went wrong, please try again"
"contact_success_title": "تم إرسال رسالتك بنجاح!" / "Your message was sent!"
"contact_success_sub": "سنرد عليك خلال 24 ساعة" / "We'll reply within 24 hours"

// Footer
"privacy_policy": "سياسة الخصوصية" / "Privacy Policy"
"terms": "الشروط والأحكام" / "Terms & Conditions"
```

---

## API Endpoints Required

### GET /api/landing/stats
- Auth: **None** (public endpoint)
- Response:
  ```json
  {
    "success": true,
    "data": {
      "totalProviders": 5240,
      "totalJobsCompleted": 18700,
      "averageRating": 4.8,
      "citiesCovered": 12
    }
  }
  ```
- Business logic:
  - `totalProviders` = COUNT of providers with tier = `Active` in `providers.providers`
  - `totalJobsCompleted` = COUNT of jobs with status = `Paid` in `bookings.jobs`
  - `averageRating` = AVG of `providers.rating_stats.positive_count / (positive_count + negative_count)` * 5, rounded to 1 decimal (or return hardcoded 4.8 for v1 if no meaningful data yet)
  - `citiesCovered` = hardcoded `12` for v1 (no cities table exists yet)
- No caching needed for v1

### POST /api/landing/contact
- Auth: **None** (public endpoint)
- Request: `{ "name": "string", "email": "string", "message": "string" }`
- Validation:
  - `name`: required, max 100 chars
  - `email`: required, valid email format, max 200 chars
  - `message`: required, max 2000 chars
- Response (success): `{ "success": true, "data": { "submitted": true } }`
- Response (validation error): `{ "success": false, "error": "VALIDATION_ERROR" }`
- Business logic: persist to `public.contact_inquiries` table

---

## Data Model / DB Changes

### New table: `public.contact_inquiries`

```sql
CREATE TABLE public.contact_inquiries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(100) NOT NULL,
  email       VARCHAR(200) NOT NULL,
  message     TEXT NOT NULL,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Add this as an EF entity config in `Program.cs` under `AppDbContext.AdditionalModelConfiguration`:
```csharp
builder.Entity<ContactInquiry>(e => {
    e.ToTable("contact_inquiries", "public");
    e.HasKey(x => x.Id);
});
```

Add the `ContactInquiry` entity class in `Khudmati.API/Domain/ContactInquiry.cs`.

---

## Backend Implementation Notes

- Create controller: `Khudmati.API/Controllers/LandingController.cs`
- Use `[AllowAnonymous]` on both endpoints — no `[Authorize]` attribute
- `GetStats` query: `Khudmati.API/Domain/Queries/GetLandingStatsQuery.cs` (use MediatR)
- `SubmitContact` command: `Khudmati.API/Domain/Commands/SubmitContactInquiryCommand.cs`
- Apply rate limiting on `POST /api/landing/contact` if ASP.NET Core rate limiting middleware is already registered; otherwise leave a `// TODO: add rate limiting` comment

---

## App.tsx Changes

Update the section order to include the new `PlatformStats` component and add `id` anchors to sections that the header nav will scroll to:

```tsx
<main>
  <Hero />
  <HowItWorks />       {/* add id="how-it-works" */}
  <Services />          {/* add id="services" */}
  <TrustBadges />
  <PlatformStats />     {/* NEW — insert here */}
  <ProviderCTA />
  <ContactForm />       {/* add id="contact" */}
</main>
```

The `id` anchors must be applied inside each component's root `<section>` element, not as a wrapper div in `App.tsx`.

---

## Edge Cases & Validation

- `PlatformStats` fetch fails silently — return null and render nothing; do not throw
- Contact form: disable submit button while request is in-flight; re-enable on error
- Contact form: client-side validate before sending (empty fields, email format)
- `Header` nav links: on mobile (< 768px) collapse the nav links; only show language toggle + download CTA
- TrustBadges: no behaviour change — just i18n fix
- Stats numbers: format large numbers with locale-aware `toLocaleString()` for Arabic digit grouping (e.g. `18700` → `18,700` in EN, `١٨٬٧٠٠` in AR if desired — but plain `toLocaleString()` is sufficient)

---

## Out of Scope (do not implement)
- Cookie consent banner
- Newsletter signup
- App Store / Play Store real links (use `#` + TODO comments)
- Privacy policy or terms pages (linked as `href="#"` only)
- Analytics / tracking scripts
- Authentication, login, or protected routes of any kind
- Animations beyond the scroll shadow on the header
- Any changes to `src/i18n/config.ts`, `src/main.tsx`, `src/styles/globals.css`

---

## Acceptance Criteria
- [ ] `GET /api/landing/stats` returns real counts from the database (no hardcoded mock data in the handler)
- [ ] `POST /api/landing/contact` persists a row to `public.contact_inquiries` and returns `{ "success": true }`
- [ ] Contact form shows loading state during submission and displays an error message on failure
- [ ] `PlatformStats` section renders with 4 stat cards and shows a loading placeholder until data arrives
- [ ] All Arabic hardcoded strings in `TrustBadges` and `ProviderCTA` are replaced with i18n keys that work in both AR and EN
- [ ] Header gains a visible box shadow when the user scrolls past 10px
- [ ] Header nav links are visible on desktop and hidden on mobile
- [ ] Footer shows the current year dynamically, and includes Privacy Policy + Terms links
- [ ] `index.html` has title, meta description, and Open Graph tags
- [ ] Switching language (AR ↔ EN) correctly updates all newly added keys in every section
- [ ] RTL layout is preserved in all modified/new components

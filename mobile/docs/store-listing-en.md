# Khudmati — English Store Listing Copy

Use this copy verbatim for both Google Play Console and App Store Connect (English locale). AR copy lives in `store-listing-ar.md`.

---

## App name (30 chars max on App Store, 50 on Play)
**Khudmati**

## Subtitle — App Store only (30 chars max)
**Trusted home services, booked**

## Short description — Play Store (80 chars max)
**Book trusted home services in minutes — cleaning, plumbing, AC, and more.**

## Keywords — App Store only (100 chars, comma-separated)
`home services, cleaning, plumbing, AC repair, handyman, service booking, maintenance, Saudi, Riyadh`

---

## Long description (4000 chars max — Play Store)

**One app. Pick your role. Get on with your day.**

Khudmati connects households in Saudi Arabia with verified home-service professionals. Whether you need a cleaner today, a plumber this afternoon, or an AC technician before the weekend, Khudmati books the job in minutes — and pays the provider safely after the work is done.

**For customers**
- Book in under a minute — tap a category, describe the job, drop a pin on the map, and confirm.
- Full transparency on price before you book — no surprise surcharges.
- Watch your provider on a live map as they head to you.
- Pay safely through the app — funds are held until you approve the completed job.
- In-app chat with your provider, before and during the job.
- Rate the job afterwards so the next customer gets an even better match.
- Earn credit when you invite friends — 20 SAR per referred customer, 15% off their first booking.

**For providers**
- Get matched with jobs near you — real-time broadcasts when a new customer needs your skill.
- 2-minute decision window on every incoming job. Accept or skip.
- Full job details and navigation to the customer's location built in.
- Upload before/after photos so your work is documented.
- Transparent earnings page — commissions, payouts, and analytics in one place.
- Weekly Stripe payouts straight to your bank account.
- Optional Power Provider subscription cuts commission and gives you a 30-second head-start on every job broadcast.

**Verified, private, secure**
- Every provider is identity-verified and skill-tested before they can accept jobs.
- All payments processed securely through Stripe.
- All communication end-to-end within the app — your phone number is never shared.

**Languages:** Arabic (primary) and English.
**Cities:** Riyadh today, expanding across the Kingdom.

Questions? Contact us at contact@khudmati.app.

---

## Category
- **Primary:** Lifestyle
- **Secondary:** Business

## Content rating
- **IARC expected rating:** Everyone (no violence, no gambling, no explicit content)

---

## Data safety / App Privacy nutrition label

Collected data and purpose:

| Data type | Collected | Shared | Purpose |
|---|---|---|---|
| Name | ✓ | No | App functionality (account) |
| Email address | ✓ (customers only) | No | App functionality, account recovery |
| Phone number | ✓ | No | Authentication, job coordination |
| Precise location | ✓ | Providers during EnRoute share live location with the assigned customer only | Navigation, matchmaking, live tracking |
| Approximate location | ✓ | No | Matchmaking (nearby providers) |
| Photos | ✓ | No | Job documentation (before/after) |
| Payment info | ✓ | Stripe (PCI-compliant processor) | Payment processing |
| App interactions | ✓ | Firebase (analytics) | App performance, fraud prevention |
| Crash logs | ✓ | Firebase Crashlytics | Stability monitoring |
| Device IDs | ✓ (FCM token) | No | Push notifications |

**Encryption in transit:** Yes (HTTPS/TLS)
**Data deletion:** Users can delete their account in-app via Profile → Delete Account. Data removed within 30 days; financial records retained per tax law.

---

## Permissions rationale (Play Store + App Store)

| Permission | In-app UX / justification |
|---|---|
| `ACCESS_FINE_LOCATION` | Customers use it to set the job address via map pin (optional — can be entered manually). Providers use it to navigate to the job. |
| `ACCESS_BACKGROUND_LOCATION` | **Providers only.** Broadcasts the provider's location to the assigned customer every 3 seconds while the job status is "EnRoute", so the customer can see the provider on a live map. Stops immediately when the provider taps "Arrived". Google Play reviewers: a short screen recording of this UX accompanies the listing. |
| `CAMERA` | Provider: capture before/after photos of the job. Customer: capture ID proof during dispute flow (optional). |
| `POST_NOTIFICATIONS` | Push notifications for job status changes, chat messages, and maintenance reminders. |
| Microphone | Voice notes in chat (future feature — permission declared but not yet used). |

---

## Apple Review 5.1.2 compliance

**In-app account deletion:** Profile → "Delete Account" → confirmation dialog → account permanently deleted server-side, tokens cleared locally, user returned to welcome screen.

**Sign-out:** Profile → "Log Out" → tokens cleared, user returned to welcome screen.

**Data retention after deletion:** All PII removed within 30 days. Financial records (transactions, payouts) retained for 7 years per Saudi tax law — disclosed in the privacy policy at `https://khudmati.app/privacy`.

---

## Apple Review 3.1.1 compliance

Power Provider monthly subscription (99 SAR/month) is **a commission-tier upgrade for service providers**, not a digital good. Payments go through Stripe, not StoreKit — same pattern as Uber driver subscriptions, DoorDash premium, etc. See guideline 3.1.3(e) — "Services" exemption.

---

## Privacy policy & terms

- Privacy policy: https://khudmati.app/privacy
- Terms of service: https://khudmati.app/terms

---

## Contact

- Email: contact@khudmati.app
- Website: https://khudmati.app

---

## Version history notes — template

### 1.0.0 — Initial release
- Unified customer + provider app. Pick your role on first launch.
- Replaces the two separate legacy apps (`com.khudmati.customer`, `com.khudmati.provider`).
- All existing users will be prompted to install this version via an in-app upgrade screen in the legacy apps.

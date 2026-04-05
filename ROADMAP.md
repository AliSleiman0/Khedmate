# Khudmati (خدمتي) — Implementation Roadmap

Track feature implementation progress. Check off each item as it's done.

---

## Phase 1 — Core Transaction Loop
> Goal: one job can be created, accepted, and paid end-to-end

- [x] Project scaffold — all platforms structured and wired up
- [x] Prompt written: `prompts/01-authentication.md`
- [x] **01 — Authentication** — customer register/OTP/login, provider register/OTP/login, admin login, JWT per audience, refresh tokens
- [x] **02 — Customer Booking Flow** — category selection → job description → location picker → confirm → job created in DB
- [x] **03 — Provider Job Acceptance** — job feed, accept/reject screen, 2-min countdown timer, auto-reject on timeout
- [ ] **04 — Job Status Tracking** — real-time state updates via SignalR (Accepted → EnRoute → InProgress → Completed) shown on both apps
- [x] **05 — Payments** — on-platform payment at booking, 15–20% commission deduction, payout released after 24h dispute window
- [x] **06 — Post-Job Rating** — binary thumbs up/down + optional tags, triggered after job marked Completed

---

## Phase 2 — Trust & Quality
> Goal: safe to launch to real users in one district

- [x] **07 — Provider Onboarding & Verification** — document upload, 10-question skill test, verification tier badge display
- [x] **08 — Live GPS Tracking** — provider location streamed to customer during EnRoute state
- [x] **09 — In-App Chat** — customer ↔ provider messaging via SignalR, per job thread
- [ ] **10 — Push Notifications** — job assigned, accepted, en route, completed, payment received
- [x] **11 — Post-Job Photo Requirement** — provider must upload photo before marking job complete, held in dispute evidence

---

## Phase 3 — Operations
> Goal: ops team can manage the platform without direct DB access

- [x] **12 — Admin: Jobs Management** — filterable jobs table, status chips, manual status override
- [x] **13 — Admin: Disputes** — 3-step mediation flow, evidence viewer, approve refund / close dispute
- [x] **14 — Admin: Provider Management** — verification queue, manual approval/rejection, suspension

---

## Phase 4 — Platform Management
> Goal: super admin controls platform config, web presence is live

- [x] **15 — Super Admin Panel** — admin account management, commission rate config, financial ledger, full audit log
- [x] **16 — Web Landing Page** — hero, how it works, service categories, trust badges, provider CTA, AR/EN toggle

---

## Phase 5 — Growth (Post-Launch / V2)
> Do not build until Phase 1–3 are live and unit economics are proven

- [x] **17 — Referral System** — double-sided: customer gets discount, referrer gets credit
- [x] **18 — Subscription Tier** — power provider monthly fee in exchange for reduced commission + premium placement
- [ ] **19 — Maintenance Reminders** — AI-powered scheduling suggestions based on last service date
- [ ] **20 — Provider Analytics Dashboard** — earnings history, job stats, rating breakdown

> Prompts written: #17 ✅ #18 ✅ #19 ✅ #20 ✅

---

## Prompt Files

| # | Feature | Prompt File | Status |
|---|---|---|---|
| 01 | Authentication | `prompts/01-authentication.md` | ✅ Ready |
| 02 | Customer Booking Flow | `prompts/02-customer-booking-flow.md` | ✅ Ready |
| 03 | Provider Job Acceptance | `prompts/03-provider-job-acceptance.md` | ✅ Ready |
| 04 | Job Status Tracking | `prompts/04-job-status-tracking.md` | ✅ Ready |
| 05 | Payments | `prompts/05-payments.md` | ✅ Ready |
| 06 | Post-Job Rating | `prompts/06-post-job-rating.md` | ✅ Ready |
| 07 | Provider Onboarding | `prompts/07-provider-onboarding-verification.md` | ✅ Ready |
| 08 | Live GPS Tracking | `prompts/08-live-gps-tracking.md` | ✅ Ready |
| 09 | In-App Chat | `prompts/09-in-app-chat.md` | ✅ Ready |
| 10 | Push Notifications | `prompts/10-push-notifications.md` | ✅ Ready |
| 11 | Post-Job Photo | `prompts/11-post-job-photo-requirement.md` | ✅ Ready |
| 12 | Admin: Jobs | `prompts/12-admin-jobs-management.md` | ✅ Ready |
| 13 | Admin: Disputes | `prompts/13-admin-disputes.md` | ✅ Ready |
| 14 | Admin: Providers | `prompts/14-admin-provider-management.md` | ✅ Ready |
| 15 | Super Admin | `prompts/15-super-admin.md` | ✅ Ready |
| 16 | Landing Page | `prompts/16-web-landing-page.md` | ✅ Ready |
| 17 | Referral System | `prompts/17-referral-system.md` | ✅ Ready |
| 18 | Subscription / Power Provider Tier | `prompts/18-subscription-power-provider-tier.md` | ✅ Ready |
| 19 | Maintenance Reminders (AI Scheduling) | `prompts/19-maintenance-reminders.md` | ✅ Ready |
| 20 | Provider Analytics Dashboard | `prompts/20-provider-analytics-dashboard.md` | ✅ Ready |

---

## Notes

- Write prompts on demand using the **khedmate-feature-prompt** skill in Cowork
- Implement each feature in Claude Code by running: `Read prompts/0X-feature-name.md and implement everything in it`
- Run `/compact` in Claude Code between features to keep token usage low
- Work one platform at a time per Claude Code session when possible

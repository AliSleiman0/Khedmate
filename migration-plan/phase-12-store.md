# Phase 12 — Store Submission (Play Store + App Store)

## Goal
Submit the unified app to both stores as a new listing under the new bundle id, coordinated with the Phase 10 user migration strategy.

## Why this phase
Store review is the longest external dependency in the project (Apple typically 24–72 hours, Google 2–24 hours). Start early.

## Pre-requisites
- Phase 11 complete (all verification passes)
- Store developer accounts active (Apple Developer Program, Google Play Console)
- Icon, screenshots, feature graphic assets finalised
- Privacy policy URL live at `https://khudmati.app/privacy`
- Terms of service URL live at `https://khudmati.app/terms`

## Scope

### 1. Play Store submission

**Listing:**
- App name: `Khudmati` (EN) / `خدمتي` (AR)
- Short description (EN + AR) — 80 chars max. Example EN: "Book trusted home services in minutes. Cleaning, plumbing, AC, and more."
- Long description (EN + AR) — 4000 chars max. Include both customer and provider value props (one app, pick your role on first launch).
- Category: Lifestyle (primary) / Business (secondary)
- Contact email, phone, website
- Privacy policy URL

**Assets:**
- Feature graphic 1024×500
- App icon 512×512
- Phone screenshots ≥ 2 (customer flow + provider flow — take from Phase 11 device runs)
- Tablet screenshots (optional but recommended for Saudi market which uses large screens)
- Promo video (optional)

**Content rating:**
- Complete IARC questionnaire — expected rating: Everyone

**Data safety:**
- Declare all collected data: name, email, phone, location (precise + approximate), photos, financial info (payment methods)
- Declare purpose: app functionality + fraud prevention + analytics
- Declare sharing: Stripe (payment processing), Firebase (analytics + messaging)
- Encryption in transit: yes (HTTPS)
- Users can request data deletion: yes (via contact@khudmati.app)

**Permissions declaration:**
- Background location: explain in-app UX (provider navigation to customer — only during EnRoute). Google Play reviews this carefully; provide a short Loom / screen recording showing the UX.

**Release:**
- Production track → internal testing track first (invite team)
- Promote to closed testing (small beta group)
- Promote to open testing if desired
- Promote to production once user migration plan is ready to execute

### 2. App Store submission

**App Store Connect setup:**
- App name, subtitle (30 chars), category
- Localized for EN + AR (set `ar-SA` locale)
- App privacy: declare per Apple's nutrition label (same categories as Play Data Safety)
- Screenshots per device size (6.7" iPhone, 5.5" iPhone, iPad if supporting)
- App Preview video (optional)
- Keywords: home services, cleaning, plumbing, AC repair, handyman, service booking (localized for AR)

**TestFlight:**
- Upload release build via Xcode or `xcrun altool`
- Invite internal testers first
- External beta (up to 10,000 users) — requires Beta App Review (~24h)

**Production review:**
- Apple Review guidelines to watch:
  - 5.1.1 — Data collection justification
  - 4.2 — Minimum functionality (the app has substantial functionality — no risk)
  - 3.1.1 — In-app purchase for digital goods (Power Provider subscription is a service, not digital goods — use Stripe, don't need StoreKit)
  - 5.1.2 — Data storage must allow sign-out and account deletion (already covered by profile's logout + a backend `DELETE /me` endpoint must exist)

### 3. Sunset the old apps (coordinate with Phase 10 strategy)

**Strategy A or C:**
- Submit a final update to both old apps that shows the migration screen (built in Phase 10)
- Once accepted, initiate the hard cutover by flipping the backend `UPGRADE_REQUIRED` flag

**Strategy B:**
- Do nothing to old apps yet — they remain available for the 90-day sunset window
- Calendar a reminder for sunset date to submit the final upgrade-required update

### 4. Link old and new listings
- On old app Play Store listing: add "This app has been replaced by Khudmati" in description; link to new listing
- Same for App Store

### 5. Monitoring during review
- Check review status daily
- Be ready to respond to reviewer questions within 24h
- If rejected, document the reason in `mobile/docs/store-rejections.md` and fix before resubmitting

## Files to create
- `mobile/docs/store-listing-en.md` — EN copy for both stores
- `mobile/docs/store-listing-ar.md` — AR copy
- `mobile/docs/store-rejections.md` — empty; filled only if reviewers reject

## Files to modify
- None

## Verification
- Both listings visible on respective stores (TestFlight + internal testing track)
- Download + install via store link works on a test device (not via APK sideload)
- Stripe, FCM, SignalR all work correctly on the store-installed build (validates production signing)

## Exit criteria
- [ ] Play Store internal testing track live
- [ ] App Store TestFlight build live
- [ ] Production submissions queued in both stores
- [ ] Store listings approved (may happen after this phase and trigger Phase 13)
- [ ] Analytics dashboard set up to track new-app installs vs old-app usage
- [ ] Commit: `docs(mobile): Phase 12 store submission`

## Rollback
- If review reveals a critical bug, fix and resubmit. Do not skip verification back to Phase 11.
- If Apple/Google reject for policy reason, update listing/app per feedback and resubmit.

# Phase 10 — Existing User Migration

## Goal
Decide and implement how users already installed on the old customer or provider apps transition to the new unified app, without breaking their sessions or losing data.

## Why this phase
This is the only phase that affects users currently in production. Getting it wrong means lost customers, angry providers, and bad store reviews. Pick one strategy, implement it precisely, communicate it clearly.

## Pre-requisites
- Phase 09 complete (release builds ready)
- Phase 0 Decision C locked in (strategy A, B, or C)
- Owner approval for sunset date (if strategy B)

## Scope

Implement exactly **one** of the three strategies. This file documents all three for reference; the one chosen in Phase 0 becomes the active implementation plan.

---

### Strategy A — Deep-link handoff (recommended for fastest cutover)

**Concept:** Old apps ship a final update that replaces the home screen with a "Download Khudmati" full-screen card. Login is disabled.

**Implementation (old apps):**
1. Create a new branch in `mobile-customer/` and `mobile-provider/`: `release/v-handoff`
2. Add a top-level widget that overrides all routes and renders a migration screen with:
   - Logo
   - Bilingual copy: "We've launched Khudmati — one app for everything. Download the new app to continue."
   - "Download" button → Play Store / App Store URL
   - Your current phone + email shown so they know what to sign in with
3. Disable `AuthNotifier.login` with a hardcoded `throw AppUpgradeRequired()`
4. Submit old customer + provider as final update to both stores
5. Release new unified app to stores in parallel
6. After both store reviews pass, old app users upgrade → see migration screen

**Duration:** ~1 week old-app handoff + 2 weeks store propagation

**Risks:** Users who don't auto-update stay on the functioning old app. Must coexist until everyone has either moved or been force-upgraded (requires `minVersion` check — simplest: old app's API returns `426 UPGRADE_REQUIRED` once cutover date is reached).

---

### Strategy B — Parallel for 90 days (recommended for lowest user friction)

**Concept:** Old apps continue to work. New unified app is released alongside. Users migrate at their own pace. After 90 days, old apps are sunsetted.

**Implementation:**
1. Release unified app under new bundle `com.khudmati.app`
2. Old apps remain in stores unchanged — existing users just keep using them
3. Marketing pushes new app via in-app banners (add a small one-time banner in old apps saying "Try the new Khudmati app" → deep link to store listing)
4. Backend already supports both JWT audiences (`customer` and `provider` unchanged) so no API changes
5. On sunset date (Phase 0 Decision C): old apps' login endpoints return `UPGRADE_REQUIRED` error, which old apps display as "Please download the new Khudmati app"

**Duration:** 90 days sunset window

**Risks:**
- Two apps to support for 90 days. Any backend change must keep both working.
- Users with the old app installed may not realize a new app exists. Mitigate with push notification broadcast at 30-day and 60-day marks.

---

### Strategy C — Hard cutover (fastest but riskiest)

**Concept:** Old apps' login endpoints immediately return `UPGRADE_REQUIRED`. Users are forced to the new app on next login.

**Implementation:**
1. Release unified app to stores
2. Wait for store approval + a couple days of propagation time
3. Backend flips `/auth/customers/login` and `/auth/providers/login` to return `426 UPGRADE_REQUIRED` for any client identified as the old app (use app version header)
4. Old apps catch this error and show a full-screen "Download new app" message

**Duration:** 1 day post-propagation

**Risks:** Users caught mid-session lose their state. Not recommended unless there's a security reason to force the cutover.

---

### Shared tasks for all strategies

**Data continuity:**
- User accounts live server-side. JWT refresh tokens issued to the old app will NOT work on the new app (new bundle id = new secure storage namespace). Users will need to re-login once on the new app. No server-side user migration is needed.
- Payment methods (Stripe customer objects), referral codes, credits, subscriptions, job history — all server-side, all preserved.
- FCM device tokens — old tokens auto-invalidate when user uninstalls old app; new app re-registers. No manual cleanup.

**Communication:**
1. In-app banner in old apps 7 days before the chosen cutover/sunset
2. Push notification on chosen cutover day
3. Email blast (if email addresses are on file — check `customers.users.email`) explaining the change
4. Update landing page (`web-landing/`) with a "Download the new app" section above the fold
5. Update help desk / FAQ with a "Why did the app change?" page

**Analytics:**
- Add a Firebase Analytics event `migration_opened_new_app` fired on first launch when user has a record of old-app usage (detect via server-side cross-check of phone number)
- Track: % of old-app users who install new app within 7/14/30/90 days

## Files to create / modify
Depends on strategy. Write the actual implementation as code once Phase 0 Decision C picks one.

## Verification
- All users with existing accounts can sign in to new app with same phone/password
- Booking history visible after migration
- Active jobs survive: start a booking on old app → complete it on new app after re-login (if within sunset window)
- Stripe customer remains linked (test: previously saved payment method still usable)
- Referral codes continue to work
- Providers with Power Provider subscription retain benefits post-migration

## Exit criteria
- [ ] Chosen strategy implemented per above
- [ ] Communication plan drafted and approved
- [ ] Help desk / FAQ updated
- [ ] Monitoring dashboard shows migration rate (Firebase + backend join query)
- [ ] No spike in `/auth/*` error rates during the first 72 hours post-cutover

## Rollback
- If migration rate after 7 days is below a threshold (define one in Phase 0, e.g. 20%), consider extending sunset or pausing forced-cutover.
- Strategy A / C rollback: backend reverts the `UPGRADE_REQUIRED` gate.
- Strategy B rollback: extend the sunset date.

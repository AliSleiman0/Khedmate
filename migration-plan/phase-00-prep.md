# Phase 00 — Prep & Decision Gates

## Goal
Make all irreversible decisions before a single line of code is written, and create the isolated branch where all migration work will happen.

## Why this phase
Four decisions materially change how Phases 1–13 execute. Making them later means rework. Making them now costs nothing but a conversation.

## Pre-requisites
- Read the master plan at `C:\Users\AliSleiman\.claude\plans\memoized-cooking-canyon.md`
- Read `C:\Khedmate - ANJU_Context\CLAUDE.md` for project conventions
- Confirm no one is actively merging to `main` for the duration of the migration

## Scope

### 1. Create the isolation branch
```bash
cd "C:/Khedmate - ANJU_Context"
git checkout -b feat/unified-app
git push -u origin feat/unified-app
```
All subsequent phases commit to this branch only.

### 2. Resolve decisions (required before Phase 1)

Write each decision into this file's **Decisions** section below before exiting the phase.

**Decision A — App identity**
- Package id / bundle id (recommendation: `com.khudmati.app`)
- Display name EN: `Khudmati`
- Display name AR: `خدمتي`
- Store listing tagline (EN + AR)

**Decision B — Firebase project**
- Option 1: Create new Firebase project `khudmati-app` (recommended — clean FCM routing, no legacy baggage)
- Option 2: Reuse existing customer or provider Firebase project
- Impact: determines `google-services.json` / `GoogleService-Info.plist` and whether backend FCM sender id needs updating

**Decision C — Existing-user migration strategy**
- Option A: Deep-link handoff — old apps ship a final update pointing to new store listing, then disable login
- Option B: Parallel for 90 days — new app ships alongside old apps; old apps remain functional until sunset date
- Option C: Hard cutover — old app login endpoints return upgrade-required error
- Backend supports all three because JWT audiences for `customer` and `provider` are preserved

**Decision D — Dual-role users**
- Can the same phone number register as both customer and provider?
- Recommendation: no — each role requires a separate phone number, avoids storing two tokens per device and simplifies role switching
- If yes: a follow-up phase is needed for session multiplexing (not covered by this plan)

### 3. Inventory snapshot
Nothing new to produce. The master plan's exploration section already contains the full inventory of both apps. Do not re-explore.

## Files to modify
- This file (`phase-00-prep.md`) — fill in Decisions section below
- No code files

## Verification
- `git branch --show-current` returns `feat/unified-app`
- This file's **Decisions** section has all four entries filled in with names, not placeholders
- Product owner has signed off (async OK) on Decisions A and C

## Exit criteria
- [ ] Branch `feat/unified-app` exists on remote
- [ ] Decision A — app identity recorded
- [ ] Decision B — Firebase project strategy recorded
- [ ] Decision C — user migration strategy recorded
- [ ] Decision D — dual-role policy recorded

## Rollback
- `git branch -D feat/unified-app` deletes the branch. No other artefacts created.

## Decisions

Resolved 2026-04-22.

**A. App identity**
- Package/bundle id: `com.khudmati.app`
- Display name EN: `Khudmati`
- Display name AR: `خدمتي`
- Tagline: (to be drafted in Phase 12 store submission)

**B. Firebase**
- Strategy: **Reuse existing customer Firebase project**
- Action: register a new Android app (`com.khudmati.app`) and new iOS app (`com.khudmati.app`) under the existing customer project; download fresh `google-services.json` and `GoogleService-Info.plist`
- Backend FCM sender id: **unchanged** (same project → same sender id → no backend env var update needed)
- Note: the existing provider Firebase project becomes legacy — leave alone until Phase 13 cleanup

**C. Existing users**
- Strategy: **C. Hard cutover**
- Mechanics:
  1. Release unified app to both stores
  2. Wait for store approval + ~48h propagation
  3. Backend flips `/auth/customers/login` and `/auth/providers/login` to return `426 UPGRADE_REQUIRED` when the client's `X-App-Version` header matches the old bundles (`com.khudmati.customer` / `com.khudmati.provider`)
  4. Old apps catch the error code and render a full-screen "Download the new Khudmati app" message with store link
- Backend changes required (scope as separate ticket, executed during Phase 12):
  - Read `X-App-Package` or `User-Agent` header in login controllers
  - Return `{ success: false, error: "UPGRADE_REQUIRED", data: { storeUrl: "..." } }` when old package detected
  - Add a feature flag `Auth:ForceUpgradeForLegacyApps` so the cutover can be toggled atomically
- Sunset date: the moment new app reaches production track (controlled via feature flag)

**D. Dual-role users**
- Allowed: **No**
- Rationale: one role per phone number. If a user genuinely needs to be both customer and provider, they register with separate phone numbers. Avoids session multiplexing, double token storage, and role-switch UX complexity.
- Backend constraint (already enforced): `customers.users.phone` and `providers.providers.phone` are independent tables, so the same phone can technically exist in both — but the unified app's register endpoint (role-aware) will not allow a new registration if the phone already exists in the target role's table.

# Phase 12 — Implementation (Store Submission)

Companion to `phase-12-store.md`. Records the concrete work landed on
`feat/unified-app` during Phase 12 and the backend / ops hand-offs that
must complete before the first Apple review round.

## What shipped in the unified app (`mobile/`)

| Area | File | Purpose |
|---|---|---|
| Store copy (EN) | `mobile/docs/store-listing-en.md` | App name, short + long description, data-safety declarations, permission rationale, Apple 5.1.2 / 3.1.1 compliance notes |
| Store copy (AR) | `mobile/docs/store-listing-ar.md` | Same, translated for the `ar-SA` locale |
| Rejection log | `mobile/docs/store-rejections.md` | Empty template for tracking reviewer rejections |
| Account deletion (Apple 5.1.1(v) prereq) | `mobile/lib/features/auth/data/auth_repository.dart` | `AuthRepository.deleteAccount()` hits `DELETE /customers/me` or `DELETE /providers/me`, then clears tokens + role |
| Auth notifier hook | `mobile/lib/features/auth/presentation/auth_provider.dart` | `AuthNotifier.deleteAccount()` wraps the repo call and resets state to `AuthUnauthenticated` |
| Shared confirmation action | `mobile/lib/features/shared/profile/presentation/delete_account_action.dart` | `showDeleteAccountDialog(context, ref)` — destructive dialog + snackbar feedback + `/welcome` redirect on success |
| Customer profile tile | `mobile/lib/features/shared/profile/presentation/profile_tiles_customer.dart` | Red "Delete Account" tile at the bottom of the tile list |
| Provider profile tile | `mobile/lib/features/shared/profile/presentation/profile_tiles_provider.dart` | Same tile on the provider side |
| L10n keys | `mobile/lib/core/l10n/app_strings.dart` | `profileDeleteAccount`, `deleteAccountDialogTitle/Body`, `deleteAccountConfirm/Cancel/Success/Error` (EN + AR) |

## Backend prerequisites (must land before first Apple submission)

Per the migration plan (rule #4, backend is untouched on `feat/unified-app`),
these endpoints and feature flags need to be implemented on the backend
separately. Coordinate rollout with Phase 12 timing — the first App Store
submission will fail 5.1.1(v) review if the delete-account endpoint isn't
live, and the Phase 10 legacy-app cutover needs the upgrade-required flag.

### 1. Account deletion endpoints (Apple 5.1.1(v), Google Data Safety) — ✅ SHIPPED

Shipped 2026-04-24 — `feat/unified-app`. Pending deploy to prod
(`api.khudmati.app`).

**Endpoints:**

```
DELETE /api/customers/me
Authorization: Bearer <customer_jwt>
→ 200 OK     { success: true }
→ 404        { success: false, error: "CUSTOMER_NOT_FOUND" }
→ 409        { success: false, error: "HAS_ACTIVE_JOBS" }
→ 500        { success: false, error: "DELETE_FAILED" }

DELETE /api/providers/me
Authorization: Bearer <provider_jwt>
→ 200 OK     { success: true }
→ 404        { success: false, error: "PROVIDER_NOT_FOUND" }
→ 409        { success: false, error: "HAS_ACTIVE_JOBS" }
→ 409        { success: false, error: "HAS_ACTIVE_SUBSCRIPTION" }
→ 500        { success: false, error: "DELETE_FAILED" }
```

**Files:**
- `backend/src/Khudmati.API/Controllers/CustomersController.cs` — `DeleteMe` action; `[Authorize(Policy = "CustomerOnly")]`; takes `AppDbContext` + `ILogger` via DI.
- `backend/src/Khudmati.API/Controllers/ProvidersController.cs` — `DeleteMe` action; `[Authorize(Policy = "ProviderOnly")]`; same DI shape.
- `backend/src/Modules/Customers/.../Entities/Customer.cs` — new `SoftDeletePii()` method: anonymises `FullName="DELETED"`, `Email=null`, `Phone="DEL_<shortId>"` (preserves unique index), blanks `PasswordHash`, calls `Deactivate()`.
- `backend/src/Modules/Providers/.../Entities/Provider.cs` — matching `SoftDeletePii()`: same PII fields plus empty `ServiceCategories`, `IsOnline=false`.

**Server-side behaviour (implemented):**

1. Fetch the account — 404 if missing.
2. Guard: refuse deletion if caller has active jobs
   - Customer: `Pending` | `Accepted` | `EnRoute` | `InProgress`
   - Provider: `Accepted` | `EnRoute` | `InProgress`
3. Guard (provider only): refuse if an `Active` or `PastDue` subscription
   row exists — caller must cancel first via `DELETE /api/providers/me/subscription`.
4. In a single transaction:
   - `ExecuteDelete` refresh tokens for this account.
   - `ExecuteDelete` OTP verifications.
   - `ExecuteDelete` device tokens (filtered by `OwnerType`).
   - Provider only: `ExecuteDelete` provider location rows.
   - Call `SoftDeletePii()` on the account entity and `SaveChangesAsync`.
   - Commit.
5. On any exception, the transaction rolls back and the handler returns
   `500 DELETE_FAILED` (logged at Error level).
6. On success, log an Information line with the deleted account id.

**Explicitly NOT done (deferred as separate tickets if needed):**
- `AccountDeleted` SignalR push to other logged-in devices — access
  tokens continue to work until they expire (~15 min), at which point
  the refresh flow will fail because refresh tokens have been wiped.
  Acceptable for Apple; add later if ops want faster invalidation.
- `admins.audit_log` row — the existing audit log is super-admin-scoped
  (admin actions against users), not user-self-actions. Consider a
  separate `user_actions` audit stream later.
- Cascading anonymisation of `bookings.jobs`, `payments.transactions`,
  `bookings.ratings` — these tables reference customer / provider via
  FK only; no PII is stored there directly, so anonymising the parent
  row is sufficient for tax-law retention.

**Error-code mapping (mobile side) — ✅ DONE**

`mobile/lib/features/shared/profile/presentation/delete_account_action.dart`
now catches `DioException` separately, pulls `error` out of the JSON
body via a small `_extractErrorCode` helper, and switches:
- `HAS_ACTIVE_JOBS` → `s.deleteAccountHasActiveJobs` — "You have an
  active job. Complete or cancel it before deleting your account."
  (AR: "لا يمكن حذف الحساب لديك طلب نشط. أكمل الطلب أو ألغه أولاً.")
- `HAS_ACTIVE_SUBSCRIPTION` → `s.deleteAccountHasActiveSubscription`
  — "Cancel your Power Provider subscription first, then delete your
  account." (AR: "ألغِ اشتراك Power Provider أولاً ثم احذف الحساب.")
- Anything else (network error, 500, missing body) → the generic
  `s.deleteAccountError`.

Snackbar duration bumped to 5 seconds for the blocked-delete
messages so users can read them before they auto-dismiss.

### 2. Legacy-app force-upgrade flag (Phase 10 hand-off — ✅ SHIPPED)

**Shipped in this session** (2026-04-24) — the backend middleware
that was originally planned as a Phase 12 ops hand-off landed on
`feat/unified-app`:

- `backend/src/Khudmati.API/Middleware/LegacyAppUpgradeMiddleware.cs`
  — inspects `X-App-Package`, returns `HTTP 426` with the
  `UPGRADE_REQUIRED` payload that the mobile clients already
  recognise. `/api/health` is bypassed for load-balancer probes.
- `backend/src/Khudmati.API/Program.cs` — registered via
  `app.UseLegacyAppUpgradeGate()` between `UseCors()` and
  `UseAuthentication()` so unauthenticated endpoints are also gated.
- `backend/src/Khudmati.API/appsettings.json` — new `Auth:` section
  with `ForceUpgradeForLegacyApps: false` (default),
  `UnifiedAndroidStoreUrl`, `UnifiedIosStoreUrl`.

**Rollout steps (when ready to cut over):**
1. Confirm unified app is live in both stores (Play Store Production
   track, App Store Production).
2. Ship a final "Download the new Khudmati app" update to both legacy
   apps (store listing + in-app migration screen already done via
   Phase 10).
3. Wait ~48h for the legacy store listings to reach most devices.
4. On the prod backend, set `Auth:ForceUpgradeForLegacyApps = true`
   in `appsettings.json` (or environment variable
   `Auth__ForceUpgradeForLegacyApps=true`) and restart the service.
5. Monitor: watch `UPGRADE_REQUIRED blocked legacy bundle …` log
   lines and the `migration_opened_new_app` Firebase Analytics event
   on the unified app. Together they track adoption.

**Example 426 response:**
```
HTTP 426 Upgrade Required
Content-Type: application/json

{
  "success": false,
  "error": "UPGRADE_REQUIRED",
  "data": {
    "storeUrl": "https://play.google.com/store/apps/details?id=com.khudmati.app",
    "iosStoreUrl": "https://apps.apple.com/app/khudmati/id000000000"
  }
}
```

### 3. Privacy policy + terms URLs — ✅ DRAFTED, NEEDS LEGAL REVIEW + DEPLOY

- Bilingual static HTML landed at:
  - `web-landing/public/privacy.html` — effective 2026-04-24, sections: data collected, how we use it, who we share with, security, retention, user rights (access / correction / deletion / export / consent), children, changes, contact.
  - `web-landing/public/terms.html` — effective 2026-04-24, sections: what Khudmati is, eligibility, customer experience, provider experience, payments, acceptable use, IP, warranty disclaimer, liability cap, termination, governing law (Saudi Arabia / Riyadh courts), contact.
- Both files share a common brand-blue header, anchor-style language toggle (`#english` / `#arabic`), inline CSS (no build step required), and the same CSS variables as the landing page.
- `web-landing/src/components/layout/Footer.tsx` — the footer links now point at `/privacy.html` and `/terms.html` (previously `href="#"`).

**Before Apple submission:**
1. Legal review of both docs (tax-law retention window, dispute timelines, governing-law clause, Stripe Connect terms disclosure).
2. Deploy `web-landing` to production so
   `https://khudmati.app/privacy.html` and `https://khudmati.app/terms.html`
   return 200 OK.
3. If the hosting supports clean URLs (Vercel / Netlify / Cloudflare Pages
   all do automatically for `.html` files), the store-listing URLs
   `https://khudmati.app/privacy` and `/terms` will also resolve.
   Otherwise, edit `mobile/docs/store-listing-en.md` + `store-listing-ar.md`
   to use the `.html` suffixes explicitly.

Apple's reviewer will click these during review. If either returns 404, the submission is rejected under 5.1.1.

## Store submission runbook

### Android (Google Play Console)

1. **Sign the release APK** with the production keystore (not debug).
   ```bash
   flutter build appbundle --release \
     --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_<REDACTED>
   ```
   (Use `appbundle`, not `apk`, for Play Store submissions.)
2. **Upload** `build/app/outputs/bundle/release/app-release.aab` to Play Console → Internal testing track.
3. **Paste** copy from `store-listing-en.md` (Description tab, English) and `store-listing-ar.md` (Arabic).
4. **Upload assets:** feature graphic (1024×500), app icon (512×512), ≥ 2 phone screenshots per locale.
5. **Data safety form** — fill using the table in `store-listing-en.md` §"Data safety".
6. **Permissions declaration** — attach a Loom / screen recording showing the provider EnRoute GPS UX (required because `ACCESS_BACKGROUND_LOCATION` is declared).
7. **Content rating** — complete IARC questionnaire → expect "Everyone".
8. **Promote** Internal → Closed testing → Production once ready.

### iOS (App Store Connect, needs Mac access)

1. **Open** `mobile/ios/Runner.xcworkspace` in Xcode.
2. **Signing & Capabilities** → set the team + bundle id `com.khudmati.app`.
3. **Product → Archive** with the release scheme + `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_<REDACTED>`.
4. **Distribute → App Store Connect → Upload.**
5. In App Store Connect, create the English + Arabic listings using copy from `store-listing-en.md` / `store-listing-ar.md`.
6. **Privacy label** — paste from §"Data safety" in the EN doc.
7. **TestFlight** → invite internal testers, then external beta (requires Beta App Review, ~24h).
8. **Submit for Review** — target Apple's median 24–48h turnaround.

### Sunset the legacy apps (post-approval)

1. Bump the legacy-app version (`mobile-customer/pubspec.yaml`, `mobile-provider/pubspec.yaml`) — e.g. `1.9.0+legacy → 1.9.1+legacy`.
2. Rebuild + resubmit both legacy apps. They already carry the Phase 10 `UpgradeRequiredScreen` gate; a fresh build is just to push the in-store listing text to "This app has been replaced by Khudmati — download the new app" in the description.
3. Once both legacy store listings are live with the redirect text, flip `Auth:ForceUpgradeForLegacyApps = true` on the backend. Legacy app launches will now hit the upgrade screen on any API call.
4. Monitor the `migration_opened_new_app` Firebase Analytics event (defined in Phase 10) to track adoption week-over-week.

## Analytics dashboard hand-off

- New-app installs: Play Console → Statistics; App Store Connect → Sales and Trends.
- Old-app → new-app migration: `migration_opened_new_app` event count in Firebase Analytics → dashboard at Firebase → Events → `migration_opened_new_app` → Weekly count.
- Crash-free user rate: Firebase Crashlytics (must reach ≥ 99.5% before considering Phase 13 deprecation).

## Exit criteria (from phase-12-store.md)

- [ ] Play Store internal testing track live
- [ ] App Store TestFlight build live
- [ ] Production submissions queued in both stores
- [x] Backend endpoints `DELETE /api/customers/me` + `DELETE /api/providers/me` implemented 2026-04-24 — pending deploy to prod
- [x] Backend `Auth:ForceUpgradeForLegacyApps` flag implemented (default off) — shipped 2026-04-24 via `LegacyAppUpgradeMiddleware`
- [ ] `https://khudmati.app/privacy` + `https://khudmati.app/terms` live — drafted; pending legal review + deploy of `web-landing`
- [ ] Store listings approved (may trigger Phase 13)
- [ ] Analytics dashboard set up

## Rollback

If review reveals a P0, fix on `feat/unified-app`, bump the version, and resubmit. Do not retreat to Phase 11 unless the regression is verification-matrix-scope.

If the account-deletion endpoint isn't ready by first submission, Apple will reject under 5.1.1(v). The fix is purely backend — the mobile UI already exists.

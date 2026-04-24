# Phase 10 — Implementation (Hard Cutover)

Strategy locked in Phase 0 Decision C: **Hard cutover**. This file records
the concrete work landed on `feat/unified-app` and the runbook for flipping
the backend gate.

## What shipped in the unified app (`mobile/`)

| Area | File | Purpose |
|---|---|---|
| App identity constants | `lib/core/constants/app_config.dart` | `appPackage = "com.khudmati.app"`, `appVersion`, `androidStoreUrl`, `iosStoreUrl` |
| API headers | `lib/core/api/api_client.dart` | Every request sends `X-App-Package` + `X-App-Version` |
| Typed exception | `lib/core/api/api_client.dart` | `AppUpgradeRequired` + `upgradeRequiredProvider` (Riverpod state) |
| Interceptor gate | `lib/core/api/api_client.dart` | `onResponse` + `onError` detect HTTP 426 and `{"error":"UPGRADE_REQUIRED"}` payloads, raise the flag |
| Full-screen takeover | `lib/features/migration/presentation/upgrade_required_screen.dart` | Bilingual brand-blue card with Download CTA + Retry (defensive — unified app should never hit the gate) |
| Root overlay | `lib/app/app.dart` | `MaterialApp.builder` swaps in `UpgradeRequiredScreen` when the provider flag is non-null |
| Migration analytics | `lib/features/migration/data/migration_analytics.dart` | Fires `migration_opened_new_app` (Firebase Analytics) once per install, flag persisted in secure storage key `migration_first_launch_logged` |
| Wire-up | `lib/main.dart` | `unawaited(MigrationAnalytics().logFirstLaunchIfNeeded(...))` after Firebase init |
| Dependency | `pubspec.yaml` | `firebase_analytics: ^10.8.0` |

## What shipped in the legacy apps

Both `mobile-customer/` and `mobile-provider/` received a minimal final
patch (no feature work, no deletions — per Phase 13 rules).

| File | Change |
|---|---|
| `lib/core/constants/app_config.dart` | Added `appPackage` (`com.khudmati.customer` / `com.khudmati.provider`), `appVersion`, `unifiedStoreUrl` |
| `lib/core/api/api_client.dart` | Added `X-App-Package` / `X-App-Version` headers + module-level `upgradeRequiredNotifier` (`ValueNotifier<String?>`); `onResponse` + `onError` raise it on 426 / `UPGRADE_REQUIRED` |
| `lib/core/widgets/upgrade_required_screen.dart` | New — bilingual takeover pointing at the unified app's store listing |
| `lib/app/app.dart` | `MaterialApp.builder` wraps the router child in a `ValueListenableBuilder<String?>` that swaps to `UpgradeRequiredScreen` when the notifier fires |

Legacy apps do **not** include Firebase Analytics changes — the migration
event is emitted by the unified app only (the sole source of "I migrated"
signal).

## Backend hand-off — ✅ SHIPPED 2026-04-24

The backend middleware that was originally specced as a Phase 12
ops hand-off has landed on `feat/unified-app`. See
`migration-plan/phase-12-implementation.md` §"Legacy-app force-upgrade
flag" for the rollout runbook (wait for stores → flip flag → monitor).

Concrete files:
- `backend/src/Khudmati.API/Middleware/LegacyAppUpgradeMiddleware.cs`
- `backend/src/Khudmati.API/Program.cs` — `app.UseLegacyAppUpgradeGate()`
  between `UseCors()` and `UseAuthentication()`.
- `backend/src/Khudmati.API/appsettings.json` — `Auth:ForceUpgradeForLegacyApps`
  (default `false`) plus `UnifiedAndroidStoreUrl` / `UnifiedIosStoreUrl`.

One deviation from the spec below: the middleware runs at the
pipeline level (not inside individual controllers) so **every**
endpoint is gated uniformly — including SignalR hub negotiation and
the unauthenticated `/auth/*` surface. `/api/health` is explicitly
allowed through.

### Original spec (for reference — the middleware implements this)

**Header-based discrimination** (in `/auth/customers/login` and
`/auth/providers/login`):

```csharp
var appPackage = Request.Headers["X-App-Package"].FirstOrDefault();
var forceUpgrade = _config.GetValue<bool>("Auth:ForceUpgradeForLegacyApps");
var isLegacy = appPackage == "com.khudmati.customer"
            || appPackage == "com.khudmati.provider";

if (forceUpgrade && isLegacy)
{
    return StatusCode(426, new {
        success = false,
        error = "UPGRADE_REQUIRED",
        data = new { storeUrl = _config["Migration:UnifiedStoreUrl"] }
    });
}
```

Header absence → treat as legacy (pre-patch installs never send the
header). Requests with `X-App-Package = com.khudmati.app` always pass
through.

**Feature flag**: `Auth:ForceUpgradeForLegacyApps` (default `false`). Flip
to `true` only after:
1. Unified app is live in both stores with ≥95% rollout.
2. Monitoring dashboard confirms ≥5% of traffic carries
   `X-App-Package = com.khudmati.app` (= the new app is reaching
   real users).
3. Marketing push + in-app banner have gone out.

**Apply to**: login, refresh, register endpoints only on cutover day.
Read-only endpoints (job list, notifications) remain open so active
sessions in the legacy apps don't lose data mid-job.

## Communication plan

| Day | Channel | Copy (EN / AR) |
|---|---|---|
| **T-14** | In-app banner (old apps) | "New app coming soon. / قريباً تطبيق جديد." |
| **T-7** | Push to all old-app installs | "Download the new Khudmati app — your account, credit, and bookings are ready. / حمّل تطبيق خدمتي الجديد." |
| **T-7** | Email blast (customers with email on file) | Longer-form: why we merged, what's preserved, store link |
| **T-0** | Backend flag flip + push blast | "The new Khudmati app is now required. Tap to download. / أصبح تطبيق خدمتي الجديد مطلوباً." |
| **T+7** | Reminder push for users who haven't migrated | Same as T-0 |
| **T+14** | SMS to users with 0 sessions on new app | Shorter copy + store link |

Data source for T+7 / T+14: cross-reference
`customers.users.phone` against Firebase Analytics'
`migration_opened_new_app` event to identify non-migrated users.

## Monitoring

Dashboard panels (Grafana + Firebase):

1. **Store installs/day** — Play Console + App Store Connect.
2. **`migration_opened_new_app` fires/day** — Firebase Analytics
   custom event. Should track installs with ~30 min lag.
3. **% of `/auth/*` requests with `X-App-Package = com.khudmati.app`** —
   backend metric (request tagging). Ramp watch.
4. **`/auth/*` 426 rate** — expected 0% pre-cutover, spikes on T-0,
   should decay to <1% within 7 days.
5. **Crash-free sessions** (Crashlytics) — unified app, segmented by
   `os` and `locale` (EN/AR).
6. **Active SignalR connections** — should transition from old
   hub clients to new without a dip.

## FAQ (published to help desk + landing page)

- **"Why did the app change?"** — We merged the customer and provider
  apps into one app so you can do everything in one place.
- **"Do I need to re-register?"** — No. Sign in with your existing
  phone + password.
- **"Where is my credit / booking history / subscription?"** — All
  preserved server-side. Sign in and you'll see everything.
- **"Why did my Stripe payment method disappear?"** — It didn't.
  It's still linked to your account; you'll see it on your next
  booking.
- **"Can I have the old app back?"** — No. The old app will stop
  working after sign-in. Please install the new one.
- **"I'm a provider — will I lose my Active tier / subscription?"** —
  No. Your verification tier, skill-test results, payout account,
  and Power Provider subscription all carry over.

## Rollback

- Flip `Auth:ForceUpgradeForLegacyApps` to `false` in appsettings (no
  redeploy — backed by a config reload hook or a simple restart).
- Legacy apps' `upgradeRequiredNotifier` remains set for the current
  session. Users see the takeover until they relaunch the old app,
  which clears the `ValueNotifier`. Not fatal — the gate is reversible.
- Sunset date can be pushed out indefinitely.

## Exit criteria

- [x] Unified app `X-App-Package` + `X-App-Version` headers.
- [x] Unified app renders `UpgradeRequiredScreen` on 426 / `UPGRADE_REQUIRED`.
- [x] Legacy customer + provider apps ship the same gate.
- [x] `migration_opened_new_app` analytics event wired.
- [x] Communication plan drafted + FAQ written (this file).
- [ ] Backend patch reviewed + merged (separate ticket, Phase 12).
- [ ] Monitoring dashboard provisioned.
- [ ] No spike in `/auth/*` non-426 error rates during the first 72h
      after cutover.

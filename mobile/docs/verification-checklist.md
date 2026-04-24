# Khudmati Unified App — Phase 11 Verification Checklist

This is the device-by-device sign-off sheet for the unified app before store submission.
Every row must pass on **both** Android + iOS, in **both** English and Arabic, as **both**
customer and provider where applicable. Initial each cell with tester name + date when
the row passes (e.g. `AS 2026-04-25`). Mark `N/A` for cells the row says don't apply.

Source of truth: `migration-plan/phase-11-verification.md`.

---

## Build artefacts

### Android (Phase 11 QA build, payments bypassed)
```bash
cd "C:/Khedmate - ANJU_Context/mobile"
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_placeholder \
  --dart-define=BYPASS_PAYMENTS=true
```

### Android (real-Stripe release build, for rows 15d / 20 / 29a–31)
```bash
flutter build apk --release \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_<real_key>
```

### iOS (when Mac access is available)
```bash
flutter build ios --release --no-codesign \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_<real_key>
```

| Artefact | Path | Built? | Size | Installed on device? |
|---|---|---|---|---|
| Android release APK (bypass) | `build/app/outputs/flutter-apk/app-release.apk` | ✅ 2026-04-24 | 66.4 MB (fat APK, all ABIs) | |
| Android release APK (real Stripe) | `build/app/outputs/flutter-apk/app-release.apk` | | | |
| iOS release IPA (Xcode-signed) | TestFlight build | | | |

⚠️ **APK-size note (row 37):** the fat APK is 66 MB, over the Phase 11
< 40 MB target. For the actual Play Store submission use
`flutter build appbundle --release …` — Play Store serves per-ABI
slices (`arm64-v8a` is ~22 MB, `armeabi-v7a` is ~20 MB, `x86_64` is
~24 MB). Re-measure with appbundle before closing out row 37.

### Build environment caveats (corporate Windows host)
1. **Gradle wrapper pinned to 8.13-bin** in
   `android/gradle/wrapper/gradle-wrapper.properties`. 8.14-all
   failed to download (`PKIX path building failed` — SSL cert
   interception blocks first-time Gradle dist fetches). 8.13 was
   already cached from the legacy apps.
2. **`-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT`** is added to
   `org.gradle.jvmargs` in `android/gradle.properties` so Maven
   fetches from `dl.google.com` / `repo.maven.apache.org` go
   through the Windows cert store (which has the corporate root
   CA). Without this, every Gradle build fails at artefact
   resolution with the same SSL error.
3. **Do not revert either change** without verifying the new
   workstation has a non-intercepted HTTPS path.

### Backend target — this is PRODUCTION
- `AppConfig.backendHost = 'https://api.khudmati.app'` — the one and
  only backend. No separate staging environment exists; local dev
  points at the same host as legacy apps and the web admin.
- **Consequences for Phase 11 testing:**
  - Use phone numbers that are clearly test accounts (e.g.
    `+966500000001–9`) so they're easy to prune later.
  - Bookings, subscriptions, ratings, disputes created during the
    matrix run are real rows in prod. Flag them for cleanup.
  - A backend change may be needed for Phase 11 broadcasting (see
    caveat below under "Payment bypass"). If so, coordinate the prod
    rollout — no ad-hoc deploys during the test window.

### Stripe
- Key class: `pk_test_…` for Phase 11 QA; never `pk_live_…`.
- Most Phase 11 rows use the **bypass** build (see "Payment bypass"
  section). Only rows **15d / 20 / 29a–31 / 34** need real Stripe
  and a separate build with `BYPASS_PAYMENTS` omitted.

### Firebase
- Project: `khudmati-1089b` (shared with legacy apps).
- Unified app bundle id `com.khudmati.app` must be registered as a
  new Android app within that project (Project Settings → Your apps
  → Add app → Android). Download `google-services.json` into
  `mobile/android/app/google-services.json` (replaces the `.example`
  placeholder). Same drill for iOS bundle id `com.khudmati.app` →
  `GoogleService-Info.plist` into `mobile/ios/Runner/`.
- FCM rows 9–11 and Crashlytics row 39 depend on this being done.

## Payment bypass (Option B)

The unified app ships with a compile-time `BYPASS_PAYMENTS` flag
that skips the Stripe flow in `BookingNotifier.submitBooking()` —
no `createIntent`, no PaymentSheet, no `confirmPayment`; the job is
created directly via `POST /bookings/jobs`. An orange warning
banner on the booking summary screen makes it impossible to miss.

**Scope**:
- ✅ Covers the full customer booking flow (category → description
  → location → summary → job created).
- ✅ Unlocks post-booking rows 18, 21, 22, 23, 24, 26, 27, 32 once
  a provider accepts.
- ⚠️ **Open question**: does the backend broadcast the job to
  providers without a `confirmPayment` call? If **no**, rows 16, 17,
  18 stall on provider side against bypassed jobs. Verify on the
  first QA run — if the backend gates broadcast on payment
  confirmation, we need either a backend test flag
  (`QA:AllowUnpaidBroadcast`) or a real-Stripe build for those rows.
- ❌ Subscription row 29a cannot be bypassed (backend expects a
  real Stripe SetupIntent id).

---

## Test accounts (record once before starting)

| Role / state | Phone | Notes |
|---|---|---|
| Customer (fresh) | | No prior bookings |
| Customer (with referral credit) | | Has a referrer pending payout |
| Customer (with active job) | | For tracking + chat tests |
| Provider (Unverified) | | For onboarding flow |
| Provider (Active, no subscription) | | For standard job feed |
| Provider (Active, Power subscription) | | For 30 s head-start verification |
| Provider (Suspended) | | For suspended-account UX |
| Admin | | For dispute/verification approvals during the run |

---

## Test matrix

Legend: `EN-A`/`AR-A` = Android English/Arabic, `EN-i`/`AR-i` = iOS English/Arabic.

### Auth, session, language (rows 1–8)

| # | Flow | Role | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|---|
| 1 | Fresh install → welcome → pick role → register → OTP → home | Customer | | | | |
| 1 | Fresh install → welcome → pick role → register → OTP → home | Provider | | | | |
| 2 | Login existing account | Customer | | | | |
| 2 | Login existing account | Provider | | | | |
| 3 | Forgot password → OTP → reset → login | Customer | | | | |
| 3 | (N/A — provider has no forgot-password) | Provider | N/A | N/A | N/A | N/A |
| 4 | Language toggle EN↔AR applies to every screen | Customer | | | | |
| 4 | Language toggle EN↔AR applies to every screen | Provider | | | | |
| 5 | Logout → welcome → sign in as **other** role (no token/role leakage) | Both | | | | |
| 6 | Cold close → reopen → still logged in | Customer | | | | |
| 6 | Cold close → reopen → still logged in | Provider | | | | |
| 7 | Kill app mid-booking → reopen → state restored | Customer | | | | |
| 8 | Token expires mid-session → next API call refreshes transparently | Customer | | | | |
| 8 | Token expires mid-session → next API call refreshes transparently | Provider | | | | |

> Row 8 reproduction: delete `access_token` in secure storage (Android Studio → Device File Explorer → `data/data/com.khudmati.app/shared_prefs/`, or iOS via Keychain inspector) and trigger a request.

### Push & deep links (rows 9–13)

| # | Flow | Role | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|---|
| 9a | FCM push (app **killed**) — `JOB_ACCEPTED` opens correct screen | Customer | | | | |
| 9b | FCM push (app **killed**) — `NEW_JOB_AVAILABLE` opens correct screen | Provider | | | | |
| 9c | FCM push (app **killed**) — `MAINTENANCE_REMINDER` opens booking flow | Customer | | | | |
| 9d | FCM push (app **killed**) — `CHAT_MESSAGE` opens chat | Both | | | | |
| 10 | FCM push (app **backgrounded**) — same four types open correct screen | Both | | | | |
| 11 | FCM push (app **foreground**) — shows in-app banner | Both | | | | |
| 12a | Deep link `khudmati://job/<id>` — opens correct screen | Customer | | | | |
| 12a | Deep link `khudmati://job/<id>` — opens correct screen | Provider | | | | |
| 12b | Deep link `khudmati://reminders` | Customer | | | | |
| 12c | Deep link `khudmati://onboarding` | Provider | | | | |
| 12d | Deep link `khudmati://referral?ref=CODE` (pre-fills) | Customer | | | | |
| 13 | SignalR connects on login + reconnects after Wi-Fi toggle | Both | | | | |

> Row 12 reproduction (Android): `adb shell am start -W -a android.intent.action.VIEW -d "khudmati://job/123" com.khudmati.app`

### Chat (row 14)

| # | Flow | Role | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|---|
| 14a | Send message customer → provider (live, persisted, badge updates) | Both | | | | |
| 14b | Send message provider → customer (live, persisted, badge updates) | Both | | | | |
| 14c | Re-open chat after kill — history loads | Both | | | | |

### Customer booking + payment + tracking (rows 15, 18, 20)

| # | Flow | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|
| 15a | Category → description → Grok "Improve with AI" returns text | | | | |
| 15b | Location pin drag + reverse geocode | | | | |
| 15c | Apply referral code at summary → discount visible | | | | |
| 15d | Stripe PaymentSheet (test card `4242 4242 4242 4242`) succeeds — **requires real-Stripe build, `BYPASS_PAYMENTS` off** | | | | |
| 15e | Confirmation screen shows reference number | | | | |
| 18 | EnRoute live GPS pin moves on customer map (run with row 18 provider side simultaneously) | | | | |
| 20 | Customer pays after job marked Completed (Stripe test) — **requires real-Stripe build** | | | | |

### Provider job lifecycle (rows 16–19, 28)

| # | Flow | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|
| 16a | Standard provider receives broadcast ~30 s after job created (Power sees it immediately) | | | | |
| 16b | Power provider receives broadcast immediately | | | | |
| 17 | Accept job within 2-min countdown (countdown ring updates) | | | | |
| 18 | Provider EnRoute → 3 s GPS broadcast visible to customer (paired with row 18 customer side) | | | | |
| 19a | Upload after-photo before Complete (gate enforced) | | | | |
| 19b | Complete transition succeeds with after-photo | | | | |
| 28a | Onboarding: ID upload submits | | | | |
| 28b | Skill test: ≥ 7/10 to pass; 24 h cooldown on fail | | | | |
| 28c | Admin approves → tier becomes Active → router unblocks | | | | |

### Rating, dispute, referral, reminders (rows 21–27)

| # | Flow | Role | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|---|
| 21 | Rating bottom sheet appears after Paid | Both | | | | |
| 22 | Rating submit reflected in provider analytics tab `rating_stats` | Both | | | | |
| 23 | Dispute raise (customer) appears in admin panel | Customer | | | | |
| 24 | Dispute resolution SignalR event shows snackbar both sides | Both | | | | |
| 25a | Customer A registers + shares referral code | Customer | | | | |
| 25b | Customer B registers with code → 15% off first booking | Customer | | | | |
| 25c | After B's first paid job, A receives 20 SAR credit | Customer | | | | |
| 26 | Maintenance reminder push (backend worker) → tap → booking pre-filled | Customer | | | | |
| 27a | Reminder snooze 7 days | Customer | | | | |
| 27b | Reminder snooze 30 days (max) | Customer | | | | |
| 27c | Reminder dismiss | Customer | | | | |

### Subscription & payouts (rows 29–34)

| # | Flow | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|
| 29a | Subscribe to Power Provider via SetupIntent — **cannot be bypassed, requires real Stripe** | | | | |
| 29b | Next job arrives 30 s ahead of standard providers | | | | |
| 30 | Subscription payment failure → snackbar + grace period UX — **requires real Stripe** | | | | |
| 31 | Subscription cancel → tier reverts to Standard at period end — **requires real Stripe** | | | | |
| 32 | Earnings page shows correct net amount (gross − commission) | | | | |
| 33 | Analytics charts render correctly in LTR and RTL | | | | |
| 34 | Stripe Connect onboarding link opens browser from earnings page | | | | |

### Profile & misc (rows 35–36)

| # | Flow | Role | EN-A | AR-A | EN-i | AR-i |
|---|---|---|---|---|---|---|
| 35 | Edit profile (name + email for customer; name only for provider) saves | Both | | | | |
| 36 | Help & Support tile opens `https://khudmati.app/#contact` externally | Both | | | | |

### Performance & release-build hygiene (rows 37–40)

| # | Check | Target | Android | iOS |
|---|---|---|---|---|
| 37 | Release APK / IPA bundle size | < 40 MB | | |
| 38 | Cold start | < 3 s on Pixel-5-class device | | |
| 39 | Crashlytics dashboard after 24 h soak | 0 crashes / ANRs | | |
| 40a | Permission rationale: Location (when-in-use) | Shown on first request | | |
| 40b | Permission rationale: Background Location (provider EnRoute) | Shown after Active tier | | |
| 40c | Permission rationale: Camera (provider after-photo, customer ID-photo TBD) | Shown on first request | | |
| 40d | Permission rationale: Notifications (Android 13+) | Shown on first launch | | |

> Row 38 reproduction: `adb shell am start -W -n com.khudmati.app/.MainActivity` — read `TotalTime`.
> Row 37 reproduction: `ls -lh build/app/outputs/flutter-apk/app-release.apk` and Xcode → Window → Organizer → Archives → Show in Finder.

---

## Security checks (Section 3 of phase doc)

| # | Check | Result | Notes |
|---|---|---|---|
| S1 | Customer JWT calling `/api/providers/me/jobs` returns **403** | | Audience claim enforced |
| S2 | Tampering with `user_role` in secure storage cannot elevate privilege (server still rejects via JWT) | | Client-side claim is routing-only |
| S3 | Logout fully clears `access_token`, `refresh_token`, `user_role`, `provider_tier` | | Inspect via `adb shell run-as com.khudmati.app ls /data/data/com.khudmati.app/shared_prefs/` |
| S4 | Stripe publishable key matches environment (`pk_test_*` for staging, `pk_live_*` for prod) | | NEVER ship live key to staging |
| S5 | `X-App-Package: com.khudmati.app` header present on every request | | Phase 10 migration gate |

---

## Performance checks (Section 4 of phase doc)

| # | Check | Target | Result |
|---|---|---|---|
| P1 | App bundle size | < 40 MB | |
| P2 | Cold start (Pixel 5) | < 3 s | |
| P3 | Home FMP after login | < 1 s | |
| P4 | Memory after 10 min normal use | < 150 MB | |
| P5 | Sustained CPU when idle in foreground | < 5 % | |

---

## Accessibility quick-check (Section 5 of phase doc)

| # | Check | Android (TalkBack) | iOS (VoiceOver) |
|---|---|---|---|
| A1 | Role tiles announce role name | | |
| A2 | Primary CTA buttons announce label | | |
| A3 | Tab labels announce | | |
| A4 | All tap targets ≥ 44 × 44 pt | | |
| A5 | Text scales correctly up to 200 % font size | | |
| A6 | Colour contrast on brandBlue / amber buttons ≥ WCAG AA | | |

---

## Open issues found during verification

| ID | Severity (P0/P1/P2/P3) | Row | Platform | Description | Owner | Status |
|---|---|---|---|---|---|---|
| | | | | | | |

---

## Sign-off

| Role | Name | Date | Signature |
|---|---|---|---|
| QA lead | | | |
| Mobile lead | | | |
| Backend lead | | | |
| Product owner | | | |

**Exit criteria** (all must be ✓ before Phase 12):
- [ ] All 40 test matrix rows signed off per platform
- [ ] No P0 / P1 bugs open
- [ ] No unresolved ProGuard / R8 stripping issues (Stripe / SignalR / Firebase intact)
- [ ] Release APK + iOS IPA built cleanly
- [ ] Crashlytics clean for the 24 h soak test

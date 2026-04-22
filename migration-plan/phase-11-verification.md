# Phase 11 — End-to-End Verification

## Goal
Exhaustively test the unified app on real devices, across both roles, across both languages, and against a production-parity backend. Release build only — debug builds hide latent ProGuard, obfuscation, and permission issues.

## Why this phase
This is the last gate before shipping to stores. Every latent issue caught here saves a bad store review later.

## Pre-requisites
- Phase 09 complete (release builds sign successfully)
- At least one real Android device + one real iOS device
- A staging backend instance or production with a test data slice
- Test accounts for both roles at various states (unverified provider, active provider with subscription, customer with referral credit, etc.)

## Scope

### 1. Build artefacts
```bash
cd "C:/Khedmate - ANJU_Context/mobile"
flutter clean
flutter pub get
flutter build apk --release --dart-define=STRIPE_PK=pk_test_xxx
flutter build ios --release --no-codesign --dart-define=STRIPE_PK=pk_test_xxx
```

Artefacts to install:
- `build/app/outputs/flutter-apk/app-release.apk` → Android device
- Signed `.ipa` via Xcode → iOS device (TestFlight recommended)

### 2. Test matrix

Each row must pass on **both** Android + iOS, in **both** English and Arabic, as **both** customer and provider where applicable.

| # | Flow | Customer | Provider | Notes |
|---|---|---|---|---|
| 1 | Fresh install → welcome screen → pick role → register → OTP → home | ✓ | ✓ | |
| 2 | Login existing account | ✓ | ✓ | |
| 3 | Forgot password → OTP → reset → login | ✓ | — | Provider has no forgot-password flow |
| 4 | Language toggle EN↔AR applies to every screen | ✓ | ✓ | Walk every tab, every screen |
| 5 | Logout → welcome → sign in as **other** role | ✓ | ✓ | Verifies no token/role leakage |
| 6 | Close app cold → reopen → still logged in | ✓ | ✓ | Token persistence |
| 7 | Kill app with in-progress booking form → reopen → state restored | ✓ | — | |
| 8 | Token expires mid-session → next API call refreshes transparently | ✓ | ✓ | Force by deleting access_token in storage |
| 9 | Receive FCM push when app killed → tap → opens correct screen | ✓ | ✓ | Test JOB_ACCEPTED + NEW_JOB_AVAILABLE + MAINTENANCE_REMINDER + CHAT_MESSAGE |
| 10 | Receive FCM when app backgrounded → tap → correct screen | ✓ | ✓ | Same types |
| 11 | Receive FCM when app foreground → shows in-app banner | ✓ | ✓ | |
| 12 | Deep link `khudmati://job/<id>` opens correct screen | ✓ | ✓ | Test via `adb shell am start` |
| 13 | SignalR connects on login, reconnects after Wi-Fi toggle | ✓ | ✓ | |
| 14 | Chat bidirectional, messages persist, unread badge updates | ✓ | ✓ | |
| 15 | Full booking flow: category → description (with AI improve) → location (pin drag + geocode) → summary (with referral code) → Stripe pay → confirmation | ✓ | — | |
| 16 | Provider sees new job broadcast within expected window | — | ✓ | Standard: ~30s delay for non-Power, immediate for Power |
| 17 | Provider accepts job within 2-min countdown | — | ✓ | |
| 18 | Provider EnRoute → customer sees live GPS pin moving | ✓ | ✓ | Test both sides simultaneously |
| 19 | Provider uploads after-photo → completes | — | ✓ | |
| 20 | Customer pays (Stripe test card 4242 4242 4242 4242) | ✓ | — | |
| 21 | Rating bottom sheet appears after Paid | ✓ | ✓ | |
| 22 | Rating submits → reflected in provider's rating_stats | ✓ | ✓ | Check analytics tab |
| 23 | Dispute raise flow (customer) → appears in admin panel | ✓ | — | |
| 24 | Dispute resolution SignalR event → shows snackbar both sides | ✓ | ✓ | |
| 25 | Referral: customer A registers → customer B registers with code → B gets 15% off, A gets 20 SAR credit after B's first paid job | ✓ | — | Full flow |
| 26 | Maintenance reminder fires via backend worker → customer receives push → taps → booking flow pre-filled | ✓ | — | |
| 27 | Reminder snooze (7/30 days) + dismiss works | ✓ | — | |
| 28 | Provider onboarding: upload ID → skill test → admin approves → tier becomes Active | — | ✓ | |
| 29 | Provider subscribes to Power Provider (Stripe SetupIntent) → receives 30s head-start on next job | — | ✓ | |
| 30 | Subscription payment failure → provider sees snackbar + grace period UX | — | ✓ | Backend can simulate |
| 31 | Subscription cancellation → tier reverts to Standard after current period | — | ✓ | |
| 32 | Earnings page shows correct net amount after commission | — | ✓ | |
| 33 | Analytics charts render in both LTR and RTL | — | ✓ | |
| 34 | Stripe Connect onboarding link works from earnings page | — | ✓ | |
| 35 | Edit profile (name + email) saves | ✓ | ✓ | |
| 36 | Help & Support link opens `https://khudmati.app/#contact` externally | ✓ | ✓ | |
| 37 | Release APK bundle size < 40 MB | — | — | `ls -lh app-release.apk` |
| 38 | Cold start < 3s on mid-range Android device | — | — | Measure with `adb shell am start -W` |
| 39 | No ANRs / crashes observed in Firebase Crashlytics during test | — | — | Check dashboard after 24h soak |
| 40 | All permission rationales display correctly | ✓ | ✓ | Location, Camera, Notifications, Background Location |

### 3. Security checks
- Verify JWT audience claim enforced on backend by attempting to call `/api/providers/me/jobs` with a customer JWT → must return 403
- Verify `user_role` in secure storage cannot be tampered with to elevate privilege (it's only used for client-side routing — the backend trusts the JWT, not the client claim)
- Verify that logout fully clears: access_token, refresh_token, user_role. Check via `adb shell run-as com.khudmati.app ls /data/data/com.khudmati.app/shared_prefs/` and secure storage inspection
- Verify Stripe publishable key used is `pk_test_*` for staging, `pk_live_*` for production — do NOT ship a live key to staging builds

### 4. Performance
- App bundle size: target < 40 MB (both apps today are ~25 MB each; union expected ~35 MB)
- Cold start: < 3s on a mid-range Android device (e.g. Pixel 5)
- Home screen first-meaningful-paint: < 1s after login
- Memory footprint after 10 minutes of normal use: < 150 MB
- No sustained CPU > 5% when app is idle in foreground

### 5. Accessibility quick-check
- Screen reader (TalkBack / VoiceOver) announces role tiles, primary buttons, tab labels
- All tap targets ≥ 44×44pt
- Text scales correctly up to 200% font size setting
- Colour contrast on brandBlue/amber buttons ≥ WCAG AA

## Files to create
- `mobile/docs/verification-checklist.md` — Markdown checklist derived from the matrix above, signed off per row per platform

## Verification
The phase's own verification is the test matrix. No additional verification needed.

## Exit criteria
- [ ] All 40 test matrix rows signed off (date + tester name per row)
- [ ] No P0 / P1 bugs open
- [ ] No unresolved ProGuard / R8 stripping issues (Stripe, SignalR, Firebase intact)
- [ ] Release APK + iOS IPA built cleanly
- [ ] Crashlytics clean for the 24h soak test
- [ ] Commit the verification checklist: `docs(mobile): Phase 11 verification sign-off`

## Rollback
- If any P0 row fails, return to the phase that introduced the regression. Do not advance to Phase 12.

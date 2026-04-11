# Feature: Provider App — Critical Bug Fixes & Routing Gaps (Part 1 of 3)

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR
- Frontend: Flutter provider app (`mobile-provider/`) — Riverpod, GoRouter, Dio
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`

## Goal
Fix every critical bug, broken route, and routing crash found in a codebase audit of the provider app. All changes are confined to `mobile-provider/`. No new features yet — this pass is purely correctness and stability.

## Platforms Affected
- [ ] Customer Mobile App
- [x] Provider Mobile App
- [ ] Web Landing Page
- [ ] Web Admin Panel
- [ ] Web Super Admin Panel

---

## Fix 1 — Logout Does Not Clear Tokens (Critical Bug)

**File:** `mobile-provider/lib/features/profile/presentation/profile_page.dart`

### Problem
The current logout just navigates to `/login` without calling `AuthNotifier.logout()`. Tokens remain in `FlutterSecureStorage`, so the provider is still "authenticated" on the next app open.

```dart
// CURRENT (broken)
onTap: () => context.go('/login'),
```

### Fix
Replace with a proper logout:

```dart
onTap: () async {
  await ref.read(authNotifierProvider.notifier).logout();
  if (context.mounted) context.go('/welcome');
},
```

`AuthNotifier.logout()` in `lib/features/auth/presentation/auth_provider.dart` already exists and properly calls `AuthRepository.logout()` which clears tokens from `FlutterSecureStorage`. Confirm this is the case — if `logout()` doesn't exist on `AuthNotifier`, add it:
```dart
Future<void> logout() async {
  await _repository.logout();
  state = const AsyncData(AuthUnauthenticated());
}
```

---

## Fix 2 — Onboarding Routes Not Registered in Router (Critical Bug)

**File:** `mobile-provider/lib/app/router.dart`

### Problem
The three onboarding screens (`OnboardingHubScreen`, `IdUploadScreen`, `SkillTestScreen`) exist in `lib/features/onboarding/presentation/` but **no routes** are defined in `router.dart`. The FCM push handler tries to navigate to `/onboarding` and crashes silently.

### Fix
Add the following routes inside `router.dart`, **outside** the `StatefulShellRoute` (they must be top-level, like `/job-detail/:jobId`):

```dart
GoRoute(
  path: '/onboarding',
  builder: (_, __) => const OnboardingHubScreen(),
),
GoRoute(
  path: '/onboarding/id-upload',
  builder: (_, __) => const IdUploadScreen(),
),
GoRoute(
  path: '/onboarding/skill-test',
  builder: (_, __) => const SkillTestScreen(),
),
```

Add the required imports at the top of `router.dart`:
```dart
import '../features/onboarding/presentation/onboarding_hub_screen.dart';
import '../features/onboarding/presentation/id_upload_screen.dart';
import '../features/onboarding/presentation/skill_test_screen.dart';
```

Also update `_isAuthRoute` to allow the auth guard to pass through these screens for authenticated users:
The guard currently redirects unauthenticated users away from non-auth routes — onboarding routes must be **accessible only when authenticated**, which is the existing default behaviour (no change needed there).

---

## Fix 3 — FCM Push Handler Routes to Missing `/onboarding` Path

**File:** `mobile-provider/lib/core/services/fcm_service.dart`

### Problem
The `_navigateFromMessage` function (around line 106) attempts to navigate to the onboarding path, but the route did not exist (now fixed in Fix 2 above). Additionally, verify the handler sends:
- `VERIFICATION_STATUS_CHANGED` → navigate to `/onboarding`
- `NEW_JOB_AVAILABLE` → navigate to `/jobs`
- Any other type → navigate to `/notifications`

### Fix
Verify the `_navigateFromMessage` function handles these exact types. If the push type strings differ from the backend, align them with the actual FCM `data['type']` values sent by the backend. Check `Modules/Notifications/` in the backend to confirm type strings.

Ensure the function:
1. Reads `message.data['type']`
2. Routes to `/onboarding` for `VERIFICATION_STATUS_CHANGED`
3. Routes to `/jobs` for `NEW_JOB_AVAILABLE`
4. Falls back to `/notifications` for everything else
5. Handles the case where the router is not yet ready (wrap with `WidgetsBinding.instance.addPostFrameCallback`)

---

## Fix 4 — API Client Refresh Path Mismatch

**Files:**
- `mobile-provider/lib/core/api/api_client.dart` (line ~46)
- `mobile-provider/lib/features/auth/data/auth_repository.dart` (line ~61)

### Problem
The `ApiClient` 401-refresh interceptor uses a different refresh endpoint path than `AuthRepository.refreshTokens()`. This means silent token refresh during API calls uses the wrong URL.

### Fix
1. Read both files and identify the actual paths used.
2. Align them to use the same path: `POST /api/providers/auth/refresh`.
3. The `ApiClient` interceptor must send `{ refreshToken: <token> }` in the request body (same as `AuthRepository`).
4. On success, store the new access token and retry the original request.
5. On refresh failure (401 on the refresh call itself), clear storage and set auth state to `AuthUnauthenticated()`.

The interceptor should:
```dart
// On 401 response:
try {
  final newTokens = await _authRepository.refreshTokens();
  // Update stored access token
  // Retry original request with new token
} catch (e) {
  // Refresh failed — force logout
  _authRepository.clearTokens();
  // Signal auth state change
}
```

If `AuthRepository` is not currently injected into `ApiClient`, inject it via the constructor or use a `Ref`-based approach consistent with the rest of the codebase.

---

## Fix 5 — NavigationPage Is Fully Simulated (Not Wired to Real Job)

**File:** `mobile-provider/lib/features/navigation/presentation/navigation_page.dart`

### Problem
`NavigationPage` receives a `jobId` but completely ignores it. The map shows hardcoded Riyadh coordinates (`24.7200, 46.6800`) and a hardcoded Beirut pin (`33.8938, 35.5018`). The address label is hardcoded Arabic text `'حي النزهة، الرياض'`. Status transitions are a local state machine disconnected from the backend.

### Fix
Wire `NavigationPage` to the real `ActiveJobDetailNotifier` (already exists in `active_job_provider.dart`):

1. Watch `activeJobDetailProvider(jobId)` to get the real `ActiveJob` object.
2. Show the customer's `latitude`/`longitude` from the job as the destination pin.  
   - The provider's current location (the "my location" pin) should come from the device GPS — use the `geolocator` package that is already a dependency in `pubspec.yaml`.
3. Replace the hardcoded address text with `job.district` or `job.address` from the `ActiveJob` model.
4. Keep the status transition buttons as-is (they call the real API via `activeJobDetailProvider`'s `advanceStatus()` method already).
5. Remove the hardcoded `_status` local string — instead derive the displayed label from `job.status`.

Map pins:
- Destination (customer): `LatLng(job.latitude, job.longitude)` — amber `Icons.location_on`
- Provider current location: device GPS `LatLng` — blue `Icons.my_location`

If `ActiveJob` does not carry `latitude`/`longitude`, use the coordinates already stored in `job_repository.dart`'s `ActiveJob.fromJson()` — they are already parsed there.

The hardcoded `const LatLng(33.8938, 35.5018)` (Beirut) must be replaced — this is a critical data error for a Saudi market app.

---

## Fix 6 — Empty State Refresh Button Is Disabled

**File:** `mobile-provider/lib/features/jobs/presentation/job_feed_screen.dart` (line ~321)

### Problem
The `_EmptyState` widget shows a refresh `IconButton` with `onPressed: null` — it is permanently disabled and unresponsive.

### Fix
Change the `IconButton` to be functional:

```dart
// Inside _EmptyState
IconButton(
  onPressed: () => ref.read(jobFeedNotifierProvider.notifier).refresh(),
  icon: const Icon(Icons.refresh, color: AppColors.brandBlue),
),
```

---

## Fix 7 — Distance Unit Hardcoded in Arabic Only

**File:** `mobile-provider/lib/features/jobs/presentation/job_feed_screen.dart` (line ~216)

### Problem
Distance is displayed as `' ${job.distanceKm} كم'` — the "كم" suffix is hardcoded Arabic and appears regardless of locale.

### Fix
Add a localised distance unit to `app_strings.dart`:
```dart
String distanceKm(double km) => isAr ? '$km كم' : '${km} km';
```

Replace the hardcoded string in `job_feed_screen.dart`:
```dart
Text(s.distanceKm(job.distanceKm), ...)
```

---

## Fix 8 — Profile Hardcodes Rating as 4.8

**File:** `mobile-provider/lib/features/profile/presentation/profile_page.dart` (line ~60)

### Problem
The star rating in the profile header is hardcoded as `Text('4.8')`. The real rating stats are available from the backend (`GET /api/providers/me/rating-stats` returns aggregate stats), and the `AuthAuthenticated` state contains the `ProviderUser` model.

### Fix
Check if `ProviderUser` (from `auth_provider.dart`) carries a `ratingAvg` or similar field. If it does, use it:
```dart
Text(user?.ratingAvg?.toStringAsFixed(1) ?? '—', style: ...)
```

If `ProviderUser` does not carry rating data, add a separate `FutureProvider` that calls `GET /api/providers/me/analytics/ratings` (endpoints already exist from Feature #20 — but analytics screen is not built yet). Extract just the `positiveRatePct` and show it as a % next to a thumbs-up icon instead of a star rating.

If neither is feasible without building the analytics module first, show `user?.jobsCompleted` count instead of the fake rating, and hide the star icon. Do not leave the hardcoded `4.8`.

---

## Acceptance Criteria
- [ ] Logout properly clears tokens — re-opening the app after logout shows the Welcome screen
- [ ] `/onboarding`, `/onboarding/id-upload`, `/onboarding/skill-test` routes are registered and navigable
- [ ] FCM push for `VERIFICATION_STATUS_CHANGED` opens the Onboarding Hub screen without error
- [ ] Token refresh in the API client interceptor uses the correct endpoint and retries failed requests
- [ ] `NavigationPage` shows the real customer location pin (from job data) not hardcoded Beirut coordinates
- [ ] `NavigationPage` shows the job's real district/address, not hardcoded Arabic text
- [ ] Empty state refresh button on Jobs tab is tappable and triggers a feed reload
- [ ] Distance label respects the app locale (Arabic `كم` / English `km`)
- [ ] Profile header does not show the hardcoded `4.8` rating

## Out of Scope (do not implement in this prompt)
- Subscription / Power Provider feature
- Analytics dashboard
- Profile Edit screen (covered in Part 2)
- Chat / rating l10n cleanup (covered in Part 2)
- Completed Jobs tab (covered in Part 2)
- Any backend changes

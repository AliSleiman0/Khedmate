# Phase 03 — Role Selection & Router Skeleton

## Goal
Build the new `WelcomeScreen` (role picker) and a minimal `GoRouter` that redirects based on `roleProvider` + auth state. No real feature screens yet — just placeholders so the routing shape can be tested end-to-end.

## Why this phase
The role is the single most important piece of app state. Getting the selection flow and persistence right here prevents subtle token-scope bugs later when features start reading `roleProvider`.

## Pre-requisites
- Phase 02 complete — `roleProvider` and `localeProvider` exist
- Branch `feat/unified-app`

## Scope

### 1. Build `WelcomeScreen`
Location: `mobile/lib/features/auth/presentation/welcome_screen.dart`

Layout (matches brand: blue surface, amber accent, Cairo/Inter):
- Logo at top
- App name + tagline
- Language toggle (EN/AR) — reuses `localeProvider`
- Two large stacked tiles:
  - **"I need a service"** (customer) — blue-filled, icon `Icons.home_outlined`
  - **"I provide services"** (provider) — amber-filled, icon `Icons.handyman_outlined`
- Below each tile a sub-label in the chosen language explaining the role
- Tile tap → `ref.read(roleProvider.notifier).setRole(UserRole.customer or .provider)` → `context.go('/login')`

New l10n keys (add to Phase 2's `app_strings.dart`):
- `welcomeRoleCustomer` / `welcomeRoleProvider`
- `welcomeRoleCustomerSub` / `welcomeRoleProviderSub`
- `welcomeRoleQuestion`

### 2. Build placeholder auth screens
Purpose: routing end-to-end test only. Real auth in Phase 4.

- `mobile/lib/features/auth/presentation/login_placeholder.dart` — single-button "Log in as mock user" that writes mock tokens + reads role
- `mobile/lib/features/auth/presentation/register_placeholder.dart` — "Go back to welcome"

### 3. Build placeholder home screens
- `mobile/lib/features/customer/placeholder_home.dart` — "Customer home (placeholder)" + logout button
- `mobile/lib/features/provider/placeholder_home.dart` — "Provider home (placeholder)" + logout button

Logout: clears access/refresh tokens, clears `roleProvider`, routes to `/welcome`.

### 4. Wire `GoRouter` in `mobile/lib/app/router.dart`
Routes:
| Path | Screen | Guard |
|---|---|---|
| `/welcome` | WelcomeScreen | public |
| `/login` | LoginPlaceholder | public; 404 if `roleProvider` is null (redirect to `/welcome`) |
| `/register` | RegisterPlaceholder | public; same guard as /login |
| `/customer/home` | CustomerPlaceholderHome | auth + role==customer |
| `/provider/home` | ProviderPlaceholderHome | auth + role==provider |

Redirect logic:
```dart
redirect: (context, state) {
  final hasToken = /* read access_token from secure storage */;
  final role = ref.read(roleProvider);
  final goingTo = state.matchedLocation;

  if (!hasToken) {
    if (goingTo == '/welcome') return null;
    if (goingTo == '/login' && role != null) return null;
    if (goingTo == '/register' && role != null) return null;
    return '/welcome';
  }

  // authenticated
  if (role == UserRole.customer && !goingTo.startsWith('/customer')) return '/customer/home';
  if (role == UserRole.provider && !goingTo.startsWith('/provider')) return '/provider/home';
  if (role == null) return '/welcome'; // edge case
  return null;
}
```

### 5. Hook router into `MaterialApp.router`
Update `mobile/lib/app/app.dart` to wire the router from step 4.

### 6. Smoke-test the flow
End-to-end without touching real auth:
1. Fresh install → lands on `/welcome`
2. Tap "I need a service" → writes role=customer → routes to `/login`
3. Tap "Log in as mock" → writes fake tokens → routes to `/customer/home`
4. Tap logout → clears tokens + role → back to `/welcome`
5. Tap "I provide services" → role=provider → `/login` → mock login → `/provider/home`
6. Hot-restart with role=customer + tokens present → goes straight to `/customer/home`

## Files to create
- `mobile/lib/features/auth/presentation/welcome_screen.dart`
- `mobile/lib/features/auth/presentation/login_placeholder.dart`
- `mobile/lib/features/auth/presentation/register_placeholder.dart`
- `mobile/lib/features/customer/placeholder_home.dart`
- `mobile/lib/features/provider/placeholder_home.dart`
- `mobile/lib/app/router.dart`

## Files to modify
- `mobile/lib/app/app.dart` — wire router
- `mobile/lib/core/l10n/app_strings.dart` — add 5 welcome keys

## Verification
- 6-step smoke test above passes on both Android + iOS
- After logout, `flutter_secure_storage` inspection shows `access_token`, `refresh_token`, `user_role` are all absent
- Fresh install after reinstall still lands on `/welcome` (role is cleared when app is uninstalled)
- Language toggle on welcome screen updates all visible text immediately

## Exit criteria
- [ ] WelcomeScreen matches brand style (brandBlue header, amber/blue role tiles)
- [ ] Router redirect logic passes all 6 smoke-test steps
- [ ] Placeholder screens are clearly labelled "PLACEHOLDER" in the UI (prevents mistaking for real screens during Phase 4+)
- [ ] `flutter analyze` clean
- [ ] Commit: `feat(mobile): role selection + router skeleton`

## Rollback
- Revert commit. No user-facing release involved yet.

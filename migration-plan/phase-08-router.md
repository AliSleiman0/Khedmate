# Phase 08 — Router Consolidation & Deep Links

## Goal
Collapse the two role-specific shells into a single `GoRouter` with top-level role-aware redirect, and wire all FCM/deep-link payloads through a single `notification_handler` that routes by role.

## Why this phase
After Phase 6 and 7 each built their own `StatefulShellRoute`, the router is functionally split in two. This phase unifies it under one `GoRouter` instance, fixes edge cases (stale role, token without role, hot-restart with partial state), and formalizes deep linking.

## Pre-requisites
- Phase 06 + 07 complete — both role branches function
- Branch `feat/unified-app`

## Scope

### 1. Unified `GoRouter`
Location: `mobile/lib/app/router.dart`

Structure:
```dart
final router = GoRouter(
  initialLocation: '/welcome',
  refreshListenable: GoRouterRefreshStream(
    Stream.fromIterable([roleProvider, authProvider]),
  ),
  redirect: (context, state) => _topLevelRedirect(ref, state),
  routes: [
    // public
    GoRoute(path: '/welcome', ...),
    GoRoute(path: '/login', ...),
    GoRoute(path: '/register', ...),
    GoRoute(path: '/otp', ...),
    GoRoute(path: '/forgot-password', ...),
    GoRoute(path: '/reset-password', ...),

    // customer shell
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (ctx, state, shell) => MainScaffoldCustomer(shell: shell),
      branches: [
        StatefulShellBranch(routes: [ /* /customer/home */ ]),
        StatefulShellBranch(routes: [ /* /customer/history */ ]),
        StatefulShellBranch(routes: [ /* /customer/notifications */ ]),
        StatefulShellBranch(routes: [ /* /customer/profile */ ]),
      ],
    ),

    // provider shell
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (ctx, state, shell) => MainScaffoldProvider(shell: shell),
      branches: [
        StatefulShellBranch(routes: [ /* /provider/jobs */ ]),
        StatefulShellBranch(routes: [ /* /provider/earnings */ ]),
        StatefulShellBranch(routes: [ /* /provider/notifications */ ]),
        StatefulShellBranch(routes: [ /* /provider/profile */ ]),
      ],
    ),

    // role-agnostic off-shell routes (booking wizard, chat, navigation, etc.)
  ],
);
```

### 2. Top-level redirect logic
```dart
String? _topLevelRedirect(WidgetRef ref, GoRouterState state) {
  final hasToken = _hasAccessToken();
  final role = ref.read(roleProvider);
  final path = state.matchedLocation;

  final publicPaths = {'/welcome', '/login', '/register', '/otp',
                      '/forgot-password', '/reset-password'};

  // Not authenticated
  if (!hasToken) {
    if (publicPaths.contains(path)) return null;
    return '/welcome';
  }

  // Authenticated but role missing (shouldn't happen, but defensive)
  if (role == null) return '/welcome';

  // Authenticated on a public route → bounce to home
  if (publicPaths.contains(path)) {
    return role == UserRole.customer ? '/customer/home' : '/provider/home';
  }

  // Wrong role trying to visit other role's tree
  if (role == UserRole.customer && path.startsWith('/provider/')) {
    return '/customer/home';
  }
  if (role == UserRole.provider && path.startsWith('/customer/')) {
    return '/provider/home';
  }

  return null;
}
```

### 3. Unified `notification_handler.dart`
Location: `mobile/lib/core/services/notification_handler.dart`

Every FCM/local notification tap flows through here. Role determines the route:

```dart
void handleTap(RemoteMessage message, WidgetRef ref) {
  final role = ref.read(roleProvider);
  final type = message.data['type'] as String?;
  final jobId = message.data['jobId'] as String?;

  switch (type) {
    case 'JOB_ACCEPTED':
      if (role == UserRole.customer) router.push('/customer/tracking/$jobId');
      break;
    case 'NEW_JOB_AVAILABLE':
      if (role == UserRole.provider) router.push('/provider/jobs');
      break;
    case 'MAINTENANCE_REMINDER':
      if (role == UserRole.customer) router.push('/customer/booking/category');
      break;
    case 'VERIFICATION_APPROVED':
    case 'VERIFICATION_REJECTED':
      if (role == UserRole.provider) router.push('/provider/onboarding');
      break;
    case 'PAYMENT_RELEASED':
      if (role == UserRole.provider) router.push('/provider/payout-status');
      break;
    case 'DISPUTE_RESOLVED':
      if (role == UserRole.customer) router.push('/customer/history/$jobId');
      if (role == UserRole.provider) router.push('/provider/job-detail/$jobId');
      break;
    case 'SUBSCRIPTION_ACTIVATED':
    case 'SUBSCRIPTION_PAYMENT_FAILED':
    case 'SUBSCRIPTION_CANCELLED':
      if (role == UserRole.provider) router.push('/provider/subscription');
      break;
    case 'CHAT_MESSAGE':
      final path = role == UserRole.customer
        ? '/customer/chat/$jobId'
        : '/provider/chat/$jobId';
      router.push(path);
      break;
  }
}
```

### 4. Android intent-filter + iOS URL scheme
Announce custom URL scheme `khudmati://` for deep links. Configure:
- Android: `AndroidManifest.xml` `<intent-filter>` under `MainActivity`
- iOS: `Info.plist` `CFBundleURLTypes`

Supported paths:
- `khudmati://job/{jobId}` → routes via handler to customer tracking or provider job detail based on role
- `khudmati://reminders` → customer reminders screen
- `khudmati://onboarding` → provider onboarding hub

### 5. Remove off-shell duplicate routes from Phase 5
Phase 5 registered `/chat/:jobId`, `/profile`, `/notifications`, `/profile/edit` at top level as a temporary shim. Now they only exist under `/customer/...` and `/provider/...`. Update internal `context.push(...)` calls throughout the codebase.

## Files to create
- `mobile/lib/core/services/notification_handler.dart` (full version)

## Files to modify
- `mobile/lib/app/router.dart` — full rewrite into single GoRouter
- `mobile/lib/main.dart` — wire FCM handler + deep-link listener
- `mobile/android/app/src/main/AndroidManifest.xml` — intent filters
- `mobile/ios/Runner/Info.plist` — URL types

## Verification
Specifically the hard cases:
1. **Cold start, no token, no role** → `/welcome`
2. **Cold start, token + role customer** → `/customer/home`
3. **Cold start, token + role provider** → `/provider/home`
4. **Cold start, token but role null** (corrupted state) → `/welcome`, token cleared
5. **Cold start, token + role provider but tier != Active** → `/provider/onboarding`
6. **Hot restart during booking flow (customer)** → returns to same step
7. **FCM tap while app killed (customer, JOB_ACCEPTED)** → opens app → `/customer/tracking/<id>`
8. **FCM tap while app backgrounded (provider, NEW_JOB_AVAILABLE)** → foregrounds → `/provider/jobs`
9. **Deep link `khudmati://job/abc`** as customer → tracking; as provider → job detail
10. **Visit customer route while logged in as provider** → redirected to `/provider/home`
11. **Logout from any screen** → `/welcome`, tokens and role cleared, cannot back-button into protected route

## Exit criteria
- [ ] All 11 hard cases pass
- [ ] Single `GoRouter` instance (no split)
- [ ] All `context.push` / `context.go` calls use new paths
- [ ] Notification handler is the only file that contains FCM-type → route mapping
- [ ] `flutter analyze` clean
- [ ] Commit: `feat(mobile): unified router + deep-link handler`

## Rollback
- Revert commit. Phase 6/7 split routing still works.

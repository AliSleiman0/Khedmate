# Phase 02 — Core infrastructure

**Depends on:** Phase 01.

Every incident report starts with "I tapped X and nothing happened." The files
in this phase sit between "I tapped X" and every observable side effect —
HTTP, SignalR, FCM, deep links, navigation, and provider graph changes. They
get **Tier 3** treatment.

## Files touched

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/core/api/api_client.dart` | T3 | 156 | Dio interceptors, token refresh, upgrade gate |
| `lib/core/services/signalr_service.dart` | T3 | 80 | HubConnection, reconnect, token factory |
| `lib/core/services/fcm_service.dart` | T3 | 106 | Token registration, foreground / opened-app / initial-message listeners |
| `lib/core/services/notification_handler.dart` | T3 | 151 | FCM type + deep-link URI dispatch |
| `lib/app/router.dart` | T3 | 391 | Redirect matrix, role/tier gating, refreshListenable |
| `lib/core/providers/role_provider.dart` | T2 | — | RoleNotifier load / set / clear |
| `lib/core/providers/locale_provider.dart` | T2 | — | LocaleNotifier load / set |

## `ApiClient` — what to log

Tag: `ApiClient` (except interceptor callbacks, which use `ApiClient.on*`).

- **Constructor** — `i 'init' baseUrl=… appPackage=… appVersion=…`.
- **onRequest** — `d 'req' method=GET path=/… hasAuth=true` (via
  `TalkerDioLogger` — see below; but keep one manual `d 'req start'` so
  the token-attach decision is visible).
- **onResponse** — if `_readUpgradeRequired` matches, `w 'upgrade gate from 200' storeUrl=redactUrl(url)`.
- **onError** — `status = error.response?.statusCode`, log once per branch:
  - `w 'upgrade gate from 4xx' status=$status` when 426 or payload match.
  - `w 'refresh start' status=401 pathHint=$role` when token refresh kicks in.
  - `i 'refresh ok' newToken=${redactToken(newAccess)}` on success.
  - `e 'refresh failed' error=…` on the refresh catch — token clear path.
  - `d 'passthrough error' status=$status path=$path` on the "everything else" branch.
- **_clearTokens** — `i 'tokens cleared'` (no values).

Also install `TalkerDioLogger` as the **first** interceptor so every request
gets automatic req/res logging. Configure it to:

```dart
TalkerDioLogger(
  talker: log.talker,
  settings: const TalkerDioLoggerSettings(
    printRequestData: false,       // hides bodies → no OTP / password leak
    printResponseData: false,
    printRequestHeaders: false,    // hides Authorization header
    printResponseHeaders: false,
    printErrorMessage: true,
  ),
)
```

PII leakage risk is the reason bodies are off. For targeted debugging,
flip them back locally with a one-line change — never commit with them on.

## `SignalRService` — what to log

Tag: `SignalR`.

- **build** — `i 'init' url=$hubUrl`.
- `onclose` — `w 'closed' error=$err`.
- `onreconnecting` — `w 'reconnecting' error=$err`.
- `onreconnected` — `i 'reconnected' connectionId=$id`.
- `joinProviderGroups` — `d 'join groups start' isActive=… hasSub=…`,
  then `d 'join ok' group=power|available` or `w 'join failed' group=… error=…`.
- **`ref.onDispose`** — `d 'stop on dispose'`.

## `fcm_service` — what to log

Tag: `Fcm`.

- **initLocalNotifications** — `i 'local notif init ok'` / `w 'local notif init failed'`.
- **setupFcmListeners** — `i 'listeners wired'`.
- **onMessage (foreground)** — `d 'fg msg' type=$type` (no body).
- **onMessageOpenedApp** — `i 'tap opened app' type=$type`.
- **getInitialMessage** — `i 'tap cold start' type=$type` (only when non-null).
- **registerFcmToken** — `i 'token register start' role=…`,
  then `i 'token register ok'` / `e 'token register failed' error=…`.
- **onTokenRefresh** — `i 'token rotated, re-registering'`.

Never log the FCM token itself.

## `NotificationHandler` — what to log

Tag: `NotifHandler`.

- **handleFcmTap** — `d 'fcm tap' type=$type jobId=${data['jobId']}`.
- **handleDeepLink** — `d 'deep link' scheme=… host=$host query=$params`
  (strip sensitive query params; `ref=CODE` is fine — it's a referral code,
  not a secret).
- Each dispatched route — `i 'route' target=/customer/tracking/…`.
- Unknown type / host — already `debugPrint`ed; swap for
  `w 'unknown type' type=$type` / `w 'unknown host' host=$host`.

## `router.dart` — what to log

Tag: `Router.redirect`. The redirect is the most frequently-wrong piece of
the app — log every decision branch.

- Entry — `v 'redirect' path=$loc hasToken=$b role=$r tier=$t`.
- Each branch return — `d 'decision' from=$loc to=$target reason=no_token|public|wrong_role|tier_gate`.
- `refreshListenable` pulse — `d 'refresh pulse' reason=role_change`.
- Corrupt-state clear (`token && role == null`) — `w 'corrupt state, clearing tokens'`.
- Install `TalkerRouteObserver(log.talker)` in the `observers: []` list of
  the root `GoRouter` — covers push / pop / replace for free.

## Riverpod observer

Add a `TalkerRiverpodObserver(log.talker)` to the root `ProviderScope` in
`main.dart`. This gives you:

- Provider build / dispose.
- Provider value changes (state emissions).
- Provider errors.

No code changes in individual providers — the observer is enough.

## Redactions reused from Phase 01

- Every `Authorization` header value — **never logged**. `TalkerDioLogger`
  settings above enforce this.
- Every token stored in secure storage — when you must log one (e.g. during
  refresh), pass it through `redactToken(...)`.
- Every URL with a query string that might carry a token — pass through a
  new `redactUrl(Uri)` helper if needed (add to `redact.dart` in this phase).

## Acceptance criteria

- Cold-start the app in debug. The Talker screen shows, in order:
  1. `[Boot] app start`
  2. `[ApiClient] init …`
  3. `[SignalR] init …`
  4. `[Fcm] listeners wired`
  5. `[Router.redirect] redirect path=/welcome …`
- Log in as a customer. The log shows:
  1. `[AuthRepo] login start` (from Phase 03, but redirect decisions land here)
  2. `[TalkerDioLogger] POST /auth/customers/login → 200`
  3. `[Router.redirect] decision from=/login to=/customer/home reason=…`
  4. `[Fcm] token register ok role=customer`
- Force a 401 by wiping the access token manually. The log shows:
  1. `[TalkerDioLogger] GET … → 401`
  2. `[ApiClient.onError] refresh start`
  3. `[ApiClient.onError] refresh ok newToken=tok:eyJhbGci`
  4. The retried request going through.
- Grep the diff: no raw `print(` / `debugPrint(` survives in touched files.
- Talker log buffer has ≤ 500 entries after 2 minutes of normal navigation
  (sanity check on log volume — if higher, demote chatty `d` logs to `v`).

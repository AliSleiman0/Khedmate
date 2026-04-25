# Phase 03 — Auth + shared features

**Depends on:** Phase 01 (helpers) and Phase 02 (ApiClient + Router are
already logging, so auth flows piggy-back on their output).

Goal: every auth flow and every role-agnostic feature surface (chat,
notifications, profile, rating) reports its state transitions so you can
reproduce a user report from the log alone.

## Files touched

### Auth

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/auth/data/auth_repository.dart` | T3 | 185 | Role-branched endpoint selection — every call logs role + endpoint |
| `lib/features/auth/presentation/auth_provider.dart` | T3 | 199 | AuthNotifier state transitions (`AuthInitial → AuthLoading → AuthAuthenticated / AuthError`) |
| `lib/features/auth/presentation/welcome_screen.dart` | T1 | — | Role-tile taps |
| `lib/features/auth/presentation/login_page.dart` | T2 | 513 | Validation failures, submit, phone-vs-email branch |
| `lib/features/auth/presentation/register_screen.dart` | T2 | 494 | Submit, role-specific field presence |
| `lib/features/auth/presentation/otp_screen.dart` | T3 | 548 | verifyOtp call, referral-sheet submit, resend timer |
| `lib/features/auth/presentation/forgot_password_screen.dart` | T1 | — | forgotPassword submit |
| `lib/features/auth/presentation/reset_password_screen.dart` | T1 | 275 | resetPassword submit |

### Shared features

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/shared/chat/data/chat_repository.dart` | T1 | 40 | getMessages / sendMessage / markAsRead |
| `lib/features/shared/chat/presentation/chat_provider.dart` | T3 | 168 | SignalR subscribe, send failure, optimistic append |
| `lib/features/shared/chat/presentation/chat_screen.dart` | T1 | — | scroll-to-bottom + send button |
| `lib/features/shared/notifications/data/notification_repository.dart` | T1 | 49 | getNotifications / markRead |
| `lib/features/shared/notifications/presentation/notifications_provider.dart` | T2 | 61 | pagination, unread-count invalidation |
| `lib/features/shared/notifications/presentation/notifications_screen.dart` | T2 | 241 | tap → `handleNotificationTap` branch |
| `lib/features/shared/profile/presentation/profile_page.dart` | T2 | — | logout, delete-account dialog, tile taps |
| `lib/features/shared/profile/presentation/profile_tiles_customer.dart` | T1 | — | Coming-soon + referral + help |
| `lib/features/shared/profile/presentation/profile_tiles_provider.dart` | T2 | 85 | Verification / payout / subscription / analytics taps |
| `lib/features/shared/profile/presentation/edit_profile_screen.dart` | T2 | — | PATCH /me call |
| `lib/features/shared/profile/presentation/delete_account_action.dart` | T3 | — | Apple 5.1.1(v) flow — full trace |
| `lib/features/shared/rating/data/rating_repository.dart` | T1 | 80 | POST /ratings + pending-list helpers |
| `lib/features/shared/rating/presentation/rating_provider.dart` | T2 | 82 | submit → `SEND_FAILED` branch |
| `lib/features/shared/rating/presentation/rating_bottom_sheet.dart` | T1 | 327 | tag toggle + submit tap |

## Per-file log blueprint

### `auth_repository.dart` (T3)

Tag: `AuthRepo`. Every public method:

- `d '<method> start' role=$role endpoint=${_prefix}/…`
- `i '<method> ok' <result summary>` on 2xx — e.g. for `login`,
  `accessToken=${redactToken(token)} userId=$userId`.
- `e '<method> failed' code=$errorCode` on known error codes
  (`INVALID_CREDENTIALS`, `OTP_EXPIRED`, etc.).
- `e '<method> crashed' error=$e stack=$s` on unexpected throws.

Phone / email / OTP / password redaction rules from Phase 01 apply to **every**
value before it hits the logger.

### `auth_provider.dart` (T3)

Tag: `AuthNotifier`.

- `build()` — `d 'build' hasToken=$b role=$role` → either `i 'fetchMe start'`
  or `i 'no session'`.
- `register / verifyOtp / login / loginWithEmail / logout / deleteAccount` —
  `d '<method> start'`, then on completion either
  `i '<method> ok' userId=…` and `state = AuthAuthenticated(...)`, or
  `w '<method> failed' code=$code` and `state = AuthError(...)`.
- Every state emission — the Riverpod observer from Phase 02 already covers this.

### `otp_screen.dart` (T3)

Tag: `OtpScreen`. This file is large and has an explicit resend timer.

- `d 'init' phone=${redactPhone(phone)} role=$role`
- `d 'resend tick' secondsLeft=$n`
- `d 'resend tap'` → `i 'resend ok'` / `w 'resend failed' code=$code`
- `d 'verify tap' otpLen=${code.length}` (no value)
- On verifyOtp result — rely on `AuthNotifier` logs; add one local
  `i 'nav next'` with the target route.
- Referral bottom-sheet submit — `d 'referral apply start' ref=$code`,
  `i 'referral apply ok'` / `w 'referral apply failed' code=$code`.

### `chat_provider.dart` (T3)

Tag: `ChatNotifier`. Family-keyed by jobId — include `jobId` in every line.

- `build(jobId)` — `d 'build' jobId=$jobId`.
- `i 'load page ok' jobId=$jobId count=$n hasMore=$b` / `e 'load failed' …`.
- `d 'signalr subscribe' jobId=$jobId` / `d 'signalr msg' jobId=$jobId msgId=$id`.
- `send(text)` — `d 'send start' jobId=$jobId len=${text.length}`,
  then `i 'send ok'` or `w 'send failed' code=$code` (sets `SEND_FAILED`).
- `markAsRead` — `d 'mark read' jobId=$jobId`.

### `notifications_screen.dart` (T2)

Tag: `NotifList`.

- `d 'tap' type=$type jobId=$jobId` — immediately before calling
  `handleNotificationTap` (which itself logs in Phase 02).
- `d 'load more' cursor=$c` on infinite scroll.

### `delete_account_action.dart` (T3)

Tag: `DeleteAccount`. This flow is destructive + user-facing — every step logged.

- `d 'dialog shown' role=$role`.
- `d 'confirm tap'`.
- `i 'api start' role=$role endpoint=…` → `i 'api ok' userId=$userId` or
  `e 'api failed' code=$code error=$e`.
- `i 'nav welcome'` before the `/welcome` replace.

### `edit_profile_screen.dart` (T2)

Tag: `EditProfile`.

- `d 'open' role=$role name=${name ?? "null"} email=${redactEmail(email)}`.
- `d 'save tap' nameChanged=$b emailChanged=$b`.
- `i 'save ok'` / `w 'save failed' code=$code`.

### `rating_provider.dart` (T2)

Tag: `RatingNotifier`.

- `d 'submit start' jobId=$jobId thumbsUp=$b tags=$tagCount`.
- `i 'submit ok' jobId=$jobId` / `w 'submit failed' jobId=$jobId code=$code`.

## Validation-error logging

Per the redaction policy: when a client-side validator fails, log the
**reason code** not the value. Example — in `register_screen.dart`, a phone
validation failure is `d 'phone invalid reason=too_short'`, never
`phone=$controller.text`.

## Acceptance criteria

- A full login → OTP → home run produces a log chain of exactly the events
  above, in order, with no missing step.
- Tripping `INVALID_CREDENTIALS` on login surfaces `w 'login failed
  code=INVALID_CREDENTIALS'` in the log, and nothing else at `error` level
  (this is an *expected* failure).
- Tripping a network outage on OTP verify surfaces exactly one
  `e 'verifyOtp crashed'` with a stack trace.
- Log count for a cold-start + login + profile tap sequence is ≤ 80 lines
  (sanity check — if higher, tighten `d`/`v` use).

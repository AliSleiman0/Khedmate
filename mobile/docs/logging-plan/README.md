# Logging plan — `mobile/` (unified Flutter app)

## Goal
Make the unified app (`mobile/`) easy to debug on-device and in CI by adding
structured logging across every non-trivial file. The logging must:

- Be **cheap in release builds** (stripped or level-gated, no PII, no token leakage).
- Be **loud and useful in debug builds** (colourised console, tag + key=value, in-app viewer).
- Be **consistent** — one helper, one API, one redaction policy.
- Scale log density with **file complexity** (see rubric below) — not every widget needs logs.

Scope is strictly `mobile/lib/**`. Legacy apps (`mobile-customer/`,
`mobile-provider/`), backend, and the web apps are **out of scope**.

## Complexity rubric (log density tiers)

| Tier | Criteria | What to log |
|---|---|---|
| **T0** | Pure presentational widgets ≤ 100 LOC, no state, no I/O | Nothing. |
| **T1** | Simple screens / providers 100–300 LOC with 1–2 API calls | Method entry, failure + rethrow, success-with-id. 2–4 log lines per file. |
| **T2** | Complex screens / providers 300–500 LOC, multiple API calls, local state machines, timers | Entry + exit per public method, branch decisions, API results (id/status only), lifecycle (init/dispose), errors with stack. 6–12 log lines per file. |
| **T3** | Anything touching **Stripe, SignalR, FCM, GPS, deep links, JWT refresh, Dio interceptor, router guards, auth** — or files > 500 LOC | Full tracing: every external call in + out, every interceptor hop, every state transition, every fallback. 15+ log lines. These files are where you live during incidents. |

A file's tier is fixed in its phase doc. When code grows, bump the tier.

## Standard log format

```
[Tag] short message key=value key=value
```

- **Tag** — always the class or top-level function name in PascalCase
  (`[ApiClient]`, `[BookingNotifier]`, `[Router.redirect]`). No file paths.
- **Message** — imperative, present tense, no trailing period.
  `login start` not `Logging in the user...`.
- **Values** — only primitives. No serialized maps. No tokens, no OTPs, no passwords.
  Use the redaction helpers (see `phase-01-foundation.md`).

Levels map to Talker levels:

| Level | Use it for |
|---|---|
| `verbose` | Chatty, per-tick events (GPS broadcast, SignalR heartbeat). Off by default. |
| `debug`   | Method entry / exit / branch decisions. Most instrumentation lands here. |
| `info`    | Meaningful state transitions (login success, job accepted, subscription active). |
| `warning` | Recoverable oddities (token refresh kicked in, SignalR reconnecting). |
| `error`   | Caught exceptions, API failures. Always pass `error` + `stackTrace`. |
| `critical`| Unrecoverable (corrupt token, router redirect loop). Rare. |

## Redaction policy (codify in Phase 01)

| Field | Rendered as |
|---|---|
| Phone | `+966****0123` (keep last 4, mask the middle) |
| Email | `a***@example.com` (keep first char + domain) |
| Access / refresh token | `tok:<first8>` — never log the full token |
| OTP code | `***` — never log the value, only length |
| Password | Never logged — not even a placeholder |
| Stripe client secrets | Never logged |
| Latitude / longitude | Rounded to 2 decimals (≈ 1.1 km) in debug, dropped in release |
| Full name | Logged only if the user is already authenticated on this device |

## Library choice

`talker_flutter` — chosen for:
- Dio interceptor (`TalkerDioLogger`) — one line covers every request.
- `go_router` observer (`TalkerRouteObserver`).
- `Riverpod` observer (`TalkerRiverpodObserver`).
- In-app log viewer screen (debug builds only).
- History buffer so users can share a log capture from the Help & Support tile.

If `talker_flutter` ever becomes problematic, the `AppLogger` wrapper in
Phase 01 hides the underlying impl — swap the adapter, keep every call site.

## Phases

| # | File | Scope | Est. LOC touched |
|---|---|---|---|
| 01 | [phase-01-foundation.md](phase-01-foundation.md) | `AppLogger` + redaction helpers + `main.dart` init + debug log viewer route | ~250 |
| 02 | [phase-02-core-infra.md](phase-02-core-infra.md) | `ApiClient`, `SignalRService`, `fcm_service`, `NotificationHandler`, router guards, Riverpod observer | ~200 |
| 03 | [phase-03-auth-shared.md](phase-03-auth-shared.md) | Auth repo + notifier + 5 auth screens, shared chat / notifications / profile / rating | ~180 |
| 04 | [phase-04-customer.md](phase-04-customer.md) | Booking wizard + Stripe, tracking, history, payments, referral, reminders, dispute | ~220 |
| 05 | [phase-05-provider.md](phase-05-provider.md) | Job feed + countdown + 3s GPS, onboarding, earnings, subscription (Stripe SetupIntent), analytics, navigation | ~240 |
| 06 | [phase-06-polish-release.md](phase-06-polish-release.md) | Release-build log rules, Crashlytics routing, in-app viewer gating, verification pass, docs | ~80 |

Each phase is independently shippable. Phase 01 blocks all others.

## Verification gate (every phase)

Before closing a phase:

1. `flutter analyze` — 0 errors, 0 new warnings.
2. `flutter test` — existing suite still passes.
3. Cold-start the app in debug, walk the happy path for the phase's feature,
   confirm the log viewer shows the expected tags.
4. Grep for `print(` and `debugPrint(` in the phase's touched files — both
   should be **zero**. All logging must go through `AppLogger`.
5. Grep for obvious PII — `token:` followed by a long string, full phone
   numbers, OTP values — should be zero.

## Non-goals

- No remote log shipping in phase 01–05. Crashlytics only in phase 06 and
  only for `error` + `critical` levels.
- No tests for log content. Logs are a debugging aid, not a contract.
- No touching legacy apps, backend, or web. A second plan can cover those.

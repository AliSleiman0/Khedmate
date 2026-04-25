# Phase 06 — Polish & release rules

**Depends on:** Phases 01–05.

Everything up to here has been optimised for debug builds. This phase makes
the logging safe and useful in release.

## What lands in this phase

1. **Release log level gate.** In release builds, `AppLogger` filters out
   everything below `warning`. `verbose` and `debug` are free / no-ops.
2. **Crashlytics routing for `error` + `critical`.** Every log at those
   levels also goes to `FirebaseCrashlytics.recordError(...)` with the tag
   as the reason and the data map as custom keys.
3. **In-app viewer gating.** The `/debug/logs` route is registered only
   when `kDebugMode`. A long-press on profile → version label is the only
   discovery mechanism. No menu entry.
4. **Sensitive-log sweep.** A script + a CI check grep for token / OTP /
   password / clientSecret / raw lat-lng patterns across `lib/` and fail
   if they show up outside the redaction helpers.
5. **Log budget audit.** Run each main flow once, snapshot the log buffer,
   confirm line counts are within the per-phase budgets called out in
   acceptance criteria. Tighten chatty files if needed.
6. **Docs.** Update `mobile/CLAUDE.md` with a short "Logging" section
   pointing at the helpers and the viewer route.

## Files touched

| Path | Change |
|---|---|
| `lib/core/logging/app_logger.dart` | Add release level gate + Crashlytics sink. |
| `lib/core/logging/crashlytics_sink.dart` | New — sends `error`+`critical` to Crashlytics. |
| `lib/main.dart` | Wire Crashlytics (only if Firebase init succeeded). |
| `lib/app/router.dart` | Wrap `/debug/logs` registration in `if (kDebugMode)`. |
| `analysis_options.yaml` | No further changes — `avoid_print` already blocks new regressions. |
| `.github/workflows/*` | Add PII sweep step (or document manual command if no CI yet). |
| `mobile/CLAUDE.md` | Add "Logging" section. |

## Release gate sketch

```dart
// app_logger.dart
void d(String tag, String msg, {Map<String, Object?>? data}) {
  if (kReleaseMode) return; // drop at compile-ish time via tree-shaking on msg param? — still gate here.
  _emit(LogLevel.debug, tag, msg, data: data);
}

void e(String tag, String msg, {Object? error, StackTrace? stack, Map<String, Object?>? data}) {
  _emit(LogLevel.error, tag, msg, error: error, stack: stack, data: data);
  if (kReleaseMode && _crashlyticsEnabled) {
    _crashlytics.recordError(
      error ?? msg,
      stack,
      reason: '[$tag] $msg',
      information: (data ?? {}).entries.map((e) => '${e.key}=${e.value}').toList(),
      fatal: false,
    );
  }
}
```

Concerns addressed:

- **Body strings still live in the release APK.** That's fine — they're not
  secrets and logs are dropped before emission. `msg` strings are
  constants the compiler can tree-shake if the call is guarded cleanly.
- **Cost.** The `if (kReleaseMode) return` branch is free — the VM prunes
  it. No string interpolation in hot paths; wrap expensive `data` maps in
  a lambda if needed (follow-up — not required in phase 06 unless a hot
  `verbose` call shows up on a profile).

## Crashlytics sink

Only added if `firebase_core` + `firebase_analytics` succeeded in
`main.dart`. A new `firebase_crashlytics` dependency is required — add to
`pubspec.yaml` in this phase.

```yaml
firebase_crashlytics: ^3.5.0
```

Wire unhandled errors as well:

```dart
FlutterError.onError = (details) {
  log.e('FlutterError', details.exceptionAsString(),
      error: details.exception, stack: details.stack);
};

PlatformDispatcher.instance.onError = (error, stack) {
  log.c('PlatformError', error.toString(), error: error, stack: stack);
  return true;
};
```

Both handlers are in `main.dart`, right after `AppLogger.bootstrap()`.

## PII sweep (CI-friendly)

Add to `mobile/docs/logging-plan/check_pii.sh` (or whatever script harness
the project already uses):

```bash
# Anything matching these patterns should only appear inside redact.dart.
rg -n --glob '!**/logging/redact.dart' \
   '\bBearer\s+[A-Za-z0-9._-]{20,}|pi_[A-Za-z0-9]{24,}|seti_[A-Za-z0-9]{24,}|sk_(live|test)_[A-Za-z0-9]+' \
   mobile/lib && { echo "PII sweep: fail"; exit 1; }

# Direct prints (defence in depth — analyzer already catches these).
rg -n '\b(print|debugPrint)\(' mobile/lib && { echo "Raw print survived"; exit 1; }

echo "PII sweep: ok"
```

Run locally before merging each logging phase. Wire into CI in phase 06.

## Log budget audit (manual)

Run these flows in a clean debug build, note line counts in the Talker
viewer, and compare against budgets:

| Flow | Budget | Phase |
|---|---|---|
| Cold start → welcome | 5–8 | 01–02 |
| Customer login → home | 12–18 | 03 |
| Full booking (bypass) | 18–22 | 04 |
| Full booking (Stripe test) | 26–32 | 04 |
| Tracking (30 s, 10 GPS updates) at default level | 3–5 | 04 |
| Provider accept → Completed | 20–30 | 05 |
| Provider Power subscribe | 10–14 | 05 |

If a flow is 2× over budget, identify the worst offender in
`talker.history.fold(...)` and demote some `d` → `v`.

## Rollout

This plan is a **per-phase PR series**, not one monster PR. Suggested PR
sequence:

1. Phase 01 PR — infrastructure only, no call sites. Easy to review.
2. Phase 02 PR — core infra instrumentation. Touches the most important
   files but each change is 10–30 lines of `log.x(...)` calls.
3. Phase 03, 04, 05 PRs — independent, can ship in any order after 02.
4. Phase 06 PR — release gate + Crashlytics + CI check.

Ship 01 + 02 together if the reviewer prefers — together they're still
under ~500 LOC of change.

## Acceptance criteria for phase 06

- A release APK build does not emit any `debug`-level entries to logcat.
  (Test with `adb logcat | grep -i khudmati` after a release install.)
- Intentionally crashing (throwing from a button tap) surfaces the crash
  in Firebase Crashlytics within 5 minutes, tagged with the originating
  `[Tag]`.
- The `check_pii.sh` script returns 0 on a clean checkout.
- `mobile/CLAUDE.md` has a new "Logging" section pointing at
  `core/logging/app_logger.dart` and documenting the long-press gesture
  for the in-app viewer.
- The debug log viewer is unreachable in a release build (navigation to
  `/debug/logs` 404s into the GoRouter error page).

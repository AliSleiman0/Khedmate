# Phase 01 — Foundation

**Blocks:** every other phase. Must ship first.

## What lands in this phase

1. `talker_flutter` added to `pubspec.yaml`.
2. A thin `AppLogger` wrapper that every other file in the app imports.
3. A `redact.dart` helper with the 7 redaction functions named in the README.
4. `main.dart` initialises the logger before anything else and passes it
   to `ApiClient`, `SignalRService`, `fcm_service`, and the router observer
   (these consumers land in Phase 02 — Phase 01 only wires the plumbing).
5. A debug-only `/debug/logs` route that shows `TalkerScreen`, reachable from
   a long-press on the profile-page version string.
6. A project-wide lint rule banning `print(` and `debugPrint(` in `lib/` via
   `analysis_options.yaml` (with one narrow allowance for `main.dart`'s
   pre-logger bootstrap catches).

## Files to add

| Path | Tier | Purpose |
|---|---|---|
| `lib/core/logging/app_logger.dart` | T3 | Singleton wrapper around `Talker`. Exposes `log.v / d / i / w / e / c(tag, msg, {data, error, stack})`. |
| `lib/core/logging/redact.dart` | T2 | Pure functions: `redactPhone`, `redactEmail`, `redactToken`, `redactLatLng`, `redactOtp`. |
| `lib/core/logging/log_viewer_screen.dart` | T1 | Wraps `TalkerScreen`, brand-styled, only registered in `kDebugMode`. |
| `lib/core/logging/app_logger_providers.dart` | T1 | `loggerProvider`, `talkerProvider` (Riverpod). |

## Files to change

| Path | Change |
|---|---|
| `pubspec.yaml` | Add `talker_flutter: ^4.4.0` (or latest on ^4.x at implementation time). |
| `analysis_options.yaml` | Enable `avoid_print: error`. Add `// ignore:` only in `main.dart` catch blocks that run *before* logger init. |
| `lib/main.dart` | Initialise `AppLogger.bootstrap()` as the very first line of `main()`. Replace the 3 existing `debugPrint` calls with `log.w('Main', '...', error: e)`. |
| `lib/app/router.dart` | Register `/debug/logs` inside `if (kDebugMode)` — no guard from auth redirect. |
| `lib/features/shared/profile/presentation/profile_page.dart` | Long-press on the version label pushes `/debug/logs` when `kDebugMode`. |

## `AppLogger` public API (sketch)

```dart
class AppLogger {
  static late final AppLogger instance;
  final Talker _talker;

  AppLogger._(this._talker);

  static void bootstrap() {
    final talker = Talker(
      settings: TalkerSettings(
        useConsoleLogs: kDebugMode,
        maxHistoryItems: 500,
      ),
    );
    instance = AppLogger._(talker);
  }

  void v(String tag, String msg, {Map<String, Object?>? data}) { ... }
  void d(String tag, String msg, {Map<String, Object?>? data}) { ... }
  void i(String tag, String msg, {Map<String, Object?>? data}) { ... }
  void w(String tag, String msg, {Map<String, Object?>? data, Object? error}) { ... }
  void e(String tag, String msg, {Object? error, StackTrace? stack, Map<String, Object?>? data}) { ... }
  void c(String tag, String msg, {Object? error, StackTrace? stack}) { ... }

  Talker get talker => _talker; // exposed for Dio / Router / Riverpod adapters
}

AppLogger get log => AppLogger.instance;
```

Rendering: the wrapper joins `data` entries as ` key=value` pairs so call sites stay one-line:

```dart
log.d('AuthRepo', 'login start', data: {'phone': redactPhone(phone)});
// → [AuthRepo] login start phone=+966****0123
```

## Redaction helpers (sketch)

```dart
String redactPhone(String? phone) {
  if (phone == null || phone.length < 6) return '****';
  return '${phone.substring(0, phone.length - 4)}****${phone.substring(phone.length - 4)}';
}

String redactEmail(String? email) {
  if (email == null) return '****';
  final at = email.indexOf('@');
  if (at < 1) return '****';
  return '${email[0]}***${email.substring(at)}';
}

String redactToken(String? token) {
  if (token == null || token.length < 8) return 'tok:****';
  return 'tok:${token.substring(0, 8)}';
}

String redactLatLng(double lat, double lng) =>
    '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';

String redactOtp(String? code) => code == null ? '****' : '*** (len=${code.length})';
```

Keep these **pure** — no imports from `talker` or `dart:developer`.

## Wiring diagram

```
main()
  └─ AppLogger.bootstrap()
        └─ talker singleton
  └─ runApp(ProviderScope(
        overrides: [loggerProvider.overrideWithValue(log)],
        child: KhudmatiApp(),
     ))

ApiClient         ─┐
SignalRService    ─┼─ ref.watch(loggerProvider)       ← wired in Phase 02
fcm_service       ─┤
NotificationHandler┘

routerProvider     ─ observers: [TalkerRouteObserver(talker)]   ← Phase 02
ProviderScope      ─ observers: [TalkerRiverpodObserver(talker)] ← Phase 02
```

## Acceptance criteria

- `log.i('Boot', 'app start')` on the first line of `main()` shows up in
  the Talker console in a debug run.
- Long-pressing the profile version label in `kDebugMode` opens a log viewer
  that scrolls through every entry.
- `flutter analyze` surfaces `avoid_print` as **error** on any stray `print(`
  in `lib/` (confirm by temporarily adding one, then reverting).
- `flutter test` still passes (no test changes required).
- The three `debugPrint` calls in `main.dart` and the two in
  `notification_handler.dart` + two in `migration_analytics.dart` are
  migrated — a repo-wide grep for `debugPrint\(` in `mobile/lib/` returns
  nothing outside comments.

## Out of scope for this phase

- Dio / SignalR / Router / Riverpod adapters — those land in Phase 02 so
  they can be reviewed against their full instrumentation set in one PR.
- Crashlytics routing — Phase 06.

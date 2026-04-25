import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'crashlytics_sink.dart';

/// Thin wrapper around `Talker` that every other file in the app imports.
///
/// All call sites use the short methods `log.v / d / i / w / e / c` with a
/// PascalCase tag and a present-tense imperative message — see
/// `mobile/docs/logging-plan/README.md` for the format spec.
///
/// Rendering: `data` entries are appended as ` key=value` pairs so the line
/// stays one-line and grep-friendly:
///
///   log.d('AuthRepo', 'login start', data: {'phone': redactPhone(phone)});
///   // → [AuthRepo] login start phone=+96650000****1234
///
/// The underlying `Talker` instance is exposed via [talker] so Phase 02 can
/// hand it to `TalkerDioLogger`, `TalkerRouteObserver`, and
/// `TalkerRiverpodObserver` without leaking the dependency to every call site.
class AppLogger {
  static AppLogger? _instance;

  /// The single instance — initialised by [bootstrap] before `runApp`.
  static AppLogger get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'AppLogger.bootstrap() must be called before log is used.',
      );
    }
    return i;
  }

  final Talker _talker;
  CrashlyticsSink? _crashlytics;

  AppLogger._(this._talker);

  /// Initialise the singleton. Idempotent so unit tests (or hot restarts) can
  /// re-bootstrap without throwing. Must be the first line of `main()` so the
  /// pre-Firebase / pre-Stripe error paths can route through it.
  static void bootstrap() {
    if (_instance != null) return;
    final talker = TalkerFlutter.init(
      settings: TalkerSettings(
        useConsoleLogs: kDebugMode,
        maxHistoryItems: 500,
        useHistory: true,
      ),
    );
    _instance = AppLogger._(talker);
  }

  Talker get talker => _talker;

  /// Wires a [CrashlyticsSink] so every `error` / `critical` log line also
  /// surfaces in Firebase Crashlytics. Called from `main.dart` after a
  /// successful `Firebase.initializeApp()`. Skipped silently when Firebase
  /// initialisation failed (placeholder config files) so the app still runs.
  void attachCrashlytics(CrashlyticsSink sink) => _crashlytics = sink;

  /// Hook for tests to remove the sink between cases.
  @visibleForTesting
  void detachCrashlytics() => _crashlytics = null;

  void v(String tag, String msg, {Map<String, Object?>? data}) {
    if (kReleaseMode) return;
    _talker.verbose(_format(tag, msg, data));
  }

  void d(String tag, String msg, {Map<String, Object?>? data}) {
    if (kReleaseMode) return;
    _talker.debug(_format(tag, msg, data));
  }

  void i(String tag, String msg, {Map<String, Object?>? data}) {
    if (kReleaseMode) return;
    _talker.info(_format(tag, msg, data));
  }

  void w(
    String tag,
    String msg, {
    Map<String, Object?>? data,
    Object? error,
  }) {
    final line = _format(tag, msg, data);
    if (error != null) {
      _talker.warning('$line error=$error');
    } else {
      _talker.warning(line);
    }
  }

  void e(
    String tag,
    String msg, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? data,
  }) {
    final line = _format(tag, msg, data);
    if (error != null) {
      _talker.handle(error, stack, line);
    } else {
      _talker.error(line);
    }
    _crashlytics?.recordError(
      tag: tag,
      msg: msg,
      error: error,
      stack: stack,
      data: data,
    );
  }

  void c(String tag, String msg, {Object? error, StackTrace? stack}) {
    final line = _format(tag, msg, null);
    if (error != null) {
      _talker.handle(error, stack, line);
    }
    _talker.critical(line);
    _crashlytics?.recordCritical(
      tag: tag,
      msg: msg,
      error: error,
      stack: stack,
    );
  }

  String _format(String tag, String msg, Map<String, Object?>? data) {
    final base = '[$tag] $msg';
    if (data == null || data.isEmpty) return base;
    final pairs = data.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    return pairs.isEmpty ? base : '$base $pairs';
  }
}

/// Top-level shorthand. Import this and call `log.d(...)` everywhere.
AppLogger get log => AppLogger.instance;

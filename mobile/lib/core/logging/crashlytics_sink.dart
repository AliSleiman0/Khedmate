import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Forwards `error` + `critical` log lines to Firebase Crashlytics.
///
/// Wired by [AppLogger.attachCrashlytics] in `main.dart`, only after Firebase
/// initialisation succeeds. The wrapper degrades to a no-op when Firebase is
/// missing (placeholder `google-services.json` / `GoogleService-Info.plist`)
/// so the app still builds and the redaction layer continues to work.
class CrashlyticsSink {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsSink(this._crashlytics);

  /// Default factory — uses the singleton instance from `firebase_core`.
  factory CrashlyticsSink.fromFirebase() =>
      CrashlyticsSink(FirebaseCrashlytics.instance);

  /// Mirrors a non-fatal error log to Crashlytics. The tag + msg become the
  /// `reason`; the data map (already redacted at the call site) is flattened
  /// to `key=value` strings and sent as `information`.
  void recordError({
    required String tag,
    required String msg,
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? data,
    bool fatal = false,
  }) {
    final info = (data ?? const <String, Object?>{})
        .entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .toList(growable: false);
    _crashlytics.recordError(
      error ?? msg,
      stack,
      reason: '[$tag] $msg',
      information: info,
      fatal: fatal,
    );
  }

  /// Critical entries are recorded as `fatal: true` so they surface in the
  /// Crashlytics dashboard alongside hard crashes.
  void recordCritical({
    required String tag,
    required String msg,
    Object? error,
    StackTrace? stack,
  }) =>
      recordError(
        tag: tag,
        msg: msg,
        error: error,
        stack: stack,
        fatal: true,
      );
}

/// Central place to configure backend URL.
/// Update [backendHost] to point at your server (droplet IP or domain).
class AppConfig {
  // ── Change this one line once your droplet is live ──────────────────────
  static const String backendHost = 'https://api.khudmati.app';
  // ────────────────────────────────────────────────────────────────────────

  static const String baseUrl = '$backendHost/api';
  static const String hubUrl  = '$backendHost/hubs/jobs';

  // ── App identity (Phase 10 — hard-cutover discrimination) ───────────────
  // Sent on every HTTP request as `X-App-Package` + `X-App-Version` so the
  // backend can return `UPGRADE_REQUIRED` for legacy bundle ids
  // (`com.khudmati.customer` / `com.khudmati.provider`) once the cutover flag
  // `Auth:ForceUpgradeForLegacyApps` is flipped on.
  //
  // Keep in sync with Android `applicationId`, iOS bundle id, and
  // pubspec `version`.
  static const String appPackage = 'com.khudmati.app';
  static const String appVersion = '1.0.0+1';

  // Store URLs shown on the defensive upgrade screen (unified app should
  // never hit this — legacy apps are the real consumers, patched separately).
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=$appPackage';
  static const String iosStoreUrl = 'https://apps.apple.com/app/khudmati/id000000000';

  // ── Phase 11 QA-only: skip Stripe for the customer booking flow ─────────
  // When the build passes `--dart-define=BYPASS_PAYMENTS=true`, the booking
  // flow calls `POST /bookings/jobs` directly without creating a Stripe
  // PaymentIntent or presenting PaymentSheet. Used for QA runs when we don't
  // have Stripe test keys wired up. MUST be false for any release build that
  // ships to customers — guarded by an on-screen banner on the booking
  // summary screen so testers can't miss it.
  static const bool bypassPayments =
      bool.fromEnvironment('BYPASS_PAYMENTS', defaultValue: false);
}

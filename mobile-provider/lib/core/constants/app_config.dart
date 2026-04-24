/// Central place to configure backend URL.
/// Update [backendHost] to point at your server (droplet IP or domain).
class AppConfig {
  // ── Change this one line once your droplet is live ──────────────────────
  static const String backendHost = 'https://api.khudmati.app';
  // ────────────────────────────────────────────────────────────────────────

  static const String baseUrl = '$backendHost/api';
  static const String hubUrl  = '$backendHost/hubs/jobs';

  // ── Legacy app identity (Phase 10 cutover patch) ─────────────────────────
  // Sent on every request so the backend can return `UPGRADE_REQUIRED` once
  // `Auth:ForceUpgradeForLegacyApps` is flipped on. Store URL below points
  // at the unified `com.khudmati.app` bundle.
  static const String appPackage = 'com.khudmati.provider';
  static const String appVersion = '1.9.0+legacy';
  static const String unifiedStoreUrl =
      'https://play.google.com/store/apps/details?id=com.khudmati.app';
}

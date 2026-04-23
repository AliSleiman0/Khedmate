/// Central place to configure backend URL.
/// Update [backendHost] to point at your server (droplet IP or domain).
class AppConfig {
  // ── Change this one line once your droplet is live ──────────────────────
  static const String backendHost = 'https://api.khudmati.app';
  // ────────────────────────────────────────────────────────────────────────

  static const String baseUrl = '$backendHost/api';
  static const String hubUrl  = '$backendHost/hubs/jobs';
}

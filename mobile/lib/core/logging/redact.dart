/// Redaction helpers used everywhere we emit logs. Pure functions with no
/// imports from `talker` or `dart:developer` so they are trivially testable
/// and safe to call from any layer.
library;

/// Mask a phone number to keep only the last 4 digits.
/// `+966500001234` → `+96650000****1234` style; for shorter inputs returns
/// `****` to avoid leaking the whole number.
String redactPhone(String? phone) {
  if (phone == null || phone.length < 6) return '****';
  final tail = phone.substring(phone.length - 4);
  final head = phone.substring(0, phone.length - 4);
  return '$head****$tail';
}

/// Mask an email by keeping only the first character and the domain.
/// `alice@example.com` → `a***@example.com`.
String redactEmail(String? email) {
  if (email == null) return '****';
  final at = email.indexOf('@');
  if (at < 1) return '****';
  return '${email[0]}***${email.substring(at)}';
}

/// Render a token as `tok:<first8>` so we can correlate sessions in the log
/// stream without exposing the full bearer.
String redactToken(String? token) {
  if (token == null || token.length < 8) return 'tok:****';
  return 'tok:${token.substring(0, 8)}';
}

/// Coordinates rounded to 2 decimal places (≈ 1.1 km accuracy).
String redactLatLng(double lat, double lng) =>
    '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';

/// Never log the OTP value — only its length so we can debug "user typed
/// the wrong digit" issues without exposing the secret.
String redactOtp(String? code) =>
    code == null ? '****' : '*** (len=${code.length})';

/// Sensitive query-parameter keys that must never end up in a log line.
/// Anything matching (case-insensitive) is replaced with `***`.
const _sensitiveQueryKeys = <String>{
  'token',
  'access_token',
  'accessToken',
  'refresh_token',
  'refreshToken',
  'otp',
  'code', // OTP / reset codes; the referral `ref=` key is intentionally not here
  'password',
  'pwd',
  'secret',
  'client_secret',
  'apikey',
  'api_key',
};

/// Strip sensitive query parameters from a URI / URL before logging.
///
/// The host + path are kept verbatim (operators need them to debug routing);
/// only the query is rewritten. Unknown keys pass through unchanged so
/// useful context like `ref=ABC123` survives.
String redactUrl(Object? url) {
  if (url == null) return '****';
  final uri = url is Uri ? url : Uri.tryParse(url.toString());
  if (uri == null) return url.toString();
  if (uri.queryParameters.isEmpty) return uri.toString();

  final sanitized = <String, String>{};
  uri.queryParameters.forEach((k, v) {
    sanitized[k] =
        _sensitiveQueryKeys.contains(k.toLowerCase()) ? '***' : v;
  });
  return uri.replace(queryParameters: sanitized).toString();
}

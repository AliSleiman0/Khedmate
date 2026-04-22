# Phase 04 — Shared Auth Flow

## Goal
Replace placeholder auth with real login/register/OTP/forgot/reset screens, backed by a role-aware `AuthRepository` that calls `/auth/customers/*` or `/auth/providers/*` based on `roleProvider`.

## Why this phase
Real auth unblocks everything — no feature can be built against real APIs until a real JWT is in secure storage.

## Pre-requisites
- Phase 03 complete (router + role selection work)
- Backend running locally or accessible via `https://api.khudmati.app`
- Seed test accounts available for both customer and provider roles

## Scope

### 1. Build role-aware `AuthRepository`
**Source:** merge `mobile-customer/lib/features/auth/data/auth_repository.dart` and `mobile-provider/lib/features/auth/data/auth_repository.dart`

Every method branches on `ref.read(roleProvider)`:
```dart
String get _prefix => ref.read(roleProvider) == UserRole.provider
    ? '/auth/providers'
    : '/auth/customers';

Future<void> login({required String phone, required String password}) {
  return _dio.post('$_prefix/login', data: {...});
}
```

Methods:
- `register(fullName, phone, email, password, {List<String>? serviceCategories})` — `serviceCategories` used only when role==provider
- `login(phone, password)`
- `verifyOtp(phone, otp)` — writes access+refresh tokens to secure storage on success
- `resendOtp(phone)`
- `forgotPassword(phone)` — customer-only endpoint (providers request reset through admin); if role==provider, throw `UnsupportedError` and surface a localized message
- `resetPassword(phone, otp, newPassword)` — customer-only, same constraint
- `logout()` — POST `$_prefix/logout`, clear tokens + role, route to `/welcome`
- `fetchMe()` — `GET /customers/me` or `GET /providers/me` based on role

Output: `mobile/lib/features/auth/data/auth_repository.dart`

### 2. Build `AuthNotifier` (Riverpod)
Wraps `AuthRepository`. Exposes:
- `isAuthenticated` derived from access token presence
- `user` — the `fetchMe` result, null until loaded
- `login(...)` / `register(...)` / `verifyOtp(...)` / `logout()` — delegate to repo
- On app boot, attempts `fetchMe()`; on 401, triggers refresh; on second 401, logs out.

Output: `mobile/lib/features/auth/presentation/auth_provider.dart`

### 3. Port auth screens
Ports (mostly verbatim from customer app — provider's register is the only material difference):

| Screen | Source | Notes |
|---|---|---|
| `LoginPage` | `mobile-customer/lib/features/auth/presentation/login_page.dart` | no changes — role selected before reaching this screen |
| `OtpScreen` | `mobile-customer/lib/features/auth/presentation/otp_screen.dart` | keep referral code sheet for customers only (conditional on role) |
| `RegisterScreen` | merge of both | show service-categories multi-select only if `role == provider` |
| `ForgotPasswordScreen` | `mobile-customer/lib/features/auth/presentation/forgot_password_screen.dart` | hide link on login page if role==provider |
| `ResetPasswordScreen` | `mobile-customer/lib/features/auth/presentation/reset_password_screen.dart` | customer-only |

Update all imports to use the new paths. All screens use `S.of(ref)` for strings.

### 4. Update router
Replace placeholders from Phase 3 with real screens:
- `/login` → `LoginPage`
- `/register` → `RegisterScreen`
- `/otp?phone=<>` → `OtpScreen`
- `/forgot-password` → `ForgotPasswordScreen` (customer role only — redirect if provider)
- `/reset-password?phone=<>` → `ResetPasswordScreen` (customer role only)

### 5. Remove placeholder auth screens
Delete:
- `mobile/lib/features/auth/presentation/login_placeholder.dart`
- `mobile/lib/features/auth/presentation/register_placeholder.dart`

Keep placeholder home screens — they're removed in Phase 6/7.

## Files to create
- `mobile/lib/features/auth/data/auth_repository.dart`
- `mobile/lib/features/auth/presentation/auth_provider.dart`
- `mobile/lib/features/auth/presentation/login_page.dart`
- `mobile/lib/features/auth/presentation/register_screen.dart`
- `mobile/lib/features/auth/presentation/otp_screen.dart`
- `mobile/lib/features/auth/presentation/forgot_password_screen.dart`
- `mobile/lib/features/auth/presentation/reset_password_screen.dart`

## Files to modify
- `mobile/lib/app/router.dart` — swap placeholders for real screens

## Files to delete
- `mobile/lib/features/auth/presentation/login_placeholder.dart`
- `mobile/lib/features/auth/presentation/register_placeholder.dart`

## Verification
End-to-end against real backend:

1. **Customer flow** — welcome → customer tile → register → OTP → lands on `/customer/home` (still placeholder)
2. **Provider flow** — welcome → provider tile → register with service categories → OTP → `/provider/home`
3. **Login existing account** — both roles
4. **Forgot password** — customer only; link not shown for provider
5. **Refresh on 401** — manually expire access token in storage, make an API call, verify refresh succeeds and request retries
6. **Logout** — clears tokens + role + returns to welcome
7. **Wrong role** — log in as provider, then manually corrupt `roleProvider` to customer. App should 401 on the next `fetchMe` (backend enforces audience) and force re-login.

## Exit criteria
- [ ] All 7 verification cases pass
- [ ] No hardcoded role in any auth-layer file — every endpoint choice reads `roleProvider`
- [ ] Customer app's existing customer accounts still log in successfully
- [ ] Provider app's existing provider accounts still log in successfully
- [ ] `flutter analyze` clean
- [ ] Commit: `feat(mobile): role-aware auth flow`

## Rollback
- Revert commit. Old apps remain the way to log in until Phase 13.

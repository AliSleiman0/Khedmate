# Customer App — Bug Fixes & Feature Gaps Plan

## Issues & Root Causes

---

### 1. Logo invisible on login / signup screens

**Root cause:**  
- `welcome_screen.dart` renders `Image.asset('assets/images/logo.png')` on a blue (`#1B4F72`) background. If the logo PNG has a blue or dark background (not transparent), it blends in.  
- `login_page.dart` shows **only** a large `Text(s.appName)` in `AppColors.brandBlue` — no logo image at all.  
- `register_screen.dart` has no logo either.

**Fix:**  
1. Ensure `assets/images/logo.png` uses a **transparent background** (or provide a white variant).  
2. Add `Image.asset('assets/images/logo.png', height: 80)` above the app name text on `LoginPage` and `RegisterScreen`.  
3. On `WelcomeScreen`, if logo color matches background, add a white circular `Container` behind it or use a white-version asset.

**Files:**  
- `lib/features/auth/presentation/login_page.dart`  
- `lib/features/auth/presentation/register_screen.dart`  
- `lib/features/auth/presentation/welcome_screen.dart`  
- `assets/images/logo.png` (check transparency)

---

### 2. Edit Profile — only name/email, not populated, missing fields & profile image

**Root cause:**  
- `CustomerUser` model has `id, fullName, phone, email` — no `profileImageUrl`.  
- `EditProfileScreen` only has `fullName` and `email` fields.  
- `email` is nullable and often `null` if the user registered without one — field appears empty.  
- `phone` is not editable (correct) but should be shown as read-only info.  
- No profile image upload.

**Fix:**  
1. Add `profileImageUrl` to `CustomerUser` and populate from `/customers/me` response.  
2. `EditProfileScreen`: add a circular avatar at top with an "edit" camera icon — tapping it opens image picker → uploads via `PATCH /customers/me` with multipart or a separate endpoint.  
3. Add read-only `phone` field showing current value (no editing — phone changes require OTP flow).  
4. Pre-populate `_emailController` from `user?.email ?? ''` — already done but email being `null` causes it to show empty. Confirm `CustomerUser.fromJson` returns empty string fallback.  
5. `updateProfile()` in `AuthRepository` should also send `profileImageUrl` when changed.

**Files:**  
- `lib/features/auth/presentation/auth_provider.dart` (`CustomerUser`)  
- `lib/features/auth/data/auth_repository.dart` (`fetchMe`, `updateProfile`)  
- `lib/features/profile/presentation/edit_profile_screen.dart`

---

### 3. Saved Addresses — "Coming Soon"

**Root cause:**  
Profile page calls `_comingSoon()` for the addresses tile.

**Fix:**  
Implement a new `AddressesScreen`:  
- `GET /customers/me/addresses` — list saved addresses  
- `POST /customers/me/addresses` — save a new address (name + lat/lng + formatted address string)  
- `DELETE /customers/me/addresses/:id` — remove  
- On the booking location screen, allow selecting a saved address  
- Wire profile tile to `/profile/addresses`

**New files:**  
- `lib/features/profile/presentation/addresses_screen.dart`  
- `lib/features/profile/data/addresses_repository.dart`

**Also requires:** backend endpoint (if not already present) — check `CustomerModule`.

---

### 4. Payment Methods — "Coming Soon"

**Root cause:**  
Profile page calls `_comingSoon()` for the payment tile.

**Fix:**  
Implement a `PaymentMethodsScreen`:  
- List saved Stripe `PaymentMethod` objects via `GET /customers/me/payment-methods` (backend calls Stripe API using customer's `stripe_customer_id`)  
- Allow removing a saved payment method  
- The "add card" flow is already handled per-booking via Stripe PaymentSheet — saved cards from those sessions appear here  
- Wire profile tile to `/profile/payment-methods`

**New files:**  
- `lib/features/profile/presentation/payment_methods_screen.dart`  
- Backend: `GET /api/customers/me/payment-methods` (Stripe `paymentMethods.list`)

---

### 5. Notifications tile — "Coming Soon"

**Root cause:**  
Profile page calls `_comingSoon()` for the notifications tile, but `NotificationsScreen` already exists at `/notifications`.

**Fix (1 line):**  
Change `() => _comingSoon(context, s)` to `() => context.push('/notifications')` in `profile_page.dart`.

**File:** `lib/features/profile/presentation/profile_page.dart`

---

### 6. Forgot Password — "Coming Soon" / not implemented

**Root cause:**  
No forgot password flow exists anywhere in the app.

**Fix:**  
1. Add "Forgot password?" link on `LoginPage` below the login button.  
2. New `ForgotPasswordScreen`: user enters their phone number → backend sends OTP → user enters OTP → sets new password.  
3. Backend endpoints needed:  
   - `POST /auth/customers/forgot-password` — sends OTP to phone  
   - `POST /auth/customers/reset-password` — accepts `{ phone, otp, newPassword }`  
4. Router: add `/forgot-password` and `/reset-password` routes.

**New files:**  
- `lib/features/auth/presentation/forgot_password_screen.dart`  
- `lib/features/auth/presentation/reset_password_screen.dart`

---

### 7. Cannot login with mobile number (bug) + no email login

**Root causes:**  
- `login_page.dart` sends the raw text from `_phoneController` but there is **no dial code prefix**. The register screen adds `_dialCode` prefix (`+961` etc.), but login doesn't — so the stored phone (`+9617XXXXXXX`) never matches the entered `7XXXXXXX`.  
- There is no email login option at all.

**Fix:**  
1. **Phone login fix:** Add a dial-code picker (same widget as register) to the login screen so the full E.164 number is constructed before sending.  
2. **Email login:** Add a tab or toggle on `LoginPage` — "Login with phone / Login with email". Email login sends `{ email, password }` to a new backend endpoint `POST /auth/customers/login-email` (or accept either field in the same endpoint).  
3. Alternatively, the backend can accept either phone or email in a single endpoint and detect automatically.

**Files:**  
- `lib/features/auth/presentation/login_page.dart`  
- `lib/features/auth/data/auth_repository.dart` (add `loginWithEmail`)  
- Backend: update `POST /auth/customers/login` to accept `email` or `phone`

---

### 8. Location picker bug — cannot choose location from map

**Root causes:**  
- Default center is **Beirut** (`33.8938, 35.5018`) but the app is for MENA/Saudi — should default to **Riyadh** (`24.7136, 46.6753`).  
- `_reverseGeocode` uses the `geocoding` package which calls **device-level geocoding** (Google on Android). This requires an active internet connection and Google Play Services — may fail silently and then `_locationConfirmed` stays `false`, blocking the "Confirm" button.  
- If geocoding fails, `_addressController` stays empty and the map appears frozen.

**Fix:**  
1. Change default `_center` to Riyadh: `LatLng(24.7136, 46.6753)`.  
2. Set `_locationConfirmed = true` inside `initState` unconditionally after setting the center — the user dragging the pin is enough, the address text is a convenience not a gate.  
3. If `_reverseGeocode` fails, fall back to showing coordinates as the address string (`"${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}"`) so the form is not empty.  
4. Ensure `onPositionChanged` triggers `_reverseGeocode` only on `hasGesture == true` (already likely) but also sets `_locationConfirmed = true` immediately so the button is active.

**File:** `lib/features/booking/presentation/location_screen.dart`

---

### 9. Registration with duplicate email — not blocked

**Root cause:**  
`register_screen.dart` already handles the `EMAIL_ALREADY_REGISTERED` error code from the backend and shows an error message. The backend **should** be returning this. If it's not:  
- The backend `CustomersModule` register command must check `email` uniqueness in `customers.customers` (the unique index `add-email-unique-index.sql` was already added per scaffold).  
- The API must return `{ "success": false, "error": "EMAIL_ALREADY_REGISTERED" }` with HTTP 409.

**Fix:**  
1. Verify `add-email-unique-index.sql` was run — if not, run it.  
2. Verify the register command handler catches the unique constraint and returns `409 EMAIL_ALREADY_REGISTERED`.  
3. Frontend already handles the code correctly — no changes needed if backend is correct.  
4. Add client-side note: the current error string key is `s.errorEmailAlreadyUsed` — confirm this key exists in all locale files.

**Files:**  
- `backend/add-email-unique-index.sql` (verify applied)  
- `backend/src/Modules/Customers/` — `RegisterCustomerHandler.cs`

---

## Priority Order

| # | Issue | Effort | Priority |
|---|---|---|---|
| 5 | Notifications tile wired wrong | Trivial (1 line) | P0 |
| 8 | Location defaults to Beirut + geocoding block | Low | P0 |
| 7 | Login dial-code bug | Low | P0 |
| 1 | Logo invisible | Low | P1 |
| 9 | Duplicate email not blocked | Low-Medium | P1 |
| 6 | Forgot password flow | Medium | P1 |
| 2 | Edit profile fields + image | Medium | P2 |
| 7b | Email login option | Medium | P2 |
| 3 | Saved addresses | High | P3 |
| 4 | Payment methods list | High | P3 |

---

## Next Step

Run the fix implementation as a Claude Code prompt covering the P0 and P1 items first. P3 items (Addresses, Payment Methods) require new backend endpoints and should be scoped as a separate feature prompt.

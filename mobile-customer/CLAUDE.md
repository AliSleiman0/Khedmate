# mobile-customer — Flutter Customer App

## Run
```bash
flutter pub get
flutter run
```
Targets Android emulator by default. API base URL: `http://10.0.2.2:5000/api` (Android emulator localhost).
For iOS simulator change to `http://localhost:5000/api` in `lib/core/api/api_client.dart`.

## Architecture
Feature-first folder structure:
```
lib/
├── app/
│   ├── app.dart          # Root widget, MaterialApp
│   ├── router.dart       # GoRouter with auth redirect guard
│   └── theme.dart        # AppTheme.light()
├── core/
│   ├── api/api_client.dart           # Dio instance + 401 refresh interceptor
│   ├── services/signalr_service.dart # HubConnection with JWT token factory + auto-reconnect
│   └── constants/
│       ├── colors.dart               # AppColors (brandBlue, amber, surface, etc.)
│       └── strings.dart              # App-wide string constants
└── features/
    ├── auth/
    │   ├── data/auth_repository.dart         # All auth HTTP calls
    │   └── presentation/
    │       ├── auth_provider.dart             # AuthNotifier (AsyncNotifier<AuthState>)
    │       ├── welcome_screen.dart
    │       ├── register_screen.dart
    │       ├── otp_screen.dart
    │       └── login_page.dart
    ├── booking/
    │   ├── data/booking_repository.dart       # createJob(), getJob(), uploadPhotos()
    │   └── presentation/
    │       ├── booking_provider.dart          # BookingNotifier (AsyncNotifier<BookingState>); full payment+booking flow
    │       ├── category_screen.dart           # 6-category grid
    │       ├── job_description_screen.dart    # Text + up to 3 photos
    │       ├── location_screen.dart           # flutter_map (OpenStreetMap) + drag-pin + reverse geocoding; NO GPS permission — user drags pin, taps confirm, address auto-filled
    │       ├── booking_summary_screen.dart    # Price input + "ادفع وأكد الحجز" → Stripe PaymentSheet
    │       └── booking_confirmation_screen.dart # Real-time status (Searching/Accepted/Expired)
    ├── payments/
    │   ├── data/payment_repository.dart       # createIntent(), confirmPayment(), getMyTransactions()
    │   └── presentation/
    │       ├── payment_provider.dart          # PaymentSummary model + provider instances
    │       ├── payment_receipt_screen.dart    # Post-payment success screen; fully localised
    │       └── payment_status_screen.dart     # Payment lifecycle view by jobId; all statuses localised
    ├── home/
    ├── tracking/
    │   ├── presentation/
    │   │   ├── tracking_page.dart           # Live map during EnRoute, status banners, rating CTA
    │   │   └── job_tracking_provider.dart   # JobTrackingNotifier with SignalR location updates
    ├── history/          # Job history list + detail; shows before/after photos in labelled sections
    ├── referral/
    │   ├── data/referral_repository.dart         # GET /api/customers/me/referral, POST /api/customers/referral/apply
    │   └── presentation/
    │       ├── referral_provider.dart             # ReferralNotifier (AsyncNotifier<ReferralState>); share + apply code
    │       └── referral_screen.dart               # Invite Friends — code card, share button, credit balance, friends count; fully localised
    ├── reminders/
    │   ├── data/reminders_repository.dart        # GET /api/customers/me/reminders, PATCH /api/customers/me/reminders/{id}
    │   └── presentation/
    │       ├── reminders_provider.dart            # RemindersNotifier (AsyncNotifier<List<ReminderModel>>); snooze + dismiss
    │       └── reminders_screen.dart              # Maintenance Reminders — reminder cards, overdue badge, Book Now CTA, 3-dot snooze/dismiss menu
    └── profile/
```

## State management
Riverpod (`flutter_riverpod`). All providers are in `presentation/` next to the screen that owns them.

Key providers:
- `authNotifierProvider` — `AsyncNotifier<AuthState>` with states: `AuthUnauthenticated`, `AuthOtpPending(phone)`, `AuthAuthenticated(CustomerUser)`
- `bookingNotifierProvider` — `AsyncNotifier<BookingState>` — holds selected category, description, location, photos, agreedAmount. `submitBooking()` runs full payment+booking flow: createIntent → PaymentSheet → createJob → confirmPayment.
- `paymentRepositoryProvider` — `Provider<PaymentRepository>` — wired into `BookingNotifier` and payment screens.
- `jobTrackingNotifierProvider` — `FamilyAsyncNotifier<JobTrackingState, String>` — subscribes to both `JobStatusChanged` and `ProviderLocationUpdated` SignalR events. Updates provider pin position + calculates distance using Haversine formula (`lib/core/utils/distance_utils.dart`).
- `referralNotifierProvider` — `AsyncNotifier<ReferralState>` — fetches referral info, exposes `shareCode()` (via `share_plus`) and `applyCode(String code)`.
- Job detail/history DTOs contain `beforePhotoUrls` and `afterPhotoUrls` as separate lists. History/detail screens render Before/After photo sections (after-photos only shown once job is `Completed` or `Paid`; sections hidden when empty).

## Routing
GoRouter in `lib/app/router.dart`. Auth redirect guard watches `authNotifierProvider`:
- Authenticated + on auth route → `/home`
- Unauthenticated + on protected route → `/welcome`

| Route | Screen |
|---|---|
| `/welcome` | WelcomeScreen |
| `/login` | LoginPage |
| `/register` | RegisterScreen |
| `/otp` | OtpScreen |
| `/home` | HomeScreen |
| `/booking/category` | CategoryScreen |
| `/booking/description` | JobDescriptionScreen |
| `/booking/location` | LocationScreen |
| `/booking/summary` | BookingSummaryScreen |
| `/booking/confirmation` | BookingConfirmationScreen |
| `/tracking/:jobId` | TrackingPage (live map + status banners) |
| `/payment/receipt` | PaymentReceiptScreen |
| `/payment/status/:jobId` | PaymentStatusScreen |
| `/disputes/raise/:jobId` | RaiseDisputeScreen |
| `/referral` | ReferralScreen |
| `/reminders` | RemindersScreen |
| `/profile/edit` | EditProfileScreen |

## Customer App — UX Gaps & Profile (Feature #23)

### Auth startup
- `auth_repository.dart` — added `fetchMe()` (`GET /api/customers/me`) and `updateProfile()` (`PATCH /api/customers/me`)
- `AuthNotifier.build()` calls `fetchMe()` after a successful token refresh so `customer.fullName` and `customer.phone` are real values on startup (profile header no longer shows `—`)

### Profile page
- **Logout** fixed: calls `AuthNotifier.logout()` (clears tokens from `FlutterSecureStorage`) then navigates to `/welcome`
- **Edit Profile** (`edit_profile_screen.dart`): pre-fills fullName + email, calls `PATCH /api/customers/me`, invalidates `authNotifierProvider` on success; inline red error on failure; if endpoint missing, shows "Coming Soon" snackbar and pops
- **Help & Support** tile: launches `https://khudmati.app/#contact` via `url_launcher` in external browser
- **Saved Addresses / Payment Methods / Notification Settings**: show "Coming Soon" snackbar (no backend yet)

### Home page
- **Search filter**: `StateProvider<String>` (`_searchQueryProvider`) filters the category grid by label; empty result shows `s.homeNoResults` centred text
- **Category tap pre-selects**: tapping a grid tile calls `bookingNotifierProvider.setCategory(categoryId, label)` then navigates to `/booking/description` (bypasses redundant category picker); category IDs mapped by index in `_categoryIds` constant

### Notifications screen
- Tap on a card marks it read **and** shows a `SnackBar` with a `s.notifViewJob` action that pushes `/history`

### Payment receipt
- Shows `chargedAmount` (actual amount after discounts) instead of `agreedAmount`; falls back to `agreedAmount` when `chargedAmount` is null
- Breakdown rows for referral discount and credit-applied shown when > 0 (localised via `receiptReferralDiscount` / `receiptCreditApplied`)

### History & Job Detail
- Category maps in both `history_page.dart` and `job_detail_page.dart` now include `moving` and `other`
- Unknown category IDs fall back to `id.replaceAll('_', ' ')` instead of raw ID string

### Notification handler
- `lib/core/services/notification_handler.dart` — `handleNotificationTap(data, router)`: routes `MAINTENANCE_REMINDER` payloads to `/booking/category` and fires best-effort PATCH to mark reminder as `Booked`
- `fcm_service.dart` wires handler into both `onMessageOpenedApp` and `getInitialMessage()`

### i18n keys added (app_strings.dart)
`remindersTitle`, `remindersEmpty`, `remindersOverdue`, `remindersSnooze7`, `remindersSnooze30`, `remindersDismiss`, `remindersBookNow`, `remindersDue(date)`, `editProfileTitle`, `editProfileName`, `editProfileEmail`, `editProfileSave`, `comingSoon`, `notifViewJob`, `homeNoResults`, `receiptReferralDiscount`, `receiptCreditApplied`

## Referral System (Feature #17)
- **ReferralScreen** (`features/referral/presentation/referral_screen.dart`): displays unique code with copy button, native share sheet via `share_plus`, credit balance card, reward explanation (15% referee / 20 SAR referrer); fully localised
- **Profile screen**: "Invite Friends" `ListTile` navigates to `ReferralScreen`
- **Signup flow**: expandable "Do you have a referral code?" field on OTP screen (`_ReferralCodeSheet`, a `ConsumerStatefulWidget`); calls `POST /api/customers/referral/apply`; success toast shows discount confirmation; errors `REFERRAL_NOT_FOUND` / `REFERRAL_ALREADY_USED` / `REFERRAL_SELF_REFERRAL` shown inline (localised)
- **Booking checkout**: price breakdown shows referral discount (15%) and credit deduction rows; green badge when applicable
- **Deep link**: `https://khudmati.app/join?ref=CODE` — GoRouter extracts `ref` param and pre-fills referral code field at signup

## Maintenance Reminders (Feature #19)
- **RemindersScreen** (`features/reminders/presentation/reminders_screen.dart`): lists upcoming reminders with due-date formatting, overdue amber badge, "Book Now" CTA that deep-links to booking flow with pre-filled `categoryId`, 3-dot menu for snooze (7 days / 30 days) and dismiss; empty state illustration when no reminders
- **Home screen / notification bell**: badge shown when there are `Sent` or overdue reminders; maintenance reminders appear as distinct card type with wrench icon in notifications list
- **Push notification handling**: payload `{ "type": "MAINTENANCE_REMINDER", "categoryId": "...", "reminderId": "..." }` opens booking flow pre-filled with category; PATCH reminder to `Booked` after booking confirmed; handled in `lib/core/services/notification_handler.dart`
- **RemindersNotifier**: `AsyncNotifier<List<ReminderModel>>` — `build()` fetches active reminders; `snooze(reminderId, days)` calls PATCH with `action: Snooze`; `dismiss(reminderId)` calls PATCH with `action: Dismiss`
- **Error handling**: `REMINDER_NOT_FOUND` / `REMINDER_ALREADY_DISMISSED` shown as inline snackbar; `SNOOZE_DAYS_EXCEEDED` prevents snooze >30 days

## Payment flow (Stripe PaymentSheet)
`submitBooking()` in `booking_provider.dart` orchestrates the full flow:
1. `POST /payments/intent` → get `clientSecret` + `paymentIntentId`
2. `Stripe.instance.initPaymentSheet()` + `presentPaymentSheet()` — user pays on device
3. `POST /bookings/jobs` — create job record (only after successful payment)
4. `POST /payments/confirm` — links `paymentIntentId` to `jobId` on server
5. On success → navigate to `/payment/receipt`

`Stripe.publishableKey` is set in `main.dart`. Catches `StripeException` for cancel/failure with localised error message.

## Real-time (SignalR)
`lib/core/services/signalr_service.dart` — `HubConnectionBuilder` connecting to `/hubs/jobs`:
- `accessTokenFactory` reads JWT from `FlutterSecureStorage`
- `withAutomaticReconnect()` configured
- `BookingConfirmationScreen` subscribes to `JobAccepted` and `JobExpired` events on connect, disposes on pop.
- `PaymentHeld` event notifies customer when provider marks job Complete (funds held 24h).
- **Live GPS Tracking**: `JobTrackingNotifier` subscribes to `ProviderLocationUpdated` events (sent to `customer-{customerId}` group). Updates every 3 seconds during EnRoute status with `{ jobId, latitude, longitude, timestamp }`.

## Live Tracking Map (EnRoute Status)
`TrackingPage` renders a live `flutter_map` when job status = `EnRoute`:
- **Two pins**: Customer location (blue, static) and provider location (amber, animated)
- **Smooth animation**: Provider pin moves via `Tween` animation (2.5s duration) between location updates
- **Distance calculation**: Real-time Haversine distance shown via `s.trackDistanceLeft(km)` (localised)
- **Auto-fit bounds**: Map camera fits both pins with padding on each update
- **Stale location fallback**: Shows `s.trackLocationUpdating` if no update received for 15+ seconds
- **InProgress transition**: Map freezes at last known location, shows `s.trackProviderArrived` banner
- All `_StatusBanner`, `_RefBadge`, `_ProviderCard`, `_InProgressMap`, `_LiveTrackingMap`, `_BottomActions`, `_ErrorView` are `ConsumerWidget`/`ConsumerStatefulWidget`

## Disputes (Feature #13)
- **RaiseDisputeScreen** (`features/dispute/presentation/raise_dispute_screen.dart`): form with complaint textarea (min 20 / max 1000 chars), character counter, submit sends `POST /api/bookings/jobs/{jobId}/dispute`; fully localised
- **Job Detail / History screens**: show "Raise Dispute" button only when `job.status == Paid` AND `transaction.status == Held`; show amber "Dispute Under Review" chip when `hasOpenDispute == true`
- **Repository**: `raiseDispute(jobId, complaint)` in `booking_repository.dart`
- **Error handling**: `DISPUTE_WINDOW_CLOSED` → `s.disputeDeadline`; `DISPUTE_ALREADY_EXISTS` → `s.disputeAlreadyRaised`; shown as snackbar
- **SignalR**: `DisputeResolved` event received on `customer-{customerId}` group — show snackbar with action and message

## Locale / Language
`lib/core/providers/locale_provider.dart` — `StateProvider<Locale>` defaulting to `Locale('en')`. Toggle between EN↔AR at runtime.
- **Welcome screen**: language toggle button at top right
- **Profile page**: Language tile calls `ref.read(localeProvider.notifier).state = ...` to toggle; shows user's real name/phone from `authNotifierProvider` (`customer.fullName`, `customer.phone`)
- `lib/core/l10n/app_strings.dart` — `S` class with 130+ getters + parametric methods; `S.of(ref)` for `build()`, `S.read(ref)` for async callbacks
- **All 20 screens fully localised** — every hardcoded Arabic string replaced with `s.<key>` calls
- **Pattern**: `ConsumerWidget.build` → `final s = S.of(ref);`; private `StatelessWidget` helpers that render text are converted to `ConsumerWidget`; `StatefulWidget` helpers become `ConsumerStatefulWidget`; `const` maps with translated labels are built dynamically inside `build()`
- **Category/status maps**: built as `Map<String, String>` inside `build()` using `s.catXxx` / `s.statusXxx` — never stored as `const` at class level
- **`_StatusChip`** (`job_detail_page.dart`): `ConsumerWidget`; color map remains `const`, label map built dynamically
- **`_ReferralCodeSheet`** (`otp_screen.dart`): converted from `StatefulWidget` → `ConsumerStatefulWidget`; all error/success strings use `S.read(ref)`
- **`_LiveTrackingMap`** (`tracking_page.dart`): converted from `StatefulWidget` → `ConsumerStatefulWidget`
- **Notifications `_relativeTime`**: accepts `S s` parameter; uses `s.timeNow`, `s.timeMinutesAgo(n)`, `s.timeHoursAgo(n)`, `s.timeDaysAgo(n)`

## Logo
Welcome screen shows `Image.asset('assets/images/logo.png', height: 130)` above the app name text (32pt).
Asset must be placed at `assets/images/logo.png` (folder declared in pubspec).

## Grok AI — Job Description Helper (Feature #21)
- **AI button** on `job_description_screen.dart`: tapping calls `POST /api/ai/improve-description` via `ai_repository.dart`
- Shows a bottom-sheet preview of the improved description; customer accepts or dismisses
- Error handling: if feature flag off (503) or Grok fails (502) → snackbar, field unchanged
- `lib/features/booking/data/ai_repository.dart` — `AiRepository.improveDescription(roughDescription, categoryName)`

`FlutterSecureStorage`. Keys: `access_token`, `refresh_token`.
`ApiClient` attaches access token to every request and auto-refreshes on 401.

## UI conventions
- All screens use `Directionality(textDirection: TextDirection.rtl, ...)`
- Font family: `Cairo` (Arabic-first). Fallback to `Inter` for Latin text.
- Brand colors via `AppColors` constants — never hardcode hex values in widget files
- Error messages displayed as inline `Text` widgets in red — never as `AlertDialog` or SnackBar for form validation errors
- OTP input uses the `pinput` package (`Pinput` widget)

## Key dependencies
| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client |
| `flutter_secure_storage` | Token persistence |
| `pinput` | OTP digit input boxes |
| `signalr_netcore` | Real-time job status updates |
| `flutter_map` | Map display (OpenStreetMap tiles) |
| `latlong2` | Coordinate types for flutter_map |
| `geolocator` | GPS current position |
| `geocoding` | Reverse geocoding (lat/lng → address) |
| `image_picker` | Photo selection from gallery/camera |
| `lottie` | Animated illustrations (searching state) |
| `flutter_stripe` | Stripe PaymentSheet for in-app payments |
| `url_launcher` | Open external URLs (Stripe onboarding) |
| `share_plus` | Native share sheet for referral code/link |

# Feature: Customer App — Maintenance Reminders, Profile Completion & UX Gaps

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR
- Frontend: Flutter customer app (`mobile-customer/`) — Riverpod, GoRouter, Dio
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`

## Goal
Implement the missing Maintenance Reminders feature (#19), complete all no-op profile tiles, fix the broken logout, and close six minor UX gaps identified during a codebase audit. All changes are confined to `mobile-customer/`.

## Platforms Affected
- [x] Customer Mobile App
- [ ] Provider Mobile App
- [ ] Web Landing Page
- [ ] Web Admin Panel
- [ ] Web Super Admin Panel

---

## Part 1 — Maintenance Reminders Feature (#19)

This feature is **fully absent** from the customer app. The backend already exists. The following files must be created.

### 1a. Data layer

**File:** `lib/features/reminders/data/reminders_repository.dart`

```
GET  /api/customers/me/reminders        → list of active reminders
PATCH /api/customers/me/reminders/{id}  → body: { action: "Snooze"|"Dismiss", snoozeDays?: int }
```

Model `ReminderModel`:
```dart
id, categoryId, categoryName, scheduledFor (DateTime), status (Scheduled|Sent|Snoozed|Overdue)
```

`status` is derived client-side: if `scheduledFor < DateTime.now()` and status is `Sent` → `Overdue`.

### 1b. State layer

**File:** `lib/features/reminders/presentation/reminders_provider.dart`

`RemindersNotifier extends AsyncNotifier<List<ReminderModel>>`:
- `build()` — calls `GET /api/customers/me/reminders`
- `snooze(String id, int days)` — calls PATCH with `action: Snooze, snoozeDays: days`; removes item from local list on success
- `dismiss(String id)` — calls PATCH with `action: Dismiss`; removes item on success
- Error codes to handle as inline snackbar: `REMINDER_NOT_FOUND`, `REMINDER_ALREADY_DISMISSED`, `SNOOZE_DAYS_EXCEEDED`

### 1c. Screen

**File:** `lib/features/reminders/presentation/reminders_screen.dart`

UI requirements:
- `Directionality(textDirection: TextDirection.rtl)`  
- AppBar: `s.remindersTitle` in white on `AppColors.brandBlue`
- Empty state: wrench icon + `s.remindersEmpty`
- `ListView` of reminder cards, each showing:
  - Category name (resolved from `categoryId` via the same map used on HomeScreen/HistoryPage)
  - Due date formatted as `s.remindersDue(formattedDate)` — e.g. "موعد الصيانة: 15 أبريل"
  - Amber `s.remindersOverdue` badge chip when status == Overdue
  - **"احجز الآن" (Book Now) button** → `context.go('/booking/category')` passing `extra: {'categoryId': reminder.categoryId}`; also calls PATCH with `action: Dismiss` before navigating (marks as Booked on backend via the same Dismiss path or a separate `Booked` action — use whichever the backend accepts; try `action: Booked` first, fall back to `Dismiss`)
  - 3-dot `PopupMenuButton` with two options:
    - `s.remindersSnooze7` → `snooze(id, 7)`
    - `s.remindersSnooze30` → `snooze(id, 30)`
    - `s.remindersDismiss` → `dismiss(id)`

### 1d. Router entry

**File:** `lib/app/router.dart`

Add inside the routes list (not inside the shell branch):
```dart
GoRoute(
  path: '/reminders',
  builder: (_, __) => const RemindersScreen(),
),
```

### 1e. Push notification handler

**File:** `lib/core/services/notification_handler.dart`

Create a standalone function `handleNotificationTap(Map<String, dynamic> data, GoRouter router)`:
- If `data['type'] == 'MAINTENANCE_REMINDER'`:
  - Extract `categoryId` and `reminderId`
  - Navigate: `router.go('/booking/category', extra: {'categoryId': categoryId})`
  - Fire-and-forget PATCH to mark reminder as `Booked` (best-effort, no await needed)
- For all other types (future extensibility): no-op

Wire this handler into `lib/core/services/fcm_service.dart`:
- In `FirebaseMessaging.onMessageOpenedApp.listen(...)` — call `handleNotificationTap(message.data, router)`
- In `getInitialMessage()` block — same call
- The `router` instance must be passed into `setupFcmListeners()`; update its signature if needed

### 1f. i18n keys to add to `lib/core/l10n/app_strings.dart`

Add the following getters to the `S` class (both `_ArStrings` and `_EnStrings`):
```
remindersTitle       → "تذكيرات الصيانة" / "Maintenance Reminders"
remindersEmpty       → "لا توجد تذكيرات حالياً" / "No reminders right now"
remindersOverdue     → "متأخرة" / "Overdue"
remindersSnooze7     → "تأجيل 7 أيام" / "Snooze 7 days"
remindersSnooze30    → "تأجيل 30 يوم" / "Snooze 30 days"
remindersDismiss     → "إلغاء التذكير" / "Dismiss"
remindersBookNow     → "احجز الآن" / "Book Now"
remindersDue(String date) → "موعد الصيانة: $date" / "Due: $date"
```

---

## Part 2 — Profile Page: Fix Logout & Complete No-op Tiles

**File:** `lib/features/profile/presentation/profile_page.dart`

### 2a. Fix logout (critical bug)

Current broken code:
```dart
onTap: () => context.go('/login'),
```

Replace with:
```dart
onTap: () async {
  await ref.read(authNotifierProvider.notifier).logout();
  if (context.mounted) context.go('/welcome');
},
```

This properly clears tokens from `FlutterSecureStorage` via `AuthNotifier.logout()`.

### 2b. Fix auth refresh — empty CustomerUser on startup

**File:** `lib/features/auth/presentation/auth_provider.dart`

After a successful token refresh on startup, the code currently builds `CustomerUser(id: '', fullName: '', phone: '')`. Fix this by calling `GET /api/customers/me` (or equivalent profile endpoint) to populate the `CustomerUser` fields.

If no profile endpoint exists yet, add a `fetchMe()` method to `AuthRepository` that calls `GET /api/customers/me` and returns the customer JSON. Call it in `AuthNotifier.build()` after saving refreshed tokens.

### 2c. Edit Profile screen

**New file:** `lib/features/profile/presentation/edit_profile_screen.dart`

- `ConsumerStatefulWidget`
- Pre-fill `fullName` and `email` from `authNotifierProvider`
- Two fields: Full Name (required), Email (optional, keyboard type email)
- Save button calls `PATCH /api/customers/me` — body `{ fullName, email }`
- On success: invalidate `authNotifierProvider` then `context.pop()`
- On error: inline red text error message (not dialog)
- Localised: `s.editProfileTitle`, `s.editProfileName`, `s.editProfileEmail`, `s.editProfileSave`
- Directionality RTL, Cairo font

Wire the profile tile:
```dart
_tile(Icons.edit, s.profileEdit, () => context.push('/profile/edit')),
```

Add route to `router.dart`:
```dart
GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
```

### 2d. Help & Support tile — link to contact form

Replace the no-op with a URL launcher to the web landing page contact form:
```dart
_tile(Icons.help_outline, s.profileHelp, () async {
  final uri = Uri.parse('https://khudmati.app/#contact');
  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
}),
```

Add `url_launcher` import (already a dependency via referral screen).

### 2e. Remaining no-op tiles — show "Coming Soon" snackbar

For **Saved Addresses**, **Payment Methods**, and **Notification Settings** — these are planned but have no backend yet. Show a snackbar instead of a silent no-op:

```dart
void _comingSoon(BuildContext context, S s) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.comingSoon, style: const TextStyle(fontFamily: 'Cairo'))),
  );
}
```

Wire all three tiles to call `_comingSoon(context, s)`.

Add i18n key: `comingSoon → "قريباً" / "Coming Soon"`.

---

## Part 3 — Minor UX Gaps

### 3a. Home — category tap pre-selects category

**File:** `lib/features/home/presentation/home_page.dart`

Each category tile calls `context.go('/booking/category')`. Change to also set the category on the notifier before navigating:

```dart
onTap: () {
  // categoryId is the index-based key matching backend enum
  final categoryIds = [
    'cleaning', 'plumbing', 'electrical', 'moving',
    'painting', 'ac_maintenance', 'carpentry', 'other'
  ];
  ref.read(bookingNotifierProvider.notifier)
     .setCategory(categoryIds[i], label);
  context.go('/booking/description'); // skip category screen, already selected
},
```

If skipping the category screen is too abrupt (user might want to change), instead navigate to `/booking/category` and highlight the pre-selected tile there. Either approach is acceptable — choose whichever requires fewer changes.

### 3b. Home — search bar filter

**File:** `lib/features/home/presentation/home_page.dart`

The search `TextField` currently has no controller. Add a `StateProvider<String>` for the query and filter the `categories` list:

```dart
final _searchQueryProvider = StateProvider<String>((ref) => '');
```

In `HomePage.build()`:
```dart
final query = ref.watch(_searchQueryProvider);
final filtered = categories.where((c) => c.$1.toLowerCase().contains(query.toLowerCase())).toList();
```

Show `filtered` in the GridView. When `filtered` is empty, show a centred `Text(s.homeNoResults)`.

Add i18n key: `homeNoResults → "لا توجد نتائج" / "No results found"`.

### 3c. Notifications — deep-link on tap

**File:** `lib/features/notifications/presentation/notifications_screen.dart`

`_NotificationCard.onTap` currently only calls `markRead`. After marking read, also navigate based on notification body/data if a `jobId` is present. Parse the notification `body` for a job reference number, or add a `relatedJobId` field to `NotificationModel` (parse from API response `data` or `metadata` field if available).

Minimal approach (no model changes): after `markRead`, check if `notification.body` contains a job reference pattern (`#\w+`) and offer a `SnackBar` action:
```dart
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text(notification.title),
  action: SnackBarAction(label: s.notifViewJob, onPressed: () => context.push('/history')),
));
```

Full approach (preferred): add optional `jobId` field to `NotificationModel` and `NotificationsRepository`; navigate to `/history/{jobId}` when present.

Add i18n key: `notifViewJob → "عرض الطلب" / "View Job"`.

### 3d. Payment receipt — show correct charged amount

**File:** `lib/features/payments/presentation/payment_receipt_screen.dart`

Currently shows `booking.agreedAmount` (before discounts). Change to show `booking.chargedAmount` instead (the actual amount charged after referral discount and credits). Also add breakdown rows when discounts were applied:

```dart
if (booking?.referralDiscountAmount != null && booking!.referralDiscountAmount! > 0)
  _ReceiptRow(label: s.receiptReferralDiscount, value: '-${booking.referralDiscountAmount!.toStringAsFixed(2)} SAR'),
if (booking?.creditApplied != null && booking!.creditApplied! > 0)
  _ReceiptRow(label: s.receiptCreditApplied, value: '-${booking.creditApplied!.toStringAsFixed(2)} SAR'),
```

Add i18n keys:
```
receiptReferralDiscount → "خصم الإحالة" / "Referral Discount"
receiptCreditApplied    → "رصيد مستخدم" / "Credit Applied"
```

### 3e. History — unknown category IDs display

**File:** `lib/features/history/presentation/history_page.dart` and `job_detail_page.dart`

Both files have a `categoryId → label` map. Add the missing entries:
```dart
'moving':  s.catMoving,
'other':   s.catOther,
```

And add a fallback for truly unknown IDs:
```dart
categoryNames[job.categoryId] ?? job.categoryId
```
Change to:
```dart
categoryNames[job.categoryId] ?? job.categoryId.replaceAll('_', ' ')
```

### 3f. History — basic pull-to-refresh (pagination deferred)

**File:** `lib/features/history/presentation/history_page.dart`

Full pagination is out of scope. Add `RefreshIndicator` so users can refresh the list:
```dart
RefreshIndicator(
  onRefresh: () => ref.refresh(_historyProvider.future),
  child: ListView.builder(...),
)
```

---

## Edge Cases & Validation

- Snooze days must not exceed 30 — `RemindersNotifier.snooze()` guards client-side; backend also returns `SNOOZE_DAYS_EXCEEDED`
- Dismiss is idempotent on the UI — remove item optimistically; if `REMINDER_ALREADY_DISMISSED` is returned, item is already gone (no error shown)
- Edit profile: if `PATCH /api/customers/me` is not yet implemented on the backend, show `s.comingSoon` snackbar and do not crash
- Notification handler: if `categoryId` from push payload is unknown, default to `/booking/category` without pre-filling
- Logout: always navigate to `/welcome` regardless of whether the API call succeeded (tokens may already be expired)

## Out of Scope (do not implement)

- Addresses / Payment Methods screens — show "Coming Soon" snackbar only; no backend endpoints for these yet
- Notification preferences screen — same, Coming Soon
- History pagination — `RefreshIndicator` is enough for now
- Provider analytics (this is provider app only)
- Any changes to the provider app or backend

## Acceptance Criteria

- [ ] `/reminders` route registered; screen renders reminder cards with overdue badge
- [ ] "Book Now" on reminder navigates to booking flow with correct category pre-filled
- [ ] Snooze 7 / Snooze 30 / Dismiss menu items call PATCH and remove card from list
- [ ] Push notification with `type: MAINTENANCE_REMINDER` opens correct booking category
- [ ] Logout calls `AuthNotifier.logout()` and clears tokens; navigates to `/welcome`
- [ ] Profile header shows real user name/phone after token refresh on startup (not `—`)
- [ ] Edit Profile screen saves name/email; invalidates auth state on success
- [ ] Help & Support tile opens `https://khudmati.app/#contact` in external browser
- [ ] Saved Addresses / Payment Methods / Notification Settings tiles show "Coming Soon" snackbar
- [ ] Home category tiles pre-select category before navigating to booking flow
- [ ] Home search filters category grid; shows "No results" empty state
- [ ] Notifications card tap shows view-job action after marking read
- [ ] Payment receipt shows `chargedAmount` with discount breakdown rows
- [ ] History/detail screens handle `moving` and `other` categories without showing raw ID
- [ ] `RefreshIndicator` on history list triggers a fresh API fetch
- [ ] All new strings present in both Arabic (`_ArStrings`) and English (`_EnStrings`)
- [ ] All new screens use `Directionality(textDirection: TextDirection.rtl)` and Cairo font
- [ ] No hardcoded hex colour values — use `AppColors.*` constants only

# Feature: Provider App — L10n Cleanup, Profile Wiring & UX Gaps (Part 2 of 3)

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR
- Frontend: Flutter provider app (`mobile-provider/`) — Riverpod, GoRouter, Dio
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`

## Goal
1. Replace all hardcoded Arabic strings with proper `S.of(ref)` l10n keys.
2. Wire all no-op profile page tiles to real actions.
3. Implement the Edit Profile screen.
4. Implement the Completed Jobs tab.
5. Delete legacy stub files.
6. Delete the Coming Soon blocks from l10n (or wire them properly).

All changes are confined to `mobile-provider/`. **Complete Part 1 (prompt `24-provider-app-bugs-routing.md`) before starting this prompt.**

## Platforms Affected
- [ ] Customer Mobile App
- [x] Provider Mobile App
- [ ] Web Landing Page
- [ ] Web Admin Panel
- [ ] Web Super Admin Panel

---

## Part 1 — Add Missing L10n Keys to `app_strings.dart`

**File:** `mobile-provider/lib/core/l10n/app_strings.dart`

Add all of the following getters to the `S` class. Each getter follows the existing pattern: `isAr ? '<Arabic>' : '<English>'`.

```dart
// ── Distance unit ─────────────────────────────────────────────────────────────
String distanceKm(double km) => isAr ? '$km كم' : '${km} km';

// ── Chat shared widgets ───────────────────────────────────────────────────────
String get chatNoMessages     => isAr ? 'لا توجد رسائل بعد'     : 'No messages yet';
String get chatToday          => isAr ? 'اليوم'                  : 'Today';
String get chatYesterday      => isAr ? 'أمس'                    : 'Yesterday';
String get chatInputHint      => isAr ? 'اكتب رسالة...'         : 'Type a message...';
String get chatSendError      => isAr ? 'فشل إرسال الرسالة'      : 'Failed to send message';

// ── Rating bottom sheet ───────────────────────────────────────────────────────
String get ratingSubmit       => isAr ? 'إرسال التقييم'          : 'Submit Rating';
String get ratingSkip         => isAr ? 'تخطي'                   : 'Skip';
String get ratingSubmitError  => isAr ? 'حدث خطأ، حاول مرة أخرى' : 'Something went wrong. Try again.';

// ── Profile tiles ─────────────────────────────────────────────────────────────
String get profileComingSoon  => isAr ? 'قريباً'                 : 'Coming Soon';
String get profileEditTitle   => isAr ? 'تعديل البيانات'         : 'Edit Profile';
String get profileEditName    => isAr ? 'الاسم الكامل'           : 'Full Name';
String get profileEditSave    => isAr ? 'حفظ التغييرات'          : 'Save Changes';
String get profileEditSuccess => isAr ? 'تم حفظ التغييرات'       : 'Changes saved';

// ── Completed jobs tab ────────────────────────────────────────────────────────
String get tabCompletedEmpty  => isAr ? 'لا توجد طلبات منجزة بعد' : 'No completed jobs yet';
String get tabCompletedError  => isAr ? 'تعذر تحميل الطلبات المنجزة' : 'Could not load completed jobs';
String get completedJobDate   => isAr ? 'تاريخ الإنجاز'          : 'Completed on';
String get completedJobAmount => isAr ? 'المبلغ الصافي'           : 'Net Amount';
```

Remove (or keep but do not reference) the existing "Stub pages" section:
```dart
// ── Stub pages ───────────────────────────────────────────────────────────────
String get jobServiceStub         => ...
String get jobLocationStub        => ...
String get jobDistanceStub        => ...
String get jobDescStub            => ...
```
These are only referenced by the legacy stub file deleted in Part 6.

---

## Part 2 — Replace Hardcoded Strings in Chat Shared Widgets

### 2a. `chat_message_list.dart`

**File:** `mobile-provider/lib/shared/widgets/chat/chat_message_list.dart`

Find and replace:
| Hardcoded string | Replace with |
|---|---|
| `'لا توجد رسائل بعد'` (empty state) | `s.chatNoMessages` |
| `'اليوم'` (date separator label) | `s.chatToday` |
| `'أمس'` (date separator label) | `s.chatYesterday` |

To access `s` in a widget that is not a `ConsumerWidget`, convert the widget to `ConsumerWidget` (or `ConsumerStatefulWidget` if it is stateful). If `ref` is not easily accessible, use a `Builder` widget that wraps the relevant section and accepts `BuildContext`, then look up the `ref` via a provider scope lookup — but preferably convert to `ConsumerWidget`.

### 2b. `chat_input_bar.dart`

**File:** `mobile-provider/lib/shared/widgets/chat/chat_input_bar.dart`

Find and replace:
| Hardcoded string | Replace with |
|---|---|
| `'اكتب رسالة...'` (text field hint) | `s.chatInputHint` |

### 2c. `chat_provider.dart`

**File:** `mobile-provider/lib/features/chat/presentation/chat_provider.dart`

The hardcoded Arabic error string on send failure should be replaced. Since providers cannot access `S.of(ref)` (it's UI-layer), the notifier should set a typed error code (`'SEND_FAILED'`) in state rather than a display string. The `chat_screen.dart` or `chat_input_bar.dart` then maps the error code to `s.chatSendError`.

If refactoring the state shape is too disruptive, at minimum replace with the English string `'Failed to send message'` and add a comment: `// TODO: localise via error code in state`.

---

## Part 3 — Replace Hardcoded Strings in Rating Bottom Sheet

**File:** `mobile-provider/lib/features/rating/presentation/provider_rating_bottom_sheet.dart`

Find and replace:
| Hardcoded string | Replace with |
|---|---|
| Arabic submit label on `ElevatedButton` (around line 199) | `s.ratingSubmit` |
| `'تخطي'` on `TextButton` (around line 215) | `s.ratingSkip` |

**File:** `mobile-provider/lib/features/rating/presentation/provider_rating_provider.dart`

Find the hardcoded Arabic error string (around line 74) set in `state.copyWith(error: '<Arabic text>')`. Replace with:
```dart
state = state.copyWith(error: s.ratingSubmitError);
```
If `s` is not accessible in the notifier (it shouldn't be — notifiers are not UI), instead store the error code `'GENERIC_ERROR'` in state and let the UI map it:
```dart
state = state.copyWith(errorCode: 'GENERIC_ERROR');
```
Then in `provider_rating_bottom_sheet.dart`, read `state.errorCode` and display `s.ratingSubmitError` (or a mapped string based on error code).

---

## Part 4 — Wire Profile Page Tiles to Real Actions

**File:** `mobile-provider/lib/features/profile/presentation/profile_page.dart`

Replace all empty `() {}` handlers with actual actions:

### 4a. Edit Profile tile
```dart
_tile(Icons.edit, s.profileEdit, () => context.push('/profile/edit')),
```
(The `/profile/edit` route and `EditProfileScreen` are created in Part 5.)

### 4b. Verification Level tile — navigate to Onboarding Hub
```dart
_tile(Icons.verified_user, s.profileVerification, () => context.push('/onboarding')),
```

### 4c. Payment Info tile — navigate to Payout Status screen
```dart
_tile(Icons.account_balance, s.profilePayment, () => context.push('/payout-status')),
```

### 4d. Work Hours tile — Coming Soon snackbar
```dart
_tile(Icons.schedule, s.profileWorkHours, () {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.profileComingSoon,
        style: const TextStyle(fontFamily: 'Cairo'))),
  );
}),
```

### 4e. Notifications tile — Coming Soon snackbar
```dart
_tile(Icons.notifications, s.profileNotifications, () {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.profileComingSoon,
        style: const TextStyle(fontFamily: 'Cairo'))),
  );
}),
```

### 4f. Help tile — open external URL
```dart
_tile(Icons.help_outline, s.profileHelp, () async {
  final uri = Uri.parse('https://khudmati.app/#contact');
  if (await canLaunchUrl(uri)) {
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}),
```
Add import: `import 'package:url_launcher/url_launcher.dart';`  
(`url_launcher` is already a dependency — confirm in `pubspec.yaml`, add if missing.)

---

## Part 5 — Edit Profile Screen (New File)

**New file:** `mobile-provider/lib/features/profile/presentation/edit_profile_screen.dart`

Backend endpoint: `PATCH /api/providers/me` — body: `{ "fullName": string }` — returns `200 { success: true }` on success.

If the backend `PATCH /api/providers/me` does not exist yet, call `PUT /api/providers/me/profile` or whatever the correct endpoint is. Check `backend/src/Modules/Providers/` to confirm.

### Screen spec

```dart
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
}
```

UI requirements:
- `Directionality(textDirection: TextDirection.rtl)`
- `AppBar` with title `s.profileEditTitle`, white on `AppColors.brandBlue`
- Pre-fill `fullName` from `authNotifierProvider` → `(state as AuthAuthenticated).provider.fullName`
- One editable field: Full Name (required, min 2 chars), `TextFormField` with `autofocus: true`
- Save button: `s.profileEditSave` — disabled while loading
- On tap Save:
  1. Validate form
  2. Call `PATCH /api/providers/me` with `{ "fullName": newName }`
  3. On success: call `ref.invalidate(authNotifierProvider)` (forces re-fetch of auth state) → show `SnackBar(content: Text(s.profileEditSuccess))` → `context.pop()`
  4. On error: show inline red `Text(s.errorGeneric)` below the field
- Font: Cairo throughout

### Route

**File:** `mobile-provider/lib/app/router.dart`

Add inside the `StatefulShellBranch` for profile (after the `GoRoute(path: '/profile', ...)` entry) or as a top-level route:

```dart
GoRoute(
  path: '/profile/edit',
  builder: (_, __) => const EditProfileScreen(),
),
```

Import at top of `router.dart`:
```dart
import '../features/profile/presentation/edit_profile_screen.dart';
```

---

## Part 6 — Implement Completed Jobs Tab

**File:** `mobile-provider/lib/features/jobs/presentation/job_feed_screen.dart`

The `_CompletedJobsTab` widget currently renders a placeholder. Wire it to a real API call.

### 6a. API

Backend endpoint: `GET /api/providers/me/jobs?status=Paid` — returns paginated list of provider's completed/paid jobs. Check `backend/src/Modules/` to confirm the exact query parameter name.

### 6b. New provider

**File:** `mobile-provider/lib/features/jobs/presentation/completed_jobs_provider.dart`

```dart
final completedJobsProvider = FutureProvider<List<CompletedJobSummary>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.dio.get('/providers/me/jobs', queryParameters: {'status': 'Paid'});
  final items = response.data['data']['items'] as List? ?? [];
  return items.map(CompletedJobSummary.fromJson).toList();
});
```

Model `CompletedJobSummary`:
```dart
final String id;
final String referenceNumber;
final String categoryName;
final String district;
final double netAmount;       // from payments.transactions.net_amount
final DateTime completedAt;  // job_status_history where new_status = 'Completed'
```

Parse from the same job list JSON shape as `JobSummary` (already in `job_repository.dart`). Reuse any field mapping that exists.

### 6c. Replace placeholder widget

Replace `_CompletedJobsTab` with a real implementation:
```dart
class _CompletedJobsTab extends ConsumerWidget {
  const _CompletedJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final async = ref.watch(completedJobsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
      error: (_, __) => Center(child: Text(s.tabCompletedError, style: const TextStyle(fontFamily: 'Cairo'))),
      data: (jobs) => jobs.isEmpty
          ? Center(child: Text(s.tabCompletedEmpty, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              itemBuilder: (ctx, i) {
                final job = jobs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withOpacity(0.12),
                      child: const Icon(Icons.check_circle, color: AppColors.success),
                    ),
                    title: Text(job.categoryName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.district} · ${job.referenceNumber}', style: const TextStyle(fontFamily: 'Cairo')),
                    trailing: Text(
                      'SAR ${job.netAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

---

## Part 7 — Delete Legacy Stub Files

Delete the following files — they are unreferenced in the current routing and only contain mock data:

1. `mobile-provider/lib/features/jobs/presentation/jobs_page.dart`  
   — legacy mock jobs list (5 hardcoded jobs, static price list)
   
2. `mobile-provider/lib/features/job_detail/presentation/job_detail_page.dart`  
   — legacy countdown UI with stubbed location, service name, and amount
   
3. `mobile-provider/lib/features/job_detail/` (**entire folder** if only `job_detail_page.dart` was in it)

Before deleting, search the entire `lib/` directory for any imports of these files. If found, remove those imports (they should not exist in the real routing — but verify).

Run `grep -r "jobs_page.dart\|job_detail_page\|JobDetailPage\|JobsPage" mobile-provider/lib/` to confirm nothing imports them.

---

## Part 8 — Notifications Provider: Add Pagination Awareness

**File:** `mobile-provider/lib/features/notifications/presentation/notifications_provider.dart`

### Problem
The provider currently fetches only the first page of notifications (no pagination). This is acceptable for v1 but should at least show a "Load more" affordance when `hasNextPage: true` is in the API response.

### Fix (minimal — do not over-engineer)
After loading the first page, check `response.data['data']['hasNextPage']` (or equivalent field). If `true`, append a sentinel item to the list or expose a `hasMore` bool on the state so the UI can show a "Load more" button.

If the API does not return pagination metadata (check actual response shape in `notifications_repository.dart`), skip this fix and mark it as future work with a comment.

---

## Acceptance Criteria
- [ ] All `S.of(ref)` keys exist for every previously hardcoded string — no bare Arabic/English literals in UI widgets
- [ ] `chat_message_list.dart` empty state, today/yesterday labels are localized
- [ ] `chat_input_bar.dart` hint text is localized
- [ ] Rating bottom sheet Submit and Skip buttons are localized
- [ ] Rating error message is not a hardcoded Arabic string in the notifier
- [ ] All profile tiles have real actions (no more empty `() {}` handlers)
- [ ] `/profile/edit` route exists and `EditProfileScreen` saves provider name via real API
- [ ] Completed Jobs tab shows real paginated data from backend (not placeholder text)
- [ ] `jobs_page.dart` and `job_detail_page.dart` legacy files are deleted
- [ ] No compile errors after deletions — grep confirms no remaining imports of deleted files
- [ ] App title in `app.dart` uses `s.appName` if feasible, or is updated to the correct bilingual string

## Out of Scope (do not implement in this prompt)
- Subscription / Power Provider feature (covered in Part 3)
- Analytics dashboard (covered in Part 3)
- Any backend changes
- GPS permission or live tracking changes beyond what Part 1 fixes in `NavigationPage`

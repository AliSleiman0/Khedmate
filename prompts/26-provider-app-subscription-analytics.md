# Feature: Provider App — Subscription Screen & Analytics Dashboard (Part 3 of 3)

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module) — `providers.provider_subscriptions`, `providers.subscription_plans` tables already exist
- Real-time: SignalR
- Frontend: Flutter provider app (`mobile-provider/`) — Riverpod, GoRouter, Dio
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`

## Goal
Implement the two completely missing features in the provider app:
1. **Power Provider Subscription screen** — providers can view their plan, subscribe, or cancel (Feature #18 Flutter layer only)
2. **Analytics Dashboard screen** — providers see earnings, job stats, and rating breakdown with charts (Feature #20 Flutter layer only)

The backend endpoints for both features already exist. This prompt is **Flutter-only** — no backend changes needed.

**Complete Parts 1 and 2 (prompts `24` and `25`) before starting this prompt.**

## Platforms Affected
- [ ] Customer Mobile App
- [x] Provider Mobile App
- [ ] Web Landing Page
- [ ] Web Admin Panel
- [ ] Web Super Admin Panel

---

## Part 1 — Dependency Check

Before writing any Dart, confirm these packages are in `mobile-provider/pubspec.yaml`:
- `flutter_stripe` or `stripe_flutter` — for Stripe PaymentSheet (needed for subscription payment)
- `fl_chart` — for earnings line chart and rating sparkline
- `url_launcher` — for external URLs (already confirmed in Part 2)

If `fl_chart` is missing, add it:
```yaml
fl_chart: ^0.68.0
```

If `flutter_stripe` is missing, add it:
```yaml
flutter_stripe: ^10.1.1
```

Run `flutter pub get` after editing `pubspec.yaml`.

---

## Part 2 — Subscription Feature

### 2a. L10n keys

**File:** `mobile-provider/lib/core/l10n/app_strings.dart`

Add to the `S` class:

```dart
// ── Subscription ──────────────────────────────────────────────────────────────
String get subTitle              => isAr ? 'اشتراك Power Provider'         : 'Power Provider Subscription';
String get subCurrentPlan        => isAr ? 'خطتك الحالية'                  : 'Your Current Plan';
String get subStandard           => isAr ? 'مزود عادي'                     : 'Standard Provider';
String get subPower              => isAr ? 'Power Provider'                 : 'Power Provider';
String get subMonthlyFee         => isAr ? 'الرسوم الشهرية'                 : 'Monthly Fee';
String get subCommission         => isAr ? 'نسبة العمولة'                   : 'Commission Rate';
String get subPriority           => isAr ? 'أولوية في استقبال الطلبات'     : 'Job Priority Access';
String get subNextBilling        => isAr ? 'تاريخ الفاتورة القادمة'         : 'Next Billing Date';
String get subCancelsAt          => isAr ? 'ينتهي الاشتراك في'              : 'Subscription ends';
String get subSubscribe          => isAr ? 'الاشتراك في Power Provider'     : 'Subscribe to Power Provider';
String get subCancel             => isAr ? 'إلغاء الاشتراك'                 : 'Cancel Subscription';
String get subCancelConfirmTitle => isAr ? 'إلغاء الاشتراك؟'                : 'Cancel Subscription?';
String get subCancelConfirmBody  => isAr ? 'ستستمر في الاستفادة من المزايا حتى نهاية الفترة الحالية.' : 'You will keep your benefits until the end of the current billing period.';
String get subCancelConfirmYes   => isAr ? 'نعم، إلغاء'                    : 'Yes, Cancel';
String get subCancelConfirmNo    => isAr ? 'لا، تراجع'                     : 'No, Keep It';
String get subActiveStatus       => isAr ? 'نشط'                           : 'Active';
String get subPastDueStatus      => isAr ? 'متأخر في الدفع'                : 'Payment Past Due';
String get subCancelledStatus    => isAr ? 'ملغى'                          : 'Cancelled';
String get subBenefitsTitle      => isAr ? 'مزايا Power Provider'           : 'Power Provider Benefits';
String get subBenefit1           => isAr ? 'عمولة 10% فقط (بدلاً من 15%)' : '10% commission (vs 15% standard)';
String get subBenefit2           => isAr ? 'أولوية استقبال الطلبات بـ 30 ثانية' : '30-second priority job access';
String get subBenefit3           => isAr ? 'شارة Power Provider على ملفك'  : 'Power Provider badge on your profile';
String get subLoadError          => isAr ? 'تعذر تحميل بيانات الاشتراك'    : 'Could not load subscription data';
String get subPaymentFailed      => isAr ? 'فشل الدفع، يرجى تحديث طريقة الدفع' : 'Payment failed. Please update your payment method.';
String get subSuccess            => isAr ? 'تم الاشتراك بنجاح!'             : 'Successfully subscribed!';
String get subCancelSuccess      => isAr ? 'تم إلغاء الاشتراك'              : 'Subscription cancelled';
String get subErrorNotActive     => isAr ? 'يجب أن يكون حسابك نشطاً للاشتراك' : 'Your account must be Active to subscribe';
String get subErrorAlready       => isAr ? 'لديك اشتراك نشط بالفعل'         : 'You already have an active subscription';
String get subErrorPayment       => isAr ? 'فشل في معالجة طريقة الدفع'     : 'Failed to process payment method';
String get subErrorStripe        => isAr ? 'حدث خطأ في نظام الدفع'          : 'Payment system error';
```

### 2b. Data layer

**New file:** `mobile-provider/lib/features/subscription/data/subscription_repository.dart`

```dart
class SubscriptionRepository {
  final ApiClient _client;
  SubscriptionRepository(this._client);

  // GET /api/providers/me/subscription
  // Returns null if not subscribed
  Future<SubscriptionInfo?> getSubscription() async { ... }

  // POST /api/providers/me/subscription
  // Body: { paymentMethodId: string }
  Future<void> subscribe(String paymentMethodId) async { ... }

  // DELETE /api/providers/me/subscription
  Future<DateTime> cancelSubscription() async { ... }  // returns cancelsAt
}
```

Model `SubscriptionInfo`:
```dart
class SubscriptionInfo {
  final String plan;              // 'PowerProvider'
  final String status;            // 'Active' | 'PastDue' | 'Cancelled'
  final double monthlyFee;        // 99.00
  final double commissionRate;    // 10.0
  final DateTime currentPeriodEnd;
  final bool cancelsAtPeriodEnd;
  final String currency;          // 'SAR'
}
```

Error code mapping — when the API returns `{ "error": "CODE" }`, throw a typed exception or return a `Result` type. Map:
- `PROVIDER_NOT_ACTIVE` → show `s.subErrorNotActive`
- `ALREADY_SUBSCRIBED` → show `s.subErrorAlready`
- `PAYMENT_METHOD_INVALID` → show `s.subErrorPayment`
- `STRIPE_ERROR` → show `s.subErrorStripe`

### 2c. State layer

**New file:** `mobile-provider/lib/features/subscription/presentation/subscription_provider.dart`

```dart
final subscriptionRepositoryProvider = Provider((ref) =>
    SubscriptionRepository(ref.watch(apiClientProvider)));

final subscriptionProvider = AsyncNotifierProvider<SubscriptionNotifier, SubscriptionInfo?>(() =>
    SubscriptionNotifier());

class SubscriptionNotifier extends AsyncNotifier<SubscriptionInfo?> {
  @override
  Future<SubscriptionInfo?> build() =>
      ref.watch(subscriptionRepositoryProvider).getSubscription();

  Future<String?> subscribe(String paymentMethodId) async {
    // Returns null on success, error string on failure
    state = const AsyncLoading();
    try {
      await ref.read(subscriptionRepositoryProvider).subscribe(paymentMethodId);
      ref.invalidateSelf();
      return null;
    } catch (e) {
      state = AsyncData(state.valueOrNull); // restore previous state
      return _mapError(e);
    }
  }

  Future<String?> cancel() async {
    // Returns null on success, error string on failure
    try {
      await ref.read(subscriptionRepositoryProvider).cancelSubscription();
      ref.invalidateSelf();
      return null;
    } catch (e) {
      return _mapError(e);
    }
  }

  String _mapError(Object e) { ... } // map error codes to l10n strings
}
```

### 2d. SignalR subscription events

In the existing `SignalRService` (`lib/core/services/signalr_service.dart`) or in the subscription screen's `initState`, listen for:
- `SubscriptionActivated` → invalidate `subscriptionProvider` + show SnackBar `s.subSuccess`
- `SubscriptionPaymentFailed` → invalidate `subscriptionProvider` + show SnackBar `s.subPaymentFailed`
- `SubscriptionCancelled` → invalidate `subscriptionProvider` + show SnackBar `s.subCancelSuccess`

### 2e. Screen

**New file:** `mobile-provider/lib/features/subscription/presentation/subscription_screen.dart`

```dart
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});
}
```

UI layout (RTL, Cairo font, `Directionality(textDirection: TextDirection.rtl)`):

#### When loading
Show `CircularProgressIndicator(color: AppColors.brandBlue)` centred.

#### When not subscribed (`data == null`)

```
┌─────────────────────────────────────┐
│  AppBar: "اشتراك Power Provider"    │
├─────────────────────────────────────┤
│  [Header card — dark blue gradient] │
│   ⚡ Power Provider                 │
│   99 ر.س / شهرياً                  │
├─────────────────────────────────────┤
│  Benefits list (3 rows):            │
│   ✓ عمولة 10% فقط                  │
│   ✓ أولوية 30 ثانية                │
│   ✓ شارة Power Provider            │
├─────────────────────────────────────┤
│  Current plan: مزود عادي (15%)      │
│                                     │
│  [ElevatedButton] — الاشتراك        │
└─────────────────────────────────────┘
```

**Subscribe button tap flow:**
1. Present Stripe PaymentSheet using `flutter_stripe`:
   ```dart
   // 1. Call backend: POST /api/providers/me/subscription/payment-intent
   //    (or whatever endpoint returns a client secret for the subscription setup)
   //    If backend uses SetupIntent: GET /api/providers/me/subscription/setup-intent → clientSecret
   // 2. Stripe.instance.initPaymentSheet(paymentSheetData: PaymentSheetData(merchantDisplayName: 'Khudmati', ...))
   // 3. await Stripe.instance.presentPaymentSheet()
   //    On success: extract paymentMethodId and call notifier.subscribe(paymentMethodId)
   ```
   
   **Important:** Check `backend/src/Modules/Providers/` to find the exact endpoint that sets up the Stripe subscription. The feature #18 design uses `POST /api/providers/me/subscription` with `{ paymentMethodId }`. If the backend requires a separate SetupIntent step, add that first.
   
   If Stripe PaymentSheet integration is complex and `flutter_stripe` is not already configured, use a simpler flow: open the Stripe-hosted payment URL in a WebView or external browser. But prefer native PaymentSheet if `flutter_stripe` is already set up (check `main.dart` for `Stripe.publishableKey` initialization).

2. On payment success: notifier shows SnackBar `s.subSuccess`, refreshes the screen.
3. On error: show inline error text from `notifier.subscribe()` return value.

#### When subscribed (`data != null`)

```
┌─────────────────────────────────────┐
│  AppBar: "اشتراك Power Provider"    │
├─────────────────────────────────────┤
│  [Header card]                      │
│   ⚡ Power Provider  [Active badge]  │
│   عمولة 10%  |  أولوية 30 ث        │
├─────────────────────────────────────┤
│  تاريخ الفاتورة القادمة: 4 مايو    │
│  (or "ينتهي الاشتراك في: 4 مايو"   │
│   if cancelsAtPeriodEnd == true)    │
├─────────────────────────────────────┤
│  [TextButton, red] — إلغاء الاشتراك │
└─────────────────────────────────────┘
```

**Cancel button tap:**
- Show `AlertDialog` with `s.subCancelConfirmTitle`, `s.subCancelConfirmBody`
- Confirm → `notifier.cancel()` → on success: show SnackBar + refresh
- Dismiss → no change

**PastDue status:** Show amber warning banner: `s.subPaymentFailed`

### 2f. Routes

**File:** `mobile-provider/lib/app/router.dart`

Add as top-level route (outside the shell, same level as `/onboarding`):
```dart
GoRoute(
  path: '/subscription',
  builder: (_, __) => const SubscriptionScreen(),
),
```

Add import:
```dart
import '../features/subscription/presentation/subscription_screen.dart';
```

### 2g. Profile page — Subscription tile

**File:** `mobile-provider/lib/features/profile/presentation/profile_page.dart`

Add a new tile after the Payment tile:
```dart
_tile(Icons.workspace_premium, s.subTitle, () => context.push('/subscription')),
```

Add `s.subTitle` l10n key (already added in §2a above).

---

## Part 3 — Analytics Dashboard

### 3a. L10n keys

**File:** `mobile-provider/lib/core/l10n/app_strings.dart`

Add:

```dart
// ── Analytics ─────────────────────────────────────────────────────────────────
String get analyticsTitle          => isAr ? 'إحصائياتي'                   : 'My Analytics';
String get analyticsPeriod7d       => isAr ? '7 أيام'                      : '7 Days';
String get analyticsPeriod30d      => isAr ? '30 يوم'                      : '30 Days';
String get analyticsPeriod3m       => isAr ? '3 أشهر'                      : '3 Months';
String get analyticsPeriodAll      => isAr ? 'الكل'                        : 'All Time';
String get analyticsEarningsTitle  => isAr ? 'الأرباح'                     : 'Earnings';
String get analyticsNetEarnings    => isAr ? 'الأرباح الصافية'              : 'Net Earnings';
String get analyticsPending        => isAr ? 'في الانتظار'                  : 'Pending';
String get analyticsVsPrev         => isAr ? 'مقارنة بالفترة السابقة'       : 'vs previous period';
String get analyticsJobsTitle      => isAr ? 'إحصائيات الطلبات'             : 'Job Statistics';
String get analyticsCompleted      => isAr ? 'طلبات منجزة'                 : 'Completed Jobs';
String get analyticsAcceptRate     => isAr ? 'معدل القبول'                  : 'Acceptance Rate';
String get analyticsAvgValue       => isAr ? 'متوسط قيمة الطلب'             : 'Avg Job Value';
String get analyticsTopCategories  => isAr ? 'أكثر الفئات طلباً'            : 'Top Categories';
String get analyticsRatingTitle    => isAr ? 'تقييماتي'                    : 'My Ratings';
String get analyticsPositiveRate   => isAr ? 'نسبة الرضا'                   : 'Satisfaction Rate';
String get analyticsTotalRatings   => isAr ? 'إجمالي التقييمات'              : 'Total Ratings';
String get analyticsTopTags        => isAr ? 'أبرز نقاط القوة'              : 'Top Strengths';
String get analyticsRatingTrend    => isAr ? 'آخر 10 تقييمات'               : 'Last 10 Ratings';
String get analyticsLoadError      => isAr ? 'تعذر تحميل الإحصائيات'        : 'Could not load analytics';
String get analyticsNoData         => isAr ? 'لا توجد بيانات بعد'           : 'No data yet';
String get analyticsSAR            => isAr ? 'ر.س'                         : 'SAR';
```

### 3b. Data layer

**New file:** `mobile-provider/lib/features/analytics/data/analytics_repository.dart`

```dart
class AnalyticsRepository {
  final ApiClient _client;
  AnalyticsRepository(this._client);

  // GET /api/providers/me/analytics/earnings?period=Last30Days
  Future<EarningsAnalytics> getEarnings(String period) async { ... }

  // GET /api/providers/me/analytics/jobs?period=Last30Days
  Future<JobAnalytics> getJobStats(String period) async { ... }

  // GET /api/providers/me/analytics/ratings
  Future<RatingAnalytics> getRatingStats() async { ... }
}
```

Models:
```dart
class EarningsAnalytics {
  final double currentPeriodEarnings;  // may be 0
  final double? previousPeriodEarnings;
  final double? changePercent;          // nullable — null if no previous data
  final double pendingEarnings;
  final String currency;
  final List<ChartDataPoint> chartDataPoints;
}

class ChartDataPoint {
  final DateTime date;
  final double amount;
}

class JobAnalytics {
  final int completedJobs;
  final int rejectedJobs;
  final int expiredJobs;
  final double acceptanceRate;         // percent, may be 0
  final double avgJobValueNet;         // may be 0
  final String currency;
  final List<CategoryStat> topCategories;
}

class CategoryStat {
  final String categoryId;
  final String categoryName;           // from API response or resolved client-side
  final int jobCount;
}

class RatingAnalytics {
  final double? positiveRatePct;       // nullable — null if no ratings
  final int totalRatings;
  final int positiveCount;
  final List<String> topPositiveTags;
  final List<String> topNegativeTags;
  final List<RecentRating> recentRatings; // last 10
}

class RecentRating {
  final bool isPositive;
  final DateTime date;
}
```

All models return zero/empty values (not null) for providers with no data — the backend guarantees this, but add safe null-coalescing in `fromJson` regardless.

### 3c. State layer

**New file:** `mobile-provider/lib/features/analytics/presentation/analytics_provider.dart`

```dart
// Period state
final analyticsPeriodProvider = StateProvider<String>((ref) => 'Last30Days');

final analyticsRepositoryProvider = Provider((ref) =>
    AnalyticsRepository(ref.watch(apiClientProvider)));

// All three analytics calls are made in parallel via Future.wait
// 5-minute cache using keepAlive or autoDispose with a timer
final analyticsProvider = FutureProvider.autoDispose<AnalyticsDashboard>((ref) async {
  final period = ref.watch(analyticsPeriodProvider);
  final repo = ref.watch(analyticsRepositoryProvider);

  final results = await Future.wait([
    repo.getEarnings(period),
    repo.getJobStats(period),
    repo.getRatingStats(),   // ratings are period-independent
  ]);

  return AnalyticsDashboard(
    earnings: results[0] as EarningsAnalytics,
    jobs: results[1] as JobAnalytics,
    ratings: results[2] as RatingAnalytics,
  );
});

class AnalyticsDashboard {
  final EarningsAnalytics earnings;
  final JobAnalytics jobs;
  final RatingAnalytics ratings;
}
```

5-minute cache: use `ref.keepAlive()` + a `Timer` that cancels after 5 minutes, or `cacheTime` if library version supports it.

### 3d. Screen

**New file:** `mobile-provider/lib/features/analytics/presentation/analytics_screen.dart`

```dart
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
}
```

Full layout (RTL, Cairo font):

```
AppBar: "إحصائياتي" — white on brandBlue

Period selector (horizontally scrollable FilterChips):
  [7 أيام]  [30 يوم ✓]  [3 أشهر]  [الكل]
  → tapping changes analyticsPeriodProvider → triggers refresh

── Section: الأرباح ──────────────────────────────────

  [Summary card — brandBlue background]
   الأرباح الصافية
   ر.س 2,450         ↑ 11.9% vs previous period
   (amber up-arrow chip if positive, red down-arrow if negative)

  [Line chart — fl_chart LineChart]
   X axis: date labels (abbreviated)
   Y axis: SAR amounts
   Line color: amber (#F39C12)
   Dots: small filled circles
   Height: 160px
   If no data points: show centered text s.analyticsNoData

  [Small card row]
   في الانتظار: ر.س 380

── Section: إحصائيات الطلبات ─────────────────────────

  [2x2 stat grid]
   [طلبات منجزة: 42]    [معدل القبول: 91.3%]
   [متوسط الطلب: ر.س 58] [مرفوض: 3]

  [Bar chart — fl_chart BarChart]
   Title: "أكثر الفئات طلباً"
   X axis: category names (Arabic, rotated 45°)
   Y axis: job count
   Bar color: brandBlue
   Height: 180px
   Show up to 5 bars
   If empty: s.analyticsNoData

── Section: تقييماتي ────────────────────────────────

  [Large rating card]
   نسبة الرضا: 94.5%      إجمالي التقييمات: 183
   [Thumbs up icon — green]

  [Tags row: أبرز نقاط القوة]
   Wrap of Chip widgets with amber background — top 3 positive tags

  [Sparkline: آخر 10 تقييمات]
   fl_chart LineChart — height 60px
   isPositive=true → 1.0, false → 0.0
   Y axis hidden, X axis hidden
   Line color: brandBlue with dots
   Point color: green if 1.0, red if 0.0 (custom dot painter)
```

Implement each section as a private widget class (`_EarningsSection`, `_JobStatsSection`, `_RatingsSection`) to keep the main screen widget readable.

All numbers formatted with `NumberFormat('#,##0.##', 'ar')` for Arabic locale and `NumberFormat('#,##0.##', 'en')` for English locale. Use the `intl` package (already in `pubspec.yaml`).

Dates on chart X-axis: abbreviated month/day — `DateFormat('d MMM', isAr ? 'ar' : 'en')`.

### 3e. Routes

**File:** `mobile-provider/lib/app/router.dart`

Add inside the `StatefulShellRoute` as a new branch (5th tab), OR add as a top-level non-shell route accessible via the Profile page. **Prefer adding as a new bottom nav tab** if the main scaffold supports a 5th item; otherwise add as a push route from the profile page.

Check `mobile-provider/lib/widgets/main_scaffold.dart` to see how many bottom nav items exist (currently 4: Jobs, Earnings, Notifications, Profile). If adding a 5th tab would crowd the nav bar, add it as a push route from the Profile page instead.

**Option A — 5th bottom nav tab (preferred if layout allows):**
```dart
StatefulShellBranch(routes: [
  GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
]),
```
And add to `MainScaffold`'s `NavigationBar` destinations:
```dart
NavigationDestination(
  icon: const Icon(Icons.bar_chart_outlined),
  selectedIcon: const Icon(Icons.bar_chart),
  label: s.analyticsTitle,
),
```

**Option B — push route from Profile page:**
```dart
GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
```
And in `profile_page.dart`:
```dart
_tile(Icons.bar_chart, s.analyticsTitle, () => context.push('/analytics')),
```

Add import in `router.dart`:
```dart
import '../features/analytics/presentation/analytics_screen.dart';
```

---

## Part 4 — Verify `fl_chart` Integration

After implementing charts, verify that:
1. `fl_chart` version in `pubspec.yaml` matches the API used in the code (the `LineChart`, `BarChart` constructors change between versions — use `fl_chart ^0.68.0` or pin the version).
2. The `LineChartData`, `BarChartData` constructors match the installed version.
3. Charts render with real data and display correctly in both RTL (Arabic) and LTR (English) modes.
4. Empty data states show `s.analyticsNoData` text, not blank/crashed chart widgets — guard with `if (dataPoints.isEmpty) return EmptyWidget()`.

---

## Acceptance Criteria

### Subscription
- [ ] Provider with `Standard` (no subscription) sees the benefits card and Subscribe button
- [ ] Tapping Subscribe presents Stripe PaymentSheet
- [ ] On successful payment, subscription status updates to `Active` on screen without manual refresh
- [ ] Provider with `Active` subscription sees their commission rate (10%), next billing date, and Cancel button
- [ ] Tapping Cancel shows confirmation dialog; confirming calls the API and shows `cancelsAtPeriodEnd` date
- [ ] `PastDue` status shows an amber warning banner with `s.subPaymentFailed`
- [ ] `/subscription` route is registered and accessible from the Profile page
- [ ] SignalR `SubscriptionActivated` event refreshes subscription state in real time

### Analytics
- [ ] Analytics screen loads 3 API calls in parallel (`Future.wait`) without sequential waterfalls
- [ ] Period chips (7d / 30d / 3m / All Time) refresh all three sections when tapped
- [ ] Earnings line chart renders with `fl_chart` — empty state shows `s.analyticsNoData` text
- [ ] Job stats grid shows all 4 metrics; bar chart handles 0–5 categories
- [ ] Rating section shows `positiveRatePct` as a large percentage; sparkline renders last 10 ratings
- [ ] All numbers use locale-aware formatting (Arabic numerals in AR mode)
- [ ] Analytics screen is accessible (push from Profile or 5th nav tab)
- [ ] Data is cached for 5 minutes — navigating away and back does not re-fetch within 5 minutes
- [ ] Zero/null data states are handled gracefully — no crashes for new providers with no history

## Out of Scope (do not implement in this prompt)
- Any backend changes (all endpoints already exist)
- Subscription plan configuration UI (web super admin — already built)
- Admin subscription overview (web admin — already built)
- Customer app changes

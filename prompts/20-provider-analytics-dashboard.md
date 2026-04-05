# Feature: Provider Analytics Dashboard

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-provider)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#06 must be implemented. Analytics are derived from `payments.transactions`, `bookings.jobs`, and `providers.rating_stats`.

## Goal
A dedicated analytics dashboard in the provider app giving providers a clear view of their business performance: net earnings over time, job counts and acceptance rate, and rating breakdown. All data is fetched from backend aggregate endpoints and cached locally for 5 minutes. This gives providers actionable visibility to understand and grow their income on the platform.

## Platforms Affected
- [x] Provider Mobile App (Flutter)
- [x] Backend (.NET 8) — analytics query endpoints
- [ ] Customer Mobile App — no changes
- [ ] Web Admin Panel — admin-side provider analytics are part of feature #14 (provider management)
- [ ] Web Landing Page — no changes
- [ ] Web Super Admin Panel — no changes

---

## User Stories
- As a **provider**, I want to see my total and net earnings for different time periods so I understand my income trend.
- As a **provider**, I want to see how many jobs I've completed and my acceptance rate so I can improve my conduct.
- As a **provider**, I want to understand my rating breakdown (positive %, tag frequency) so I know what customers value.

---

## Analytics Dimensions

### 1. Earnings Summary
- **Net earnings** (after platform commission) by period: Last 7 days, Last 30 days, Last 3 months, All time
- **Earnings chart**: line chart — X axis: days (for 7d/30d), weeks (for 3m), months (for all time); Y axis: SAR
- **Period comparison**: show "↑ 12% vs previous period" badge
- **Pending earnings** (jobs `Completed` but not yet `Paid` — still in 24h hold)

### 2. Job Statistics
- Total jobs completed (all time and selected period)
- Total jobs rejected
- Acceptance rate (%): `accepted / (accepted + expired + rejected) * 100`
- Average job value (net, after commission)
- Jobs by category: top 5 categories as a bar chart

### 3. Rating Breakdown
- Overall positive rating %: derived from `providers.rating_stats`
- Total ratings received
- Top positive tags (sorted by frequency, top 5)
- Top negative/neutral tags (if any, top 3)
- Rating trend over last 10 jobs: mini sparkline (thumbs up = 1, thumbs down = 0)

---

## Backend Changes

### New query handlers in `Modules/Providers/Application/Queries/`

#### `GetProviderEarningsQuery.cs`
```csharp
public record GetProviderEarningsQuery(
    Guid ProviderId,
    AnalyticsPeriod Period   // Last7Days | Last30Days | Last3Months | AllTime
) : IRequest<EarningsAnalyticsDto>;
```

**Handler logic:**
1. Determine date range from `Period`.
2. Query `payments.transactions` joined with `bookings.jobs` for this provider:
   - Filter `status = Released` (only settled payments count as realised earnings)
   - Sum `net_amount` (amount after commission) for current period → `currentPeriodEarnings`
   - Sum for equivalent previous period → `previousPeriodEarnings`
   - Group by day/week/month depending on period → `chartDataPoints: [{ date, amount }]`
3. Query pending: `payments.transactions` where `status = Held` for this provider → `pendingEarnings`
4. Return `EarningsAnalyticsDto`.

**SQL hint (raw query or EF):**
```sql
SELECT
    DATE_TRUNC('day', t.created_at) AS period,
    SUM(t.net_amount) AS earnings
FROM payments.transactions t
JOIN bookings.jobs j ON j.id = t.job_id
WHERE j.provider_id = @providerId
  AND t.status = 'Released'
  AND t.created_at >= @startDate
GROUP BY DATE_TRUNC('day', t.created_at)
ORDER BY period;
```

Truncation unit (`day` / `week` / `month`) is determined by the period parameter.

#### `GetProviderJobStatsQuery.cs`
```csharp
public record GetProviderJobStatsQuery(
    Guid ProviderId,
    AnalyticsPeriod Period
) : IRequest<JobStatsDto>;
```

**Handler logic:**
Query `bookings.jobs` for this provider within the period:
- Count by status: `Completed`, `Rejected`, `Expired` (auto-expired after 2-min countdown)
- Acceptance rate: `completed / (completed + rejected + expired) * 100` — round to 1 decimal
- Average net job value: `AVG(t.net_amount)` from joined `payments.transactions WHERE status = Released`
- Top 5 categories by count: `GROUP BY category_id ORDER BY COUNT DESC LIMIT 5` — join to get category name

#### `GetProviderRatingStatsQuery.cs`
```csharp
public record GetProviderRatingStatsQuery(Guid ProviderId) : IRequest<RatingAnalyticsDto>;
```

**Handler logic:**
1. Load `providers.rating_stats` row for provider → `positiveCount`, `totalCount`.
2. Compute `positiveRatePct = positiveCount / totalCount * 100`.
3. Query `bookings.ratings` for this provider:
   - Top positive tags: `WHERE is_positive = true GROUP BY tag ORDER BY COUNT DESC LIMIT 5`
   - Top negative tags: `WHERE is_positive = false GROUP BY tag ORDER BY COUNT DESC LIMIT 3`
   - Last 10 ratings ordered by `created_at DESC` → `recentRatings: [{ isPositive: bool, date }]` (for sparkline)
4. Return `RatingAnalyticsDto`.

---

## API Endpoints

### GET /api/providers/me/analytics/earnings?period=Last30Days
- Auth: Provider JWT
- Query param: `period` — `Last7Days | Last30Days | Last3Months | AllTime`
- Response:
```json
{
  "success": true,
  "data": {
    "currentPeriodEarnings": 2450.00,
    "previousPeriodEarnings": 2190.00,
    "changePercent": 11.9,
    "pendingEarnings": 380.00,
    "currency": "SAR",
    "chartDataPoints": [
      { "date": "2026-03-05", "amount": 120.00 },
      { "date": "2026-03-06", "amount": 0.00 }
    ]
  }
}
```

### GET /api/providers/me/analytics/jobs?period=Last30Days
- Auth: Provider JWT
- Response:
```json
{
  "success": true,
  "data": {
    "completedJobs": 42,
    "rejectedJobs": 3,
    "expiredJobs": 1,
    "acceptanceRate": 91.3,
    "avgJobValueNet": 58.33,
    "currency": "SAR",
    "topCategories": [
      { "categoryId": "...", "categoryNameAr": "تكييف وتبريد", "jobCount": 18 }
    ]
  }
}
```

### GET /api/providers/me/analytics/ratings
- Auth: Provider JWT
- No period filter — ratings are all-time aggregates
- Response:
```json
{
  "success": true,
  "data": {
    "positiveRatePct": 94.5,
    "totalRatings": 183,
    "positiveCount": 173,
    "topPositiveTags": ["دقيق في المواعيد", "عمل رائع", "نظيف وأنيق"],
    "topNegativeTags": ["تأخر"],
    "recentRatings": [
      { "isPositive": true, "date": "2026-04-01" },
      { "isPositive": true, "date": "2026-03-30" }
    ]
  }
}
```

---

## Provider App Changes

### New Screen: Analytics Dashboard (`lib/features/analytics/presentation/analytics_screen.dart`)

**Layout:**

**Header row:**
- Period selector chips: "7 أيام" | "30 يوم" | "3 أشهر" | "الكل" — horizontally scrollable
- Tapping a chip refreshes all sections

**Section 1 — الأرباح (Earnings)**
- Hero card (brand blue):
  - Large number: "٢,٤٥٠ ر.س" (net earnings for selected period)
  - Sub: "⬆ 12% عن الفترة السابقة" (green arrow) or "⬇ 5%" (red arrow)
  - Pending badge: "٣٨٠ ر.س قيد الانتظار" (amber)
- Line chart — use `fl_chart` package (already likely in project or add to `pubspec.yaml`):
  - Brand blue line, amber dots on data points
  - Y axis: SAR amounts, X axis: dates in Arabic short format
  - Touch tooltip showing exact amount + date

**Section 2 — إحصائيات الوظائف (Job Statistics)**
- 2×2 stat cards grid:
  - ✅ "وظائف مكتملة" — large number
  - 📊 "معدل القبول" — "91.3%"
  - ❌ "وظائف مرفوضة" — number
  - 💰 "متوسط قيمة الوظيفة" — "58 ر.س"
- Top categories horizontal bar chart (fl_chart `BarChart`):
  - Label: "أكثر الفئات طلباً"
  - Bars: amber fill, category name in Arabic as label

**Section 3 — التقييمات (Ratings)**
- Rating score card:
  - Thumbs up percentage: "94.5%" large, green
  - Total: "١٨٣ تقييم"
- Positive tags row: amber chip for each tag, sorted by frequency
- Negative tags row (if any): light red chip
- Sparkline (last 10 ratings): `fl_chart` `LineChart` or a custom row of 10 icons (👍/👎)

**Navigation:**
- Add "التحليلات" (Analytics) tab to the provider app bottom navigation bar (or add as a screen accessible from the profile drawer — choose the approach that fits the existing nav structure)

### State Management

New Riverpod provider: `lib/features/analytics/presentation/analytics_provider.dart`
```dart
@riverpod
class AnalyticsNotifier extends _$AnalyticsNotifier {
  AnalyticsPeriod _period = AnalyticsPeriod.last30Days;

  @override
  Future<AnalyticsDashboardState> build() => _load();

  Future<void> setPeriod(AnalyticsPeriod period) async {
    _period = period;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<AnalyticsDashboardState> _load() async {
    final [earnings, jobs, ratings] = await Future.wait([
      ref.read(analyticsRepositoryProvider).getEarnings(_period),
      ref.read(analyticsRepositoryProvider).getJobStats(_period),
      ref.read(analyticsRepositoryProvider).getRatingStats(),
    ]);
    return AnalyticsDashboardState(
      earnings: earnings,
      jobStats: jobs,
      ratingStats: ratings,
      period: _period,
    );
  }
}
```

All three API calls are made in parallel via `Future.wait`. Implement **5-minute local cache** in the repository using a simple timestamp check — on subsequent calls for the same period within 5 minutes, return the cached response.

New repository: `lib/features/analytics/data/analytics_repository.dart`

New model classes: `lib/features/analytics/domain/`
- `EarningsAnalytics`
- `JobStats`
- `RatingAnalytics`
- `AnalyticsPeriod` enum

---

## Performance Considerations

- All three backend queries must be fast (<200ms for 95th percentile). Use database-level aggregations (not application-level iteration).
- Add composite indexes if needed:
  ```sql
  CREATE INDEX idx_transactions_provider_status_date
      ON payments.transactions(job_id, status, created_at);
  -- (join through bookings.jobs to get provider_id)

  CREATE INDEX idx_jobs_provider_status_date
      ON bookings.jobs(provider_id, status, created_at);

  CREATE INDEX idx_ratings_provider_created
      ON bookings.ratings(provider_id, created_at DESC);
  ```
- Response is cacheable per provider per period. Add `Cache-Control: max-age=300` headers on analytics endpoints.

---

## Edge Cases & Validation

- If the provider has no jobs yet: return zero values for all metrics, empty `chartDataPoints` array — never return null or 404
- If `totalRatings = 0`: return `positiveRatePct = null` (not 0) so the UI can show "لا توجد تقييمات بعد" instead of "0%"
- `changePercent` is null when `previousPeriodEarnings = 0` (can't compute % change from zero)
- Period chips are disabled while data is loading — show a shimmer/loading state on each section card
- Chart handles days with 0 earnings (show as 0, not missing data point)
- All monetary amounts are in SAR; no multi-currency in V1

---

## Out of Scope (do not implement)
- CSV/PDF export of earnings report
- Tax summary
- Comparison with other providers / leaderboard
- Admin-side analytics dashboard for all providers (feature #14)
- Web version of the analytics dashboard
- Real-time earnings counter (page refreshes on pull-to-refresh only)

---

## Dependencies

Add to `mobile-provider/pubspec.yaml` if not already present:
```yaml
fl_chart: ^0.68.0   # or latest compatible version
```

---

## File Locations

| File | Purpose |
|---|---|
| `Modules/Providers/Application/Queries/GetProviderEarningsQuery.cs` | Earnings aggregate query |
| `Modules/Providers/Application/Queries/GetProviderJobStatsQuery.cs` | Job stats aggregate query |
| `Modules/Providers/Application/Queries/GetProviderRatingStatsQuery.cs` | Rating breakdown query |
| `Khudmati.API/Controllers/ProvidersController.cs` | Add three analytics endpoints |
| `lib/features/analytics/presentation/analytics_screen.dart` | Main dashboard screen |
| `lib/features/analytics/presentation/analytics_provider.dart` | Riverpod state |
| `lib/features/analytics/data/analytics_repository.dart` | API calls + 5-min cache |
| `lib/features/analytics/domain/` | Model classes |

---

## Acceptance Criteria
- [ ] Provider can view earnings for 7-day, 30-day, 3-month, and all-time periods
- [ ] Line chart renders correctly with real data, showing SAR amounts by period
- [ ] Period-over-period change % is shown with directional arrow (green/red)
- [ ] Pending earnings (Held transactions) are displayed separately
- [ ] Job stats show completed count, acceptance rate, and top categories
- [ ] Rating section shows positive %, total count, positive tags, and negative tags
- [ ] Changing the period selector refreshes all three sections simultaneously
- [ ] All three API calls are made in parallel — no sequential waterfall
- [ ] 5-minute local cache prevents redundant API calls
- [ ] Zero/empty states are handled gracefully — no null errors or blank screens
- [ ] All monetary values display in Arabic numerals with "ر.س" suffix
- [ ] All UI text is in Arabic; layout is RTL

# Feature: Post-Job Rating

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-customer, mobile-provider)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#05 must be implemented. Rating is triggered after job reaches `Paid` status.

## Goal
After a job is paid, both sides rate each other. The customer rates the provider with a binary thumbs up/down plus optional tags. The provider rates the customer the same way. Ratings are visible on provider profiles and feed into the verification tier display. This closes Phase 1 completely.

## Platforms Affected
- [x] Customer Mobile App (Flutter) — rates the provider after payment
- [x] Provider Mobile App (Flutter) — rates the customer after job completion
- [x] Backend (.NET 8) — stores ratings, updates provider aggregate score
- [ ] Admin Panel — feature #12
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Stories
- As a **customer**, I want to rate the provider after my job is done so others know if they're trustworthy.
- As a **provider**, I want to rate the customer after the job so the platform knows if they're reliable.
- As the **platform**, I want to aggregate provider ratings so I can surface trustworthy providers and detect bad actors.

---

## Rating System Design

**Binary only — no 5 stars.** Thumbs up 👍 or thumbs down 👎.

**Optional tags** (customer rating a provider):
- وصل في الوقت المحدد (Arrived on time)
- عمل نظيف (Clean worksite)
- سعر عادل (Fair pricing)
- محترف (Professional)
- أنصح به (Would recommend)

**Optional tags** (provider rating a customer):
- سهل التعامل (Easy to deal with)
- وصف المشكلة بدقة (Described problem accurately)
- دفع فوري (Paid promptly)

Tags are positive only — no negative tags in V1. Negative sentiment is captured by the thumbs down alone.

**Rating window:** customer has 48 hours after job reaches `Paid` status to submit a rating. After 48 hours the prompt is dismissed and no rating is recorded. Provider has the same 48-hour window.

**One rating per job per direction** — one customer→provider rating and one provider→customer rating per job. Cannot be edited after submission.

---

## Customer App Changes

### Update: Job Tracking Screen (`lib/features/booking/presentation/job_tracking_screen.dart`)
After job status = `Paid`, replace the action area with:
- "قيّم تجربتك" (Rate your experience) amber button
- Tapping → opens Rating Bottom Sheet

### New: Rating Bottom Sheet (`lib/features/rating/presentation/rating_bottom_sheet.dart`)
A modal bottom sheet (not a full screen — keeps context):

**Layout:**
- Provider name + avatar placeholder (initials in a circle)
- Question: "كيف كانت تجربتك مع {providerName}؟" (How was your experience with {providerName}?)
- Two large buttons side by side:
  - 👍 "ممتاز" (Excellent) — outlined, turns filled brand blue when selected
  - 👎 "سيء" (Poor) — outlined, turns filled red when selected
- Tags section (shows after thumbs selection, only if thumbs up):
  - "أخبرنا أكثر" (Tell us more) label
  - Wrap row of tag chips — tap to toggle, amber when selected, grey when not
  - Tags are optional
- Submit button: "إرسال التقييم" (Submit Rating) — disabled until thumbs up or down is selected
- "تخطي" (Skip) text link at bottom — dismisses without submitting
- On submit → API call → show brief success animation → dismiss sheet

### New: Rating Reminder Notification (in-app only — push is feature #10)
On app open, if there are unrated jobs within the 48h window:
- Show a banner at top of Home screen: "لديك تقييم معلق" (You have a pending rating) with a "قيّم الآن" (Rate now) link
- Banner dismisses when rating is submitted or skipped

---

## Provider App Changes

### Update: Completed Jobs list (`lib/features/jobs/presentation/active_jobs_screen.dart`)
For jobs with status `Paid` and no provider→customer rating submitted yet (within 48h):
- Show a small amber "قيّم العميل" (Rate customer) chip on the job card

### New: Provider Rating Bottom Sheet (`lib/features/rating/presentation/provider_rating_bottom_sheet.dart`)
Same structure as customer rating sheet but simpler:
- "كيف كان تعامل العميل؟" (How was the customer to deal with?)
- Thumbs up / thumbs down
- Optional positive tags (provider→customer tags listed above)
- Submit / Skip

---

## State Management

### Rating Notifier (`lib/features/rating/presentation/rating_provider.dart`)
```dart
@riverpod
class RatingNotifier extends _$RatingNotifier {
  @override
  RatingState build(String jobId) => RatingState.initial();

  void setThumb(bool isPositive) {
    state = state.copyWith(isPositive: isPositive, selectedTags: []);
  }

  void toggleTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    state = state.copyWith(selectedTags: tags);
  }

  Future<void> submit() async {
    if (state.isPositive == null) return;
    state = state.copyWith(isSubmitting: true);
    final result = await ref.read(ratingRepositoryProvider).submitRating(
      jobId: jobId,
      isPositive: state.isPositive!,
      tags: state.selectedTags,
    );
    state = result
      ? state.copyWith(isSubmitting: false, isSubmitted: true)
      : state.copyWith(isSubmitting: false, error: 'فشل الإرسال');
  }
}

class RatingState {
  final bool? isPositive;
  final List<String> selectedTags;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? error;
}
```

---

## API Endpoints

### POST /api/ratings
- Auth: Customer JWT or Provider JWT
- Request:
```json
{
  "jobId": "uuid",
  "isPositive": true,
  "tags": ["arrived_on_time", "professional"]
}
```
- Response:
```json
{
  "success": true,
  "data": {
    "ratingId": "uuid",
    "jobId": "uuid",
    "isPositive": true,
    "submittedAt": "ISO8601"
  }
}
```
- Business rules:
  - Determine rater type from JWT audience (`customer` or `provider`)
  - Validate job belongs to the rater (customer_id or provider_id on the job matches JWT sub)
  - Job must be in `Paid` status — return `400 "JOB_NOT_ELIGIBLE_FOR_RATING"` otherwise
  - Check rating window: `now() < paid_at + 48 hours` — return `400 "RATING_WINDOW_EXPIRED"` if late
  - Check no existing rating for this job + direction — return `409 "ALREADY_RATED"` if duplicate
  - On submit: update provider aggregate stats (see below)
  - Tags must be from the allowed list for the rater type — ignore unknown tags silently

### GET /api/ratings/pending
- Auth: Customer JWT or Provider JWT
- Purpose: Check if the user has any unrated jobs within the 48h window
- Response:
```json
{
  "success": true,
  "data": {
    "pendingRatings": [
      {
        "jobId": "uuid",
        "referenceNumber": "KH-20240403-0001",
        "categoryName": "سباكة",
        "paidAt": "ISO8601",
        "expiresAt": "ISO8601",
        "rateTarget": "Ahmad K."
      }
    ]
  }
}
```

### GET /api/providers/{providerId}/rating
- Auth: Public (visible on provider profile)
- Response:
```json
{
  "success": true,
  "data": {
    "totalRatings": 47,
    "positiveCount": 44,
    "negativeCount": 3,
    "positiveRate": 93,
    "topTags": ["arrived_on_time", "professional", "clean_worksite"],
    "completionRate": 96
  }
}
```

---

## Data Model

```sql
-- bookings schema (ratings live here — tied to jobs)

CREATE TABLE bookings.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES bookings.jobs(id) ON DELETE CASCADE,
    rater_id UUID NOT NULL,                         -- customer or provider id
    ratee_id UUID NOT NULL,                         -- the one being rated
    rater_type VARCHAR(20) NOT NULL,                -- 'customer' or 'provider'
    is_positive BOOLEAN NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',              -- array of tag keys
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(job_id, rater_type)                      -- one rating per direction per job
);

CREATE INDEX idx_ratings_ratee_id ON bookings.ratings(ratee_id);
CREATE INDEX idx_ratings_job_id ON bookings.ratings(job_id);

-- Provider aggregate rating stats (denormalised for fast reads)
-- Update this on every new customer→provider rating submission
CREATE TABLE providers.rating_stats (
    provider_id UUID PRIMARY KEY,
    total_ratings INT NOT NULL DEFAULT 0,
    positive_count INT NOT NULL DEFAULT 0,
    negative_count INT NOT NULL DEFAULT 0,
    positive_rate DECIMAL(5, 2) NOT NULL DEFAULT 0, -- percentage 0-100
    top_tags TEXT[] NOT NULL DEFAULT '{}',          -- top 3 tags by frequency
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Update `providers.rating_stats` atomically** in the same DB transaction as the rating insert:
```sql
INSERT INTO providers.rating_stats (provider_id, total_ratings, positive_count, negative_count, positive_rate)
VALUES (@providerId, 1, @positiveIncrement, @negativeIncrement, @rate)
ON CONFLICT (provider_id) DO UPDATE SET
  total_ratings = rating_stats.total_ratings + 1,
  positive_count = rating_stats.positive_count + EXCLUDED.positive_count,
  negative_count = rating_stats.negative_count + EXCLUDED.negative_count,
  positive_rate = ROUND((rating_stats.positive_count + EXCLUDED.positive_count)::decimal
                  / (rating_stats.total_ratings + 1) * 100, 2),
  updated_at = now();
```

Also update `top_tags` after every 10th rating (not on every insert — too expensive). Background service or a simple counter check.

---

## Backend Structure

```
Modules/Bookings/Khudmati.Modules.Bookings/
├── Application/
│   ├── Commands/
│   │   ├── SubmitRatingCommand.cs + Handler + Validator
│   └── Queries/
│       ├── GetPendingRatingsQuery.cs + Handler
│       └── GetProviderRatingQuery.cs + Handler
├── Domain/
│   └── Entities/
│       └── Rating.cs
└── Infrastructure/
    └── Persistence/
        └── RatingRepository.cs

Modules/Providers/Khudmati.Modules.Providers/
└── Infrastructure/
    └── Persistence/
        └── ProviderRatingStatsRepository.cs
```

---

## Edge Cases & Validation

- Customer rates before job is `Paid` → `400 "JOB_NOT_ELIGIBLE_FOR_RATING"`
- Rating submitted after 48h window → `400 "RATING_WINDOW_EXPIRED"`
- Duplicate rating attempt → `409 "ALREADY_RATED"`
- Customer skips rating → no record created, `pending_ratings` no longer returns this job
- Provider with 0 ratings → return `positiveRate: null` (not 0%) so UI shows "لا توجد تقييمات بعد" (No ratings yet) rather than 0%
- Tags from wrong rater type submitted → silently ignored
- Job paid_at timestamp missing (edge case from feature #05 bug) → treat as ineligible, log warning

---

## CLAUDE.md Update After This Feature

Add to root `CLAUDE.md` under Business Rules:
```
- Rating: binary thumbs up/down + optional positive tags — stored in bookings.ratings
- Provider aggregate stats in providers.rating_stats — updated on every customer→provider rating
- Rating window: 48 hours after job Paid status
```

This completes Phase 1. Update the features table:
```
| ✅ | 06 | Post-Job Rating |
```

---

## Out of Scope (do not implement)
- Negative tags — V2
- Written reviews / comments — V2
- Rating appeals or disputes — V2
- Public customer rating profile — V2
- Rating-based commission tiers — V2 (rule is defined in CLAUDE.md but not applied yet)
- Push notification prompting rating — feature #10

---

## Acceptance Criteria
- [ ] Customer can submit thumbs up/down with optional tags after job is `Paid`
- [ ] Provider can submit thumbs up/down with optional tags after job is `Paid`
- [ ] Rating is rejected if submitted outside the 48-hour window
- [ ] Duplicate rating for the same job + direction returns `409`
- [ ] `providers.rating_stats` is updated atomically with the rating insert
- [ ] `GET /api/providers/{id}/rating` returns correct positive rate and top tags
- [ ] `GET /api/ratings/pending` returns only jobs within the 48h window with no rating yet
- [ ] In-app banner on Home screen shows when there is a pending rating
- [ ] Skipping rating dismisses prompt and removes job from pending list
- [ ] Provider with 0 ratings shows "لا توجد تقييمات بعد" not 0%
- [ ] All screens render correctly in RTL Arabic layout

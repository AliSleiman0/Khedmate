# Phase 05 — Provider features

**Depends on:** Phase 01, 02, 03.

Provider-side stack under `lib/features/provider/`. The 2-minute job
countdown, the 3-second GPS broadcast during EnRoute, and the subscription
Stripe SetupIntent path are the incident hotspots — T3 treatment.

## Files touched

### Jobs

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/provider/jobs/data/job_repository.dart` | T2 | 225 | available / active / advance / uploadAfterPhotos |
| `lib/features/provider/jobs/presentation/job_feed_provider.dart` | T2 | 71 | SignalR `NewJobAvailable` subscription |
| `lib/features/provider/jobs/presentation/job_detail_provider.dart` | T3 | 89 | 2-minute countdown, expiry, accept / reject |
| `lib/features/provider/jobs/presentation/active_job_provider.dart` | T3 | 98 | 3-second GPS broadcast during EnRoute |
| `lib/features/provider/jobs/presentation/completed_jobs_provider.dart` | T1 | 45 | GET /providers/me/jobs?status=Paid |
| `lib/features/provider/jobs/presentation/job_feed_screen.dart` | T2 | 417 | Tab switch, empty-state refresh |
| `lib/features/provider/jobs/presentation/job_detail_screen.dart` | T2 | 438 | Accept tap, reject tap, countdown UI |
| `lib/features/provider/jobs/presentation/active_jobs_screen.dart` | T1 | 240 | Rating CTA |
| `lib/features/provider/jobs/presentation/active_job_detail_screen.dart` | T3 | 516 | Status machine: Accepted → EnRoute → Arrived → InProgress → Completed |
| `lib/features/provider/jobs/presentation/upload_after_photos_screen.dart` | T2 | 395 | image_picker + upload + gate to Complete |

### Onboarding

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/provider/onboarding/data/onboarding_api_service.dart` | T2 | 94 | status fetch + doc submit + skill test endpoints |
| `lib/features/provider/onboarding/presentation/onboarding_hub_screen.dart` | T2 | — | Stepper branch decisions |
| `lib/features/provider/onboarding/presentation/id_upload_screen.dart` | T2 | 244 | image_picker + upload |
| `lib/features/provider/onboarding/presentation/skill_test_screen.dart` | T3 | 277 | Session start, per-question answer, submit, 24h cooldown |

### Navigation / earnings

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/provider/navigation/presentation/navigation_page.dart` | T2 | — | Geolocator permission + current position |
| `lib/features/provider/earnings/data/earnings_repository.dart` | T2 | — | earnings + payout status |
| `lib/features/provider/earnings/presentation/earnings_provider.dart` | T2 | 75 | Load + refresh |
| `lib/features/provider/earnings/presentation/earnings_page.dart` | T1 | 342 | |
| `lib/features/provider/earnings/presentation/payout_status_screen.dart` | T2 | 300 | Stripe Connect onboarding link launch |

### Subscription

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/provider/subscription/data/subscription_repository.dart` | T2 | 68 | GET / POST / DELETE /providers/me/subscription |
| `lib/features/provider/subscription/presentation/subscription_provider.dart` | T3 | 58 | SetupIntent + PaymentSheet + SignalR `SubscriptionActivated` |
| `lib/features/provider/subscription/presentation/subscription_screen.dart` | T3 | 511 | Subscribe tap → Stripe SetupIntent path |

### Analytics

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/provider/analytics/data/analytics_repository.dart` | T1 | 39 | 3 endpoints |
| `lib/features/provider/analytics/presentation/analytics_provider.dart` | T2 | — | Future.wait parallel loads, 5-min cache |
| `lib/features/provider/analytics/presentation/analytics_screen.dart` | T1 | 730 | Period chip tap, refresh |

## Per-file log blueprint

### `job_detail_provider.dart` (T3)

Tag: `JobDetailNotifier`. The 2-minute countdown is the hottest part of the
whole app — every timer tick and every state transition gets logged, but
most at `v` so the default view stays clean.

- `build(jobId)` — `d 'build' jobId=$jobId`.
- Countdown start — `i 'countdown start' jobId=$jobId seconds=120`.
- Tick — `v 'tick' jobId=$jobId remaining=$s`.
- Expiry — `w 'expired' jobId=$jobId`.
- `accept()` — `d 'accept start' jobId=$jobId`, `i 'accept ok'` /
  `e 'accept failed' code=$code`.
- `reject(reason)` — `d 'reject start' jobId=$jobId reason=$reason`,
  `i 'reject ok'` / `e 'reject failed'`.

### `active_job_provider.dart` (T3)

Tag: `ActiveJobNotifier`.

- `build(jobId)` — `d 'build' jobId=$jobId`.
- Status transitions — `i 'status' jobId=$jobId from=$old to=$new`.
- GPS broadcast start (when entering EnRoute) — `i 'gps broadcast start'
  jobId=$jobId intervalMs=3000`.
- Each broadcast — `v 'gps push' jobId=$jobId coords=${redactLatLng(...)}`.
- GPS broadcast stop — `i 'gps broadcast stop' jobId=$jobId reason=arrived|disposed|error`.
- GPS errors — `e 'gps failed' error=$e` with stack.

### `active_job_detail_screen.dart` (T3)

Tag: `ActiveJobDetail`. Big file with the status-machine action buttons.

- Each CTA tap: `d 'action tap' jobId=$jobId action=enroute|arrived|start|complete`.
- After the repo call: `i 'action ok' action=…` / `e 'action failed' code=$code`.
- Upload-after-photos gate — `d 'advance blocked reason=no_after_photo'`.
- Chat FAB tap — `d 'chat fab tap' jobId=$jobId`.

### `skill_test_screen.dart` (T3)

Tag: `SkillTest`. Test sessions have a 24h cooldown + per-question timer —
you'll regret not logging these.

- `d 'init' category=$cat`.
- `i 'session start' sessionId=$id total=$n`.
- For each question answered — `d 'answer' q=$idx optionId=$opt`.
- `d 'submit start' sessionId=$id`.
- `i 'session ok' score=$k passed=$b` / `w 'session failed cooldown' cooldownSec=$s`.

### `subscription_provider.dart` + `subscription_screen.dart` (T3)

Tag: `Subscription` (screen) and `SubscriptionNotifier` (provider).

- `subscribe()` branch:
  - `i 'subscribe start'`.
  - `d 'setup intent start'` → `i 'setup intent ok' id=$id
    clientSecret=${redactToken(secret)}`.
  - `d 'sheet present'` → `i 'sheet confirmed'` / `w 'sheet cancelled'` /
    `e 'sheet failed' code=$stripeCode`.
  - `d 'activate api start'` → `i 'activate ok' status=Active
    commissionRate=$r periodEnd=$iso`.
  - SignalR `SubscriptionActivated` received — `i 'signalr activated'`.
- `cancel()` — `d 'cancel start'`, `i 'cancel ok' cancelsAt=$iso`.
- Webhook-triggered SignalR events `SubscriptionPaymentFailed` /
  `SubscriptionCancelled` — `w 'payment failed retryDate=$iso'` /
  `i 'cancelled endsAt=$iso'`.

### `onboarding_api_service.dart` + `id_upload_screen.dart` (T2)

Tag: `Onboarding` (screens) and `OnboardingApi` (service).

- `fetchStatus()` — `d 'status start'`, `i 'status ok' tier=$tier' stepsDone=$n`.
- `uploadDocument(type, file)` — `d 'doc upload start' type=$type bytes=$b`,
  `i 'doc upload ok'` / `e 'doc upload failed'`.
- `id_upload_screen.dart` tap — `d 'pick image' source=camera|gallery`.

### `payout_status_screen.dart` (T2)

Tag: `PayoutStatus`.

- `d 'load start'`, `i 'load ok' status=$status hasPayoutAccount=$b`.
- `d 'connect tap'` → `i 'open external' url=${redactUrl(url)}`.

### `analytics_provider.dart` (T2)

Tag: `AnalyticsNotifier`.

- `load(period)` — `d 'load start' period=$period cache=$hit|miss`.
- For cache hit — `i 'load ok from cache' ageSec=$s`.
- Parallel loads — `d 'parallel fetch start'` → `i 'parallel fetch ok'` /
  `e 'parallel fetch failed' which=earnings|jobs|ratings`.

### `navigation_page.dart` (T2)

Tag: `ProviderNav`.

- `d 'init' jobId=$jobId'`.
- `d 'permission check'` → `i 'permission ok'` or
  `w 'permission denied' level=denied|deniedForever`.
- `d 'get current position'` → `v 'pos' coords=${redactLatLng(...)}` or
  `e 'pos failed' error=$e`.

## Provider-tier gate logging reminder

Phase 02 logs the router redirect to `/provider/onboarding` when
`provider_tier` is not active. No extra logging is needed here — but a
successful onboarding step that bumps the tier should log
`i 'tier bumped' from=$old to=$new` in `OnboardingApi` so the subsequent
redirect reason is traceable.

## Acceptance criteria

- Accepting a job, driving it through EnRoute → Arrived → InProgress →
  Completed produces ≤ 30 `debug`/`info` log lines with the full state
  timeline. GPS `v` lines do not pollute the default view.
- Running the skill test top-to-bottom produces one `i 'session start'` line,
  one per question at `debug`, and one `i 'session ok' passed=true|false`
  line.
- Subscribing to Power Provider produces a 10–14 line Stripe trace ending
  with either `i 'activate ok'` or a typed `e 'sheet failed' code=…`.
- No raw client secret or GPS coordinate pair (at full precision) is
  findable in the log buffer after running the full provider flow.

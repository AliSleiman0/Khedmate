# Feature: Live GPS Tracking

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-customer, mobile-provider)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#07 must be implemented. GPS tracking is active only during `EnRoute` status (feature #04).

## Goal
When a provider marks a job as `EnRoute`, their live location streams to the customer's tracking screen in real time. The customer sees a moving pin on a map until the provider arrives. This replaces the static "provider is on the way" message from feature #04 with actual live location.

## Platforms Affected
- [x] Provider Mobile App (Flutter) — broadcasts location every 3 seconds while EnRoute
- [x] Customer Mobile App (Flutter) — receives location updates, moves pin on map
- [x] Backend (.NET 8) — receives, validates, and relays location via SignalR
- [ ] Admin Panel
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Stories
- As a **customer**, I want to see the provider moving toward me on a map so I know exactly when they'll arrive.
- As a **provider**, I want my location to be shared automatically when I go en route so the customer feels informed without me having to do anything extra.
- As the **platform**, I want location sharing to start and stop automatically based on job status so providers don't need to manage it manually.

---

## How It Works

```
Provider taps "I'm on my way" → status = EnRoute (feature #04)
  ↓
Provider app starts broadcasting location every 3 seconds
  → POST /api/tracking/jobs/{jobId}/location
  ↓
Backend validates and relays via SignalR
  → ProviderLocationUpdated event → customer-{customerId} group
  ↓
Customer map moves provider pin in real time
  ↓
Provider taps "Arrived, start job" → status = InProgress
  → Provider app stops broadcasting
  → Customer map freezes on last known location, shows "وصل المزود" (Provider arrived)
```

---

## Provider App Changes

### Update: Active Job Detail Screen (`lib/features/jobs/presentation/active_job_detail_screen.dart`)
Add location broadcasting logic when status = `EnRoute`:

```dart
// In active_job_provider.dart — start broadcasting when status transitions to EnRoute
void _startLocationBroadcast(String jobId) {
  _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    await ref.read(trackingRepositoryProvider).sendLocation(
      jobId: jobId,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  });
}

void _stopLocationBroadcast() {
  _locationTimer?.cancel();
  _locationTimer = null;
}
```

- Start broadcasting immediately when provider taps "I'm on my way"
- Stop broadcasting when provider taps "Arrived, start job" (transition to `InProgress`)
- Stop broadcasting if app goes to background for > 30 seconds (battery consideration)
- Resume broadcasting if app returns to foreground while status is still `EnRoute`
- Handle location permission denied: show one-time prompt explaining why location is needed — "يحتاج التطبيق إلى موقعك لإعلام العميل بوصولك" — if denied, job can still proceed but customer sees no map

### No UI change on provider side — location broadcast is silent/background.

---

## Customer App Changes

### Update: Job Tracking Screen (`lib/features/booking/presentation/job_tracking_screen.dart`)
Replace static map from feature #04 with a live tracking map during `EnRoute` status.

**Layout during EnRoute:**
- Full-width map (flutter_map + OpenStreetMap tiles) taking ~55% of screen height
- Two pins on the map:
  - 📍 Customer location pin — static, brand blue, labelled "موقعك" (Your location)
  - 🚗 Provider pin — amber, animated (smooth movement between location updates), labelled provider first name
- Map auto-fits to show both pins with padding
- Distance label below map: "المسافة المتبقية: ٢.٣ كم" (Distance remaining: 2.3 km) — calculated from current provider coords to customer coords using Haversine formula
- Status banner: "المزود في الطريق إليك" — yellow background (unchanged from feature #04)
- Provider name + category shown below map

**Smooth pin movement:**
Use a `Tween` animation to smoothly interpolate the provider pin between location updates rather than jumping. Duration: 2.5 seconds (slightly less than the 3-second update interval for a fluid effect).

```dart
// In job_tracking_provider.dart
void _subscribeToProviderLocation() {
  ref.read(signalRServiceProvider).on('ProviderLocationUpdated', (data) {
    if (data['jobId'] == jobId) {
      final newLat = data['latitude'] as double;
      final newLng = data['longitude'] as double;
      state = AsyncData(state.value!.copyWith(
        providerLatitude: newLat,
        providerLongitude: newLng,
      ));
    }
  });
}
```

**When status transitions to InProgress (provider arrived):**
- Stop listening for location updates
- Freeze provider pin at last known location
- Replace distance label with: "وصل المزود! جاري تنفيذ الخدمة" (Provider arrived! Service in progress) — amber banner
- Map stays visible but static

**Fallback if no location updates received for > 15 seconds:**
- Show subtle message under map: "يتم تحديث الموقع..." (Updating location...)
- Do not hide the map or show an error — just indicate loading

---

## State Management

### Tracking State (`lib/features/booking/presentation/job_tracking_provider.dart`)
Extend the existing `JobTrackingNotifier` from feature #04:

```dart
class JobTrackingState {
  final JobDetail job;
  final double? providerLatitude;      // null until first update received
  final double? providerLongitude;
  final double? distanceKm;            // calculated client-side from provider coords
  final DateTime? lastLocationUpdate;  // used to show "updating..." fallback
}
```

Distance calculation (Haversine — implement in `lib/core/utils/distance_utils.dart`):
```dart
double calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0; // Earth radius in km
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}
```

---

## API Endpoint

### POST /api/tracking/jobs/{jobId}/location
- Auth: Provider JWT
- Request:
```json
{
  "latitude": 33.8869,
  "longitude": 35.5131
}
```
- Response: `{ "success": true }`
- Business rules:
  - Validate provider owns this job (`job.provider_id = providerId from JWT`)
  - Validate job status = `EnRoute` — reject with `400 "TRACKING_NOT_ACTIVE"` if not EnRoute
  - Validate coordinates: lat must be -90 to 90, lng must be -180 to 180
  - Upsert provider location in `providers.locations` (already exists from feature #03)
  - **Do not store location history** — just relay via SignalR and update current location
  - Fire SignalR `ProviderLocationUpdated` event immediately after upsert

This endpoint is called every 3 seconds — keep it as fast as possible. No complex logic, no heavy queries. Just validate, upsert one row, fire SignalR.

---

## Backend Changes

### New controller
```
Khudmati.API/Controllers/Tracking/TrackingController.cs
```

### New command
```
Modules/Bookings/Khudmati.Modules.Bookings/Application/Commands/
  UpdateProviderLocationCommand.cs
  UpdateProviderLocationCommandHandler.cs
```

Handler logic:
```csharp
public async Task<Result<bool>> Handle(UpdateProviderLocationCommand request, CancellationToken ct)
{
    var job = await _jobs.GetByIdAsync(request.JobId, ct);
    if (job is null || job.ProviderId != request.ProviderId)
        return Result<bool>.Fail("Job not found.");

    if (job.Status != JobStatus.EnRoute)
        return Result<bool>.Fail("TRACKING_NOT_ACTIVE");

    await _locationRepo.UpsertAsync(request.ProviderId, request.Latitude, request.Longitude, ct);

    await _hubContext.Clients
        .Group($"customer-{job.CustomerId}")
        .SendAsync("ProviderLocationUpdated", new
        {
            JobId = job.Id,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Timestamp = DateTime.UtcNow
        }, ct);

    return Result<bool>.Ok(true);
}
```

No new DB tables needed — `providers.locations` from feature #03 already stores current location.

---

## Real-time / SignalR Events

| Event | Fired when | Sent to | Payload |
|---|---|---|---|
| `ProviderLocationUpdated` | Provider sends location update | `customer-{customerId}` | `{ jobId, latitude, longitude, timestamp }` |

---

## Permissions

**Provider app:** Request `ACCESS_FINE_LOCATION` (Android) and `NSLocationWhenInUseUsageDescription` (iOS).
Show permission rationale before requesting: "يحتاج التطبيق إلى موقعك أثناء التنقل لإعلام العميل بوصولك".
Use `geolocator` Flutter package.

**Customer app:** Request location permission only for the "Use my current location" button on the booking screen (already done in feature #02). No new permissions needed for the tracking screen — customer location is already known from the booking.

---

## Battery & Performance Considerations

- Provider broadcasts every **3 seconds** during EnRoute only — not during the entire job
- Average EnRoute duration: 5–15 minutes → 100–300 location updates per job — acceptable
- Use `LocationAccuracy.high` on provider side for accuracy
- Stop all location work immediately on status change to InProgress — no lingering timers
- If provider app is killed (force-closed) while EnRoute: customer sees "updating location..." fallback after 15 seconds. Job continues normally — no auto-transition.

---

## CLAUDE.md Update After This Feature

Add to SignalR events in root `CLAUDE.md`:
```
- `ProviderLocationUpdated` → `customer-{customerId}`
```

---

## Edge Cases & Validation

- Provider sends location while status is not `EnRoute` → `400 "TRACKING_NOT_ACTIVE"` — silently ignored on Flutter side (timer just gets no-op response)
- Customer has no internet during EnRoute → map shows last known pin position, fallback message shows after 15s
- Provider location permission denied → job proceeds, customer sees static map with "تعذر تحديد موقع المزود" (Cannot determine provider location) message — not a blocking error
- Provider coordinates wildly off (e.g. 0,0 default) → validate: reject coordinates where lat=0 AND lng=0 exactly (common GPS initialisation artifact)
- Multiple rapid location updates arrive out of order on customer → use `timestamp` field to discard older updates if a newer one is already applied

---

## Out of Scope (do not implement)
- Location history / route replay — V2
- ETA calculation (requires routing API like Google Maps Directions) — V2
- Geofencing (auto-trigger InProgress when provider arrives within X meters) — V2
- Background location on iOS (requires always-on permission) — V2
- Provider location visible to admin in real time — feature #12

---

## Acceptance Criteria
- [ ] Provider location broadcasts every 3 seconds automatically when job status = `EnRoute`
- [ ] Broadcasting stops automatically when status transitions to `InProgress`
- [ ] Customer map shows provider pin moving smoothly toward customer location
- [ ] Distance label updates with each location ping
- [ ] Customer sees "وصل المزود" message when provider transitions to InProgress
- [ ] If no location updates for 15 seconds, customer sees "updating location..." indicator
- [ ] Location endpoint returns `400` if job is not in `EnRoute` status
- [ ] Coordinates 0,0 are rejected by the API
- [ ] Provider location permission denial does not crash the app or block the job
- [ ] All screens render correctly in RTL Arabic layout

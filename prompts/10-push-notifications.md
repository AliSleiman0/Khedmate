# Feature: Push Notifications (Phase 2 — Trust)

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module); `public.notifications` table already exists
- Real-time: SignalR (already live for all events) — push is the *offline/background* complement
- Frontend(s): Flutter (Customer App + Provider App)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context

## Goal
Deliver FCM push notifications to customers and providers when they are **offline or backgrounded**, covering every meaningful lifecycle event already fired via SignalR. This closes the trust gap where users miss critical updates (job accepted, payment released, verification approved) because they aren't actively in the app.

## Platforms Affected
- [x] Customer Mobile App (`mobile-customer/`)
- [x] Provider Mobile App (`mobile-provider/`)
- [x] Backend (`backend/`)
- [ ] Web Landing Page
- [ ] Web Admin Panel
- [ ] Web Super Admin Panel

---

## User Stories
- As a **customer**, I want to receive a push notification when my job is accepted, when the provider is en route, and when payment is confirmed, so I stay informed without keeping the app open.
- As a **provider**, I want to receive a push notification when a new job is available (if I miss the SignalR alert), when my verification tier changes, and when my payout is released.

---

## Notification Events to Implement

| Trigger | Recipient | Title (AR) | Body (AR) |
|---|---|---|---|
| Job `Pending → Accepted` | Customer | طلبك قُبل ✅ | مزود الخدمة في طريقه إليك قريباً |
| Job `Accepted → EnRoute` | Customer | المزود في الطريق 🚗 | تتبّع موقعه الآن من التطبيق |
| Job `InProgress → Completed` | Customer | اكتملت الخدمة 🎉 | يرجى تقييم تجربتك |
| `PaymentHeld` | Customer | تم الدفع بنجاح 💳 | مبلغ {amount} محجوز لحين التأكيد |
| `PaymentReleased` | Provider | تم تحويل أرباحك 💰 | استلمت {netAmount} في حسابك |
| `NewJobAvailable` (fallback) | Provider | وظيفة جديدة قريبة منك! 🔔 | {categoryName} — {district} |
| `VerificationStatusChanged` (approved) | Provider | تم التحقق من حسابك ✅ | يمكنك الآن استقبال الطلبات |
| `VerificationStatusChanged` (rejected) | Provider | مراجعة مطلوبة ❌ | يرجى إعادة رفع مستنداتك |

---

## Backend Changes

### 1. Device Token Registration

#### New table: `public.device_tokens`
```sql
CREATE TABLE public.device_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id    UUID NOT NULL,
    owner_type  TEXT NOT NULL CHECK (owner_type IN ('customer', 'provider')),
    fcm_token   TEXT NOT NULL,
    platform    TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ,
    UNIQUE (owner_id, platform)  -- one token per platform per user
);
```

Add EF config in `Program.cs` → `AppDbContext.AdditionalModelConfiguration`:
```csharp
modelBuilder.Entity<DeviceToken>(e => e.ToTable("device_tokens", "public"));
```

#### New entity: `Khudmati.Modules.Notifications/Domain/Entities/DeviceToken.cs`
```csharp
public class DeviceToken : AuditableEntity
{
    public Guid OwnerId { get; private set; }
    public string OwnerType { get; private set; } = string.Empty; // "customer" | "provider"
    public string FcmToken { get; private set; } = string.Empty;
    public string Platform { get; private set; } = string.Empty;  // "android" | "ios"

    private DeviceToken() { }

    public static DeviceToken Create(Guid ownerId, string ownerType, string fcmToken, string platform) =>
        new() { OwnerId = ownerId, OwnerType = ownerType, FcmToken = fcmToken, Platform = platform };

    public void UpdateToken(string newToken) { FcmToken = newToken; SetUpdated(); }
}
```

### 2. Device Token API Endpoint

#### POST /api/notifications/device-token
- **Auth:** Customer JWT or Provider JWT
- **Request:** `{ "fcmToken": string, "platform": "android" | "ios" }`
- **Response:** `{ "success": true }`
- **Logic:** Upsert by `(ownerId, platform)` — update token if row exists, insert otherwise.
- **Controller:** `Khudmati.API/Controllers/Notifications/NotificationsController.cs`
- **Command:** `Khudmati.Modules.Notifications/Application/Commands/RegisterDeviceTokenCommand.cs`

#### GET /api/notifications
- **Auth:** Customer JWT or Provider JWT
- **Query params:** `page` (default 1), `pageSize` (default 20)
- **Response:** `{ "success": true, "data": { "items": [NotificationDto], "totalCount": int } }`
- **Logic:** Return persisted notifications for the caller from `public.notifications`, ordered by `created_at DESC`. Use existing `Notification` entity.

#### POST /api/notifications/{id}/read
- **Auth:** Customer JWT or Provider JWT
- **Response:** `{ "success": true }`
- **Logic:** Call `notification.MarkRead()` — only owner can mark their own notification read (validate `RecipientId` matches token sub).

### 3. Push Service

#### Interface: `Khudmati.Modules.Notifications/Application/IPushNotificationService.cs`
```csharp
public interface IPushNotificationService
{
    Task SendAsync(Guid recipientId, string recipientType, string title, string body,
                   Dictionary<string, string>? data = null, CancellationToken ct = default);
}
```

#### Implementation: `Khudmati.Modules.Notifications/Infrastructure/FcmPushNotificationService.cs`
- Use `FirebaseAdmin` NuGet package (`FirebaseAdmin` v2.x).
- Initialize `FirebaseApp` once at startup from `appsettings.json` key `Firebase:ServiceAccountJson` (path to service account JSON file) or `Firebase:CredentialsJson` (raw JSON string for production secrets).
- Lookup all `DeviceToken` rows for `(recipientId, recipientType)`.
- For each token, send `Message` with `Notification { Title, Body }` + `Data` dictionary.
- On `FirebaseMessagingException` with `ErrorCode.Unregistered` or `ErrorCode.InvalidArgument` → delete the stale token from DB silently.
- Register in `NotificationsModule.cs` as `IServiceCollection.AddScoped<IPushNotificationService, FcmPushNotificationService>()`.

#### appsettings.json — add:
```json
"Firebase": {
  "ServiceAccountPath": "firebase-service-account.json"
}
```

### 4. Persist + Push in Each Event Handler

For every event listed in the table above, update the existing event handler in `backend/src/Khudmati.API/EventHandlers/` to:
1. Inject `IPushNotificationService` and `AppDbContext` (or a `INotificationRepository`).
2. Create and persist a `Notification` entity (reuse existing `Notification.Create()`).
3. Call `IPushNotificationService.SendAsync(...)` with matching title/body.
4. Keep the existing SignalR `SendAsync` call unchanged — push is additive.

**Handlers to update:**
- `JobAcceptedEventHandler.cs` — notify customer (`Pending → Accepted`)
- `JobStatusChangedEventHandler.cs` — notify customer for `EnRoute` and `Completed` transitions
- `PaymentHeldEventHandler.cs` — notify customer
- `PaymentReleasedEventHandler.cs` — notify provider
- `JobCreatedEventHandler.cs` — notify providers via FCM as fallback (send to all registered provider tokens in `providers-available` group, or load Active provider tokens from DB)
- `VerificationStatusChangedEventHandler.cs` — notify provider

### 5. INotificationRepository (if not already present)

Create `Khudmati.Modules.Notifications/Infrastructure/Persistence/NotificationRepository.cs`:
```csharp
public interface INotificationRepository
{
    Task AddAsync(Notification notification, CancellationToken ct = default);
    Task<(IReadOnlyList<Notification> Items, int TotalCount)> GetByRecipientAsync(
        Guid recipientId, string recipientType, int page, int pageSize, CancellationToken ct = default);
    Task<Notification?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}
```

---

## Flutter Changes (Both Apps)

Both `mobile-customer/` and `mobile-provider/` follow the same pattern.

### Dependencies to add in `pubspec.yaml`
```yaml
firebase_core: ^2.27.0
firebase_messaging: ^14.9.0
flutter_local_notifications: ^17.0.0
```

### 1. Firebase Initialization

In `lib/main.dart` (both apps), before `runApp`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await FirebaseMessaging.instance.requestPermission();
```

Add generated `lib/firebase_options.dart` (via `flutterfire configure`). Document this step — do not hardcode credentials.

### 2. FCM Service: `lib/core/services/fcm_service.dart`

Responsibilities:
- On app start: get token → call `POST /api/notifications/device-token` with platform.
- Listen to `FirebaseMessaging.onMessage` (foreground) → show local notification via `flutter_local_notifications`.
- Listen to `FirebaseMessaging.onMessageOpenedApp` (tapped from background) → navigate to relevant screen using GoRouter.
- Handle `FirebaseMessaging.onBackgroundMessage` (static top-level handler) → no navigation, system tray only.
- Refresh token via `onTokenRefresh` stream → re-register with backend.

### 3. Deep-link Navigation on Tap

When a push notification is tapped, use `data` payload to navigate:

| `data.type` | Navigate to (Customer) | Navigate to (Provider) |
|---|---|---|
| `job_accepted` | `/tracking/{jobId}` | — |
| `job_en_route` | `/tracking/{jobId}` | — |
| `job_completed` | `/rating/{jobId}` | — |
| `payment_held` | `/payment/status/{jobId}` | — |
| `payment_released` | — | `/payout-status` |
| `new_job` | — | `/jobs` (feed) |
| `verification_changed` | — | `/onboarding` |

### 4. Notification Inbox Screen: `lib/features/notifications/presentation/notifications_screen.dart`

- **Route:** `/notifications`
- **Data:** Calls `GET /api/notifications` (paginated).
- **Repository:** `lib/features/notifications/data/notifications_repository.dart`
- **Provider:** `lib/features/notifications/presentation/notifications_provider.dart`
- **UI:**
  - `AppBar` with title "الإشعارات"
  - `ListView` of notification cards: icon by type, bold title, body text, relative time (e.g. "منذ ساعتين"), unread indicator (blue dot using `#1B4F72`)
  - Tap → `PATCH /api/notifications/{id}/read` + navigate per deep-link table above
  - Empty state: centered icon + "لا توجد إشعارات بعد"
  - Pull-to-refresh

### 5. Unread Badge on Home / Navigation Bar

- Add a `notificationsBadgeProvider` (Riverpod) that fetches total unread count.
- Show amber `#F39C12` badge on the notifications bell icon in:
  - Customer: `lib/features/home/presentation/home_page.dart` (bell `IconButton` already present at line 32)
  - Provider: navigation bar

---

## Data Model Summary

| Table | Schema | New? |
|---|---|---|
| `notifications` | `public` | Exists — no change |
| `device_tokens` | `public` | **New** |

---

## Edge Cases & Validation

- Do not send push if `fcm_token` is unknown for the user — skip silently, still persist the `Notification` row.
- Stale/invalid FCM tokens → delete from `device_tokens` on `Unregistered` error; never crash the event handler.
- `NewJobAvailable` push to providers: only target `Active` tier providers. Load their device tokens from DB filtered by `owner_type = 'provider'` + cross-reference Active provider IDs from `providers` table. Avoid broadcasting to all registered tokens.
- Multiple devices per user (e.g. phone + tablet) — table has UNIQUE on `(owner_id, platform)`, so one token per platform. Fan-out to all matching rows for the user.
- Token registration must be idempotent — same token re-registered after app reinstall should upsert cleanly.
- Notification inbox only shows the last 100 notifications maximum; older ones are not deleted, just not surfaced.
- Mark-as-read only permitted by the notification's owner; return `403` if sub doesn't match `RecipientId`.
- Arabic copy is the source of truth; English fallback strings are not required in V1.

---

## Out of Scope (do not implement)
- Web push / browser notifications
- Notification preferences / opt-out settings per category
- Email or SMS notifications
- Admin-authored broadcast notifications
- Scheduled / delayed notifications
- Rich media push (images in notification)
- Per-notification sound customisation

---

## Acceptance Criteria
- [ ] `POST /api/notifications/device-token` upserts token correctly for both customer and provider JWTs
- [ ] `GET /api/notifications` returns paginated, ordered notifications for the authenticated user only
- [ ] `POST /api/notifications/{id}/read` marks notification read; returns 403 if caller is not the owner
- [ ] FCM push delivered when customer's job transitions to `Accepted`, `EnRoute`, `Completed`
- [ ] FCM push delivered to provider when payment is released
- [ ] FCM push delivered to provider when verification status changes
- [ ] Stale FCM token is deleted from DB on `Unregistered` error without crashing the handler
- [ ] Foreground push displays as local notification via `flutter_local_notifications`
- [ ] Tapping a push notification deep-links to the correct screen
- [ ] Notification inbox screen loads, shows unread dot, marks read on tap, and has empty state
- [ ] Unread badge counter visible on home bell icon (customer) and nav bar (provider)
- [ ] All UI strings are in Arabic; layout is RTL-correct
- [ ] Existing SignalR events are unaffected (push is additive only)

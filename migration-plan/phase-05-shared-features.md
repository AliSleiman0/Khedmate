# Phase 05 — Shared Features (Chat, Notifications, Profile, Rating)

## Goal
Port the four feature areas that both roles use, into `lib/features/shared/`. These are role-agnostic at the UI layer; they branch on role only at the API call site.

## Why this phase
Done before role-specific features because both customer and provider screens will need to navigate into chat, notifications, profile, and rating. If we port them later we risk duplicating.

## Pre-requisites
- Phase 04 complete (auth works, `fetchMe` returns real user)
- `authProvider`, `roleProvider`, `apiClient` all wired

## Scope

### 1. Port Chat
**Sources:**
- `mobile-customer/lib/features/chat/` (~95% identical to provider's)
- `mobile-provider/lib/shared/widgets/chat/` (cleaner shared widgets: `ChatMessageList`, `ChatInputBar`)

Target: `mobile/lib/features/shared/chat/`

Files:
- `chat_screen.dart` — unified; message bubble alignment determined by `senderType == currentUserRole`
- `chat_provider.dart` — SignalR `NewChatMessage` subscription + REST load history
- `chat_repository.dart` — `GET /bookings/jobs/{jobId}/chat`, `POST /bookings/jobs/{jobId}/chat`
- `widgets/chat_message_list.dart` — reused
- `widgets/chat_input_bar.dart` — reused

Route: `/chat/:jobId` (both roles)

### 2. Port Notifications
**Source:** `mobile-customer/lib/features/notifications/` (provider's is near-identical)

Target: `mobile/lib/features/shared/notifications/`

Files:
- `notifications_screen.dart` — list with unread badge, tap → navigation handler
- `notifications_provider.dart` — paginated list, mark-as-read
- `notification_repository.dart` — `GET /notifications?role=<>` (role sent as query param so backend returns role-appropriate types)

**Tap handler (critical)** — reads `roleProvider` then picks destination:
```dart
void onNotificationTap(AppNotification n) {
  final role = ref.read(roleProvider);
  switch (n.type) {
    case 'JOB_ACCEPTED':
      role == UserRole.customer
        ? context.push('/tracking/${n.jobId}')
        : context.push('/active-job/${n.jobId}');
      break;
    case 'MAINTENANCE_REMINDER':
      if (role == UserRole.customer) context.push('/reminders');
      break;
    case 'VERIFICATION_APPROVED':
    case 'VERIFICATION_REJECTED':
      if (role == UserRole.provider) context.push('/onboarding');
      break;
    // ... other types
  }
}
```

### 3. Port Profile
**Sources:**
- `mobile-customer/lib/features/profile/` — customer profile + edit
- `mobile-provider/lib/features/profile/` — provider profile + edit (has more tiles: verification, payment, work hours)

Target: `mobile/lib/features/shared/profile/`

Structure:
- `profile_page.dart` — shell; renders role-specific tile list via `profile_tiles_customer.dart` / `profile_tiles_provider.dart` branched on `roleProvider`
- `profile_tiles_customer.dart` — Edit Profile, Language, Help, About, Coming-Soon tiles (Addresses/Payments/Notifications), Logout
- `profile_tiles_provider.dart` — Edit Profile, Verification → `/onboarding`, Payment → `/payout-status`, Subscription → `/subscription`, Analytics → `/analytics`, Work Hours (Coming Soon), Language, Help, Logout
- `edit_profile_screen.dart` — form (name + email), role-aware endpoint: `PATCH /customers/me` or `PATCH /providers/me`

Route: `/profile` (inside role-specific shell in Phase 6/7), `/profile/edit`

### 4. Port Rating
**Source:** `mobile-customer/lib/features/rating/` + `mobile-provider/lib/features/rating/`

Both apps show a rating bottom sheet after a job reaches `Paid`. Customer rates provider (thumbs up/down + tags), provider rates customer (star + optional comment).

Target: `mobile/lib/features/shared/rating/`

Files:
- `rating_bottom_sheet.dart` — two layouts branched on role:
  - customer variant: thumbs up/down + tag chips
  - provider variant: 1–5 stars + comment
- `rating_repository.dart` — `POST /bookings/jobs/{jobId}/rating` (payload differs by role; backend expects both shapes)

### 5. Update app_strings.dart
Every string in these four ported features must use `S.of(ref)`. No hardcoded Arabic. Cross-check against the merged l10n file from Phase 2 — add any keys still missing.

### 6. Wire into router (temporary routes)
Until Phase 6/7 add the shells, register the routes at top level under the auth guard:
- `/chat/:jobId`
- `/notifications`
- `/profile`
- `/profile/edit`

## Files to create
- `mobile/lib/features/shared/chat/**` (5 files)
- `mobile/lib/features/shared/notifications/**` (3 files)
- `mobile/lib/features/shared/profile/**` (4 files)
- `mobile/lib/features/shared/rating/**` (2 files)

## Files to modify
- `mobile/lib/app/router.dart` — add the four routes
- `mobile/lib/core/l10n/app_strings.dart` — any missing keys

## Verification
- **Chat** — create a test job via backend (or via one of the old apps), open `/chat/<jobId>` as customer and send message, confirm provider side receives via SignalR on the old provider app (proves the hub still works with role-aware JWT)
- **Notifications** — list loads for both roles; tap routing verified for at least 3 notification types per role
- **Profile** — name, phone, email display correctly; edit saves successfully; language tile toggles locale
- **Rating** — submit as customer on a paid job, submit as provider on a paid job

## Exit criteria
- [ ] All four feature areas route-reachable and functional
- [ ] No hardcoded strings (Arabic or English) in these features
- [ ] Profile shows role-appropriate tile list
- [ ] `flutter analyze` clean
- [ ] Commit: `feat(mobile): shared features — chat/notifications/profile/rating`

## Rollback
- Revert commit. These features remain available in the old apps.

# Feature: In-App Chat

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-customer, mobile-provider)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#08 must be implemented. Chat is scoped per job — only active between job `Accepted` and `Completed`.

## Goal
Add in-app messaging between customer and provider for a specific job. Messages are sent and received in real time via SignalR and persisted to the database. Chat is available from the moment a provider accepts a job until the job is marked Completed. This removes the need to exchange phone numbers and keeps all communication on-platform.

## Platforms Affected
- [x] Customer Mobile App (Flutter)
- [x] Provider Mobile App (Flutter)
- [x] Backend (.NET 8)
- [ ] Admin Panel — chat log visible in dispute review (feature #13)
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Stories
- As a **customer**, I want to message the provider about my job so I can clarify details without sharing my phone number.
- As a **provider**, I want to message the customer to confirm arrival time or ask about the job so I arrive prepared.
- As the **platform**, I want all communication to stay on-platform so we have a record for disputes and both sides feel safe.

---

## Chat Scope & Lifecycle

- One chat thread per job — keyed by `jobId`
- Chat opens when job reaches `Accepted` status
- Chat closes (read-only) when job reaches `Completed` or `Expired`
- Messages are persisted — chat history is available even after the job ends (for dispute evidence in feature #13)
- No chat between strangers — only the customer and provider assigned to a specific job can message each other

---

## Customer App Changes

### Update: Job Tracking Screen (`lib/features/booking/presentation/job_tracking_screen.dart`)
Add a chat FAB (Floating Action Button) in the bottom-right corner when job status is `Accepted`, `EnRoute`, or `InProgress`:
- Icon: chat bubble, brand blue background
- Unread badge count on FAB when there are unread messages
- Tapping → navigates to Chat Screen

### New Screen: Chat Screen (`lib/features/chat/presentation/chat_screen.dart`)
Standard messaging UI:

**Layout:**
- AppBar: provider first name + "محادثة" (Chat), back arrow
- Message list (scrollable, newest at bottom):
  - Customer messages: right-aligned, brand blue bubble, white text
  - Provider messages: left-aligned, light grey bubble, dark text
  - Timestamp under each message: "10:34 ص" (Arabic time format)
  - Date separator chips between messages from different days: "اليوم" (Today), "أمس" (Yesterday), full date otherwise
- Input row at bottom:
  - Text field: "اكتب رسالة..." (Write a message...) — multiline, max 3 lines before scrolling
  - Send button: amber circle with send icon — disabled when field is empty
- When job is `Completed`: show read-only banner at top "انتهت المحادثة" (Conversation ended) — input row hidden
- Auto-scroll to bottom on new message
- Mark messages as read when screen is open

---

## Provider App Changes

### Update: Active Job Detail Screen (`lib/features/jobs/presentation/active_job_detail_screen.dart`)
Same chat FAB as customer side — bottom-right, with unread badge.

### New Screen: Chat Screen (`lib/features/chat/presentation/chat_screen.dart`)
Identical to customer chat screen. Provider messages are right-aligned (provider is the "self" side), customer messages are left-aligned. AppBar shows customer first name.

---

## Shared Chat Widget
Extract the message bubble and list rendering into a shared widget at:
`lib/shared/widgets/chat/chat_message_list.dart`
`lib/shared/widgets/chat/chat_input_bar.dart`

Both apps import from `lib/shared/` — avoids duplicating chat UI code.

---

## State Management

### Chat Notifier (`lib/features/chat/presentation/chat_provider.dart`)
```dart
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  Future<ChatState> build(String jobId) async {
    final messages = await ref.read(chatRepositoryProvider).getMessages(jobId);
    _subscribeToMessages(jobId);
    await ref.read(chatRepositoryProvider).markAsRead(jobId);
    return ChatState(messages: messages, isSending: false);
  }

  void _subscribeToMessages(String jobId) {
    ref.read(signalRServiceProvider).on('NewChatMessage', (data) {
      if (data['jobId'] == jobId) {
        final message = ChatMessage.fromJson(data);
        state = AsyncData(state.value!.copyWith(
          messages: [...state.value!.messages, message],
        ));
        // Mark as read immediately if screen is open
        ref.read(chatRepositoryProvider).markAsRead(jobId);
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    state = AsyncData(state.value!.copyWith(isSending: true));
    await ref.read(chatRepositoryProvider).sendMessage(jobId: jobId, text: text.trim());
    state = AsyncData(state.value!.copyWith(isSending: false));
    // Incoming message will arrive via SignalR and be added by _subscribeToMessages
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
}
```

### Unread Count Provider (for FAB badge)
```dart
@riverpod
Future<int> unreadMessageCount(UnreadMessageCountRef ref, String jobId) async {
  return ref.read(chatRepositoryProvider).getUnreadCount(jobId);
}
```
Invalidate this provider whenever `NewChatMessage` is received in the background (when chat screen is not open).

---

## API Endpoints

### GET /api/chat/jobs/{jobId}/messages
- Auth: Customer JWT or Provider JWT
- Query params: `page=1&pageSize=50` (load latest 50, paginate backwards for history)
- Response:
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "id": "uuid",
        "jobId": "uuid",
        "senderId": "uuid",
        "senderType": "customer",
        "text": "متى ستصل؟",
        "sentAt": "ISO8601",
        "isRead": true
      }
    ],
    "totalCount": 12,
    "page": 1
  }
}
```
- Business rules:
  - Only the customer or provider of this job can fetch messages — return `403` otherwise
  - Return messages ordered by `sent_at ASC`

### POST /api/chat/jobs/{jobId}/messages
- Auth: Customer JWT or Provider JWT
- Request: `{ "text": "string" }`
- Response:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "text": "متى ستصل؟",
    "sentAt": "ISO8601"
  }
}
```
- Business rules:
  - Only customer or provider of this job can send — `403` otherwise
  - Job must be in `Accepted`, `EnRoute`, or `InProgress` status — return `400 "CHAT_NOT_AVAILABLE"` if Completed/Expired
  - Text max 1000 characters, cannot be empty or whitespace only
  - Persist message to DB
  - Fire SignalR `NewChatMessage` event to the **other party** only (not the sender)
  - Determine recipient: if sender is customer → send to `provider-{providerId}` group; if sender is provider → send to `customer-{customerId}` group

### POST /api/chat/jobs/{jobId}/read
- Auth: Customer JWT or Provider JWT
- Request: (empty body)
- Response: `{ "success": true }`
- Business rules: Mark all messages in this job thread as read for the calling user. Update `read_at` on unread messages where `sender_type != calling_user_type`.

### GET /api/chat/jobs/{jobId}/unread-count
- Auth: Customer JWT or Provider JWT
- Response: `{ "success": true, "data": { "unreadCount": 3 } }`
- Business rules: Count messages in thread where `sender_type != calling_user_type` AND `read_at IS NULL`

---

## Data Model

```sql
-- bookings schema (chat is scoped to jobs)

CREATE TABLE bookings.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES bookings.jobs(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    sender_type VARCHAR(20) NOT NULL,       -- 'customer' or 'provider'
    text TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at TIMESTAMPTZ                     -- null = unread by recipient
);

CREATE INDEX idx_chat_messages_job_id ON bookings.chat_messages(job_id, sent_at ASC);
CREATE INDEX idx_chat_messages_unread ON bookings.chat_messages(job_id, read_at)
  WHERE read_at IS NULL;
```

---

## Backend Structure

```
Modules/Bookings/Khudmati.Modules.Bookings/
├── Application/
│   ├── Commands/
│   │   ├── SendChatMessageCommand.cs + Handler + Validator
│   │   └── MarkMessagesReadCommand.cs + Handler
│   ├── Queries/
│   │   ├── GetChatMessagesQuery.cs + Handler
│   │   └── GetUnreadMessageCountQuery.cs + Handler
│   └── DTOs/
│       └── ChatMessageDto.cs
├── Domain/
│   └── Entities/
│       └── ChatMessage.cs
└── Infrastructure/
    └── Persistence/
        └── ChatMessageRepository.cs

Khudmati.API/Controllers/
└── Chat/
    └── ChatController.cs
```

---

## Real-time / SignalR Events

| Event | Fired when | Sent to | Payload |
|---|---|---|---|
| `NewChatMessage` | Message sent | The other party only (`customer-{id}` or `provider-{id}`) | `{ jobId, id, senderId, senderType, text, sentAt }` |

The sender does NOT receive their own message via SignalR — it's already in their local state from the optimistic UI or API response.

---

## CLAUDE.md Update After This Feature

Add to SignalR events:
```
- `NewChatMessage` → customer-{customerId} or provider-{providerId} (other party only)
```

---

## Edge Cases & Validation

- Message sent when job is `Completed` → `400 "CHAT_NOT_AVAILABLE"` — Flutter shows "انتهت المحادثة" toast
- Message text empty or whitespace → `400` — send button is disabled in UI anyway, but validate on server too
- Message > 1000 chars → `400 "MESSAGE_TOO_LONG"` — show char count in input field, disable send at 1000
- Third party tries to read/send in a job they're not part of → `403`
- Provider sends message to wrong job (stale jobId) → `403` if not their job, `400` if job is closed
- Large message history (100+ messages): paginate with `page` param — Flutter loads previous page on scroll to top
- Both parties send a message simultaneously → both are persisted, both arrive via SignalR — no conflict
- SignalR disconnected when message arrives → message is still in DB, loads on next `GET /messages` call (pull-to-refresh or screen reopen)

---

## Out of Scope (do not implement)
- Image/file attachments in chat — V2
- Message deletion or editing — V2
- Typing indicators — V2
- Message reactions — V2
- Group chat — V2 (multi-provider is V2 anyway)
- Push notification for new chat message — feature #10

---

## Acceptance Criteria
- [ ] Customer and provider can exchange text messages in real time via SignalR
- [ ] Messages are persisted to DB and visible on screen re-open
- [ ] Chat FAB shows unread badge count on job tracking and active job screens
- [ ] Unread count clears when chat screen is opened
- [ ] Messages sent after job `Completed` return `400 "CHAT_NOT_AVAILABLE"`
- [ ] Input row is hidden and banner shown when job is Completed
- [ ] Sender does not receive their own message via SignalR (no duplicate)
- [ ] Only the customer and provider of the specific job can access its chat — third party gets `403`
- [ ] Message history paginates correctly — older messages load on scroll to top
- [ ] Chat message log is stored in DB for future dispute review (feature #13)
- [ ] All screens render correctly in RTL Arabic layout with Arabic text wrapping correctly in bubbles

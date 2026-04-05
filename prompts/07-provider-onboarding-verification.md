# Feature: Provider Onboarding & Verification

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-provider), React TypeScript (web-admin)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#06 must be implemented. Verification tier controls job feed access established in feature #03.

## Goal
Build the full provider onboarding flow after registration: document upload, a 10-question skill test per service category, and a visible verification tier badge. Admins manually review documents and advance tiers. Only providers who reach `Active` tier can see and accept jobs. This is the trust infrastructure that makes the platform safe to launch.

## Platforms Affected
- [x] Provider Mobile App (Flutter) — onboarding flow after registration
- [x] Backend (.NET 8) — tier management, document storage, skill test logic
- [x] Web Admin Panel (React + TypeScript) — admin reviews documents, advances tiers
- [ ] Customer Mobile App — customers see provider tier badge on job accepted screen (small update)
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Stories
- As a **new provider**, I want to upload my ID and complete a skill test so I can get verified and start accepting jobs.
- As a **provider**, I want to see my current verification tier and know what's needed to reach the next level.
- As an **admin**, I want to review uploaded documents and approve or reject them so only legitimate providers get verified.
- As a **customer**, I want to see that my provider is verified so I feel safe letting them into my home.

---

## Verification Tier System

```
Unverified     → registered but nothing submitted yet — cannot see jobs
IdVerified     → ID document uploaded and approved by admin
SkillTested    → passed skill test for at least one service category
PhoneVerified  → phone number verified via OTP (done at registration in feature #01)
Active         → all above complete — can see and accept jobs
```

Tiers are cumulative — a provider must complete all previous tiers to reach `Active`.
Tier is stored on `providers.accounts.verification_tier`.
Only `Active` providers join the `providers-available` SignalR group.

---

## Provider App — Onboarding Flow

Triggered automatically after login if `verification_tier != Active`.
Show as a stepper/progress screen — provider can see exactly where they are.

### Screen: Onboarding Hub (`lib/features/onboarding/presentation/onboarding_hub_screen.dart`)
- Title: "أكمل ملفك الشخصي" (Complete your profile)
- Vertical stepper with 3 steps:
  1. ✅/⏳/❌ **تحقق من الهوية** (ID Verification) — upload ID document
  2. ✅/⏳/❌ **اختبار المهارة** (Skill Test) — 10 questions per category
  3. ✅/⏳ **التحقق من الهاتف** (Phone Verified) — auto-marked done if verified at registration
- Each step shows status: "مكتمل" (Complete) in green, "في الانتظار" (Pending review) in amber, "مطلوب" (Required) in grey
- Tapping an incomplete step navigates into that step's flow
- When all steps complete: show "🎉 حسابك جاهز! يمكنك الآن قبول الطلبات" (Account ready! You can now accept jobs)

### Screen: ID Upload (`lib/features/onboarding/presentation/id_upload_screen.dart`)
- Instructions: "ارفع صورة واضحة من بطاقة هويتك الوطنية أو جواز سفرك" (Upload a clear photo of your national ID or passport)
- Two upload areas: Front of ID + Back of ID (passport: front only)
- Document type selector: National ID / Passport / Residence Permit
- Each upload area: tap → image picker (camera or gallery) → show thumbnail with remove option
- "إرسال للمراجعة" (Submit for review) button — disabled until both sides uploaded (or one for passport)
- After submit: show "تم إرسال وثائقك، سيتم المراجعة خلال 24 ساعة" (Documents submitted, review within 24 hours)
- Status polling: check every 60 seconds while app is in foreground — update step status when approved/rejected

### Screen: Skill Test (`lib/features/onboarding/presentation/skill_test_screen.dart`)
- Provider selects which category to test for first (from their registered categories)
- 10 multiple-choice questions, one at a time, full screen per question
- Progress bar at top: "السؤال 3 من 10"
- Question text in Arabic, 4 answer options (A/B/C/D)
- Tap to select → highlight selection → "التالي" (Next) button activates
- Cannot go back to previous question
- Pass mark: 7/10 correct
- On completion:
  - Pass: "أحسنت! اجتزت الاختبار" (Well done! You passed) — green animation, advance to next step
  - Fail: "لم تجتز الاختبار" (You didn't pass) — show score, "إعادة المحاولة بعد 24 ساعة" (Retry after 24 hours) — enforce cooldown server-side
- Questions are fetched from the API (not hardcoded) — one API call loads all 10 for the session

### Screen: Verification Badge on Profile (`lib/features/profile/presentation/provider_profile_screen.dart`)
- Show current tier as a badge:
  - Unverified: grey badge, padlock icon
  - IdVerified: blue badge "هوية محققة"
  - SkillTested: blue badge + wrench icon "مهارة محققة"
  - Active: green badge + checkmark "مزود نشط ✓"
- Show next step required to advance

---

## Customer App — Small Update

In the Job Accepted screen (feature #03) and provider profile view, show the provider's tier badge next to their name. Just read `verificationTier` from the job detail API response — no new API call needed. Show "مزود نشط ✓" in green for `Active` providers.

---

## Admin Panel — Provider Verification Queue

### New Page: Provider Verification (`web-admin/src/pages/Providers/VerificationQueue/index.tsx`)
- Table of providers with pending document reviews
- Columns: provider name, phone, submitted date, document type, action buttons
- Each row: "عرض الوثائق" (View Documents) button → opens document review modal

### Document Review Modal
- Show uploaded ID images (front + back) at full size, zoomable
- Provider name, phone, registration date
- Two action buttons:
  - "موافقة" (Approve) — green, advances tier to `IdVerified`
  - "رفض" (Reject) — red, with required rejection reason text field
- On approve/reject: row disappears from queue, provider notified via SignalR

### New Page: All Providers (`web-admin/src/pages/Providers/index.tsx`)
- Full list of all providers with filters: by tier, by category, by registration date
- Columns: name, phone, tier badge, categories, jobs completed, rating, joined date
- Clicking a provider → Provider Detail page (read-only in V1: profile info + job history + tier history)

---

## API Endpoints

### POST /api/providers/onboarding/documents
- Auth: Provider JWT
- Request: `multipart/form-data` — fields: `documentType` (string), `frontImage` (file), `backImage` (file, optional)
- Response: `{ "success": true, "data": { "submissionId": "uuid", "status": "PendingReview" } }`
- Business rules:
  - Max file size: 5MB per image. Allowed types: jpg, png, pdf
  - Store files in `wwwroot/uploads/providers/{providerId}/documents/` — return relative URLs
  - Create record in `providers.document_submissions` with status `PendingReview`
  - Only one active submission per provider — if one exists with status `PendingReview`, reject with `409`

### GET /api/providers/onboarding/status
- Auth: Provider JWT
- Response:
```json
{
  "success": true,
  "data": {
    "verificationTier": "IdVerified",
    "steps": {
      "idVerified": { "status": "Complete", "completedAt": "ISO8601" },
      "skillTested": { "status": "PendingReview", "submittedAt": "ISO8601" },
      "phoneVerified": { "status": "Complete", "completedAt": "ISO8601" }
    },
    "canAcceptJobs": false
  }
}
```

### GET /api/providers/skill-test/{categoryId}
- Auth: Provider JWT
- Response:
```json
{
  "success": true,
  "data": {
    "testId": "uuid",
    "categoryId": "plumbing",
    "categoryName": "سباكة",
    "questions": [
      {
        "id": "uuid",
        "questionText": "ما هو السبب الأكثر شيوعاً لتسرب المياه تحت المغسلة؟",
        "options": [
          { "key": "A", "text": "تآكل الحلقة المطاطية" },
          { "key": "B", "text": "انسداد المصيدة" },
          { "key": "C", "text": "ضغط الماء العالي" },
          { "key": "D", "text": "تلف الصنبور" }
        ]
      }
    ]
  }
}
```
- Business rules:
  - Check cooldown: if provider failed in last 24 hours → return `429` with `retryAfter` timestamp
  - Shuffle question order and randomise option order on each fetch (store correct answer key server-side only — never return it)
  - Log that a test session has started in `providers.skill_test_sessions`

### POST /api/providers/skill-test/{categoryId}/submit
- Auth: Provider JWT
- Request:
```json
{
  "testId": "uuid",
  "answers": [
    { "questionId": "uuid", "selectedKey": "A" }
  ]
}
```
- Response:
```json
{
  "success": true,
  "data": {
    "passed": true,
    "score": 8,
    "totalQuestions": 10,
    "passmark": 7,
    "nextRetryAt": null
  }
}
```
- Business rules:
  - Validate `testId` matches an open session for this provider
  - Score answers server-side (never trust client)
  - On pass: update `providers.accounts.verification_tier` if tier conditions met, mark session passed
  - On fail: set `next_retry_at = now() + 24 hours` on the session record
  - Test session expires after 30 minutes (if not submitted, must restart)

### Admin: GET /api/admin/providers/verification-queue
- Auth: Admin JWT
- Response: paginated list of providers with `PendingReview` document submissions

### Admin: POST /api/admin/providers/{providerId}/verify-documents
- Auth: Admin JWT
- Request: `{ "action": "approve" | "reject", "rejectionReason": "string" }`
- Business rules:
  - On approve: update `document_submissions.status = Approved`, advance `verification_tier` to `IdVerified`
  - On reject: update status to `Rejected`, store reason
  - Fire SignalR `VerificationStatusChanged` event to `provider-{providerId}` group
  - Log admin action with `adminId` and timestamp in `providers.tier_history`

### Admin: GET /api/admin/providers
- Auth: Admin JWT
- Query params: `tier`, `categoryId`, `page`, `pageSize`
- Response: paginated provider list with tier, rating stats, job count

---

## Skill Test Questions (seed data)

Seed 10 questions per category into `providers.skill_test_questions`. Categories for V1:
- `plumbing` — سباكة
- `electrical` — كهرباء
- `cleaning` — تنظيف
- `carpentry` — نجارة
- `painting` — دهان
- `ac_maintenance` — تكييف

Write realistic trade questions in Arabic for each category. Each question has 4 options, one correct answer. Store `correct_key` in DB — never expose in API response.

---

## Data Model

```sql
-- providers schema

ALTER TABLE providers.accounts
  ADD COLUMN verification_tier VARCHAR(30) NOT NULL DEFAULT 'Unverified',
  ADD COLUMN service_categories TEXT[] NOT NULL DEFAULT '{}';

-- Document submissions
CREATE TABLE providers.document_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL,
    document_type VARCHAR(30) NOT NULL,           -- NationalId, Passport, ResidencePermit
    front_image_url VARCHAR(500) NOT NULL,
    back_image_url VARCHAR(500),
    status VARCHAR(30) NOT NULL DEFAULT 'PendingReview',
    -- status: PendingReview, Approved, Rejected
    rejection_reason TEXT,
    reviewed_by UUID,                             -- adminId
    reviewed_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_doc_submissions_provider ON providers.document_submissions(provider_id);
CREATE INDEX idx_doc_submissions_status ON providers.document_submissions(status);

-- Tier change history (audit trail)
CREATE TABLE providers.tier_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL,
    previous_tier VARCHAR(30) NOT NULL,
    new_tier VARCHAR(30) NOT NULL,
    changed_by UUID NOT NULL,                     -- adminId or system
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT
);

-- Skill test questions (seed data)
CREATE TABLE providers.skill_test_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id VARCHAR(50) NOT NULL,
    question_text TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_key CHAR(1) NOT NULL,                 -- 'A', 'B', 'C', or 'D'
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Skill test sessions
CREATE TABLE providers.skill_test_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL,
    category_id VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'InProgress',
    -- status: InProgress, Passed, Failed, Expired
    score INT,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    submitted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,              -- started_at + 30 minutes
    next_retry_at TIMESTAMPTZ                     -- set on fail: submitted_at + 24 hours
);

CREATE INDEX idx_skill_sessions_provider ON providers.skill_test_sessions(provider_id, category_id);
```

---

## Backend Structure

```
Modules/Providers/Khudmati.Modules.Providers/
├── Application/
│   ├── Commands/
│   │   ├── SubmitDocumentsCommand.cs + Handler + Validator
│   │   ├── StartSkillTestCommand.cs + Handler
│   │   ├── SubmitSkillTestCommand.cs + Handler + Validator
│   │   ├── ApproveProviderDocumentsCommand.cs + Handler   ← admin
│   │   └── RejectProviderDocumentsCommand.cs + Handler    ← admin
│   ├── Queries/
│   │   ├── GetOnboardingStatusQuery.cs + Handler
│   │   ├── GetSkillTestQuestionsQuery.cs + Handler
│   │   ├── GetVerificationQueueQuery.cs + Handler         ← admin
│   │   └── GetAllProvidersQuery.cs + Handler              ← admin
│   └── DTOs/
│       ├── OnboardingStatusDto.cs
│       ├── SkillTestDto.cs
│       ├── SkillTestResultDto.cs
│       └── ProviderAdminDto.cs
├── Domain/
│   ├── Entities/
│   │   ├── Provider.cs                     ← add Advance/VerifyTier methods
│   │   ├── DocumentSubmission.cs
│   │   └── SkillTestSession.cs
│   └── Enums/
│       └── VerificationTier.cs
└── Infrastructure/
    └── Persistence/
        ├── DocumentSubmissionRepository.cs
        └── SkillTestRepository.cs
```

---

## SignalR Events

| Event | Fired when | Sent to | Payload |
|---|---|---|---|
| `VerificationStatusChanged` | Admin approves/rejects documents | `provider-{providerId}` | `{ newTier, status, message }` |

On receiving `VerificationStatusChanged` in the Flutter app:
- If `newTier = Active` → show celebration banner "🎉 تم تفعيل حسابك! يمكنك الآن قبول الطلبات"
- If `status = Rejected` → show rejection reason, prompt to resubmit

---

## CLAUDE.md Update After This Feature

Add to root `CLAUDE.md` under Business Rules:
```
- Provider verification tiers: Unverified → IdVerified → SkillTested → PhoneVerified → Active
- Only Active tier providers join providers-available SignalR group and see jobs
- Tier history logged in providers.tier_history on every change
```

Add to SignalR events:
```
- `VerificationStatusChanged` → `provider-{providerId}`
```

---

## Edge Cases & Validation

- Provider submits documents twice → `409 "SUBMISSION_ALREADY_PENDING"` — must wait for review
- Provider retakes skill test before 24h cooldown → `429` with `retryAfter` timestamp
- Skill test session expires (30 min) → `400 "TEST_SESSION_EXPIRED"` — must restart
- Admin approves documents but provider already at higher tier → no downgrade, log warning
- Provider registers without service categories → force category selection before showing skill test
- Image upload > 5MB → `400 "FILE_TOO_LARGE"` with clear message
- Unsupported file type → `400 "UNSUPPORTED_FILE_TYPE"`
- Admin rejects without providing reason → `400 "REJECTION_REASON_REQUIRED"`

---

## Out of Scope (do not implement)
- Automated document verification (AI/OCR) — V2
- Background check integration — V2
- Video skill assessment — V2
- Provider re-verification after suspension — V2
- Customer-visible full provider profile page — V2

---

## Acceptance Criteria
- [ ] New provider sees onboarding stepper after login showing all 3 steps
- [ ] Provider can upload ID documents (front + back) and see "Pending Review" status
- [ ] Admin can see document queue, view images, and approve or reject with reason
- [ ] On approval, provider tier advances to `IdVerified` and provider receives SignalR notification
- [ ] Provider can fetch skill test questions and submit answers — score is calculated server-side
- [ ] Passing score (7/10) advances tier, failing sets 24h cooldown
- [ ] Cooldown is enforced server-side — cannot start new test before `next_retry_at`
- [ ] Provider with `Active` tier joins `providers-available` SignalR group on connect
- [ ] Provider with any tier below `Active` cannot see jobs (returns empty feed)
- [ ] Tier changes are logged to `providers.tier_history`
- [ ] Customer sees provider's `Active` verification badge on job accepted screen
- [ ] All Flutter screens render correctly in RTL Arabic layout

# Feature: Post-Job Photo Requirement (Phase 2 — Trust)

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module); `bookings.job_photos` table already exists
- Real-time: SignalR (already wired)
- Frontend(s): Flutter (Provider App + Customer App)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context

## Goal
Require the provider to upload at least one "after" photo of the completed work before the job can advance from `InProgress → Completed`. The customer sees these after-photos alongside the original before-photos in their job history. This builds trust by creating visual proof of work done.

## Platforms Affected
- [x] Provider Mobile App (`mobile-provider/`)
- [x] Customer Mobile App (`mobile-customer/`)
- [x] Backend (`backend/`)
- [ ] Web Landing Page
- [ ] Web Admin Panel
- [ ] Web Super Admin Panel

## User Stories
- As a **provider**, I want to upload photos of the finished work before marking a job complete, so there is a clear record of the service I delivered.
- As a **customer**, I want to see before/after photos of the job in my history, so I have confidence the work was done properly.

---

## Current State (read carefully before changing anything)

### What already exists
- `bookings.job_photos` table with columns: `id`, `job_id`, `url`, `uploaded_at` — **no `photo_type` column yet**.
- `JobPhoto` entity: `Khudmati.Modules.Bookings/Domain/Entities/JobPhoto.cs`
- `AddJobPhotosCommand` at `Khudmati.Modules.Bookings/Application/Commands/AddJobPhotosCommand.cs` — saves URLs to DB with no type distinction.
- `POST /api/bookings/jobs/{jobId}/photos` in `BookingsController.cs` (CustomerOnly policy) — handles **before** photos uploaded by the customer during booking.
- `POST /api/providers/jobs/{jobId}/advance` in `ProviderJobsController.cs` — calls `AdvanceJobStatusCommand`, which calls `job.Advance()` with **no photo gate**.
- `job.Advance()` in `Job.cs` drives: `Accepted → EnRoute → InProgress → Completed`.

### What to change
- Add `photo_type` column (`before` | `after`) to `bookings.job_photos`.
- Gate `InProgress → Completed` transition: require at least 1 `after` photo for that job.
- Add a new provider endpoint to upload after-photos.
- Surface after-photos to the customer in job detail / history.

---

## DB Changes

### Migration: add `photo_type` to `bookings.job_photos`
```sql
ALTER TABLE bookings.job_photos
    ADD COLUMN photo_type TEXT NOT NULL DEFAULT 'before'
        CHECK (photo_type IN ('before', 'after'));
```

The `DEFAULT 'before'` backfills all existing rows correctly — existing customer-uploaded photos are "before" photos.

### Update EF configuration in `Program.cs`
In `AppDbContext.AdditionalModelConfiguration`, update the `JobPhoto` entity mapping:
```csharp
modelBuilder.Entity<JobPhoto>(e =>
{
    e.ToTable("job_photos", "bookings");
    e.Property(p => p.PhotoType).HasColumnName("photo_type");
});
```

---

## Backend Changes

### 1. Update `JobPhoto` entity
File: `Khudmati.Modules.Bookings/Domain/Entities/JobPhoto.cs`

Add `PhotoType` property and update the factory:
```csharp
public string PhotoType { get; private set; } = "before"; // "before" | "after"

public static JobPhoto Create(Guid jobId, string url, string photoType = "before") =>
    new() { JobId = jobId, Url = url, PhotoType = photoType };
```

### 2. Gate `InProgress → Completed` in `AdvanceJobStatusCommandHandler`
File: `Khudmati.Modules.Bookings/Application/Commands/AdvanceJobStatusCommand.cs`

Before calling `job.Advance()`, when the current status is `InProgress`:
1. Check that the job has at least one `JobPhoto` with `PhotoType == "after"`.
2. If not, return `Result<AdvanceJobStatusResultDto>.Fail("AFTER_PHOTO_REQUIRED")`.

The check must query `job.Photos` (already auto-included via EF config in `Program.cs`).

### 3. New provider endpoint: upload after-photos
File: `Khudmati.API/Controllers/Providers/ProviderJobsController.cs`

```
POST /api/providers/jobs/{jobId}/after-photos
```
- **Auth:** Provider JWT (existing `ProviderOnly` policy)
- **Content-Type:** `multipart/form-data`
- **Files:** 1–5 images (jpg/png, max 5 MB each)
- **Validation:**
  - Job must exist and `ProviderId` must match the caller.
  - Job must be in `InProgress` status — reject with `INVALID_JOB_STATUS` otherwise.
  - At least 1 file required; skip invalid MIME types/sizes silently (same pattern as existing `UploadPhotos`).
- **Storage:** Save to `wwwroot/uploads/jobs/{jobId}/after/` (mirror the existing pattern in `BookingsController`).
- **Response:** `{ "success": true, "data": { "urls": ["string"] } }`
- **Logic:** Call `AddJobPhotosCommand` with the saved URLs and `photoType = "after"`.

Update `AddJobPhotosCommand` record and handler to accept the `photoType` parameter:
```csharp
public record AddJobPhotosCommand(Guid JobId, IReadOnlyList<string> Urls, string PhotoType = "before")
    : IRequest<Result<IReadOnlyList<string>>>;
```
Pass `PhotoType` into `JobPhoto.Create(...)` in the handler.

### 4. Update `AdvanceJobStatus` error response
File: `Khudmati.API/Controllers/Providers/ProviderJobsController.cs`

In the `AdvanceJobStatus` action, handle the new error code:
```csharp
"AFTER_PHOTO_REQUIRED" => UnprocessableEntity(result),
```

### 5. Expose `photoType` in job detail DTOs
Files: `Khudmati.Modules.Bookings/Application/DTOs/`

Wherever `photoUrls` is returned in a DTO (e.g. `JobDetailForProviderDto`, `JobDto`), split it into:
```json
{
  "beforePhotoUrls": ["string"],
  "afterPhotoUrls": ["string"]
}
```
Map `job.Photos.Where(p => p.PhotoType == "before")` and `"after"` respectively when building the DTO.

---

## Flutter — Provider App Changes

### 1. New screen: `lib/features/jobs/presentation/upload_after_photos_screen.dart`

- **Route:** `/active-job/:jobId/after-photos`
- **Purpose:** Provider selects 1–5 photos from camera/gallery, previews them, and uploads before completing the job.
- **Key UI elements:**
  - `AppBar` with title "صور إنجاز العمل" (brand blue)
  - Photo grid (max 5 slots) — tap empty slot to add via `image_picker`, tap filled slot to remove
  - Each selected photo shows a remove `×` button
  - Minimum 1 photo enforced — "رفع الصور" button disabled until at least 1 photo selected
  - Upload progress indicator (amber `#F39C12`)
  - On success: pop screen and trigger advance-to-completed via `activeJobNotifierProvider`
- **Error states:**
  - Upload failure → snackbar "فشل في رفع الصور، حاول مرة أخرى"
  - Image too large → snackbar "الصورة أكبر من 5 ميغابايت"

### 2. Update `active_job_detail_screen.dart` — Complete button flow

File: `mobile-provider/lib/features/jobs/presentation/active_job_detail_screen.dart`

When the job status is `InProgress` and the provider taps the "إنهاء الخدمة" / complete button:
- **Do NOT** call `advance` directly.
- Navigate to `/active-job/:jobId/after-photos` instead.
- The upload screen calls advance after successful upload.

### 3. New repository method
File: `mobile-provider/lib/features/jobs/data/job_repository.dart`

Add:
```dart
Future<List<String>> uploadAfterPhotos(String jobId, List<XFile> photos);
```
- `POST /api/providers/jobs/{jobId}/after-photos` with `multipart/form-data`.
- Returns list of saved URLs on success.

---

## Flutter — Customer App Changes

### Update job detail / history to show before/after photos

Wherever customer-facing screens display `photoUrls`:
- Files: `mobile-customer/lib/features/history/` and `mobile-customer/lib/features/booking/presentation/booking_confirmation_screen.dart`

Split the photo display into two labelled sections:
- **"صور قبل العمل"** — `beforePhotoUrls` (may be empty if customer didn't upload)
- **"صور بعد العمل"** — `afterPhotoUrls` (shown only when job status is `Completed` or `Paid`)

If neither list has photos, show nothing (no empty section headers).

Update the `JobDetail` / `JobDto` Dart model to parse `beforePhotoUrls` and `afterPhotoUrls` separately.

---

## Edge Cases & Validation

- Provider cannot upload after-photos unless job is `InProgress` — return `INVALID_JOB_STATUS`.
- Provider cannot advance from `InProgress → Completed` without at least 1 after-photo — return `AFTER_PHOTO_REQUIRED` (HTTP 422).
- The existing `POST /api/bookings/jobs/{jobId}/photos` (customer before-photos) is unchanged — it still saves with `photoType = "before"`.
- After-photos can be uploaded incrementally (multiple calls) — each adds to the set. The gate only checks that at least 1 exists at advance time.
- Max 5 after-photos per job (enforced in the upload endpoint via `.Take(5)`).
- Files must be `image/jpeg` or `image/png`, max 5 MB each — skip silently, same as existing pattern.
- If the provider is offline during upload, show a retry option — do not auto-advance.
- Existing jobs in `Completed` or `Paid` status with zero after-photos (pre-migration data) are unaffected.

---

## Out of Scope (do not implement)
- Admin review of after-photos before releasing payment
- Customer ability to dispute based on photo quality
- Mandatory before-photos — this prompt only gates after-photos
- Video uploads
- Photo compression / resizing on the server
- CDN / S3 migration (stay consistent with existing local disk storage)

---

## Acceptance Criteria
- [ ] `bookings.job_photos.photo_type` column exists; all pre-existing rows have value `before`
- [ ] `POST /api/providers/jobs/{jobId}/after-photos` saves photos with `photo_type = 'after'`, only for `InProgress` jobs owned by the provider
- [ ] `POST /api/providers/jobs/{jobId}/advance` returns HTTP 422 with error `AFTER_PHOTO_REQUIRED` when job is `InProgress` and 0 after-photos exist
- [ ] Advance succeeds when at least 1 after-photo has been uploaded
- [ ] Job detail DTOs return `beforePhotoUrls` and `afterPhotoUrls` as separate arrays
- [ ] Provider app redirects to upload screen instead of advancing directly when status is `InProgress`
- [ ] Provider can select 1–5 photos, preview them, and upload before completing
- [ ] Customer job history displays before and after photos in separate labelled sections
- [ ] All UI labels are in Arabic; layout is RTL-correct
- [ ] Existing customer before-photo upload (`POST /api/bookings/jobs/{jobId}/photos`) is unaffected

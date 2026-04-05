# Feature: Customer Booking Flow

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR
- Frontend: Flutter (mobile-customer)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context

## Goal
Implement the end-to-end customer booking flow — the core value action of the entire app. A customer selects a service category, describes their job, sets their location, reviews a summary, and confirms. The result is a Job record in `Pending` status, ready for provider matching.

## Platforms Affected
- [x] Customer Mobile App (Flutter)
- [x] Backend (.NET 8)
- [ ] Provider Mobile App — providers will see the job in feature #03
- [ ] Admin Panel — admins will see it in feature #12
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Story
As a **customer**, I want to select a service category, describe my problem, pin my location, and confirm my booking so that a provider gets assigned to my job.

---

## Screens to Build

### Screen 1: Service Category Selection (`lib/features/booking/presentation/category_screen.dart`)
- Purpose: Entry point to booking — customer picks what type of service they need
- UI:
  - Page title: "احجز خدمة" (Book a Service)
  - Grid of category cards (2 columns), each with an icon and Arabic label
  - Categories for V1: سباكة (Plumbing), كهرباء (Electrical), تنظيف (Cleaning), نجارة (Carpentry), دهان (Painting), تكييف (AC Maintenance)
  - Brand blue card header, amber icon accent, white background
  - Tapping a card navigates to Job Description screen, passing the selected category
- Data: Categories are hardcoded in V1 (no API call needed yet)

### Screen 2: Job Description (`lib/features/booking/presentation/job_description_screen.dart`)
- Purpose: Customer describes what needs to be done
- UI:
  - Show selected category name at top as a chip/tag
  - Large multiline text field: "صِف المشكلة أو الخدمة المطلوبة" (Describe the problem or service needed) — min 20 chars, max 500
  - Optional: photo upload button (up to 3 photos) — show thumbnail previews, allow remove — store locally for now, upload in confirm step
  - "التالي" (Next) button — disabled until description is filled
  - Back arrow returns to category screen
- Validation: description required, min 20 characters, show char count

### Screen 3: Location Picker (`lib/features/booking/presentation/location_screen.dart`)
- Purpose: Customer sets where the service should happen
- UI:
  - Embedded map (flutter_map with OpenStreetMap tiles — free, no API key needed)
  - Draggable pin in the center of the map — pin position = selected location
  - "استخدم موقعي الحالي" (Use my current location) button — requests GPS permission, centers map on device location
  - Address text field below the map — reverse geocode the pin coordinates to a readable address (use `geocoding` package)
  - Address is editable — customer can type a correction
  - "التالي" (Next) button — disabled until a location is confirmed
- Permissions: request location permission on screen load, show explanation if denied

### Screen 4: Booking Summary & Confirm (`lib/features/booking/presentation/booking_summary_screen.dart`)
- Purpose: Customer reviews everything before submitting
- UI:
  - Card showing: category icon + name, job description (truncated to 3 lines with expand), address, photos (small thumbnails if any)
  - Estimated price range: show "يتم تحديد السعر مع المزود" (Price agreed with provider) — no pricing engine in V1
  - Primary CTA button: "تأكيد الحجز" (Confirm Booking) — amber background, white text, full width
  - Loading state on button while API call is in progress
  - On success → navigate to Booking Confirmation screen
  - On error → show inline error message, keep user on screen

### Screen 5: Booking Confirmation (`lib/features/booking/presentation/booking_confirmation_screen.dart`)
- Purpose: Post-submit feedback — lets customer know their job was created and they're waiting for a provider
- UI:
  - Large checkmark animation (use `lottie` package or simple animated icon)
  - Title: "تم تأكيد حجزك!" (Your booking is confirmed!)
  - Subtitle: "جاري البحث عن أقرب مزود خدمة متاح" (Finding the nearest available provider...)
  - Job reference number (short ID)
  - "عرض تفاصيل الطلب" (View booking details) button → navigates to Job Detail screen (stub for now — just show the job data)
  - "العودة للرئيسية" (Back to Home) button

---

## State Management

### Booking State (`lib/features/booking/presentation/booking_provider.dart`)
Use a single `BookingNotifier extends AsyncNotifier<BookingState>` that holds the in-progress booking across all steps:

```dart
class BookingState {
  final String? categoryId;
  final String? categoryName;
  final String description;
  final List<File> photos;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? createdJobId;   // set after successful API call
}
```

Methods:
- `setCategory(id, name)`
- `setDescription(text)`
- `addPhoto(file)` / `removePhoto(index)`
- `setLocation(lat, lng, address)`
- `submitBooking()` → calls API, updates state with returned job ID on success
- `reset()` → clears all state (called after confirmation or on cancel)

The notifier is **scoped to the booking flow** — create it with `ref.watch` only within the booking navigator so it's disposed when the flow exits.

---

## Navigation Flow

Use `go_router`. The booking flow is a nested sub-route:

```
/home
/booking
  /booking/category          ← Step 1
  /booking/description       ← Step 2 (receives category from state, not route params)
  /booking/location          ← Step 3
  /booking/summary           ← Step 4
  /booking/confirmation      ← Step 5 (receives jobId)
```

The back button on each step returns to the previous step. On the confirmation screen, back is disabled — "Back to Home" clears state and navigates to `/home`.

---

## API Endpoints

### POST /api/bookings/jobs
- Auth: Customer JWT (audience = `customer`)
- Request:
```json
{
  "categoryId": "string",
  "description": "string",
  "latitude": 0.0,
  "longitude": 0.0,
  "address": "string",
  "photoUrls": ["string"]
}
```
- Response:
```json
{
  "success": true,
  "data": {
    "jobId": "uuid",
    "referenceNumber": "KH-20240403-0001",
    "status": "Pending",
    "category": "string",
    "description": "string",
    "address": "string",
    "createdAt": "ISO8601"
  }
}
```
- Business rules:
  - Extract `customerId` from JWT claims — do not accept it in the request body
  - Validate: description min 20 chars, valid coordinates (lat -90/90, lng -180/180), categoryId must be a known value
  - Generate a human-readable `referenceNumber`: `KH-{YYYYMMDD}-{4-digit-sequence}` — use a DB sequence per day
  - Initial status = `Pending`
  - Log a `JobCreatedEvent` domain event (for audit trail)
  - Return `400` with field-level errors if validation fails

### GET /api/bookings/jobs/{jobId}
- Auth: Customer JWT
- Response: same shape as POST response above
- Business rules: only return the job if it belongs to the authenticated customer (return `404` otherwise — don't leak existence)

### GET /api/bookings/jobs?status=Pending&page=1&pageSize=10
- Auth: Customer JWT
- Purpose: customer job history list (used on Home and History screens)
- Response: paginated list of jobs belonging to the authenticated customer

---

## Data Model

```sql
-- bookings schema

CREATE TABLE bookings.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id UUID NOT NULL,
    provider_id UUID,                          -- null until accepted
    category_id VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address VARCHAR(500) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_jobs_customer_id ON bookings.jobs(customer_id);
CREATE INDEX idx_jobs_status ON bookings.jobs(status);
CREATE INDEX idx_jobs_created_at ON bookings.jobs(created_at DESC);

-- Photo attachments (separate table — jobs can have 0-3 photos)
CREATE TABLE bookings.job_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES bookings.jobs(id) ON DELETE CASCADE,
    url VARCHAR(1000) NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Daily sequence for reference number generation
CREATE SEQUENCE bookings.daily_job_seq START 1;
-- Reset this sequence daily via a scheduled job (or handle in application logic)
```

### Reference number generation logic (in application layer):
```csharp
// Format: KH-{YYYYMMDD}-{sequence padded to 4 digits}
// Example: KH-20240403-0042
var date = DateTime.UtcNow.ToString("yyyyMMdd");
var seq = await _db.Database.ExecuteSqlRawAsync("SELECT nextval('bookings.daily_job_seq')");
return $"KH-{date}-{seq:D4}";
```

---

## Backend Structure

```
Modules/Bookings/Khudmati.Modules.Bookings/
├── Domain/
│   ├── Entities/
│   │   ├── Job.cs                          ← Job aggregate root
│   │   └── JobPhoto.cs
│   ├── Enums/
│   │   └── JobStatus.cs                    ← Pending,Accepted,EnRoute,InProgress,Completed,Paid
│   ├── Events/
│   │   └── JobCreatedEvent.cs
│   └── ValueObjects/
│       └── JobLocation.cs                  ← Lat/Lng/Address as a value object
├── Application/
│   ├── Commands/
│   │   ├── CreateJobCommand.cs
│   │   ├── CreateJobCommandHandler.cs
│   │   └── CreateJobCommandValidator.cs
│   ├── Queries/
│   │   ├── GetJobByIdQuery.cs
│   │   ├── GetJobByIdQueryHandler.cs
│   │   ├── GetCustomerJobsQuery.cs
│   │   └── GetCustomerJobsQueryHandler.cs
│   └── DTOs/
│       ├── CreateJobRequest.cs
│       ├── JobDto.cs
│       └── JobListDto.cs
├── Infrastructure/
│   └── Persistence/
│       ├── JobRepository.cs
│       └── JobConfiguration.cs             ← EF Core fluent config
└── BookingsModule.cs
```

---

## Photo Upload

For V1, use a simple local file storage approach — save uploaded photos to `wwwroot/uploads/jobs/{jobId}/`. Return the relative URL in the response. This is easy to swap for Azure Blob or S3 later.

Add an endpoint: `POST /api/bookings/jobs/{jobId}/photos` — accepts `multipart/form-data`, max 3 files, max 5MB each, allowed types: jpg/png. Returns array of URLs.

On the Flutter side, upload photos one by one after job creation (in `submitBooking()` after the job ID is returned), then PATCH the job with photo URLs. If photo upload fails, the job still exists — photos are non-blocking.

---

## Edge Cases & Validation

- Description under 20 chars → inline error "الوصف قصير جداً، أضف تفاصيل أكثر" (Too short, add more detail)
- Location permission denied → show explanation sheet, offer manual address entry as fallback (text field only, no map)
- Network error on submit → show "حدث خطأ، يرجى المحاولة مرة أخرى" (Something went wrong, please try again), keep booking state intact so customer doesn't lose their input
- Customer submits while another job is `Pending` or `Accepted` → for V1 allow multiple concurrent jobs (no restriction)
- Photos fail to upload → job is created successfully, photos silently skipped, no error shown to user

---

## Out of Scope (do not implement)
- Provider matching / assignment — that is feature #03
- Price estimation engine — V2
- Scheduling for a future date/time — V2
- Service sub-categories — V2
- Real file storage (Azure Blob / S3) — use local wwwroot for now
- Push notification to providers when job is created — feature #10

---

## Acceptance Criteria
- [ ] Customer can complete all 5 screens and create a job
- [ ] Job is saved to DB with status `Pending` and a valid reference number (format KH-YYYYMMDD-XXXX)
- [ ] `customerId` is taken from the JWT — never from the request body
- [ ] Description under 20 chars is rejected at both Flutter UI and API level
- [ ] Location picker centers on device GPS when permission granted
- [ ] Booking state is preserved if user navigates back through the flow
- [ ] Confirmation screen shows the job reference number
- [ ] All screens render correctly in RTL Arabic layout
- [ ] API returns `404` if customer tries to fetch a job that doesn't belong to them
- [ ] Photo upload failures do not block job creation

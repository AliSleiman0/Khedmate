---
name: khedmate-feature-writer
description: >
  Writes complete, production-ready feature code for the Khudmati (خدمتي) home services
  marketplace project. Given a feature description, this skill generates all the necessary
  implementation files — backend C# (CQRS handlers, controllers, DTOs), Flutter Dart
  (screens, providers, repositories), and React TypeScript (pages, hooks, components) —
  and saves them directly into the project. Use this skill whenever Ali wants to implement,
  build, code, or add a feature to Khudmati/Khedmate. Trigger on: "write the X feature",
  "implement X", "build X for Khedmate", "code the X screen", "add X to the app",
  "create the X module", "I need the X flow", or any request to produce actual working
  code for the Khudmati project. Always use this skill — not generic coding — when the
  task involves Khudmati features.
---

# Khedmate Feature Writer

This skill writes complete feature code for the **Khudmati (خدمتي)** home services
marketplace. Your job is to gather the feature scope from Ali and then produce real,
runnable implementation files — not pseudocode, not summaries, actual code.

---

## Project Quick Reference

**Platforms & paths inside `C:\Khedmate - ANJU_Context\`:**

| Platform | Path | Stack |
|---|---|---|
| Backend API | `backend/src/` | .NET 8, ASP.NET Core |
| Customer App | `mobile-customer/lib/` | Flutter + Riverpod |
| Provider App | `mobile-provider/lib/` | Flutter + Riverpod |
| Landing Page | `web-landing/src/` | React + TypeScript + Vite |
| Admin Panel | `web-admin/src/` | React + TypeScript + Vite |
| Super Admin | `web-superadmin/src/` | React + TypeScript + Vite |

**Backend module paths:** `backend/src/Modules/{Bookings|Customers|Providers|Payments|Notifications}/Khudmati.Modules.{Name}/`

**Brand:** Blue `#1B4F72` · Amber `#F39C12` · Cairo (Arabic) · Inter (English) · RTL-first

**Job state machine:** `Pending → Accepted → EnRoute → InProgress → Completed → Paid`

**JWT audiences:** `customer` · `provider` · `admin` · `superadmin`

**API response wrapper:** `Result<T> { bool Success, T? Data, string? Error }`

---

## Step 1 — Understand the Feature

Before writing a single line of code, get clarity on these (extract from context first, only ask what's missing):

- **Feature name** — what's it called?
- **Platform(s)** — which app(s) does it live in? (backend only? mobile + backend? all?)
- **User story** — who does what, what's the result?
- **Core logic** — any business rules, state transitions, validations?
- **What data is involved** — new DB table? existing entity? just an API call?
- **Out of scope** — anything to explicitly skip (e.g. "no notifications yet", "skip error states for now")?

Keep the interview short — 2-3 targeted questions max. If Ali's description is detailed enough, skip asking and go straight to writing.

---

## Step 2 — Plan the Files

Before writing code, state clearly what files you're going to create and in which platform. This keeps things traceable and lets Ali redirect if something's off.

Example plan:
```
Backend:
  - Modules/Bookings/.../Commands/AcceptJobCommand.cs
  - Modules/Bookings/.../Commands/AcceptJobCommandHandler.cs
  - Modules/Bookings/.../DTOs/JobResponseDto.cs
  - API/Controllers/JobsController.cs  (add endpoint to existing)

Provider Mobile App:
  - features/job-detail/presentation/job_detail_screen.dart
  - features/job-detail/presentation/job_detail_provider.dart
  - features/job-detail/data/job_repository.dart
  - features/job-detail/domain/job_response_model.dart
```

---

## Step 3 — Write the Code

Write each file completely. No `// TODO` stubs. No `// implement this`. Real, compilable code.

Read the relevant reference file before writing for that platform:
- **Backend (.NET 8)** → read `references/backend-patterns.md`
- **Flutter** → read `references/flutter-patterns.md`
- **React + TypeScript** → read `references/react-patterns.md`

These files contain exact patterns, import conventions, and boilerplate for this project. Following them keeps the codebase consistent.

---

## Step 4 — Deliver the Files

### If the Khedmate project folder is mounted:
Check for the project at the mounted path (look for a folder containing `backend/`, `mobile-customer/`, etc.). Write files directly into the correct locations within the project structure.

### If not mounted (most common):
Create the files in a mirrored folder structure inside the Downloads folder:
```
Downloads/
└── khedmate-feature-{feature-name}/
    ├── backend/
    │   └── ... (mirroring the backend module path)
    ├── mobile-provider/
    │   └── ...
    └── (etc.)
```
Tell Ali: "Move the contents of `khedmate-feature-{name}/` into your project at `C:\Khedmate - ANJU_Context\`, matching the folder structure."

---

## Code Quality Standards

These matter because Ali is the sole developer and needs code he can maintain:

**All platforms:**
- No magic numbers — use named constants
- Meaningful names — `acceptJob()` not `doAction()`
- Handle the unhappy path — empty states, error states, loading states
- Arabic strings go in the i18n/strings file, not hardcoded

**Backend:**
- Follow CQRS — one Command or Query class per operation, one Handler
- Handlers return `Result<T>` — never throw from a handler, catch and return `Result.Failure(...)`
- Validate with FluentValidation in a separate `*Validator.cs` class
- DB access only in Infrastructure layer — never query from Application layer directly
- Log state machine transitions as domain events

**Flutter:**
- Use Riverpod `AsyncNotifierProvider` for any screen that loads data
- Split screen from logic — `*_screen.dart` has only UI, `*_provider.dart` has state
- Support RTL — use `Directionality` widget or check `TextDirection` for any layout that might flip
- Brand colors from `core/constants/colors.dart`, never hardcode hex values

**React (admin/superadmin):**
- Server state via React Query (`useQuery` / `useMutation`) — don't duplicate in Zustand
- Local UI state only in Zustand
- All API calls go through the Axios instance in `src/api/` — never use `fetch` directly
- Use Tailwind utility classes — no inline styles
- TypeScript strict — no `any`, define proper response types

---

## After Writing

1. List every file created with its full path
2. Note any dependencies the feature needs that aren't already in the project (new NuGet packages, Flutter pub packages, npm packages)
3. Note any DB migration needed
4. Flag anything that needs a follow-up (e.g. "you'll need to add the SignalR event for this once the Notifications module is wired up")

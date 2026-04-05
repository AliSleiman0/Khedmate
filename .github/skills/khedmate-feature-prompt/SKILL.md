---
name: khedmate-feature-prompt
description: >
  Generates structured, scoped Claude Code prompts for new features in the Khudmati (خدمتي)
  home services marketplace project at C:\Khedmate - ANJU_Context. Use this skill whenever
  Ali wants to build a new feature, screen, flow, module, or component for Khudmati —
  whether for the customer mobile app, provider mobile app, web landing page, web admin
  panel, or web super admin panel. Trigger on: "add X to Khedmate", "write a prompt for",
  "new feature for the app", "feature prompt", "I want to build", "prompt for Claude Code",
  "implement X in Khedmate", or any request to generate a Claude Code-ready prompt for
  this project. Always use this skill when Ali is working on the Khudmati / Khedmate project.
---

# Khedmate Feature Prompt Builder

This skill generates a complete, scoped Claude Code prompt for a specific feature in the **Khudmati (خدمتي)** home services marketplace project.

Khudmati is a two-sided marketplace connecting customers needing home services with verified service providers, built for MENA markets (Arabic-first). Ali is the sole developer on this project.

---

## Project Context

### Platforms

| Platform | Type | Target User |
|---|---|---|
| Customer App | Flutter (mobile) | Homeowners booking services |
| Provider App | Flutter (mobile) | Service providers accepting jobs |
| Web Landing Page | React + TypeScript | Marketing / public visitors |
| Web Admin Panel | React + TypeScript | Anju/Khudmati operations team |
| Web Super Admin Panel | React + TypeScript | Super admins / platform management |

### Tech Stack

- **Backend:** ASP.NET Core — modular monolith, clean architecture
  - Modules: Bookings, Providers, Customers, Payments, Notifications
  - State machines for job status transitions with full event log (for disputes/auditing)
- **Database:** PostgreSQL — single DB, schema-per-module in v1
- **Real-time:** SignalR — job status, provider location, in-app chat
- **Auth:** JWT-based; separate flows for customers, providers, admins
- **Notifications:** Queue-backed, retry-capable (critical for booking flow trust)

### Brand System

- **Brand Blue:** `#1B4F72` — primary actions, headers
- **Amber:** `#F39C12` — CTAs, badges, highlights
- **Fonts:** Cairo (Arabic content) + Inter (English content)
- **Direction:** RTL-first; all UI must support Arabic text properly
- **Tone:** Trustworthy, community-rooted, professional-but-warm

### Core Business Rules (important for prompt accuracy)

- Commission: 15–20% per transaction (tiered by provider rating/tenure at later stage)
- Job flow: `Pending → Accepted → En Route → In Progress → Completed → Paid`
- Provider verification tiers: ID verified → skill tested → phone verified → first job done → 10 jobs
- Dispute window: 24 hours post-job before payment releases
- Rating: binary thumbs up/down + optional tags (not 5 stars)
- V1 excludes: subscriptions, AI features, complex scheduling, referral system

---

## How to Use This Skill

When Ali describes a feature he wants to build, follow this process:

### Step 1 — Gather Feature Details

Ask Ali for any missing details across these dimensions (only ask what's not already clear from context):

1. **Platform(s)** — which app(s) does this feature touch? (customer app / provider app / landing / admin / super admin)
2. **Feature scope** — what screens, flows, or API endpoints are involved?
3. **User story** — who does what, and what's the expected outcome?
4. **Inputs/Outputs** — what data goes in, what comes out?
5. **Edge cases** — any validation rules, error states, empty states worth calling out?
6. **Design notes** — any specific UI behaviour, brand requirements, or existing patterns to follow?
7. **Out of scope** — anything this prompt should explicitly NOT implement?

Gather these conversationally — don't present them as a numbered form. If Ali has already answered most of these in his request, skip directly to Step 2.

### Step 2 — Generate the Claude Code Prompt

Produce a complete, copy-paste-ready prompt following the **Prompt Template** below.

The prompt should be **self-contained** — Claude Code reading it should have everything it needs to implement the feature without needing to ask follow-up questions. Reference actual file paths, module names, and tech stack specifics where helpful.

---

## Prompt Template

Use this exact structure. Adjust section depth based on feature complexity.

```
# Feature: [Feature Name]

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR
- Frontend(s): [list relevant platform(s) — Flutter / React + TypeScript]
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context

## Goal
[1–2 sentence plain-English description of what this feature does and why it matters.]

## Platforms Affected
- [ ] Customer Mobile App
- [ ] Provider Mobile App
- [ ] Web Landing Page
- [ ] Web Admin Panel
- [ ] Web Super Admin Panel

## User Story
As a [user type], I want to [action] so that [outcome].

## Screens / Components to Build
[List each screen or component, with a brief description of what it shows/does.]

### Screen: [Name]
- Purpose: ...
- Key UI elements: ...
- Data shown: ...
- Actions available: ...

## API Endpoints Required
[List each endpoint needed. Include method, route, request shape, response shape, and any auth requirements.]

### POST /api/[module]/[route]
- Auth: [Customer JWT / Provider JWT / Admin JWT / Public]
- Request: `{ field: type, ... }`
- Response: `{ field: type, ... }`
- Business rules: [any validation, state machine transitions, side effects]

## Data Model / DB Changes
[Any new tables, columns, or migrations needed. Reference the module/schema.]

## Business Logic
[Step-by-step description of the core logic. Reference state machine transitions if applicable.]

## Real-time / Notifications
[If SignalR events or push notifications are triggered, describe them here: event name, who receives it, when it fires.]

## Edge Cases & Validation
- [validation rule or error state]
- [empty state behaviour]
- [error state behaviour]

## Out of Scope (do not implement)
- [explicit exclusion]
- [explicit exclusion]

## Acceptance Criteria
- [ ] [verifiable condition]
- [ ] [verifiable condition]
- [ ] [verifiable condition]
```

---

## Output Format

After generating the prompt, present it inside a code block so Ali can copy it directly.

Also offer to save it as a `.md` file in `C:\Khedmate - ANJU_Context\prompts\[feature-name].md` if Ali wants to keep a record of feature prompts in the project folder. This is a good habit for traceability.

---

## Example

**Ali says:** "I want to build the provider job acceptance flow — when a new job is assigned, the provider gets a notification and can accept or reject it within 2 minutes."

**Skill output prompt (summary of what gets generated):**
- Feature: Provider Job Acceptance Flow
- Platform: Provider Mobile App + Backend
- Screens: Job Alert modal with countdown timer, Accept/Reject buttons
- API: `POST /api/bookings/jobs/{id}/respond` — body `{ action: "accept" | "reject" }` — transitions job from `Pending → Accepted` or back to pool
- Real-time: SignalR event `job:assigned` → provider app; `job:accepted` → customer app
- Business rules: 2-minute timeout auto-rejects and reassigns; provider acceptance rate tracked
- Edge cases: timeout handling, provider offline at time of assignment
- Out of scope: provider earnings display, scheduling calendar

---

## Notes for Prompt Quality

- **Be specific about file paths** when you know them — e.g. `Modules/Bookings/Application/Commands/RespondToJobCommand.cs` is more useful than "add a command handler".
- **Reference the state machine** explicitly when the feature touches job status transitions.
- **RTL is not optional** — any UI prompt must include a reminder to test Arabic layout.
- **Keep V1 scope** — don't let prompts drift into subscription tiers, AI features, or referral systems unless Ali explicitly asks.
- **Notifications are first-class** — if the feature has a user-facing event, include the notification trigger in the prompt.

# Khudmati — Unified Mobile App Migration

This directory contains the migration prompts for merging `mobile-customer` and `mobile-provider` into a single Flutter app (`mobile/`) with role selection at signup/login.

Each numbered file is a **self-contained prompt** that can be fed to Claude Code (or any engineer) to execute that phase. Phases are sequential — complete and verify phase N before starting N+1.

## Phase index

| # | File | Summary |
|---|---|---|
| 0 | [phase-00-prep.md](phase-00-prep.md) | Decisions, branch, Firebase strategy, user-migration strategy |
| 1 | [phase-01-scaffold.md](phase-01-scaffold.md) | Create `mobile/` Flutter app, merged pubspec, assets, platform config baseline |
| 2 | [phase-02-core.md](phase-02-core.md) | Port shared core: colors, l10n, api_client (role-aware), signalr, fcm, role_provider |
| 3 | [phase-03-role-welcome.md](phase-03-role-welcome.md) | New welcome screen with role picker; router redirect skeleton |
| 4 | [phase-04-auth.md](phase-04-auth.md) | Shared auth screens; role-aware AuthRepository hits `/auth/customers/*` or `/auth/providers/*` |
| 5 | [phase-05-shared-features.md](phase-05-shared-features.md) | Chat, notifications, profile, rating — shared by both roles |
| 6 | [phase-06-customer.md](phase-06-customer.md) | Port all customer-only features: booking, home, history, tracking, payments, disputes, referral, reminders |
| 7 | [phase-07-provider.md](phase-07-provider.md) | Port all provider-only features: jobs, onboarding, navigation, earnings, analytics, subscription |
| 8 | [phase-08-router.md](phase-08-router.md) | Role-aware GoRouter consolidation; deep-link handling |
| 9 | [phase-09-platform.md](phase-09-platform.md) | Android manifest, iOS Info.plist, Firebase, icons, splash |
| 10 | [phase-10-user-migration.md](phase-10-user-migration.md) | Strategy for existing users on old bundle ids |
| 11 | [phase-11-verification.md](phase-11-verification.md) | End-to-end test matrix; release build verification |
| 12 | [phase-12-store.md](phase-12-store.md) | Play Store + App Store submission |
| 13 | [phase-13-deprecate.md](phase-13-deprecate.md) | Archive old apps; update root docs |

## Rules of execution

1. **Branch discipline** — all work on `feat/unified-app`. `main`, `mobile-customer/`, `mobile-provider/` are not touched until Phase 13.
2. **Exit criteria are gates** — do not start the next phase until the current phase's exit criteria are all met and verified on a real device where required.
3. **No scope creep** — each phase has a specific scope. Defer anything outside scope to a later phase or a separate ticket.
4. **Backend is untouched** — this migration does not modify `backend/`. If a change seems needed, stop and raise it explicitly.
5. **Keep the old apps working** — old apps continue to build and run until Phase 13. Do not delete files from them.

## Final plan reference

The master plan (decisions rationale, architecture, verification) lives at:
`C:\Users\AliSleiman\.claude\plans\memoized-cooking-canyon.md`

Read it before starting Phase 0.

# Phase 13 — Deprecate Old Apps

## Goal
Archive `mobile-customer/` and `mobile-provider/` within the repo, update root-level documentation to reflect the new monorepo layout, and tag the old codebases for historical reference.

## Why this phase
Once production traffic has shifted to the unified app (per the Phase 10 strategy), the old directories become a maintenance hazard — people may accidentally edit them, CI may still build them, and new engineers get confused about which is canonical.

## Pre-requisites
- Phase 12 complete — unified app live in both stores
- Migration rate ≥ the threshold set in Phase 10 (e.g. 80% of active users on new app)
- Sunset date per Phase 10 strategy has passed (for Strategy B)

## Scope

### 1. Tag the old apps
```bash
cd "C:/Khedmate - ANJU_Context"
git tag -a v-final-customer -m "Final state of mobile-customer before archive"
git tag -a v-final-provider -m "Final state of mobile-provider before archive"
git push origin v-final-customer v-final-provider
```

### 2. Move to archive directory
```bash
mkdir -p archive
git mv mobile-customer archive/mobile-customer
git mv mobile-provider archive/mobile-provider
```

Do not delete — keep for reference. Files under `archive/` will not be touched or built again.

### 3. Update `archive/README.md` (new file)
```markdown
# Archived Apps

These are the legacy codebases from before the unified Khudmati app migration.

- `mobile-customer/` — customer-only Flutter app (last built from tag `v-final-customer`)
- `mobile-provider/` — provider-only Flutter app (last built from tag `v-final-provider`)

**Status:** Read-only. Do not edit. For the active mobile app, see `/mobile`.

**History:** Merged into the unified app during Phase 13 of the migration plan (see `/migration-plan/phase-13-deprecate.md`). Migration completed on <DATE>.
```

### 4. Update root `CLAUDE.md`
Modify the Monorepo layout table:

**Before:**
| Directory | Stack | Dev port |
| `mobile-customer/` | Flutter | — |
| `mobile-provider/` | Flutter | — |

**After:**
| Directory | Stack | Dev port |
| `mobile/` | Flutter (Riverpod, GoRouter, Dio) — unified customer + provider | — |
| `archive/mobile-customer/` | (archived) | — |
| `archive/mobile-provider/` | (archived) | — |

Update all other references in the file that point to the old apps — feature index table rows that mention `mobile-customer` / `mobile-provider` file paths should be updated to `mobile/lib/features/customer/...` / `mobile/lib/features/provider/...`.

### 5. Update root `README.md` (if one exists)
Same substitution as CLAUDE.md.

### 6. Update CI configuration
If `.github/workflows/`, `.gitlab-ci.yml`, or similar CI files reference the old apps, remove those jobs and add a single `mobile/` job.

Verify no CI job is still trying to build `archive/mobile-customer` or `archive/mobile-provider`.

### 7. Update `.gitignore` if needed
Add `archive/` to CI exclusion lists if the CI otherwise scans all directories.

### 8. Announce
Post to the team channel:
- Migration complete as of <DATE>
- New app live in both stores
- Old apps archived under `/archive/`
- New contributions go to `/mobile/`
- Link to updated CLAUDE.md

## Files to create
- `archive/README.md`

## Files to modify
- `CLAUDE.md` (root) — monorepo layout + file paths
- `README.md` (root, if exists)
- CI configuration files

## Files to move (not delete)
- `mobile-customer/` → `archive/mobile-customer/`
- `mobile-provider/` → `archive/mobile-provider/`

## Verification
- `git log --follow archive/mobile-customer/pubspec.yaml` shows full history preserved
- `flutter build apk --release --directory mobile/` still succeeds (unified app unaffected by the move)
- Searching for `mobile-customer` or `mobile-provider` in active directories (excluding `archive/`) returns zero results:
  ```bash
  grep -r "mobile-customer\|mobile-provider" --exclude-dir=archive --exclude-dir=.git "C:/Khedmate - ANJU_Context"
  ```
  Any hits are stale references and must be fixed.
- CI only runs jobs for `mobile/`, not `archive/mobile-customer/` or `archive/mobile-provider/`
- Tags `v-final-customer` and `v-final-provider` visible on remote

## Exit criteria
- [ ] Tags pushed
- [ ] `archive/` structure in place
- [ ] Root docs updated
- [ ] CI updated
- [ ] Team announcement posted
- [ ] No stale references to old app paths in active code or docs
- [ ] Commit: `chore: archive old mobile apps (migration complete)`

## Rollback
- `git mv archive/mobile-customer mobile-customer` and revert doc changes. No user-facing impact.

## Post-migration cleanup (optional, separate tickets)
After the migration dust settles, consider:
- Removing `archive/` entirely after 12 months (tags preserve history)
- Extracting shared libs (API client, SignalR, theme) into a standalone Dart package inside the monorepo if we ever build a 3rd app (e.g. admin mobile)
- Consolidating Firebase projects if Strategy B was used and the old apps' Firebase projects still exist

---

## Migration complete

This phase is the final phase. The repo now contains one active mobile app (`mobile/`), one archived directory, and updated docs. Subsequent work on the mobile app happens only in `/mobile`.

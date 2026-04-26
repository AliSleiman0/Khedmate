# Deploy runbook — Khudmati backend

Production server: `root@157.230.22.154` · API: `https://api.khudmati.app`

## Standard update

**Local:**
```bash
git add <files>
git commit -m "..."
git push origin <branch>
# PR → merge to main on GitHub
```

**Server:**
```bash
ssh root@157.230.22.154
bash /opt/khudmati/backend/deploy/pull-and-deploy.sh
```

That wrapper does: `git pull` in `/opt/khudmati/khudmati-source` → rsync `backend/` into `/opt/khudmati/backend/` (preserving `.env`, `firebase-service-account.json`, `uploads/`) → `bash deploy/deploy.sh` (rebuilds + restarts + health-checks).

## Exceptions

| Scenario | Extra step |
|---|---|
| New SQL migration (`add-foo.sql`) | After `pull-and-deploy.sh`: `docker exec -i $(docker ps -qf name=postgres) psql -U khudmati_user -d khudmati < /opt/khudmati/backend/add-foo.sql` |
| `.env` change (new secret) | Edit `/opt/khudmati/backend/.env` on the server, then `pull-and-deploy.sh` |
| `docker-compose.prod.yml` change | Handled — `deploy.sh` uses `up -d --remove-orphans` |
| Postgres / nginx config change | Handled — same path |
| Mobile-only change | Skip server. Build APK/IPA → store submission |
| Web admin / landing change | Separate deploy — those serve from `/var/www/{admin,landing,superadmin}`, not via this script |

## Smoke tests

```bash
curl -s https://api.khudmati.app/api/health
curl -s https://api.khudmati.app/api/categories/active
curl -s https://api.khudmati.app/api/landing/stats
```

## Rollback

If a deploy breaks the API:
```bash
# Each pull-and-deploy creates a timestamped backup automatically only on init-git.sh.
# For a hot rollback, restore from the most recent backend.bak.* dir:
ls -lt /opt/khudmati/backend.bak.* | head -3
# Pick one and:
docker compose -f /opt/khudmati/backend/docker-compose.prod.yml down api
rsync -av --delete /opt/khudmati/backend.bak.<timestamp>/ /opt/khudmati/backend/
cd /opt/khudmati/backend && bash deploy/deploy.sh
```

## First-time setup (already done)

`bash deploy/init-git.sh` runs once — clones the repo to `/opt/khudmati/khudmati-source`, rsyncs the backend tree, applies `add-service-categories.sql`, writes `pull-and-deploy.sh`. Don't re-run unless you're rebuilding the server from scratch.

#!/usr/bin/env bash
# =============================================================================
# init-git.sh — One-time setup to convert /opt/khudmati/backend into a
# git-tracked deploy. After this runs, future deploys are:
#
#   cd /opt/khudmati/backend
#   git pull origin main
#   bash deploy/deploy.sh
#
# Strategy: clone the full Khedmate repo to /opt/khudmati/khudmati-source,
# then sync its backend/ subtree into /opt/khudmati/backend (preserving the
# server-only files .env, firebase-service-account.json, and uploads/).
# Finally, install a wrapper "deploy/pull-and-deploy.sh" that future
# deploys can call.
#
# Run from the server with:
#   bash /opt/khudmati/backend/deploy/init-git.sh
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/AliSleiman0/Khedmate.git"
SOURCE_DIR="/opt/khudmati/khudmati-source"
DEPLOY_DIR="/opt/khudmati/backend"
BRANCH="main"

# ── 1. Sanity check ───────────────────────────────────────────────────────
if [[ ! -d "$DEPLOY_DIR" ]]; then
  echo "ERROR: $DEPLOY_DIR does not exist."
  exit 1
fi
if [[ ! -f "$DEPLOY_DIR/.env" ]]; then
  echo "ERROR: $DEPLOY_DIR/.env not found — refusing to run without server secrets in place."
  exit 1
fi

# ── 2. Snapshot current /opt/khudmati/backend ─────────────────────────────
TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/khudmati/backend.bak.${TS}"
echo "==> Backing up $DEPLOY_DIR -> $BACKUP_DIR"
cp -a "$DEPLOY_DIR" "$BACKUP_DIR"

# ── 3. Clone (or update) the source repo ──────────────────────────────────
if [[ -d "$SOURCE_DIR/.git" ]]; then
  echo "==> $SOURCE_DIR is already a git repo — fetching latest"
  git -C "$SOURCE_DIR" fetch origin
  git -C "$SOURCE_DIR" checkout "$BRANCH"
  git -C "$SOURCE_DIR" pull --ff-only origin "$BRANCH"
else
  echo "==> Cloning $REPO_URL -> $SOURCE_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$SOURCE_DIR"
fi

# ── 4. Sync backend/ subtree into the deploy dir ──────────────────────────
# --delete cleans up files removed upstream; excludes preserve server-only
# files that are not (and must not be) tracked in git.
echo "==> rsync $SOURCE_DIR/backend/ -> $DEPLOY_DIR/"
rsync -av --delete \
  --exclude='.env' \
  --exclude='firebase-service-account.json' \
  --exclude='uploads/' \
  --exclude='*.bak.*' \
  "$SOURCE_DIR/backend/" "$DEPLOY_DIR/"

# ── 5. Apply pending DB migrations ────────────────────────────────────────
# add-service-categories.sql is the only one new since the last deploy. It is
# idempotent (CREATE TABLE IF NOT EXISTS + ON CONFLICT DO NOTHING) so re-runs
# on every git-init are safe.
PG_CONTAINER=$(docker ps --filter "name=postgres" --format '{{.Names}}' | head -n1)
if [[ -n "$PG_CONTAINER" && -f "$DEPLOY_DIR/add-service-categories.sql" ]]; then
  # Source .env for POSTGRES_USER / POSTGRES_DB (deploy.sh requires .env).
  set -a; . "$DEPLOY_DIR/.env"; set +a
  echo "==> Applying add-service-categories.sql against $PG_CONTAINER"
  docker exec -i "$PG_CONTAINER" psql -U "${POSTGRES_USER:?POSTGRES_USER not set in .env}" -d "${POSTGRES_DB:?POSTGRES_DB not set in .env}" \
    < "$DEPLOY_DIR/add-service-categories.sql"
else
  echo "WARN: postgres container not running or migration file missing — skip SQL apply."
fi

# ── 6. Drop a pull-and-deploy wrapper for future deploys ──────────────────
cat > "$DEPLOY_DIR/deploy/pull-and-deploy.sh" <<'WRAPPER'
#!/usr/bin/env bash
# pull-and-deploy.sh — Future deploys: git pull source repo, rsync backend
# subtree, then run deploy.sh. Idempotent, preserves .env + firebase creds.
set -euo pipefail

SOURCE_DIR="/opt/khudmati/khudmati-source"
DEPLOY_DIR="/opt/khudmati/backend"
BRANCH="main"

echo "==> git pull origin $BRANCH"
git -C "$SOURCE_DIR" fetch origin
git -C "$SOURCE_DIR" checkout "$BRANCH"
git -C "$SOURCE_DIR" pull --ff-only origin "$BRANCH"

echo "==> rsync backend subtree"
rsync -av --delete \
  --exclude='.env' \
  --exclude='firebase-service-account.json' \
  --exclude='uploads/' \
  --exclude='*.bak.*' \
  "$SOURCE_DIR/backend/" "$DEPLOY_DIR/"

echo "==> bash deploy/deploy.sh"
cd "$DEPLOY_DIR"
bash deploy/deploy.sh
WRAPPER
chmod +x "$DEPLOY_DIR/deploy/pull-and-deploy.sh"

echo
echo "==> Done."
echo "   Source repo:  $SOURCE_DIR"
echo "   Deploy dir:   $DEPLOY_DIR"
echo "   Backup:       $BACKUP_DIR  (delete once you've verified the deploy)"
echo
echo "Future deploys:  bash $DEPLOY_DIR/deploy/pull-and-deploy.sh"

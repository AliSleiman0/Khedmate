#!/usr/bin/env bash
# =============================================================================
# deploy-web.sh — Build the three Vite web apps and deploy them to nginx.
#
# Strategy: builds run inside a one-shot `node:20-alpine` Docker container
# (no Node install on the host), output is rsynced into /var/www/<name>/
# where the existing nginx container serves it as static files. No nginx
# restart needed.
#
# Run from the server with:
#   bash /opt/khudmati/backend/deploy/deploy-web.sh           # builds all three
#   bash /opt/khudmati/backend/deploy/deploy-web.sh admin     # one app only
#   bash /opt/khudmati/backend/deploy/deploy-web.sh admin landing
# =============================================================================
set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-/opt/khudmati/khudmati-source}"
BRANCH="${BRANCH:-main}"

declare -A APPS=(
  [admin]="web-admin"
  [landing]="web-landing"
  [superadmin]="web-superadmin"
)

# ── 1. Pick which apps to build ─────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
  TARGETS=("admin" "landing" "superadmin")
else
  TARGETS=("$@")
fi

for t in "${TARGETS[@]}"; do
  if [[ -z "${APPS[$t]:-}" ]]; then
    echo "ERROR: unknown app '$t'. Valid: ${!APPS[*]}"
    exit 1
  fi
done

# ── 2. Refresh source ───────────────────────────────────────────────────────
if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  echo "ERROR: $SOURCE_DIR is not a git repo. Run deploy/init-git.sh first."
  exit 1
fi

echo "==> git pull origin $BRANCH"
git -C "$SOURCE_DIR" fetch origin
git -C "$SOURCE_DIR" checkout "$BRANCH"
git -C "$SOURCE_DIR" pull --ff-only origin "$BRANCH"

# ── 3. Build + deploy each requested app ────────────────────────────────────
for t in "${TARGETS[@]}"; do
  APP_DIR="${APPS[$t]}"
  SRC="$SOURCE_DIR/$APP_DIR"
  DEST="/var/www/$t"

  if [[ ! -f "$SRC/package.json" ]]; then
    echo "WARN: $SRC/package.json missing, skipping $t"
    continue
  fi

  echo
  echo "==> [$t] building $APP_DIR"
  # `npm ci` is reproducible; `npm install` would mutate package-lock.json.
  # Mount the app dir + a named npm cache volume so subsequent builds reuse downloads.
  docker run --rm \
    -v "$SRC":/work \
    -v "khudmati_npm_cache_$t":/root/.npm \
    -w /work \
    node:20-alpine \
    sh -c "npm ci && npm run build"

  if [[ ! -d "$SRC/dist" ]]; then
    echo "ERROR: [$t] build produced no dist/ — aborting."
    exit 1
  fi

  echo "==> [$t] rsync dist/ -> $DEST"
  mkdir -p "$DEST"
  rsync -av --delete "$SRC/dist/" "$DEST/"
done

echo
echo "==> Done. Hard-refresh the browser (Ctrl+Shift+R) to bypass cache."
echo "    Smoke tests:"
echo "      curl -sI https://khudmati.app/                      | head -3"
echo "      curl -sI https://admin.khudmati.app/                | head -3"
echo "      curl -sI https://superadmin.khudmati.app/           | head -3"

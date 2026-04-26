#!/usr/bin/env bash
# =============================================================================
# pull-and-deploy.sh — Standard server-side update for the backend.
#
# Pulls the latest source repo, rsyncs the backend subtree into the deploy
# dir (preserving server-only files: .env, firebase-service-account.json,
# uploads/), and runs deploy.sh to rebuild + restart the API container.
#
# Run from the server with:
#   bash /opt/khudmati/backend/deploy/pull-and-deploy.sh
#
# IMPORTANT: the rsync excludes deploy/pull-and-deploy.sh itself so this
# script does not delete itself on each run. (The script is version-controlled
# in this repo, so the exclude keeps the on-server copy stable across runs.)
# =============================================================================
set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-/opt/khudmati/khudmati-source}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/khudmati/backend}"
BRANCH="${BRANCH:-main}"

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  echo "ERROR: $SOURCE_DIR is not a git repo. Run deploy/init-git.sh first."
  exit 1
fi

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

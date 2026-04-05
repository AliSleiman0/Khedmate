#!/usr/bin/env bash
# =============================================================================
# deploy.sh  — Deploy / re-deploy Khudmati backend on the droplet
#
# Run from /opt/khudmati/backend/:
#   bash deploy/deploy.sh
# =============================================================================
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

echo "==> Working directory: $APP_DIR"

# ── 1. Verify .env exists ─────────────────────────────────────────────────
if [[ ! -f ".env" ]]; then
  echo "ERROR: .env not found. Copy .env.example → .env and fill in secrets."
  exit 1
fi

# ── 2. Pull latest images ─────────────────────────────────────────────────
echo "==> Pulling base images"
docker compose -f docker-compose.prod.yml pull postgres nginx

# ── 3. Build API image ────────────────────────────────────────────────────
echo "==> Building API image"
docker compose -f docker-compose.prod.yml build api

# ── 4. Start / restart all services ──────────────────────────────────────
echo "==> Starting all services"
docker compose -f docker-compose.prod.yml up -d --remove-orphans

# ── 5. Wait and run health check ──────────────────────────────────────────
echo "==> Waiting for services to start..."
sleep 8

echo "==> Health check"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/api/health" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "  API is healthy (HTTP 200)"
else
  echo "  WARNING: /api/health returned HTTP ${HTTP_CODE}. Check logs:"
  echo "    docker compose -f docker-compose.prod.yml logs api --tail=50"
fi

echo ""
echo "=========================================================="
echo "  Deployment complete!"
  echo "  API: https://api.khudmati.app/api/health"
echo "  Logs: docker compose -f docker-compose.prod.yml logs -f api"
echo "=========================================================="

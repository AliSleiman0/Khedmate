#!/bin/bash
set -e

echo "=== Installing Certbot ==="
apt-get update -qq
apt-get install -y -qq certbot

echo "=== Opening firewall ports ==="
ufw allow 80/tcp  || true
ufw allow 443/tcp || true

echo "=== Stopping nginx to free port 80 for certbot standalone ==="
docker stop backend-nginx-1

echo "=== Issuing Let's Encrypt certificate ==="
certbot certonly --standalone \
  -d khudmati.app \
  -d www.khudmati.app \
  -d api.khudmati.app \
  --non-interactive \
  --agree-tos \
  -m admin@khudmati.app

echo "=== Restarting nginx with HTTPS config ==="
cd /opt/khudmati/backend
docker compose -f docker-compose.prod.yml up -d --no-deps nginx

echo "=== Waiting for nginx to start ==="
sleep 3

echo "=== Testing endpoints ==="
curl -s -o /dev/null -w "HTTP  khudmati.app     : %{http_code}\n" http://khudmati.app/
curl -s -o /dev/null -w "HTTPS khudmati.app     : %{http_code}\n" https://khudmati.app/
curl -s -o /dev/null -w "HTTPS khudmati.app/admin/    : %{http_code}\n" https://khudmati.app/admin/
curl -s -o /dev/null -w "HTTPS khudmati.app/superadmin/: %{http_code}\n" https://khudmati.app/superadmin/
curl -s -o /dev/null -w "HTTPS api.khudmati.app/api/health: %{http_code}\n" https://api.khudmati.app/api/health

echo "=== Done! ==="

# Set up auto-renewal
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --pre-hook 'docker stop backend-nginx-1' --post-hook 'cd /opt/khudmati/backend && docker compose -f docker-compose.prod.yml up -d --no-deps nginx'") | crontab -
echo "=== Certbot auto-renewal cron installed ==="

#!/usr/bin/env bash
# =============================================================================
# setup-droplet.sh  — Run ONCE on a fresh Ubuntu 22.04 DigitalOcean droplet
#
# Usage (as root or sudo):
#   curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/khudmati/main/backend/deploy/setup-droplet.sh | bash
#   — or — scp this file to the droplet and run: bash setup-droplet.sh
# =============================================================================
set -euo pipefail

echo "==> [1/7] System update"
apt-get update -y && apt-get upgrade -y

echo "==> [2/7] Install dependencies"
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    git \
    ufw \
    fail2ban

echo "==> [3/7] Install Docker Engine"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu \
   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "==> [4/7] Install Docker Compose v2 alias"
ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose || true

echo "==> [5/7] Configure UFW firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

echo "==> [6/7] Enable fail2ban"
systemctl enable fail2ban
systemctl start fail2ban

echo "==> [7/7] Create app directory"
mkdir -p /opt/khudmati/backend
chown -R "$SUDO_USER":"$SUDO_USER" /opt/khudmati 2>/dev/null || true

echo ""
echo "=========================================================="
echo "  Droplet setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Upload your backend/ folder to /opt/khudmati/backend/"
echo "  2. Copy .env.example → .env and fill in all values"
echo "  3. Point your domain DNS A-record to this droplet's IP"
echo "  4. Run deploy/deploy.sh"
echo "=========================================================="

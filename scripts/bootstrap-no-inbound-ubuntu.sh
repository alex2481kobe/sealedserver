#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root or with sudo."
  exit 1
fi

if [[ "${1:-}" == "" ]]; then
  echo "Usage: sudo bash scripts/bootstrap-no-inbound-ubuntu.sh <tailscale-hostname>"
  exit 1
fi

TAILSCALE_HOSTNAME="$1"

apt update
apt upgrade -y
apt install -y nginx sqlite3 unattended-upgrades ufw logrotate cron curl ca-certificates rsync fail2ban

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  mkdir -p /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
    | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
    > /etc/apt/sources.list.d/cloudflared.list
  apt update
  apt install -y cloudflared
fi

systemctl enable --now unattended-upgrades

echo
echo "Base packages installed."
echo "Next:"
echo "1. Run: sudo bash scripts/harden-ubuntu.sh"
echo "2. Run: sudo tailscale up --hostname ${TAILSCALE_HOSTNAME}"
echo "3. Confirm ssh deploy@${TAILSCALE_HOSTNAME} works from another terminal."
echo "4. Run: sudo bash scripts/lock-no-inbound-firewall.sh"
echo "5. Create the Cloudflare Tunnel and install /etc/cloudflared/config.yml."

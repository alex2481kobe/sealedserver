#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root or with sudo."
  exit 1
fi

if ! ip link show tailscale0 >/dev/null 2>&1; then
  echo "tailscale0 is missing. Run and verify Tailscale before locking the firewall."
  exit 1
fi

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow in on tailscale0 to any port 22 proto tcp
ufw --force enable
ufw status verbose

echo
echo "No-inbound firewall applied."
echo "Public 80/443/app ports were not opened."
echo "Admin SSH is allowed only through tailscale0."

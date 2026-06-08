#!/usr/bin/env bash
set -euo pipefail

echo "== UFW =="
if command -v ufw >/dev/null 2>&1; then
  sudo ufw status verbose
else
  echo "ufw is not installed."
fi

echo
echo "== Listening TCP sockets =="
sudo ss -tulpen

echo
echo "Expected no-inbound shape:"
echo "- nginx listens on 127.0.0.1:8080, not 0.0.0.0:80 or 0.0.0.0:443."
echo "- app services listen on 127.0.0.1 ports."
echo "- SSH is reachable over Tailscale only."
echo "- cloudflared connects outbound to Cloudflare."

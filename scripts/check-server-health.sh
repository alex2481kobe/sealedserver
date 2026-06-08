#!/usr/bin/env bash
set -euo pipefail

echo "== Disk =="
df -h /

echo
echo "== Memory =="
free -h || true

echo
echo "== Services =="
for service in nginx cloudflared php8.3-fpm litestream; do
  if systemctl list-unit-files "$service.service" >/dev/null 2>&1; then
    systemctl --no-pager --full status "$service" | sed -n '1,8p'
    echo
  fi
done

echo "== Failed Units =="
systemctl --failed --no-pager

echo
echo "== Firewall =="
ufw status verbose || true

echo
echo "== Recent nginx errors =="
tail -n 40 /var/log/nginx/error.log 2>/dev/null || true

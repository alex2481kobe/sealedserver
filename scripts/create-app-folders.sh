#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root or with sudo."
  exit 1
fi

if [[ "${1:-}" == "" ]]; then
  echo "Usage: sudo bash scripts/create-app-folders.sh <app-name> [static|php|go]"
  exit 1
fi

APP="$1"
LANE="${2:-static}"

case "${LANE}" in
  static|php|go) ;;
  *)
    echo "Lane must be static, php, or go."
    exit 1
    ;;
esac

if ! id "${APP}" >/dev/null 2>&1; then
  useradd -r -m -d "/var/www/${APP}" -s /usr/sbin/nologin "${APP}"
fi

mkdir -p "/var/www/${APP}/public" "/var/lib/${APP}" "/etc/${APP}" "/var/log/${APP}"
chown -R "${APP}:${APP}" "/var/www/${APP}" "/var/lib/${APP}" "/var/log/${APP}"
chmod 750 "/var/www/${APP}" "/var/lib/${APP}" "/var/log/${APP}"

# Env files: root writes them, the app group reads them.
chown root:"${APP}" "/etc/${APP}"
chmod 750 "/etc/${APP}"

# nginx runs as www-data and reads the 750 web root through the app group.
usermod -aG "${APP}" www-data

if [[ "${LANE}" == "go" ]]; then
  mkdir -p "/opt/${APP}"
  chown -R root:root "/opt/${APP}"
  chmod 755 "/opt/${APP}"
fi

echo "Created ${LANE} app folders for ${APP}."
echo "Public root: /var/www/${APP}/public"
echo "Data root:   /var/lib/${APP}"
echo "Env path:    /etc/${APP}/${APP}.env"
echo "Logs root:   /var/log/${APP}"
echo "Restart nginx once so www-data picks up the new group: sudo systemctl restart nginx"

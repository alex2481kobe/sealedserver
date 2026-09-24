#!/usr/bin/env bash
# Closes the firewall to everything except SSH on tailscale0.
# Refuses to run if that would cut off the session you are using.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root or with sudo."
  exit 1
fi

if ! tailscale status --json 2>/dev/null | grep -q '"BackendState": *"Running"'; then
  echo "Tailscale is not connected. Run sudo tailscale up and check SSH over Tailscale first."
  exit 1
fi

# Every open SSH session must come in over Tailscale (100.64.0.0/10 or
# fd7a:115c:a1e0::/48). A session over the public address would be cut off.
outside_peers() {
  ss -Htn state established '( sport = :22 )' | awk '{ print $4 }' | while read -r peer; do
    ip="${peer%:*}"; ip="${ip#[}"; ip="${ip%]}"; ip="${ip#::ffff:}"
    case "${ip}" in
      fd7a:115c:a1e0:*) ;;
      100.*)
        second="$(echo "${ip}" | cut -d. -f2)"
        if (( second < 64 || second > 127 )); then echo "${ip}"; fi
        ;;
      *) echo "${ip}" ;;
    esac
  done
}
outside="$(outside_peers)"
if [[ -n "${outside}" ]]; then
  echo "SSH sessions from outside Tailscale are open and would be cut off:"
  echo "${outside}"
  echo "Reconnect over Tailscale (ssh deploy@<server-name>), close these, then run this again."
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

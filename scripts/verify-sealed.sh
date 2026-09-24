#!/usr/bin/env bash
# Pass/fail check that the server is sealed. Read-only.
# Exits non-zero if any check fails.
#
# Usage: sudo bash scripts/verify-sealed.sh
set -u # no pipefail: command output is captured first, then checked

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo."
  exit 1
fi

pass=0
fail=0
check() { # check "description" command...
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS  ${desc}"
    pass=$((pass + 1))
  else
    echo "FAIL  ${desc}"
    fail=$((fail + 1))
  fi
}
has() { grep -qxE "$2" <<<"$1"; }
# At least one allow rule, and every one of them is on tailscale0.
all_on_tailscale() { [[ -n "$1" ]] && ! grep -v 'on tailscale0' <<<"$1" | grep -q .; }

# A TCP listener is public unless it is on loopback or a Tailscale address.
# Port 22 is allowed on every address because UFW admits it on tailscale0 only.
public_listeners() {
  ss -Htlnp | awk '{ print $4, $6 }' | while read -r addr proc; do
    [[ "${addr##*:}" == "22" ]] && continue
    ip="${addr%:*}"; ip="${ip#[}"; ip="${ip%]}"; ip="${ip%\%*}"
    case "${ip}" in
      127.* | ::1 | fd7a:115c:a1e0:*) continue ;;
      100.*)
        second="$(echo "${ip}" | cut -d. -f2)"
        if (( second >= 64 && second <= 127 )); then continue; fi
        ;;
    esac
    echo "${addr} ${proc}"
  done
}

sshd_config="$(sshd -T 2>/dev/null)"
ufw_status="$(ufw status verbose 2>/dev/null)"
ufw_allows="$(grep ALLOW <<<"${ufw_status}")"
tailscale_json="$(tailscale status --json 2>/dev/null)"
open_ports="$(public_listeners)"

echo "SSH"
check "root login off" has "${sshd_config}" 'permitrootlogin no'
check "password login off" has "${sshd_config}" 'passwordauthentication no'
check "keyboard-interactive login off" has "${sshd_config}" 'kbdinteractiveauthentication no'
check "key login on" has "${sshd_config}" 'pubkeyauthentication yes'

echo "Firewall"
check "UFW active" has "${ufw_status}" 'Status: active'
check "inbound denied by default" grep -q 'deny (incoming)' <<<"${ufw_status}"
check "every allow rule is on tailscale0" all_on_tailscale "${ufw_allows}"
check "no public TCP listeners besides SSH" test -z "${open_ports}"

echo "Tailscale"
check "tailscaled running" systemctl is-active --quiet tailscaled
check "connected" grep -qE '"BackendState": *"Running"' <<<"${tailscale_json}"

echo "Updates"
check "unattended upgrades enabled" systemctl is-enabled --quiet unattended-upgrades
check "automatic reboot on" grep -q 'Unattended-Upgrade::Automatic-Reboot "true"' <<<"$(apt-config dump 2>/dev/null)"

if [[ -n "${open_ports}" ]]; then
  echo
  echo "Public TCP listeners:"
  echo "${open_ports}"
fi
echo
echo "Passed: ${pass}  Failed: ${fail}"
[[ "${fail}" -eq 0 ]]

#!/usr/bin/env bash
# Run from your own machine. Over SSH, it hardens the server, installs updates,
# reboots if the updates need it, and saves a server report locally.
#
# Asks for the SSH key passphrase once and the sudo password once per run.
# The key goes into a private ssh-agent that only this run uses and that is
# killed when the script ends, so no other terminal can use the unlocked key.
# The sudo password stays in this script's memory and goes to sudo over the
# SSH connection only.
#
# Usage: bash scripts/maintain-server.sh deploy@<server-name> [all|report] [output-dir]
#   all     harden, update, reboot if needed, report (default)
#   report  report only
set -euo pipefail

HOST="${1:-}"
MODE="${2:-all}"
OUT_DIR="${3:-.}"
if [[ -z "${HOST}" || ! "${MODE}" =~ ^(all|report)$ ]]; then
  echo "Usage: bash scripts/maintain-server.sh deploy@<server-name> [all|report] [output-dir]" >&2
  exit 1
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
REMOTE_DIR=".backend-template-scripts"
say() { printf '\n== %s\n' "$1"; }
remote() { ssh "${SSH_OPTS[@]}" "${HOST}" "$@"; }
# -k: always read the password, so it is never left over as the command's input.
remote_sudo() { printf '%s\n' "${SUDO_PW}" | remote "sudo -k -S -p '' $*"; }

# Private agent for this run only, never the shared one.
eval "$(ssh-agent -s)" >/dev/null
trap 'ssh-agent -k >/dev/null 2>&1' EXIT
trap 'exit 130' INT TERM
ssh-add
SSH_OPTS=(-o ConnectTimeout=10 -o BatchMode=yes -o "IdentityAgent=${SSH_AUTH_SOCK}" -o AddKeysToAgent=no)

say "Connecting to ${HOST}"
if ! remote true; then
  echo "Cannot reach ${HOST}. Is Tailscale connected, and is the key right?" >&2
  exit 1
fi

read -rsp "sudo password for ${HOST}: " SUDO_PW
echo
if ! remote_sudo true 2>/dev/null; then
  echo "sudo password was not accepted." >&2
  exit 1
fi

remote "mkdir -p ${REMOTE_DIR}"
scp -q "${SSH_OPTS[@]}" "${HERE}/harden-ubuntu.sh" "${HERE}/server-report.sh" "${HOST}:${REMOTE_DIR}/"

if [[ "${MODE}" == "all" ]]; then
  say "Hardening"
  remote_sudo bash "${REMOTE_DIR}/harden-ubuntu.sh"

  say "Checking a new SSH login still works"
  if ! remote true; then
    echo "A new SSH login failed. Keep any open sessions and fix it through the provider console." >&2
    exit 1
  fi
  echo "ok"

  say "Updating packages"
  remote_sudo env DEBIAN_FRONTEND=noninteractive bash -c "'apt-get update -q && apt-get -q -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef full-upgrade && apt-get -q -y autoremove'"

  if remote test -f /var/run/reboot-required; then
    say "Rebooting"
    remote_sudo systemctl reboot || true
    sleep 20
    for _ in $(seq 1 30); do
      if remote true 2>/dev/null; then break; fi
      sleep 10
    done
    remote true || { echo "${HOST} did not come back within 5 minutes." >&2; exit 1; }
    echo "back up"
  else
    say "No reboot needed"
  fi
fi

say "Server report"
mkdir -p "${OUT_DIR}"
report="${OUT_DIR}/server-report-$(date +%Y-%m-%d-%H%M).txt"
(umask 077; remote_sudo bash "${REMOTE_DIR}/server-report.sh" > "${report}")
remote "rm -rf ${REMOTE_DIR}"
unset SUDO_PW
echo "Saved ${report}"
echo "Compare with an older one: diff <older-report> ${report}"

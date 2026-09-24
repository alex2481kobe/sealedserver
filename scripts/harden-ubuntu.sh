#!/usr/bin/env bash
# Hardening for a server built from this template. Safe to run again.
#
# - SSH: keys only, no root login, no X11 forwarding.
# - Security updates reboot the server at 04:00 UTC when they need to.
#
# Usage: sudo bash scripts/harden-ubuntu.sh
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo."
  exit 1
fi

# Turning off root login is only safe if a sudo user can log in with a key.
key_user=""
for user in $(getent group sudo | cut -d: -f4 | tr ',' ' '); do
  home=$(getent passwd "${user}" | cut -d: -f6)
  if [[ -s "${home}/.ssh/authorized_keys" ]]; then key_user="${user}"; fi
done
if [[ -z "${key_user}" ]]; then
  echo "No sudo user has SSH keys. Create one (see documentation/setup.md) before running this."
  exit 1
fi

# Ubuntu reads sshd_config.d first and the first value wins, so this file
# overrides sshd_config and cloud-init's 50-cloud-init.conf.
cat > /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
X11Forwarding no
EOF
mkdir -p /run/sshd # Ubuntu 24.04 starts sshd on demand; the check needs this folder
sshd -t
systemctl reload ssh || true

cat > /etc/apt/apt.conf.d/52-automatic-reboot <<'EOF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
EOF

echo
echo "SSH now:"
sshd -T | grep -E '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|x11forwarding) '
echo
echo "Before closing this session, check ssh ${key_user}@<server-name> works from a second terminal."

#!/usr/bin/env bash
# Read-only report of a server: stack, users, app folders, listeners, firewall,
# SSH, services, nginx, tunnel, backups, then live readings and origin timings.
#
# It changes nothing. Secret-looking values are masked and env files show key
# names only. Stable sections come first so two reports diff cleanly.
#
# Usage: sudo bash scripts/server-report.sh > server-report.txt

set -uo pipefail # no -e: one failing probe must not stop the report

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

section() { printf '\n## %s\n\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
mask() {
  sed -E '/^[[:space:]]*server_tokens /!s/((token|secret|password|passwd|api[_-]?key|access[_-]?key|private[_-]?key|authorization|bearer|credentials)[^=: ]*[=: ]+)[^ ;"]+/\1<masked>/Ig'
}
env_keys() {
  awk '/^[ \t]*(#|$)/ { next } /=/ {
    k = $0; sub(/=.*/, "", k); sub(/^[ \t]*(export[ \t]+)?/, "", k)
    v = substr($0, index($0, "=") + 1)
    print "    " k "=" (v == "" ? "<empty>" : "<set>")
  }' "$1"
}
version() { if have "$1"; then printf '%-14s %s\n' "$1" "$("$@" 2>&1 | head -1)"; else printf '%-14s not installed\n' "$1"; fi; }

echo "# Server report"
echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

section "System"
. /etc/os-release && echo "OS:       ${PRETTY_NAME}"
echo "Kernel:   $(uname -r)"
echo "Virt:     $(systemd-detect-virt 2>/dev/null)"
echo "CPUs:     $(nproc)"
echo "Memory:   $(free -h | awk '/^Mem:/ { print $2 }')"
echo "Swap:     $(free -h | awk '/^Swap:/ { print $2 }')"
echo "Disk /:   $(df -h / | awk 'NR == 2 { print $2 }')"
echo "Timezone: $(timedatectl show -p Timezone --value 2>/dev/null)"

section "Stack"
version nginx -v
version php -v
version go version
version cloudflared --version
version tailscale version
version litestream version
version sqlite3 --version
version fail2ban-client --version
version certbot --version
version docker --version
version redis-server --version
version psql --version
version node --version
version caddy version
echo
dpkg-query -W -f='${Package} ${Version}\n' 'php*' 'nginx*' 2>/dev/null | sort

section "Users and access"
echo "Login users (uid >= 1000):"
getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 { print "  " $1 " shell=" $7 }' | sort
echo
echo "sudo group: $(getent group sudo | cut -d: -f4)"
echo "www-data:   $(id www-data 2>/dev/null)"
echo "sudoers.d:  $(ls /etc/sudoers.d 2>/dev/null | tr '\n' ' ')"
for home in /root /home/*; do
  keys="${home}/.ssh/authorized_keys"
  [[ -f "${keys}" ]] && echo "$(basename "${home}") authorized_keys: $(grep -cE '^(ssh|ecdsa|sk-)' "${keys}") key(s), types: $(awk '/^(ssh|ecdsa|sk-)/ { print $1 }' "${keys}" | sort | uniq -c | tr -s ' ' | tr '\n' ' ')"
done

section "App folders"
# Apps: folders under /var/www and /opt, plus the users custom units run as.
apps=$( (ls /var/www 2>/dev/null; ls /opt 2>/dev/null; sed -n 's/^User=//p' /etc/systemd/system/*.service 2>/dev/null) \
  | grep -vxE 'html|containerd|root' | sort -u)
for app in ${apps}; do
  echo "${app}:"
  id "${app}" >/dev/null 2>&1 && echo "    user: $(getent passwd "${app}" | awk -F: '{ print "uid=" $3 " home=" $6 " shell=" $7 }')"
  for dir in "/var/www/${app}" "/var/www/${app}/public" "/opt/${app}" "/var/lib/${app}" "/etc/${app}" "/var/log/${app}"; do
    [[ -e "${dir}" ]] && stat -c '    %A %U:%G %n' "${dir}"
  done
  [[ -d "/var/www/${app}/public" ]] && echo "    public: $(find "/var/www/${app}/public" -type f | wc -l) files, $(du -sh "/var/www/${app}/public" | cut -f1)"
  for file in /etc/"${app}"/*; do
    [[ -f "${file}" ]] || continue
    stat -c '    %A %U:%G %n (%s bytes)' "${file}"
    if [[ "${file}" == *.env ]]; then env_keys "${file}"; fi
  done
done

section "Listeners"
ss -tulnpH | awk '{ print $1, $5, $7 }' | sort -u

section "Firewall"
ufw status verbose 2>&1

section "SSH and Tailscale"
sshd -T 2>/dev/null | grep -E '^(port|listenaddress|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|allowusers|allowgroups|maxauthtries|x11forwarding) ' | sort
echo
tailscale debug prefs 2>/dev/null | grep -E '"(RunSSH|Hostname|AdvertiseTags|ShieldsUp|AdvertiseRoutes)"'

section "Services"
echo "Running:"
systemctl list-units --type=service --state=running --no-legend --plain | awk '{ print "  " $1 }' | sort
echo
echo "Failed:"
systemctl list-units --state=failed --no-legend --plain | awk '{ print "  " $1 }'
echo
echo "Enabled timers:"
systemctl list-unit-files --type=timer --state=enabled --no-legend | awk '{ print "  " $1 }' | sort
echo
echo "Cron: $(ls /etc/cron.d 2>/dev/null | tr '\n' ' ')"
for user in root $(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 { print $1 }'); do
  echo "crontab ${user}: $(crontab -l -u "${user}" 2>/dev/null | grep -cvE '^[[:space:]]*(#|$)') entries"
done
echo
for unit in /etc/systemd/system/*.service; do
  [[ -f "${unit}" && ! -L "${unit}" ]] || continue
  name=$(basename "${unit}")
  echo "--- ${unit} (enabled: $(systemctl is-enabled "${name}" 2>&1), active: $(systemctl is-active "${name}" 2>&1))"
  sed -E 's/^(Environment=).*/\1<masked>/' "${unit}" | grep -vE '^[[:space:]]*(#|$)' | mask
done

section "PHP-FPM pools"
for pool in /etc/php/*/fpm/pool.d/*.conf; do
  [[ -f "${pool}" ]] || continue
  echo "--- ${pool}"
  grep -vE '^[[:space:]]*(;|$)' "${pool}" | sed -E 's/^(env\[[^]]*\][[:space:]]*=).*/\1 <masked>/' | mask
done

section "Cloudflare Tunnel"
systemctl cat cloudflared 2>/dev/null | grep -E '^ExecStart=' | mask
for config in /etc/cloudflared/config.yml /root/.cloudflared/config.yml /home/*/.cloudflared/config.yml; do
  [[ -f "${config}" ]] || continue
  echo "--- ${config}"
  grep -E '^[[:space:]]*(- )?(hostname|service|path|protocol|originRequest|noTLSVerify):' "${config}"
done

section "Backups"
systemctl list-units 'litestream*' --all --no-legend --plain | awk '{ print $1, $3, $4 }'
for config in /etc/litestream.yml /etc/*/litestream.yml; do
  [[ -f "${config}" ]] && echo "${config}: $(grep -E '^[[:space:]]*- path:' "${config}" | tr -s ' ' | tr '\n' ' ')"
done
echo "SQLite files:"
find /var/lib /var/www /opt -maxdepth 3 -type f \( -name '*.sqlite' -o -name '*.sqlite3' -o -name '*.db' \) 2>/dev/null \
  | grep -vE '^/var/lib/(apt|dpkg|systemd|ucf|PackageKit|fwupd|snapd|tailscale)' | while read -r db; do stat -c '  %A %U:%G %n' "${db}"; done

section "Updates and hardening"
echo "unattended-upgrades: $(systemctl is-enabled unattended-upgrades 2>&1)"
grep -hE 'Unattended-Upgrade|Update-Package-Lists' /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null
echo "fail2ban: $(fail2ban-client status 2>/dev/null | grep 'Jail list' | cut -f2-)"

section "nginx config"
nginx -t 2>&1
echo
echo "sites-enabled: $(ls /etc/nginx/sites-enabled 2>/dev/null | tr '\n' ' ')"
echo "conf.d:        $(ls /etc/nginx/conf.d 2>/dev/null | tr '\n' ' ')"
echo
nginx -T 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' | mask

section "Live readings (change every run)"
uptime
echo
free -m
echo
df -h -x tmpfs -x devtmpfs -x squashfs -x overlay
echo
echo "Pending updates: $(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l), reboot required: $([[ -f /var/run/reboot-required ]] && echo yes || echo no)"
echo "Journal size: $(journalctl --disk-usage 2>/dev/null | grep -oE '[0-9.]+[KMGT]')"
echo "/var/log size: $(du -sh /var/log 2>/dev/null | cut -f1)"
echo "Failed SSH logins, last 24h: $(journalctl -u ssh --since -24h --no-pager 2>/dev/null | grep -c 'Failed')"
echo
echo "Top processes by memory:"
ps -eo user,%cpu,%mem,rss,comm --sort=-rss | head -11
echo
echo "Recent nginx errors:"
tail -n 20 /var/log/nginx/error.log 2>/dev/null

section "Origin timings (5 requests per host to 127.0.0.1:8080)"
hosts=$(nginx -T 2>/dev/null | awk '$1 == "server_name" { for (i = 2; i <= NF; i++) { gsub(";", "", $i); print $i } }' | grep -vE '^(_|localhost)$|[*~]' | sort -u)
printf '%-40s %5s %10s %22s\n' host code bytes "first-byte ms min/max"
for host in ${hosts}; do
  for _ in 1 2 3 4 5; do
    curl -s -o /dev/null -m 10 -H "Host: ${host}" -w '%{http_code} %{size_download} %{time_starttransfer}\n' http://127.0.0.1:8080/
  done | awk -v h="${host}" '{ ms = $3 * 1000; if (NR == 1 || ms < lo) lo = ms; if (ms > hi) hi = ms; c = $1; b = $2 }
    END { printf "%-40s %5s %10s %13.1f / %.1f\n", h, c, b, lo, hi }'
done

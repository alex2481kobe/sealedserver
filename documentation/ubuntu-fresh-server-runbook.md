# Ubuntu Fresh Server Runbook

This is the end-to-end path for a new Ubuntu VPS.

## 1. First Login

If no provider console password is available, temporarily allow public SSH from the admin's current IP only, then remove that rule after Tailscale works.

```sh
ssh root@<server-ip>
apt update
apt upgrade -y
```

Create a deploy/admin user if the provider only gave root:

```sh
adduser deploy
usermod -aG sudo deploy
mkdir -p /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
```

Log out and continue as `deploy`.

## 2. Basic Security

```sh
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo systemctl reload ssh
```

Install base packages:

```sh
sudo apt update
sudo apt install -y unattended-upgrades ufw fail2ban nginx sqlite3 curl ca-certificates rsync git logrotate cron
```

Enable unattended upgrades:

```sh
sudo systemctl enable --now unattended-upgrades
```

## 3. Private Access

Install Tailscale:

```sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname <server-name>
```

Confirm SSH over Tailscale works before enabling UFW:

```sh
ssh root@<server-name>
```

If using Tailscale SSH instead of normal OpenSSH over Tailscale, start Tailscale with:

```sh
sudo tailscale up --ssh --hostname <server-name>
tailscale ssh root@<server-name>
```

For production, also follow `documentation/tailscale-hardening.md`:

- enable device approval;
- use a one-off pre-approved auth key when automating setup;
- tag servers with `tag:server` and `tag:prod`;
- choose Tailscale SSH check mode or normal OpenSSH over Tailscale.

## 4. Firewall

Set the provider firewall to deny public inbound traffic once Tailscale SSH is verified. The server firewall below is the second layer.

No-inbound Tunnel mode:

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

Direct public mode:

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

## 5. App Folders

For each app:

```sh
APP=example
sudo useradd -r -m -d /var/www/$APP -s /usr/sbin/nologin $APP
sudo mkdir -p /var/www/$APP /var/lib/$APP /etc/$APP /var/log/$APP
sudo chown -R $APP:$APP /var/www/$APP /var/lib/$APP /var/log/$APP
sudo chmod 750 /etc/$APP
```

## 6. PHP Lane

```sh
sudo apt install php8.3-cli php8.3-fpm php8.3-sqlite3
sudo systemctl enable --now php8.3-fpm
```

## 7. SQLite Backup Lane

```sh
curl -fsSL https://litestream.io/install.sh | sudo bash
```

Install one Litestream service per SQLite app or one shared config that lists all DBs.

## 8. Cloudflare Tunnel Lane

```sh
cloudflared tunnel login
cloudflared tunnel create <tunnel-name>
cloudflared tunnel route dns <tunnel-name> example.com
sudo cp /path/to/config.yml /etc/cloudflared/config.yml
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

For Cloudflare account, Tunnel, WAF, Turnstile, DNSSEC, and Access setup, follow `documentation/cloudflare-hardening.md`.

## 9. Verification

```sh
sudo nginx -t
sudo systemctl status nginx
sudo systemctl status cloudflared
sudo systemctl status php8.3-fpm
sudo ufw status verbose
```

Check app health:

```sh
curl http://127.0.0.1:<local-port>/api/healthz
curl -I https://example.com
```

Run the template checks:

```sh
sudo bash scripts/verify-no-inbound.sh
sudo bash scripts/check-server-health.sh
```

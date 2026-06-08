# Server Bootstrap

High-level checklist for a fresh Ubuntu server. For exact commands, use `documentation/ubuntu-fresh-server-runbook.md`.

1. Create the server with SSH key authentication.
2. Disable password SSH login.
3. Install only the dependency lanes needed by the apps. See `documentation/dependencies.md`.
4. Enable unattended security upgrades.
5. Configure Tailscale for private SSH/admin access.
6. Configure UFW. Preferred first mode is no-inbound: deny public incoming traffic, allow outbound traffic, and allow SSH only on `tailscale0`.
7. Configure Cloudflare DNS/CDN/WAF. Use Cloudflare Tunnel if you want no public inbound ports; use Certbot only when nginx terminates public TLS directly.
8. Create one Linux user per app.
9. Create `/var/www/<app>`, `/var/lib/<app>`, `/etc/<app>`, and `/var/log/<app>`.
10. Install nginx site files per domain/subdomain.
11. Install systemd units for backend services.
12. Configure SQLite backups before production writes matter.
13. Test restore from backup before relying on the server.

## Scripted No-Inbound Path

The helper scripts encode the preferred first-server posture:

```sh
sudo bash scripts/bootstrap-no-inbound-ubuntu.sh <server-name>
sudo tailscale up --ssh --hostname <server-name>
sudo bash scripts/lock-no-inbound-firewall.sh
sudo bash scripts/create-app-folders.sh example static
sudo bash scripts/verify-no-inbound.sh
sudo bash scripts/check-server-health.sh
```

Run the firewall script only after Tailscale access is confirmed from another terminal.

Before production traffic, also complete:

- `documentation/tailscale-hardening.md`
- `documentation/cloudflare-hardening.md`
- `documentation/backup-restore-drills.md` for any SQLite app

## App Isolation

Each app should be independently movable. Do not share one database across every product, and do not run every backend as the same Linux user.

## Admin Access

Prefer Tailscale or Cloudflare Access for dashboards and server administration. Do not expose private dashboards publicly by default.

# Security Checklist

## Server

- SSH keys only.
- Disable password SSH login.
- Enable `ufw`.
- Use cron only for simple recurring jobs; use systemd timers for jobs that need stronger logs and failure visibility.
- Enable unattended security upgrades.
- Use Tailscale for private SSH/admin access.
- Keep admin dashboards off the public internet or behind Cloudflare Access/Tailscale.
- Keep app users separate.
- Keep env files in `/etc/<app>`, not the deployed code folder.
- Lock the VPS provider firewall to no public inbound ports in Tunnel mode.
- Run `scripts/verify-no-inbound.sh` after firewall, nginx, or Tunnel changes.

## Cloudflare

- Enable 2FA for all Cloudflare users.
- Use least-privilege API tokens instead of the global API key.
- Enable DNSSEC after nameserver migration is stable.
- Use Tunnel public hostnames for no-inbound apps.
- Add WAF rules for strange methods, dotfile probes, admin paths, and abusive public writes.
- Use Cloudflare Access if an admin hostname must be public.
- Validate Turnstile tokens server-side.
- Never challenge payment webhook paths; verify webhook signatures in the app.
- See `documentation/cloudflare-hardening.md` and `infra/cloudflare/waf-baseline.md`.

## Tailscale

- Enable device approval.
- Use server tags such as `tag:server` and `tag:prod`.
- Use one-off auth keys for server setup.
- Prefer Tailscale SSH with check mode for production servers.
- Restrict SSH users to `deploy` unless root is explicitly needed.
- Remove stale machines.
- See `documentation/tailscale-hardening.md` and `infra/tailscale/tailnet-policy.example.hujson`.

## nginx

- Run `sudo nginx -t` before reloads.
- Add security headers.
- Set sane `client_max_body_size`.
- Cache hashed static assets aggressively.
- Do not expose dotfiles.
- Proxy websocket routes with `Upgrade` and `Connection` headers.

## PHP

- Validate JSON at the route boundary.
- Use prepared statements.
- Set max body size.
- Use SQLite WAL and `busy_timeout`.
- Keep admin endpoints token-protected and private.
- Verify Lemon Squeezy webhook signatures before trusting purchase events.

## Go

- Set `ReadHeaderTimeout`.
- Keep service bound to `127.0.0.1` unless it must listen publicly.
- Terminate TLS at nginx, Caddy, Cloudflare Tunnel, or a load balancer.
- Log structured errors without secrets.
- Add graceful shutdown for long-running services.

## SQLite

- Store DB files under `/var/lib/<app>`.
- Back up with Litestream or an equivalent tested flow.
- Test restore before production data matters.
- Use Postgres when write contention or operational needs outgrow SQLite.
- Run monthly restore drills for production SQLite apps.
- See `documentation/backup-restore-drills.md`.

# VPS Backend Template

A practical Ubuntu VPS template for small production apps: static sites, PHP +
SQLite backends, Go services, nginx, Cloudflare Tunnel, Tailscale, systemd,
Litestream backups, per-app isolation, and safe open-source contribution
defaults.

This repo is meant to be copied, trimmed, and adapted. It gives you a clear
server shape without forcing Docker, Kubernetes, Redis, Postgres, or a managed
platform before the app actually needs them.

## What You Get

- Static-site, PHP + SQLite, and Go service starter lanes.
- nginx configs for direct public hosting and no-inbound Cloudflare Tunnel mode.
- Ubuntu hardening and bootstrap runbooks.
- Tailscale admin-access guidance.
- Cloudflare WAF, Tunnel, R2, and cache notes.
- systemd, cron, logrotate, and Litestream examples.
- Per-app Linux user, folder, env, logs, and database conventions.
- Small ops helpers for private SSH-only status, logs, and app shells.
- Public/private workspace templates for keeping local notes and secrets out of git.
- Contributor, security, and read-only CI defaults for open source.

## Default Stack

| Need | Default |
| --- | --- |
| Static website | nginx static files |
| Small web API/admin/download backend | PHP 8.3 + SQLite |
| Realtime or long-running service | Go + SQLite |
| Large files | Cloudflare R2 |
| SQLite backups | Litestream |
| Scheduled jobs | cron or systemd timers |
| Admin access | Tailscale SSH |
| Public routing | Cloudflare Tunnel or Cloudflare-proxied nginx |

## When To Add More

Use Postgres when you need high-concurrency writes, complex reporting, team
permissions, marketplace-style data, or you already depend on Postgres.

Use Redis, NATS, or another message bus only when one process cannot own the
live state: distributed queues, pub/sub, cross-node presence, distributed rate
limits, or shared matchmaking.

Use Docker when the app has dependencies that are hard to install repeatably, or
when orchestration becomes genuinely useful. It is not the default for this
template.

## Repository Shape

```text
vps-backend-template/
  README.md
  documentation/
  apps/
    static-site/
    php-sqlite-app/
    go-service/
  infra/
    cloudflare/
    cron/
    litestream/
    logrotate/
    manifests/
    nginx/
    sudoers/
    systemd/
    tailscale/
  ops/
  scripts/
  template-root/
```

`template-root/` contains files you can copy into a new project root. Those
templates help keep local-only agent notes, scratch docs, secrets, build output,
and throwaway archives out of tracked public files.

## Quick Start

1. Clone or copy the repo.
2. Pick one starter lane:
   - `apps/static-site`
   - `apps/php-sqlite-app`
   - `apps/go-service`
3. Read `documentation/stack-decisions.md`.
4. Create an app manifest from `documentation/app-manifest.md`.
5. For a new server, follow `documentation/ubuntu-fresh-server-runbook.md`.
6. For no-inbound hosting, follow `documentation/no-inbound-server.md`.
7. Deploy each app with `documentation/deployment-flow.md`.
8. For SQLite apps, run the restore drill in `documentation/backup-restore-drills.md`.

## Server Model

The preferred first deployment mode is no-inbound:

```text
Cloudflare edge
  -> cloudflared outbound tunnel
  -> nginx on 127.0.0.1:8080
  -> app-specific static folders or localhost services
```

That lets the VPS firewall deny public inbound traffic while Cloudflare Tunnel
publishes the public hostnames. Direct public `80/443` is also documented for
cases where you intentionally want nginx reachable from the internet.

## Starter Apps

### Static Site

Use `apps/static-site` for simple sites, docs, landing pages, legal pages, and
prebuilt frontend bundles.

### PHP + SQLite App

Use `apps/php-sqlite-app` for small APIs, admin dashboards, event tracking,
download records, webhook capture, and boring durable web backends.

### Go Service

Use `apps/go-service` for websocket tools, workers, realtime services,
simulation loops, utility APIs, and compiled long-running services.

## Validation

Useful local checks:

```sh
cd apps/go-service
go test ./...
```

```sh
php -l apps/php-sqlite-app/public/index.php
php -l apps/php-sqlite-app/scripts/migrate.php
php -l apps/php-sqlite-app/src/bootstrap.php
php -l apps/php-sqlite-app/src/commerce.php
php -l apps/php-sqlite-app/src/records.php
php -l apps/php-sqlite-app/src/assets.php
```

```sh
sh -n scripts/bootstrap-no-inbound-ubuntu.sh
sh -n scripts/check-server-health.sh
sh -n scripts/create-app-folders.sh
sh -n scripts/lock-no-inbound-firewall.sh
sh -n scripts/verify-no-inbound.sh
```

## Open Source Safety

This repository is configured for a solo-owner open-source workflow:

- outside pull requests are reviewed before privileged work runs;
- CI uses read-only repository permissions and no secrets;
- dependency changes are reviewed manually instead of being auto-opened or
  auto-merged by bots;
- the owner can still push or merge their own work while the project has one
  maintainer.

See `CONTRIBUTING.md`, `SECURITY.md`, and `.github/` for the public policy and
workflow defaults.

## Security Notes

- Keep real env files, credentials, private hostnames, and live server notes out
  of git.
- Bind app services to localhost unless they must listen publicly.
- Keep admin dashboards private through Tailscale or Cloudflare Access.
- Use one Linux user per app.
- Test backup restores before trusting production data.
- Version or hash immutable static assets when they change.

## License

MIT. See `LICENSE`.

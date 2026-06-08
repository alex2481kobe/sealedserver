# Migration Checklist

Use this checklist when moving a site or service from another host to a VPS
using this template.

## Before Migration

1. Write an app manifest from `documentation/app-manifest.md`.
2. Choose the app lane: static site, PHP + SQLite app, Go service, or existing backend.
3. Inventory current DNS, redirects, TLS, env values, databases, logs, storage, and cron jobs.
4. Decide the rollback path before changing DNS or Tunnel routes.
5. Create the app Linux user and folders.
6. Install nginx and systemd templates.
7. Configure backups before production writes matter.
8. Run local health checks.

## Cutover

1. Deploy files or binaries to the new server.
2. Verify the origin through localhost/nginx with the intended `Host` header.
3. Start and inspect services with `systemctl` and `journalctl`.
4. Route DNS or Cloudflare Tunnel hostnames to the new origin.
5. Verify public HTTPS responses.
6. Watch logs during the first real traffic.
7. Keep the old host available until rollback is no longer needed.

## After Migration

1. Run restore drills for any SQLite database.
2. Confirm public inbound firewall posture.
3. Confirm admin routes are private or protected.
4. Confirm static assets are versioned or content-hashed when immutable cache headers are used.
5. Remove old hosting only after the new route is stable.

## Cost Control

Start by consolidating low-risk static sites and small APIs. Move realtime,
payment, subscription, or user-data-heavy services only after their runtime and
data migration plan is concrete.

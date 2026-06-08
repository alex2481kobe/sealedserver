# Deployment Flow

Use this flow for a new app on an Ubuntu server.

Before setup, write an app manifest using `documentation/app-manifest.md`.

For a fresh VPS, run `documentation/ubuntu-fresh-server-runbook.md` first. For no-inbound hosting, follow `documentation/no-inbound-server.md`.

For the first shared production server, also read `documentation/first-server-consolidation.md`. It explains the shared nginx listener, local port map, and how multiple apps fit on one server without becoming one monolith.

## 1. Create App User And Folders

```sh
sudo useradd -r -m -d /var/www/example -s /usr/sbin/nologin example
sudo mkdir -p /var/www/example /var/lib/example /etc/example /var/log/example
sudo chown -R example:example /var/www/example /var/lib/example /var/log/example
sudo chmod 750 /etc/example
```

Or use the helper:

```sh
sudo bash scripts/create-app-folders.sh example static
sudo bash scripts/create-app-folders.sh example php
sudo bash scripts/create-app-folders.sh example go
```

Store production env values in:

```text
/etc/example/example.env
```

Store SQLite data in:

```text
/var/lib/example/example.sqlite
```

## 2. Deploy Code

Static site:

```text
/var/www/example/public
```

PHP app:

```text
/var/www/example/public
/var/www/example/src
/var/www/example/db/schema.sql
```

Go service:

```text
/var/www/example/example-server
```

For static assets served with long immutable cache headers, deploys must also
change the public asset URL when a browser-visible asset changes. Prefer
content-hashed filenames from a build tool. For plain static sites without a
build step, use a version query on CSS/JS references, such as:

```html
<link rel="stylesheet" href="/assets/css/styles.css?v=YYYYMMDDa">
```

This avoids the failure mode where nginx has the new file but Cloudflare or the
browser continues serving an old cached asset.

## 3. Install nginx Config

Copy the matching file from `infra/nginx/` into:

```text
/etc/nginx/sites-available/example.conf
```

Then:

```sh
sudo ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled/example.conf
sudo nginx -t
sudo systemctl reload nginx
```

## 4. Install systemd Unit

For Go services, copy the unit from `infra/systemd/` into:

```text
/etc/systemd/system/example.service
```

Then:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now example
sudo systemctl status example
```

PHP-FPM is usually shared through `php8.3-fpm`; do not create a custom systemd service unless the app has a worker.

## 4b. Install Scheduled Jobs

Use cron for simple recurring commands:

```text
/etc/cron.d/example
```

Use systemd timers when the job needs dependencies, journald logs, separate enable/disable controls, or stronger failure visibility.

## 5. Configure Backups

For SQLite apps:

1. Put the database under `/var/lib/<app>`.
2. Configure Litestream from `infra/litestream/`.
3. Restore-test before trusting it.

Use `documentation/backup-restore-drills.md` for the exact restore-test flow.

## 6. Verify

```sh
curl -I https://example.com
curl https://example.com/api/healthz
sudo journalctl -u example --since "10 minutes ago"
```

For PHP-only apps, check:

```sh
sudo systemctl status php8.3-fpm
sudo tail -n 50 /var/log/nginx/error.log
```

For shared-server posture checks:

```sh
sudo bash scripts/verify-no-inbound.sh
sudo bash scripts/check-server-health.sh
```

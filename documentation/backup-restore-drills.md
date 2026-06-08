# Backup And Restore Drills

Backups are not real until a restore has succeeded. For this template, SQLite apps use Litestream to replicate database changes to object storage such as Cloudflare R2.

## What Needs Backup

Back up:

- SQLite databases under `/var/lib/<app>/`;
- app env file inventory, without exposing secret values;
- nginx site files;
- systemd unit files;
- cloudflared config metadata, without tunnel credentials;
- uploaded files if an app ever stores local uploads.

Do not rely on the VPS disk as the only copy of production data.

## Litestream Setup

Use a private R2 bucket for SQLite replicas.

Keep credentials out of git:

```text
/etc/litestream.yml
/etc/<app>/<app>.env
```

Install:

```sh
curl -fsSL https://litestream.io/install.sh | sudo bash
sudo cp infra/litestream/litestream.example.yml /etc/litestream.yml
sudo systemctl enable --now litestream
sudo systemctl status litestream
```

Each SQLite app should use:

```text
/var/lib/<app>/<app>.sqlite
```

## Restore Drill

Run this before trusting a production database, and repeat after major app changes.

Restore to a temporary path:

```sh
APP=example
DB=/var/lib/$APP/$APP.sqlite
RESTORE=/tmp/$APP-restore.sqlite

sudo rm -f "$RESTORE" "$RESTORE-wal" "$RESTORE-shm" "$RESTORE-journal"
sudo litestream restore -o "$RESTORE" "$DB"
sqlite3 "$RESTORE" 'PRAGMA integrity_check;'
sqlite3 "$RESTORE" '.tables'
```

Expected integrity result:

```text
ok
```

Litestream will not overwrite an existing non-empty database by default. That safety behavior is good. Remove temporary restore files before each drill.

## Production Restore

Use this only during recovery.

1. Stop the app or PHP worker that writes to the database.
2. Stop Litestream for that database.
3. Move the broken database aside.
4. Restore to the original path.
5. Fix ownership.
6. Run `PRAGMA integrity_check`.
7. Start the app.
8. Start Litestream.
9. Confirm app health.

Example:

```sh
APP=example
DB=/var/lib/$APP/$APP.sqlite

sudo systemctl stop litestream
sudo mv "$DB" "$DB.broken.$(date +%Y%m%d%H%M%S)"
sudo rm -f "$DB-wal" "$DB-shm" "$DB-journal"
sudo litestream restore "$DB"
sudo chown $APP:$APP "$DB"
sqlite3 "$DB" 'PRAGMA integrity_check;'
sudo systemctl start litestream
curl http://127.0.0.1:8080/api/healthz
```

For a Go service, stop and start the app service around the restore:

```sh
sudo systemctl stop <app>.service
sudo systemctl start <app>.service
```

For PHP apps, stop PHP-FPM only if the app is actively writing:

```sh
sudo systemctl stop php8.3-fpm
sudo systemctl start php8.3-fpm
```

## Restore Schedule

Minimum:

- Run one restore drill after first production deploy.
- Run one restore drill after wiring each new SQLite app.
- Run one restore drill after changing Litestream/R2 settings.
- Run monthly restore drills for apps with important data.

Record only the result, app name, date, and operator in public-safe docs or issue trackers. Do not record secrets or backup URLs with credentials.

## Failure Cases

If restore fails:

- Check `sudo journalctl -u litestream -n 120 --no-pager`.
- Check R2 credentials and bucket permissions.
- Check that the DB path in `/etc/litestream.yml` matches the real database.
- Check that the output path does not already contain a non-empty database or sidecar files.
- Check disk space.

## Official References

- Litestream restore command: `https://litestream.io/reference/restore/`
- Litestream documentation: `https://litestream.io/`

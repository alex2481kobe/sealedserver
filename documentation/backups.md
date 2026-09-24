# Backups

Each SQLite database is copied continuously to a private Cloudflare R2 bucket
by Litestream. A backup counts once a restore from it has worked.

## What is backed up

| What | How |
| --- | --- |
| SQLite databases in `/var/lib/<app>` | Litestream to R2 |
| Env files | Values kept in a password manager |
| nginx, systemd and cloudflared config | Rebuilt from this repo |
| Tunnel credentials | Recreated with `cloudflared tunnel create` |

## Install Litestream

Download the `.deb` for your server from the
[Litestream releases](https://github.com/benbjohnson/litestream/releases), then:

```sh
sudo dpkg -i litestream-*.deb
sudo systemctl disable --now litestream
```

The package's own service is turned off. Each app runs its own Litestream
service as the app user, so SQLite's `-wal` and `-shm` files keep the app's
ownership.

## Set up an app

Create an R2 bucket and an R2 API token with access to that bucket only. Then:

```sh
sudo install -m 640 -o root -g example infra/litestream/litestream.example.yml /etc/example/litestream.yml
sudoedit /etc/example/litestream.yml
sudo cp infra/systemd/litestream.service /etc/systemd/system/litestream-example.service
sudo systemctl daemon-reload
sudo systemctl enable --now litestream-example
sudo journalctl -u litestream-example -n 50 --no-pager
```

## Restore drill

Restores to a temporary file and checks it. Run it after setting up an app,
after changing Litestream or R2 settings, and monthly for data that matters.

```sh
APP=example
OUT=/tmp/$APP-restore.sqlite
sudo rm -f "$OUT" "$OUT-wal" "$OUT-shm"
sudo -u $APP litestream restore -config /etc/$APP/litestream.yml -o "$OUT" /var/lib/$APP/$APP.sqlite
sudo sqlite3 "$OUT" 'PRAGMA integrity_check;'
sudo sqlite3 "$OUT" '.tables'
sudo rm -f "$OUT" "$OUT-wal" "$OUT-shm"
```

`integrity_check` prints `ok`. Litestream will not write over an existing file,
which is why the old one is removed first.

## Restoring for real

```sh
APP=example
DB=/var/lib/$APP/$APP.sqlite
sudo systemctl stop $APP litestream-$APP
sudo mv "$DB" "$DB.broken.$(date +%Y%m%d%H%M%S)"
sudo rm -f "$DB-wal" "$DB-shm"
sudo -u $APP litestream restore -config /etc/$APP/litestream.yml "$DB"
sudo -u $APP sqlite3 "$DB" 'PRAGMA integrity_check;'
sudo systemctl start $APP litestream-$APP
```

## When a restore fails

- `sudo journalctl -u litestream-<app> -n 100 --no-pager`
- The R2 token can read and write the bucket.
- The `path` in `litestream.yml` matches the real database path.
- The output path has no leftover database or `-wal`/`-shm` files.
- The disk has space: `df -h`.

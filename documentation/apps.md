# Apps

Every app on the server has its own Linux user and the same set of folders.
Replace `example` with the app name everywhere below.

| Path | Owner | Holds |
| --- | --- | --- |
| `/var/www/example/public` | `example` | Files nginx serves |
| `/opt/example/example-server` | `root` | Go binary |
| `/var/lib/example` | `example` | SQLite database and other data |
| `/etc/example/example.env` | `root:example`, mode 640 | Settings and secrets |
| `/var/log/example` | `example` | App logs |

## Ports

| Port | Used by |
| --- | --- |
| `127.0.0.1:8080` | nginx, shared by every site |
| `127.0.0.1:8081` and up | Go services, one port each |
| `127.0.0.1:9090` and up | Private metrics, never proxied by nginx |

## Create the app

On the server, from the repo clone:

```sh
sudo bash scripts/create-app-folders.sh example static   # or go
sudo systemctl restart nginx
```

The script creates the user and folders and adds `www-data` to the app's group,
so nginx can read the app's files. nginx picks up the new group on restart.

Add each hostname to `/etc/cloudflared/config.yml`, route it with
`cloudflared tunnel route dns`, and restart `cloudflared`.

## Static site

```sh
sudo cp infra/nginx/static-site.conf /etc/nginx/sites-available/example.conf
sudo ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

Deploy by copying files to a staging folder, then swapping them in:

```sh
rsync -az --delete dist/ deploy@<server-name>:/tmp/example-public/
ssh -t deploy@<server-name> 'sudo rsync -a --delete /tmp/example-public/ /var/www/example/public/ && sudo chown -R example:example /var/www/example/public'
```

Files under `/assets/` are cached for a year, so a changed asset needs a new
file name or `?v=` value. Everything else is cached for five minutes.

## Go service

```sh
sudo install -m 640 -o root -g example /dev/null /etc/example/example.env
sudoedit /etc/example/example.env
sudo cp infra/systemd/go-service.service /etc/systemd/system/example.service
sudo systemctl daemon-reload
sudo systemctl enable example
sudo cp infra/nginx/go-service.conf /etc/nginx/sites-available/example.conf
sudo ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

```text
APP_NAME=example
APP_ADDR=127.0.0.1:8081
APP_DB_PATH=/var/lib/example/example.sqlite
APP_ADMIN_TOKEN=<long random value>
```

Deploy from your machine:

```sh
cd apps/go-service
make deploy APP=example HOST=deploy@<server-name>
```

`make rollback` puts the previous binary back. The database is not rolled back,
so schema changes stay additive.

The unit runs the binary as the app user with no capabilities, a read-only
system, write access to `/var/lib/example` and `/var/log/example` only, and a
syscall filter, and restarts it on failure.

## Check an app

Through nginx on the server, then through Cloudflare:

```sh
curl -I -H 'Host: www.example.com' http://127.0.0.1:8080/
curl -I https://www.example.com/
```

Logs:

```sh
sudo journalctl -u example -n 100 --no-pager
sudo journalctl -u example -f
sudo tail -n 100 /var/log/nginx/error.log
sudo tail -n 100 /var/log/example/*.log
```

`infra/logrotate/app.conf` rotates `/var/log/example/*.log`. Copy it to
`/etc/logrotate.d/example`.

SQLite apps need backups before real data arrives. See [Backups](backups.md).

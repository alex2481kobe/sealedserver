# Go Service

A small Go HTTP service with SQLite: one static binary, bound to
`127.0.0.1:8081`. SQLite runs through `modernc.org/sqlite`, a pure Go driver,
so the binary builds without C and runs anywhere.

| Route | Purpose |
| --- | --- |
| `GET /healthz` | Health check, including the database |
| `POST /events` | Record an event: `{"event_type": "...", "subject": "..."}` |
| `GET /admin/summary` | Event counts by type. Needs `X-Admin-Token` |

The schema in `cmd/service/store.go` is applied on every start. Changes stay
additive, such as new tables or new nullable columns, so `make rollback` can
run the previous binary against the same database.

## Run locally

```sh
make run
curl http://127.0.0.1:8081/healthz
curl -X POST http://127.0.0.1:8081/events -d '{"event_type":"visit"}'
make test
```

## Deploy

The server needs the app folders, the env file, the systemd unit and the nginx
site first. See [Apps](../../documentation/apps.md#go-service).

```sh
make deploy APP=example HOST=deploy@<server-name>
make rollback APP=example HOST=deploy@<server-name>
```

`deploy` builds a Linux binary, keeps the running one as
`/opt/<app>/<app>-server.previous`, installs the new one and restarts the
service. `rollback` puts the previous binary back.

## Settings

| Variable | Default |
| --- | --- |
| `APP_NAME` | `go-service` |
| `APP_ADDR` | `127.0.0.1:8081` |
| `APP_DB_PATH` | `app.sqlite` in the working directory, `/var/lib/<app>` on the server |
| `APP_ADMIN_TOKEN` | empty, which turns the admin route off |

The admin route is blocked at nginx and Cloudflare. It is reached over an SSH
tunnel:

```sh
ssh -L 8081:127.0.0.1:8081 deploy@<server-name>
curl -H "X-Admin-Token: $TOKEN" http://127.0.0.1:8081/admin/summary
```

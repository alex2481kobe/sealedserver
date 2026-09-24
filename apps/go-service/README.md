# Go Service

A small Go HTTP service: one binary, standard library only, bound to
`127.0.0.1:8081`, with a health check and a token-protected admin route.

| Route | Purpose |
| --- | --- |
| `GET /healthz` | Health check |
| `GET /admin/summary` | Needs `X-Admin-Token` |

## Run locally

```sh
make run
curl http://127.0.0.1:8081/healthz
make test
```

## Deploy

The server needs the app folders, the env file, the systemd unit and the nginx
site first. See [Apps](../../documentation/apps.md#go-service).

```sh
make deploy APP=example HOST=deploy@<server-name>
```

This builds a Linux binary, copies it to `/opt/<app>/<app>-server` and
restarts the service.

## Settings

| Variable | Default |
| --- | --- |
| `APP_NAME` | `go-service` |
| `APP_ADDR` | `127.0.0.1:8081` |
| `APP_ADMIN_TOKEN` | empty, which turns the admin route off |

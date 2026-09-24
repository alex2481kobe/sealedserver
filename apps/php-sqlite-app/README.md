# PHP + SQLite App

A small PHP 8.3 API with no framework and no Composer packages. It records
events in SQLite and has a token-protected admin page.

| Route | Purpose |
| --- | --- |
| `GET /api/healthz` | Health check |
| `POST /api/events` | Record an event: `{"event_type": "...", "subject": "...", "metadata": {}}` |
| `GET /api/admin/summary` | Event counts by type. Needs `X-Admin-Token` |
| `GET /api/admin/recent` | Latest 20 events. Needs `X-Admin-Token` |
| `/admin.html` | Page that calls the two admin routes |

The schema in `db/schema.sql` is applied when the app opens the database.

## Run locally

```sh
cp .env.example .env
make dev
curl http://127.0.0.1:8080/api/healthz
curl -X POST http://127.0.0.1:8080/api/events \
  -H 'Content-Type: application/json' \
  -d '{"event_type":"visit","metadata":{"page":"home"}}'
```

## Deploy

The server needs the app folders, the env file, the PHP-FPM pool and the nginx
site first. See [Apps](../../documentation/apps.md#php--sqlite-app).

```sh
make deploy APP=example HOST=deploy@<server-name>
```

## Settings

The app reads settings from the environment, then from the file named by
`APP_ENV_FILE`. On the server that file is `/etc/<app>/<app>.env`.

| Variable | Default |
| --- | --- |
| `APP_NAME` | `php-sqlite-app` |
| `APP_DB_PATH` | `var/app.sqlite` inside the app folder |
| `APP_ADMIN_TOKEN` | empty, which turns the admin routes off |
| `APP_MAX_BODY_BYTES` | `65536` |

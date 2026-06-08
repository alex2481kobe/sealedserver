# PHP SQLite App

Thin starter lane for websites, admin dashboards, event APIs, download records, Lemon Squeezy webhooks, and other small server-side endpoints.

## Shape

```text
apps/php-sqlite-app/
  public/
  src/
  migrations/
```

## Rules

- Keep routing small and explicit.
- Validate input at the route boundary.
- Store the SQLite DB under `/var/lib/<app>/<app>.sqlite`, not in the deployed code folder.
- Put env values under `/etc/<app>/<app>.env`.
- Use prepared statements for all SQL.
- Use Litestream or another tested backup path before production writes matter.

## Use Something Else When

- The app needs realtime websockets or simulation loops: use Go.
- The app needs seller accounts, uploads, moderation, payouts, team permissions, or heavy reporting: use Postgres.

## Local Dev

```sh
make dev
```

Then test:

```sh
curl http://127.0.0.1:8080/api/healthz
curl -X POST http://127.0.0.1:8080/api/events \
  -H 'Content-Type: application/json' \
  -d '{"event_type":"visit","metadata":{"page":"home"}}'
```

## Production Notes

- Set `APP_DB_PATH=/var/lib/<app>/<app>.sqlite`.
- Set `APP_ADMIN_TOKEN` in `/etc/<app>/<app>.env`.
- Set `LEMON_SQUEEZY_WEBHOOK_SECRET` before enabling `/api/webhooks/lemon-squeezy`.
- Put the env file outside the deployed code folder.
- Use Cloudflare Turnstile or another challenge on public write-heavy forms.
- Add Lemon Squeezy webhook signature verification before trusting purchase events.
- Replace the demo `APP_DOWNLOAD_TOKEN` paid-download check with real entitlement or signed R2 URL behavior before selling files at scale.

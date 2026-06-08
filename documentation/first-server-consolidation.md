# First Server Consolidation

This is the default shape for hosting several small apps on one production VPS
while keeping each app easy to move later.

## Goal

The shared server provides:

- Ubuntu;
- nginx;
- Tailscale;
- Cloudflare Tunnel or direct Cloudflare-proxied `80/443`;
- UFW;
- systemd;
- cron/systemd timers;
- Litestream where SQLite backups are needed;
- logrotate;
- per-app users, folders, env files, services, logs, and databases.

## Preferred First Mode

Use no-inbound Cloudflare Tunnel mode first:

```text
Cloudflare edge
  -> cloudflared outbound tunnel
  -> nginx on 127.0.0.1:8080
  -> app-specific local services and static folders
```

This lets UFW deny public inbound traffic while still serving public sites.

Direct public `80/443` remains supported for existing or exceptional
deployments, but it is not the default for a new consolidation server.

Template files:

- Tunnel/no-inbound: `infra/nginx/first-server-tunnel.conf` and `infra/cloudflare/first-server-tunnel.yml`.
- Direct public: `infra/nginx/first-server-direct-public.conf`.

## Shared nginx Listener

For one server holding several apps, do not give every site its own nginx
listener port. Use one local nginx listener and dispatch by hostname:

```text
nginx: 127.0.0.1:8080

static.example.com   -> /var/www/static-app/public
app.example.com      -> /var/www/php-app/public + PHP API
game.example.com     -> /var/www/game-app/public + /ws to 127.0.0.1:8081
api.example.com      -> Go service on 127.0.0.1:8082
```

Cloudflare Tunnel can route multiple hostnames to the same local nginx service.
nginx then chooses the right `server_name`.

## Local Port Convention

Keep public nginx local at:

```text
127.0.0.1:8080
```

Reserve app-local ports:

```text
8081  first Go/websocket public mux
8082  second Go/API public mux
8083  third Go/API public mux
9090  first private metrics service
9091  next private metrics service
```

Private metrics should bind to localhost and should not be proxied by nginx.

## Direct Public Mode Notes

If using direct public mode:

- UFW should allow public `80/tcp` and `443/tcp`.
- SSH should still stay Tailscale-only.
- Certbot or Cloudflare Origin Certificates must handle TLS.
- nginx should redirect HTTP to HTTPS.
- app services still bind to localhost, not public interfaces.
- private metrics must remain unproxied.

## App Folder Convention

Static/PHP apps:

```text
/var/www/<app>/public
/var/www/<app>/src
/var/www/<app>/db/schema.sql
/var/lib/<app>/<app>.sqlite
/etc/<app>/<app>.env
/var/log/<app>
```

Go services:

```text
/opt/<app>/<app>-server
/etc/<app>/<app>.env
/var/lib/<app>
/var/log/<app>
/etc/systemd/system/<app>.service
```

For a static client plus Go backend, keep the static client in `/var/www` and
the binary in `/opt`.

## Go Service Lessons

- Go does not need to be installed on the server; cross-compile locally or in CI
  and ship the binary.
- nginx should terminate public traffic and proxy websocket/API routes to a
  localhost Go service.
- private metrics should bind to a separate localhost port and stay unproxied.
- each app should run as an unprivileged system user.
- systemd hardening is worth keeping.
- public stats endpoints can be proxied and rate-limited separately from
  websocket routes.
- websocket frame rate limits belong in Go; nginx only sees the upgrade.

## Migration Order

Do not move everything at once. Migrate in slices:

1. static sites;
2. low-risk PHP + SQLite apps;
3. small Go services;
4. realtime/game services;
5. payment, subscription, or user-data-heavy services after a dedicated plan.

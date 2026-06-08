# Dependencies

This template keeps the base server small. Install only the lane a product needs.

## Base Server

Required for most deployments:

```sh
sudo apt update
sudo apt install nginx sqlite3 unattended-upgrades ufw logrotate cron curl ca-certificates rsync
```

Recommended:

```sh
sudo apt install fail2ban
```

Use Tailscale for private SSH/admin access.

## PHP + SQLite Lane

```sh
sudo apt install php8.3-cli php8.3-fpm php8.3-sqlite3
```

No Composer dependency is required by the starter app.

## Go Service Lane

Install Go on the build machine. The production server only needs the compiled binary unless you choose to build on the server.

For Linux/amd64 VPS deploys:

```sh
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w"
```

## SQLite Backups

Use Litestream for SQLite backup replication:

```sh
curl -fsSL https://litestream.io/install.sh | sudo bash
```

Back up to Cloudflare R2 or another S3-compatible bucket.

## Cloudflare

Use Cloudflare for DNS, CDN, WAF/basic edge protection, Turnstile, and R2.

Install `cloudflared` only when using Cloudflare Tunnel. If the server exposes public 80/443 directly through Cloudflare-proxied DNS, use nginx plus either Cloudflare origin certificates or Certbot.

## Not Default

Do not install Redis, Docker, Postgres, or a process manager by default. Add them only when the product decision table says they are needed.

<p align="center">
  <img src="assets/sealedserver-mark.png" alt="Sealed Server" width="140" height="140" />
</p>

<h1 align="center">Sealed Server</h1>

<p align="center">
  <strong>Host your sites and small backends on one Ubuntu server with no open ports.</strong><br />
  Static sites and Go + SQLite services, each isolated and easy to move.
</p>

<p align="center">
  <a href="#get-started">Get started</a> ·
  <a href="#whats-inside">What's inside</a> ·
  <a href="documentation/setup.md">Server setup</a>
</p>

Visitors reach the server through Cloudflare Tunnel. You reach it through
Tailscale, with OpenSSH or Tailscale SSH. No port is open to the internet, not
even 22.

```text
visitor -> Cloudflare -> Tunnel -> nginx on 127.0.0.1:8080 -> static files or Go
admin   -> Tailscale  -> SSH
```

## Get started

Tell your coding agent:

```text
Set up my Ubuntu server with https://github.com/alex2481kobe/sealedserver, starting from documentation/setup.md.
```

Or do it yourself: [set up the server](documentation/setup.md), then
[add an app](documentation/apps.md).

## What's inside

| For | Uses | Starter |
| --- | --- | --- |
| Websites | HTML, CSS and JavaScript served by nginx | [`apps/static-site`](apps/static-site) |
| APIs, realtime and background work | Go with SQLite | [`apps/go-service`](apps/go-service) |
| SQLite backups | Litestream to Cloudflare R2, per app | |
| Large files | Cloudflare R2 | |

Each app gets its own Linux user, folders, env file, logs and database, so it
can move to another server on its own.

## Not included

- **More than one server.** No load balancing, failover or replication. If the
  server goes down, every app on it goes down.
- **Containers and extra data stores.** No Docker, Postgres, Redis or queues.
- **App features.** No user accounts, sessions, email or payments.
- **Deploy pipelines.** Deploys run from your machine with `make` and `rsync`.
- **Monitoring and alerts.** Logs and `scripts/server-report.sh` only; nothing
  pages you when a site is down.
- **Load testing.** The limits in [Server setup](documentation/setup.md#limits)
  are configured, not measured.

## Documentation

- [Server setup](documentation/setup.md): a fresh server to a locked-down one
- [Apps](documentation/apps.md): add, deploy and check an app
- [Cloudflare](documentation/cloudflare.md): DNS, Tunnel, WAF, caching and R2
- [Tailscale](documentation/tailscale.md): admin access and tailnet policy
- [Backups](documentation/backups.md): Litestream and restore drills

## Works with

Ubuntu 24.04 LTS on any VPS or a home server. You need a domain on Cloudflare
and a Tailscale account. Both free plans are enough.

Cloudflare Tunnel and Tailscale both connect outward, so a home server behind a
router needs no port forwarding.

MIT. See [LICENSE](LICENSE).

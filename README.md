<h1 align="center">Backend Template</h1>

<p align="center">
  <strong>Host your sites and small backends on one Ubuntu server with no open ports.</strong><br />
  Static sites, PHP + SQLite and Go services, each isolated and easy to move.
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
visitor -> Cloudflare -> Tunnel -> nginx on 127.0.0.1:8080 -> static files, PHP or Go
admin   -> Tailscale  -> SSH
```

## Get started

Tell your coding agent:

```text
Set up my Ubuntu server with https://github.com/alex2481kobe/backend-template, starting from documentation/setup.md.
```

Or do it yourself: [set up the server](documentation/setup.md), then
[add an app](documentation/apps.md).

## What's inside

| For | Uses | Starter |
| --- | --- | --- |
| Websites | nginx | [`apps/static-site`](apps/static-site) |
| Small APIs, admin pages, forms | PHP 8.3 + SQLite | [`apps/php-sqlite-app`](apps/php-sqlite-app) |
| Realtime and long-running services | Go | [`apps/go-service`](apps/go-service) |
| SQLite backups | Litestream to Cloudflare R2 | |
| Large files | Cloudflare R2 | |

Each app gets its own Linux user, folders, env file, logs and database, so it
can move to another server on its own. Docker, Postgres and Redis are not part
of the template.

## Documentation

- [Server setup](documentation/setup.md): a fresh server to a locked-down one
- [Apps](documentation/apps.md): add, deploy and check an app
- [Cloudflare](documentation/cloudflare.md): DNS, Tunnel, WAF, caching and R2
- [Tailscale](documentation/tailscale.md): admin access and tailnet policy
- [Backups](documentation/backups.md): Litestream and restore drills

## Works with

Ubuntu 24.04 LTS on any VPS provider. You need a domain on Cloudflare and a
Tailscale account. Both free plans are enough.

MIT. See [LICENSE](LICENSE).

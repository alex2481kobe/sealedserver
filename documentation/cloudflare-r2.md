# Cloudflare And R2

Use Cloudflare as the public edge, not as a place to hide app complexity.

Cloudflare helps with DNS, TLS, CDN caching, WAF rules, rate limiting, DDoS absorption at the edge, Turnstile, and R2. It does not remove the need for app-level validation, auth, backups, firewall rules, or secret handling.

Cloudflare Tunnel can publish sites and APIs without opening inbound ports on the origin server. In that mode, `cloudflared` connects outbound to Cloudflare, and the server firewall can deny public inbound traffic.

## DNS And TLS

Preferred options:

- Cloudflare-proxied DNS with nginx listening publicly on 80/443.
- Cloudflare Tunnel with nginx listening locally, useful when you want no public inbound ports.

Use Certbot when the server terminates public TLS itself. If Cloudflare terminates TLS or Tunnel carries traffic, Certbot may not be needed.

For first consolidation work, prefer Tunnel/no-inbound mode so the server can keep public ports closed while still serving websites.

## Protection Boundary

Cloudflare is the public edge. It can absorb and filter a lot before traffic reaches the server, but the app still needs:

- input validation;
- auth on admin/private endpoints;
- webhook signature verification;
- rate limits or Turnstile on public write endpoints;
- private env files;
- SQLite backups and restore tests;
- UFW/Tailscale server firewall rules.

## WAF And Forms

Use Cloudflare WAF rules and Turnstile for public write endpoints such as contact forms, feedback, reviews, and free-download abuse prevention.

Do not rely on Cloudflare alone for application authorization. Admin endpoints still need private network access, Cloudflare Access, Tailscale, and/or app-level tokens.

Use `documentation/cloudflare-hardening.md` for the setup runbook and `infra/cloudflare/waf-baseline.md` for starter WAF expressions.

## R2 Downloads

Use R2 for:

- app installers;
- GLB/asset packs;
- preview images and videos;
- premium production packs;
- SQLite backups through Litestream.

Public/free files can be direct R2 links through a custom domain. Paid files should be resolved through Lemon Squeezy fulfillment or short-lived signed URLs from the private backend.

## Litestream To R2

Use a private R2 bucket for database backups. Keep R2 credentials in the app env file or a dedicated Litestream env file, never in git.

Restore test:

```sh
litestream restore -o /tmp/example.sqlite /var/lib/example/example.sqlite
sqlite3 /tmp/example.sqlite 'PRAGMA integrity_check;'
```

Use `documentation/backup-restore-drills.md` for the full restore drill and production restore flow.

## Official References

- Cloudflare Tunnel: `https://developers.cloudflare.com/tunnel/`
- Cloudflare Tunnel firewall behavior: `https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/`

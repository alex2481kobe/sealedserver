# Cloudflare

Cloudflare is the only public entry point. It handles DNS, TLS, the tunnel to
the server, caching, WAF rules and object storage. Apps still validate input,
check auth and verify webhook signatures themselves.

## Account

- 2FA on every Cloudflare user, with recovery codes saved.
- API tokens scoped to one job each, such as DNS for one zone or one R2
  bucket. The global API key is not used.
- Tokens live in `/etc/<app>/<app>.env` or `/etc/<app>/litestream.yml`, never in
  git.

## DNS and TLS

1. Add the domain to Cloudflare and switch the registrar's nameservers.
2. Turn on **Always Use HTTPS**.
3. Turn on DNSSEC once the nameservers are active. If the registrar is not
   Cloudflare, add the DS record Cloudflare shows at the registrar.

Cloudflare serves the visitor-facing certificate. The server needs no Certbot.

## Tunnel

One tunnel per server. Every hostname in `/etc/cloudflared/config.yml` points to
`http://127.0.0.1:8080`, and nginx chooses the site by hostname. The tunnel
setup commands are in [Server setup](setup.md#6-cloudflare-tunnel).

Each hostname needs a DNS route:

```sh
cloudflared tunnel route dns <tunnel-name> <hostname>
sudo systemctl restart cloudflared
```

The tunnel connects outbound on port `7844` (TCP and UDP). A provider firewall
that limits outbound traffic has to allow it.

## WAF rules

Under **Security > WAF > Custom rules**:

| Rule | Expression | Action |
| --- | --- | --- |
| Unusual methods | `not (http.request.method in {"GET" "POST" "HEAD" "OPTIONS"})` | Block |
| Dotfile probes | `http.request.uri.path contains "/." and not starts_with(http.request.uri.path, "/.well-known/")` | Block |
| Admin paths | `starts_with(http.request.uri.path, "/admin")` | Block |
| Public API writes | `http.request.method eq "POST" and starts_with(http.request.uri.path, "/api/") and not starts_with(http.request.uri.path, "/api/webhooks/")` | Managed Challenge |

Webhook paths are left out of challenges, because payment and platform
providers cannot solve them.

Rate limiting, under **Security > WAF > Rate limiting rules**:

| Match | Counted by | Limit |
| --- | --- | --- |
| `starts_with(http.request.uri.path, "/api/")` | IP | 60 requests per 10 seconds, then block for 10 seconds |

nginx also limits each visitor to 30 requests a second with a burst of 60,
keyed on the `CF-Connecting-IP` header.

Watch **Security > Events** for a few days after adding rules.

## Caching

nginx sends a one-year cache time for `/assets/` and five minutes for pages.
Cloudflare caches common file types such as CSS, JavaScript and images on its
own. Other types under `/assets/`, such as `.glb` or `.wasm`, need a Cache Rule:

- Match: URI path starts with `/assets/`
- Cache eligibility: eligible for cache
- Edge TTL: use the origin's cache-control header

Check with two requests; the second shows `cf-cache-status: HIT`.

## Turnstile

Turnstile protects public forms. The browser widget alone does nothing; the app
sends the token to
`https://challenges.cloudflare.com/turnstile/v0/siteverify` with the secret
from its env file and rejects the request if the check fails.

## Access

Admin pages are reached over Tailscale and blocked at the edge by the admin WAF
rule. An admin page that has to be public goes behind Cloudflare Access, limited
to named emails, and keeps its own token or login as well.

## R2

- A private bucket per app for Litestream backups. See [Backups](backups.md).
- A public bucket on a custom domain, such as `assets.example.com`, for large
  downloads. Large files are not stored on the server.
- Paid files go out through short-lived signed URLs or the payment provider,
  never a public link.

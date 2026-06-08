# Cloudflare Hardening

Use Cloudflare as the public edge for DNS, TLS, Tunnel, caching, WAF rules, DDoS absorption, Turnstile, R2, and optional Access. Cloudflare reduces origin exposure, but it does not replace app validation, auth, backups, or server hardening.

## Default Hosting Mode

Preferred first-server shape:

```text
visitor
  -> Cloudflare HTTPS edge
  -> Cloudflare Tunnel
  -> nginx on 127.0.0.1:8080
  -> static files, PHP-FPM, or Go services
```

In this mode:

- Do not install Certbot for public sites.
- Do not open public inbound `80` or `443`.
- Keep nginx bound to `127.0.0.1`.
- Keep app services bound to `127.0.0.1`.
- Let Cloudflare serve the visitor-facing HTTPS certificate.

Use Certbot or Cloudflare Origin CA only for direct-public mode where nginx intentionally listens on public `80/443`.

## Account Security

Set these before moving production traffic:

1. Verify the Cloudflare account email.
2. Enable 2FA for every Cloudflare user.
3. Save recovery codes in the password manager.
4. Use least-privilege API tokens, not the global API key.
5. Remove unused account members.
6. Review audit logs after DNS, Tunnel, or WAF changes.

Token guidance:

- DNS deploy token: grant only the zone DNS permissions needed.
- R2 backup token: grant only the bucket permissions needed by Litestream.
- Automation token: create a separate token per automation lane.
- Never put tokens in git; put them in `/etc/<app>/<app>.env`, `/etc/litestream.yml`, or the server password manager.

## DNS And TLS

For each zone:

1. Add the domain to Cloudflare.
2. Change registrar nameservers to Cloudflare nameservers.
3. Set public app hostnames to proxied where applicable.
4. Use Cloudflare Tunnel public hostnames for no-inbound apps.
5. Enable Always Use HTTPS at the edge for public websites.
6. Enable DNSSEC after nameserver migration is stable.

If the registrar is not Cloudflare Registrar, Cloudflare will show a DS record when DNSSEC is enabled. Add that DS record at the registrar.

## Tunnel Setup

Create a tunnel per shared server:

```sh
cloudflared tunnel login
cloudflared tunnel create <server-tunnel-name>
cloudflared tunnel route dns <server-tunnel-name> example.com
cloudflared tunnel route dns <server-tunnel-name> www.example.com
sudo cp infra/cloudflare/first-server-tunnel.yml /etc/cloudflared/config.yml
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

Update `/etc/cloudflared/config.yml` with:

- the real tunnel id;
- the real credentials file path;
- one hostname entry per public hostname;
- `service: http://127.0.0.1:8080` for the shared nginx listener.

Firewall egress:

- Allow outbound connections.
- If the provider firewall restricts outbound traffic, allow Cloudflare Tunnel outbound `7844` TCP/UDP.
- Optional outbound `443` helps cloudflared features such as auto-updates and Access JWT validation.

## WAF Baseline

Set rules gently at first and watch Security Events before becoming aggressive.

Cloudflare Free plan baseline:

- DDoS protection is automatic.
- Bot Fight Mode can be enabled under Security settings.
- Free plan rate limiting is limited, so use one broad public-write rule first.

Suggested custom rules:

| Name | Expression | Action | Notes |
| --- | --- | --- | --- |
| Block strange methods | `not (http.request.method in {"GET" "POST" "HEAD" "OPTIONS"})` | Block | Keep public surface small. |
| Block dotfile probes | `starts_with(http.request.uri.path, "/.") and not starts_with(http.request.uri.path, "/.well-known/")` | Block | Blocks common secret probes. |
| Managed challenge public writes | `(http.request.method eq "POST") and starts_with(http.request.uri.path, "/api/") and not starts_with(http.request.uri.path, "/api/webhooks/")` | Managed Challenge | Do not challenge payment webhooks. |
| Block public admin | `starts_with(http.request.uri.path, "/admin")` | Block | Use only if admin is Tailscale-only. |

Suggested rate limit:

| Name | Match | Count | Mitigation |
| --- | --- | --- | --- |
| Public write endpoints | `starts_with(http.request.uri.path, "/api/")` | IP | Challenge or block obvious abuse. |

Tune the threshold per app. For free downloads and feedback forms, start conservative enough to avoid blocking normal users, then tighten from Security Events.

## Webhooks

Payment and platform webhooks need a clear path through Cloudflare:

- Do not put Turnstile on webhook endpoints.
- Do not Managed Challenge webhook endpoints.
- Do verify webhook signatures in the app.
- Do log webhook failures without logging secrets.
- Consider a narrow WAF rule for webhook paths only after confirming provider IP/user-agent behavior.

For Lemon Squeezy, the app must verify the HMAC signature before trusting purchase events.

## Turnstile

Use Turnstile on public forms and high-abuse public write endpoints:

- contact forms;
- feedback forms;
- free download request forms;
- accountless waitlists;
- suspicious high-volume write endpoints.

Server-side validation is mandatory. The browser widget alone is not protection. The backend should send the token to:

```text
POST https://challenges.cloudflare.com/turnstile/v0/siteverify
```

Store the Turnstile secret in `/etc/<app>/<app>.env`.

## Cloudflare Access

Preferred admin posture:

1. Do not publish admin dashboards publicly.
2. Serve admin dashboards only over Tailscale.

If an admin dashboard must be reachable through a public hostname:

1. Put it behind Cloudflare Access.
2. Allow only trusted emails or identity provider groups.
3. Keep the app's own admin token/session auth enabled.
4. Add a WAF rule for the admin hostname/path.

Cloudflare Access is an identity layer before the request reaches the origin; it is not a replacement for app authorization.

## Verification

After setup:

```sh
curl -I https://example.com
curl -I -H 'Host: example.com' http://127.0.0.1:8080/
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -n 120 --no-pager
sudo bash scripts/verify-no-inbound.sh
```

In Cloudflare:

- Check DNS records are proxied or routed through Tunnel.
- Check Tunnel status is healthy.
- Check Security Events after enabling WAF rules.
- Check Analytics after traffic begins.

## Official References

- Cloudflare Tunnel configuration: `https://developers.cloudflare.com/tunnel/configuration/`
- Cloudflare self-hosted Access apps: `https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/self-hosted-apps/`
- Cloudflare 2FA: `https://developers.cloudflare.com/fundamentals/account/account-security/2fa/`
- Cloudflare API tokens: `https://developers.cloudflare.com/fundamentals/api/get-started/create-token/`
- Cloudflare WAF interoperability: `https://developers.cloudflare.com/waf/feature-interoperability/`
- Cloudflare rate limiting rules: `https://developers.cloudflare.com/waf/rate-limiting-rules/`
- Cloudflare Turnstile server validation: `https://developers.cloudflare.com/turnstile/get-started/server-side-validation/`
- Cloudflare DNSSEC: `https://developers.cloudflare.com/dns/dnssec/`

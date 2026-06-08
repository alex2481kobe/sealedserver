# Static Site

Use this lane for simple product sites, landing pages, legal pages, app store files, and static builds.

## Server Shape

- Build locally or in CI.
- Deploy static files to `/var/www/<app>/public`.
- Serve with nginx.
- Use Cloudflare for DNS, CDN, TLS, WAF, and cache controls.

## Good Fits

- Product landing pages.
- Static docs.
- Download pages where links are public or handed off to a separate API.

## Add PHP When

- You need Lemon Squeezy webhooks.
- You need private admin stats.
- You need event/download tracking.
- You need signed R2 links for paid assets.

# Commerce And Downloads

The PHP + SQLite lane includes starter endpoints for webhook capture, download
tracking, and small admin summaries. It is a scaffold, not a full marketplace.

Only add paid download behavior after the project has real product pages,
support/refund notes, and payment-provider approval.

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/api/webhooks/lemon-squeezy` | Store signed Lemon Squeezy webhook events |
| `GET` | `/api/assets/<asset_key>/download` | Resolve an asset download URL and record the download |
| `GET` | `/api/admin/summary` | Token-protected counts |
| `GET` | `/api/admin/recent` | Token-protected recent records |

## Lemon Squeezy

Lemon Squeezy signs webhook payloads with HMAC-SHA256 and sends the hex digest in the `X-Signature` header. The starter verifies that header against `LEMON_SQUEEZY_WEBHOOK_SECRET` before storing the event.

Set:

```text
LEMON_SQUEEZY_WEBHOOK_SECRET=<secret from webhook settings>
```

The starter stores raw webhook payloads for idempotency and later fulfillment logic. It does not grant entitlements yet; product-specific code should decide which products map to which assets.

Official docs: `https://docs.lemonsqueezy.com/help/webhooks/signing-requests`

## Free Downloads

Insert free assets into the `assets` table with:

```text
price_tier = free
license = MIT, CC-BY-4.0, CC0, or project-specific license
public_url or r2_key
```

Free downloads can return a public R2/custom-domain URL.

## Premium Downloads

The starter uses `APP_DOWNLOAD_TOKEN` as a placeholder entitlement check. Replace this with one of:

- Lemon Squeezy fulfillment links;
- short-lived R2 signed URLs;
- an entitlement table keyed by order/license/customer;
- a private download token generated after verified payment.

Do not rely on the placeholder token for a real marketplace.

## Admin Page

The starter includes `/admin.html`. Keep it private behind Tailscale or Cloudflare Access for production, even though API calls still require `X-Admin-Token`.

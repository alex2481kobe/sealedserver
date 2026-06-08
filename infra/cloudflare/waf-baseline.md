# Cloudflare WAF Baseline

These examples are starting points. Apply them in log/challenge mode first where possible, watch Security Events, then tighten.

## Custom Rules

### Block Strange Methods

Expression:

```text
not (http.request.method in {"GET" "POST" "HEAD" "OPTIONS"})
```

Action: `Block`

### Block Dotfile Probes

Expression:

```text
starts_with(http.request.uri.path, "/.") and not starts_with(http.request.uri.path, "/.well-known/")
```

Action: `Block`

### Challenge Public API Writes

Expression:

```text
(http.request.method eq "POST") and starts_with(http.request.uri.path, "/api/") and not starts_with(http.request.uri.path, "/api/webhooks/")
```

Action: `Managed Challenge`

Do not challenge payment webhooks or machine-to-machine endpoints.

### Block Public Admin Paths

Expression:

```text
starts_with(http.request.uri.path, "/admin")
```

Action: `Block`

Use this when admin dashboards are Tailscale-only. If admin must be public, use Cloudflare Access instead of this block rule.

## Rate Limit Rule

Free plan has very limited rate limit capacity, so start with one broad public-write rule.

Expression:

```text
starts_with(http.request.uri.path, "/api/")
```

Characteristic: `IP`

Suggested starting behavior:

```text
60 requests per 10 seconds -> Managed Challenge or Block for 10 seconds
```

Tune by endpoint. A feedback form should be much lower; a game stats endpoint may need a different rule or app-level rate limit.

## App-Level Rules Still Required

Cloudflare rules are edge controls. The app still needs:

- JSON/body size limits;
- prepared statements;
- admin tokens/sessions;
- webhook signature checks;
- Turnstile server-side validation for protected forms;
- structured logs without secrets;
- per-route rate limits in Go for websocket/game traffic.

# Template Coverage

Use this checklist before applying the template to a real project.

## Covered

- Static nginx site lane.
- PHP + SQLite app lane.
- Minimal Go service lane.
- nginx templates for static, PHP, and Go/websocket routing.
- systemd templates for Go services, Litestream, and scheduled timers.
- cron template for simple scheduled jobs.
- Litestream backup template.
- Cloudflare DNS/CDN/WAF/Tunnel notes.
- Cloudflare R2 notes for object storage.
- App manifest format.
- Fresh Ubuntu bootstrap checklist.
- No-inbound server setup with Tailscale and Cloudflare Tunnel.
- Direct public `80/443` reference config for exceptions.
- Per-app Linux user and folder conventions.
- Root local/private file boundary templates.
- Private ops helper for SSH-only logs/status/shell access.
- SQLite backup and restore drill runbook.

## Still Product-Specific

These pieces should be designed in the consuming project, not assumed by this
template:

- real admin dashboard UX;
- analytics and event schema;
- payment provider product mapping;
- signed download entitlement rules;
- game matchmaking/session rules;
- marketplace seller, moderation, review, and payout flows;
- high-traffic monitoring/alerting;
- multi-region or multi-node coordination.

## Public-Repo Safety Check

Before publishing or tagging this template, confirm tracked files do not contain:

- private hostnames, IPs, account IDs, or provider project names;
- personal names, emails, usernames, or local machine paths;
- live server migration notes;
- secrets, keys, tokens, certificates, or real env values;
- current task notes, internal roadmaps, or product-specific plans.

# App Lane Playbooks

Use these generic lane notes to decide which starter app shape fits a project.

## Static Website

Use `apps/static-site` when the project only needs public HTML, CSS, JS, images,
legal pages, static docs, or a prebuilt frontend bundle.

Good fit:

- landing pages;
- product pages;
- docs sites;
- public download pages;
- app store files such as `robots.txt`, `sitemap.xml`, and `app-ads.txt`.

Add PHP or Go only when the site needs server-side forms, webhooks, private
admin stats, signed downloads, or realtime behavior.

## PHP + SQLite App

Use `apps/php-sqlite-app` for small durable web backends:

- admin dashboards;
- download tracking;
- contact or feedback forms;
- webhook receivers;
- small APIs;
- SQLite-backed event logs;
- private stats pages.

Move to Postgres when writes become highly concurrent, when multiple operators
need complex reporting, or when marketplace/account/team features appear.

## Go Service

Use `apps/go-service` when the backend benefits from a compiled long-running
process:

- websocket services;
- realtime tools;
- small workers;
- simulation loops;
- health/admin services;
- utility APIs that should ship as one binary.

Keep public routes behind nginx, bind the Go service to localhost, and use
systemd for supervision.

## Game Service

Start from the Go lane for simple browser or app games. Add custom platform
code only when the game actually needs sessions, matchmaking, presence, wallets,
inventory, leaderboards, match logs, or multi-node coordination.

SQLite is fine for single-server durable state. Add Postgres or Redis only when
the game needs the concurrency or cross-node behavior.

## Existing Backend

Do not rewrite a working production backend just to match this template. Use the
template for server hardening, app folders, nginx, backups, and deployment
discipline first. Migrate code only when the product requirements justify it.

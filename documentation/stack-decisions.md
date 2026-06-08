# Stack Decisions

Use this as the default decision table for new server projects.

| Need | Default | Move Up When |
| --- | --- | --- |
| Static website | nginx static files | It needs server-side forms, admin stats, or webhooks |
| Site/admin/API | PHP + SQLite | It needs high-concurrency writes, seller accounts, moderation, uploads, or complex reporting |
| Non-game Go service | Go + SQLite | It needs realtime sockets, a compiled binary, long-running workers, or utility/service code where PHP is awkward |
| Realtime game service | Go service | It needs sessions, matches, matchmaking, presence, game state, or region coordination |
| Reusable game server platform | Custom Go platform | It needs multi-region orchestration or external managed DBs |
| Large downloads/assets | Cloudflare R2 | Never store large production downloads on the VPS by default |
| Ephemeral distributed state | No Redis by default | Add Redis/NATS when one process cannot own the live state |
| Container packaging | No Docker by default | Add Docker when a dependency stack is hard to install repeatably or when orchestration becomes useful |
| Scheduled maintenance | Cron | Use systemd timers when logs, dependencies, retries, or service-level control matter |

## Game-Platform Fit

A custom Go game-platform layer belongs in the game-server lane. It can become
the reusable substrate for accounts, sessions, websocket transport, matches,
matchmaking, wallet/storage/leaderboards, admin views, and future multiplayer
services.

That platform layer should not replace PHP + SQLite website/admin/download
endpoints. Those endpoints are intentionally boring and cheap.

Keep a separate minimal Go lane for non-game Go work: websocket tools, small
workers, utility services, health/admin services, and compiled backends where a
full game platform would be overkill.

Redis is not required for first single-node game deployments. One Go service can
keep live match/session state in memory and persist durable state to its
database. Add Redis or another message bus only when multiple nodes need shared
queues, shared matchmaking, cross-node presence, distributed rate limits, or
pub/sub fanout.

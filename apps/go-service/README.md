# Go Service

Thin starter lane for non-game Go services, websocket tools, workers, utilities, and small long-running services.

## Shape

```text
apps/go-service/
  cmd/service/
  internal/
  migrations/
```

## Rules

- Keep the service as one deployable binary when practical.
- Store durable small-product state in SQLite first.
- Keep live websocket state in memory when one process owns it.
- Persist durable result, purchase, entitlement, audit, or job records explicitly when needed.
- Use a dedicated game-platform service only when the app needs sessions, matchmaking, inventory, leaderboards, or multi-node multiplayer behavior.

## Redis Decision

Do not add Redis just because the service is Go. Add it only when multiple processes or regions need shared ephemeral state such as queues, pub/sub, presence fanout, distributed rate limits, or matchmaking coordination.

## Local Dev

```sh
make run
curl http://127.0.0.1:8090/healthz
```

## Build For Linux

```sh
make build-linux
```

## Game-Platform Fit

This example is intentionally small. Use it for tiny services, workers,
websocket tools, and non-game Go utilities. For game-platform features such as
sessions, matches, matchmaking, wallets, leaderboards, presence, and multiplayer
admin tools, build or adopt a dedicated game-platform service instead.

# App Manifest

Every deployed app should have a small manifest. Keep the public example generic; keep production secrets and private hostnames in a private runbook or password manager.

## Fields

| Field | Purpose |
| --- | --- |
| `name` | Short app id used for folders, users, services, and logs |
| `lane` | `static-site`, `php-sqlite-app`, `go-service`, or `game-service` |
| `domains` | Public domains/subdomains |
| `linux_user` | Per-app server user |
| `www_root` | Deployed code/static files |
| `data_root` | SQLite DBs and persistent app data |
| `env_file` | Production env path |
| `logs_root` | App log path |
| `nginx_site` | nginx site config path |
| `systemd_units` | Service units owned by this app |
| `database` | SQLite path or external DB decision |
| `backups` | Litestream/R2/other backup plan |
| `object_storage` | R2 buckets or public asset domains |

## Example

```json
{
  "name": "example",
  "lane": "php-sqlite-app",
  "domains": ["example.com"],
  "linux_user": "example",
  "www_root": "/var/www/example",
  "data_root": "/var/lib/example",
  "env_file": "/etc/example/example.env",
  "logs_root": "/var/log/example",
  "nginx_site": "/etc/nginx/sites-available/example.conf",
  "systemd_units": ["litestream-example.service"],
  "database": {
    "type": "sqlite",
    "path": "/var/lib/example/example.sqlite"
  },
  "backups": {
    "sqlite": "litestream",
    "target": "cloudflare-r2"
  },
  "object_storage": {
    "provider": "cloudflare-r2",
    "public_assets": "assets.example.com"
  }
}
```

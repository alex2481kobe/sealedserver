# Ops Console

This is a private shell/logs/status helper layer for a VPS.

## Access Model

- Use Tailscale SSH for shell access.
- Use `ops/appctl` for common commands.
- Use `journalctl` and nginx logs for service logs.
- Do not expose a browser shell publicly.
- Keep private dashboards behind Tailscale or Cloudflare Access.

## Common Commands

```sh
APP=example SERVICE=example ./ops/appctl status
APP=example SERVICE=example ./ops/appctl logs
APP=example SERVICE=example ./ops/appctl follow
APP=example SERVICE=example ./ops/appctl restart
APP=example ./ops/appctl nginx-logs
APP=example ./ops/appctl shell
```

For PHP-only apps, `SERVICE` may be `php8.3-fpm` or omitted if you only need nginx and app shell commands.

## Logs

Use:

```sh
sudo journalctl -u <service> -n 120 --no-pager
sudo journalctl -u <service> -f
sudo tail -n 120 /var/log/nginx/error.log
sudo tail -n 120 /var/log/<app>/*.log
```

## Shell

Use app shell for filesystem inspection and maintenance:

```sh
APP=example ./ops/appctl shell
```

This runs as the app Linux user and starts in `/var/www/<app>`.

## Sudoers

Start with normal sudo for your admin/deploy user. If deployment becomes repetitive, use `infra/sudoers/deploy-ops.example` as a narrow starting point.

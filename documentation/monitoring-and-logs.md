# Monitoring And Logs

Start simple. Do not add a heavy observability stack until the server has enough traffic or incidents to justify it.

## Minimum Checks

Per app:

- `GET /api/healthz` or `GET /healthz`.
- systemd service status.
- nginx config test.
- Litestream service status for SQLite apps.
- SQLite restore drill.

## Useful Commands

```sh
sudo systemctl status nginx
sudo systemctl status php8.3-fpm
sudo systemctl status cloudflared
sudo systemctl list-timers
sudo journalctl -u <service> -n 120 --no-pager
sudo journalctl -u <service> -f
sudo tail -n 120 /var/log/nginx/error.log
sudo ufw status verbose
sudo bash scripts/check-server-health.sh
```

## Alerts

First useful alerts:

- server disk > 80%;
- failed systemd service;
- failed Litestream backup;
- health endpoint down;
- SSL/Tunnel routing failure;
- payment webhook failures.

## Later

Add a real monitoring stack only when needed:

- Uptime Kuma for simple uptime checks.
- Grafana/Loki/Prometheus for logs and metrics.
- Cloudflare analytics for traffic and WAF events.

Keep dashboards private behind Tailscale or Cloudflare Access.

## Security Event Checks

Cloudflare:

- Review Security Events after adding WAF rules.
- Check Tunnel health after deploys and DNS changes.
- Watch webhook failures after enabling challenge/rate-limit rules.

Tailscale:

- Review Machines for stale devices.
- Confirm production servers keep the expected tags.
- Confirm SSH check mode still applies to production tags.

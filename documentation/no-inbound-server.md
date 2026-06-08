# No-Inbound Server Mode

Use this mode when the server should not expose public inbound ports. It pairs:

- Tailscale for private admin/SSH access.
- Cloudflare Tunnel for public websites and APIs.
- nginx listening on `127.0.0.1` only.
- UFW denying public inbound traffic.

This is the preferred first server shape when you want one cheap VPS to host several sites and small backends without leaving SSH, nginx, dashboards, or app services directly open to the internet.

## Traffic Shape

```text
visitor
  -> Cloudflare edge
  -> outbound Cloudflare Tunnel from server
  -> nginx on 127.0.0.1
  -> static files, PHP-FPM, or Go service

admin
  -> Tailscale
  -> SSH / private admin endpoints
```

## Provider Firewall

Use the VPS provider firewall as the first wall and UFW as the server wall.

For no-inbound mode, the provider firewall should deny public inbound traffic. Keep public `80`, `443`, `22`, and app ports closed. Allow outbound traffic so Tailscale and Cloudflare Tunnel can connect out.

During first setup, use the provider web console or a temporary SSH allowance only long enough to install and verify Tailscale. Remove that temporary allowance before considering the server production-ready.

Account-side hardening lives in:

- `documentation/tailscale-hardening.md`
- `documentation/cloudflare-hardening.md`

## 1. Install Base Packages

```sh
sudo apt update
sudo apt install nginx sqlite3 unattended-upgrades ufw logrotate cron curl ca-certificates rsync
```

Install lane-specific packages:

```sh
sudo apt install php8.3-cli php8.3-fpm php8.3-sqlite3
```

Install Litestream if the server will host SQLite production data:

```sh
curl -fsSL https://litestream.io/install.sh | sudo bash
```

You can also use the helper script for the base install:

```sh
sudo bash scripts/bootstrap-no-inbound-ubuntu.sh <server-name>
```

## 2. Install Tailscale

```sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname <server-name>
tailscale status
```

For unattended setup, create an auth key in the Tailscale admin console and use:

```sh
sudo tailscale up --auth-key <tskey-auth-...> --hostname <server-name>
```

Confirm SSH over Tailscale works from another terminal before changing firewall rules:

```sh
ssh <user>@<tailscale-ip-or-magicdns-name>
```

If using Tailscale SSH instead of normal OpenSSH over Tailscale, add `--ssh` to `tailscale up` and test with:

```sh
tailscale ssh <user>@<server-name>
```

## 3. Lock Down UFW

Do this only after Tailscale access works.

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

In no-inbound Tunnel mode, do not open public `80` or `443`. Cloudflare Tunnel connects outbound to Cloudflare.

If private admin pages need to be reachable over Tailscale:

```sh
sudo ufw allow in on tailscale0 to any port 8080 proto tcp
```

The matching helper script is:

```sh
sudo bash scripts/lock-no-inbound-firewall.sh
```

## 4. Bind nginx Locally

In Tunnel mode, nginx site configs should listen locally. For a single shared server, prefer one nginx listener for all public hostnames:

```nginx
listen 127.0.0.1:8080;
```

Cloudflare Tunnel routes public hostnames to that local listener. nginx dispatches by `server_name`. See `infra/nginx/first-server-tunnel.conf`.

## 5. Install Cloudflare Tunnel

Install `cloudflared`, authenticate, create a tunnel, and install it as a system service. Keep the tunnel credentials out of git.

Example shape:

```sh
cloudflared tunnel login
cloudflared tunnel create <tunnel-name>
cloudflared tunnel route dns <tunnel-name> example.com
sudo mkdir -p /etc/cloudflared
sudo cp cloudflared-tunnel.yml /etc/cloudflared/config.yml
sudo cloudflared service install
sudo systemctl enable --now cloudflared
sudo systemctl status cloudflared
```

Use `infra/cloudflare/first-server-tunnel.yml` for the shared first server, or `infra/cloudflare/cloudflared-tunnel.yml` for a single-app example.

## 6. Verify

On the server:

```sh
curl http://127.0.0.1:8080
sudo systemctl status nginx
sudo systemctl status cloudflared
sudo ufw status verbose
```

For the full firewall/listener check:

```sh
sudo bash scripts/verify-no-inbound.sh
sudo bash scripts/check-server-health.sh
```

From outside:

```sh
curl -I https://example.com
```

## Direct Public Mode

Use this only when you intentionally want nginx to accept public HTTP/HTTPS.

```sh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

Then configure nginx to listen on `80` and `443`, and use Cloudflare-proxied DNS, Cloudflare Origin Certificates, or Certbot. Public SSH should still stay closed if Tailscale is working.

## Official References

- Cloudflare Tunnel public applications: `https://developers.cloudflare.com/tunnel/`
- Cloudflare Tunnel firewall behavior: `https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/`
- Tailscale Ubuntu UFW hardening: `https://tailscale.com/docs/how-to/secure-ubuntu-server-with-ufw`
- Tailscale SSH: `https://tailscale.com/kb/1193/tailscale-ssh/`

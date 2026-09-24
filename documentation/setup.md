# Server Setup

This takes a fresh Ubuntu 24.04 server to the template's shape:

- no public inbound ports, at the provider firewall and in UFW;
- SSH only over Tailscale, with keys, as a `deploy` user;
- nginx on `127.0.0.1:8080`, published by Cloudflare Tunnel;
- automatic security updates, with a reboot at 04:00 UTC when one is needed.

Replace `<server-name>` with the server's Tailscale name and `<server-ip>` with
its public address.

## 1. First login

Create the server with your SSH key. Until Tailscale works, the provider
firewall allows SSH from your own IP address only.

On a home server, the router plays the provider firewall's part and forwards
no ports at all, and the machine's own keyboard and screen replace the
provider's web console. The first login happens on the local network.

```sh
ssh root@<server-ip>
apt update && apt upgrade -y
```

Create the `deploy` user with your key:

```sh
adduser deploy
usermod -aG sudo deploy
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
install -m 600 -o deploy -g deploy /root/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
```

Check `ssh deploy@<server-ip>` works from a second terminal, then continue as
`deploy`.

## 2. Base packages and hardening

```sh
sudo apt install -y git
git clone https://github.com/alex2481kobe/sealedserver.git
cd sealedserver
sudo bash scripts/bootstrap-no-inbound-ubuntu.sh <server-name>
sudo bash scripts/harden-ubuntu.sh
```

The bootstrap script installs nginx, SQLite, UFW, fail2ban, logrotate,
unattended upgrades, Tailscale and `cloudflared`.

The hardening script, safe to run again:

| Change | Effect |
| --- | --- |
| SSH: no passwords, no root login, no X11 forwarding | Only `deploy` logs in, with a key; root work goes through `sudo` and its password |
| Automatic reboot at 04:00 UTC | Kernel and library fixes take effect; services start again on boot |

It refuses to run until a sudo user has an SSH key. Check `ssh deploy@...`
from a second terminal before closing the current one.

## 3. Tailscale

```sh
sudo tailscale up --hostname <server-name>
```

From your own machine, on the same tailnet:

```sh
ssh deploy@<server-name>
```

Only continue once this works. This is OpenSSH over Tailscale. Tailscale SSH,
tailnet policy, tags and device approval are in [Tailscale](tailscale.md).

## 4. Close the firewall

```sh
sudo bash scripts/lock-no-inbound-firewall.sh
```

UFW now denies all inbound traffic and allows SSH on `tailscale0` only. Then
remove every inbound rule from the provider firewall and keep outbound open.

The script refuses to run while Tailscale is disconnected, or while any SSH
session comes in over the public address, since closing the firewall would cut
that session off.

## 5. nginx

Remove the default site, which listens on public port 80, and add the shared
tunnel settings:

```sh
sudo unlink /etc/nginx/sites-enabled/default
sudo cp infra/nginx/tunnel.conf /etc/nginx/conf.d/tunnel.conf
sudo nginx -t && sudo systemctl reload nginx
```

Sites are added per app. See [Apps](apps.md).

## 6. Cloudflare Tunnel

```sh
cloudflared tunnel login
cloudflared tunnel create <tunnel-name>
sudo mkdir -p /etc/cloudflared
sudo install -m 600 ~/.cloudflared/<tunnel-id>.json /etc/cloudflared/
sudo cp infra/cloudflare/config.yml /etc/cloudflared/config.yml
```

Edit `/etc/cloudflared/config.yml` with the tunnel id and your hostnames, then:

```sh
cloudflared tunnel route dns <tunnel-name> www.example.com
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

Run `route dns` once per hostname. Account and zone settings are in
[Cloudflare](cloudflare.md).

## 7. Check

```sh
sudo bash scripts/verify-sealed.sh
sudo bash scripts/server-report.sh > server-report.txt
```

`verify-sealed.sh` prints PASS or FAIL for each part of the sealed setup: SSH
login settings, firewall rules, public listeners, Tailscale, and automatic
updates. It exits with an error if anything fails.

The report is read-only and masks secrets. It covers the stack, users, app
folders, listeners, firewall, SSH, services, nginx, the tunnel, backups, and
live readings such as memory, disk and response times. Two reports from
different days can be compared with `diff`.

| Listener | Expected |
| --- | --- |
| nginx | `127.0.0.1:8080` only |
| App services | `127.0.0.1` ports only |
| sshd | `0.0.0.0:22`, reachable only through `tailscale0` |
| cloudflared | outbound connections only |

No port is open to the internet, not even 22. From a machine outside the
tailnet, all of these fail:

```sh
nc -vz -w 5 <server-ip> 22
nc -vz -w 5 <server-ip> 80
nc -vz -w 5 <server-ip> 443
```

## Limits

| Resource | Limit | What happens past it |
| --- | --- | --- |
| nginx connections | 768 per worker, one worker per CPU (Ubuntu's default) | New connections are refused; nginx logs `worker_connections are not enough` |
| Open websockets | About 768 on a 2-CPU server, across all apps | Same as above. A proxied websocket holds two nginx connections, one from `cloudflared` and one to the app |
| Go service files | 65536 per service (`LimitNOFILE`) | The service cannot accept more connections |
| Memory | The server's RAM; no swap and no per-app cap | The kernel stops the process using the most memory, and systemd restarts it |

Page and API requests hold a connection for milliseconds, so the connection
limit only matters for long-lived connections such as websockets.

Raising the nginx limit is an option in `/etc/nginx/nginx.conf`:

```nginx
worker_rlimit_nofile 8192;          # top level, next to worker_processes

events {
    worker_connections 4096;
}
```

Then `sudo nginx -t && sudo systemctl reload nginx`. Each open connection uses
memory in nginx, `cloudflared` and the app, so a higher limit allows more
memory use.

## Maintenance

From your own machine, with Tailscale connected:

```sh
bash scripts/maintain-server.sh deploy@<server-name>            # harden, update, reboot, report, check
bash scripts/maintain-server.sh deploy@<server-name> report     # report and check only
```

It asks for the SSH key passphrase once and the sudo password once. The key is
unlocked in a private agent that ends with the run. Then it:

1. runs `harden-ubuntu.sh` and checks a new SSH login still works;
2. installs all updates, keeping edited config files;
3. reboots if the updates need it and waits for the server to come back;
4. saves `server-report-<date>.txt` in the current folder, or in the folder
   given as a third argument;
5. runs `verify-sealed.sh` and exits with an error if any check fails.

Reports from different days can be compared with `diff`.

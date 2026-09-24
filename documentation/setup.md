# Server Setup

This takes a fresh Ubuntu 24.04 server to the template's shape:

- no public inbound ports, at the provider firewall and in UFW;
- SSH only over Tailscale, with keys, as a `deploy` user;
- nginx on `127.0.0.1:8080`, published by Cloudflare Tunnel;
- automatic security updates.

Replace `<server-name>` with the server's Tailscale name and `<server-ip>` with
its public address.

## 1. First login

Create the server with your SSH key. Until Tailscale works, the provider
firewall allows SSH from your own IP address only.

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

Turn off password logins:

```sh
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl reload ssh
```

Check `ssh deploy@<server-ip>` works from a second terminal, then continue as
`deploy`.

## 2. Base packages

```sh
sudo apt install -y git
git clone https://github.com/alex2481kobe/backend-template.git
cd backend-template
sudo bash scripts/bootstrap-no-inbound-ubuntu.sh <server-name>
```

The script installs nginx, SQLite, UFW, fail2ban, logrotate, unattended
upgrades, Tailscale and `cloudflared`.

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
sudo bash scripts/server-report.sh > server-report.txt
```

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

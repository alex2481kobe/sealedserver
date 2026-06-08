# Tailscale Hardening

Use Tailscale for private admin access. Public visitors should go through Cloudflare; administrators should reach SSH, logs, local dashboards, and private endpoints through Tailscale.

## Account Baseline

Before relying on Tailscale for production admin:

1. Enable 2FA on the identity provider used for Tailscale login.
2. Enable device approval for the tailnet.
3. Remove stale machines.
4. Use ACL tags for servers.
5. Use one-off auth keys for new servers.
6. Choose either Tailscale SSH with check mode or normal OpenSSH over Tailscale. For passphrase-gated admin workflows, normal OpenSSH over Tailscale is a good default.

## Device Approval

Device approval means new devices cannot send or receive tailnet traffic until approved.

Setup:

1. Open the Tailscale admin console.
2. Go to Device management.
3. Enable device approval.
4. Approve only trusted laptops, phones, and servers.

For servers, generate a pre-approved one-off auth key when you want unattended setup.

## Server Tags

Use tags for servers because servers should not inherit a personal user's tailnet identity.

Suggested tags:

```text
tag:server
tag:prod
tag:dev
```

Add tags in the tailnet policy file before using them. See `infra/tailscale/tailnet-policy.example.hujson`.

## Joining A Server

Interactive setup:

```sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --hostname <server-name>
```

If using normal OpenSSH over Tailscale instead of Tailscale SSH:

```sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname <server-name>
```

If the machine was previously started with `--ssh`, remove that non-default setting with:

```sh
sudo tailscale up --reset --hostname <server-name>
```

Auth-key setup:

```sh
sudo tailscale up \
  --ssh \
  --hostname <server-name> \
  --auth-key <tskey-auth-...> \
  --advertise-tags=tag:server,tag:prod
```

Auth key rules:

- Prefer one-off keys.
- Keep expiry short.
- Use pre-approved keys only when device approval is enabled.
- Revoke unused keys.
- Delete or expire old server nodes when replacing a VPS.

## SSH Policy

There are two private SSH modes.

### Tailscale SSH

Use `tailscale ssh <user>@<server-name>`. For production hosts, require check mode. Check mode forces an identity-provider reauth before SSH is established.

Recommended production behavior:

- Allow SSH only from admin users.
- Allow SSH only to `tag:server` or `tag:prod`.
- Allow only the `deploy` Linux user by default.
- Require check mode with `checkPeriod` set to `always` or a short window.
- Avoid broad `autogroup:nonroot` access on tagged servers.

See `infra/tailscale/tailnet-policy.example.hujson`.

### Normal OpenSSH Over Tailscale

Use `ssh <user>@<server-name>` or `ssh <user>@<tailscale-ip>`. The server's OpenSSH daemon still listens on port `22`, but public firewall rules keep that port closed to the internet. Tailscale carries the private network path.

Benefits:

- uses normal SSH keys and passphrases;
- matches common VPS workflows;
- does not expose public SSH;
- works even without Tailscale SSH enabled.

Recommended behavior:

- keep public provider firewall inbound closed;
- allow UFW `22/tcp` only on `tailscale0`;
- keep `PasswordAuthentication no`;
- use passphrase-protected SSH keys;
- limit root SSH over time by creating a `deploy` user.

## Server Firewall

After Tailscale access is confirmed from another terminal:

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

Provider firewall should also deny public inbound traffic. Keep outbound allowed for Tailscale and Cloudflare Tunnel.

## Private Admin Endpoints

Preferred shape:

```text
admin laptop
  -> Tailscale
  -> server private endpoint
```

Do not expose private dashboards through public hostnames unless they are behind Cloudflare Access and still require app auth.

If a local dashboard listens on `127.0.0.1:9000`, access it with SSH forwarding:

```sh
ssh -L 9000:127.0.0.1:9000 deploy@<server-tailscale-name>
```

Or bind private dashboards to the Tailscale IP only and allow that port on `tailscale0`.

## Verification

From the server:

```sh
tailscale status
tailscale ip -4
sudo ufw status verbose
```

From an admin machine:

```sh
tailscale status
tailscale ssh deploy@<server-name>
ssh deploy@<server-name>
```

Verify that public SSH is closed from outside the tailnet:

```sh
nc -vz <public-server-ip> 22
```

The expected result in no-inbound mode is failure from the public internet and success through Tailscale.

## Official References

- Tailscale device approval: `https://tailscale.com/docs/features/access-control/device-management/device-approval`
- Tailscale auth keys: `https://tailscale.com/docs/features/access-control/auth-keys`
- Tailscale SSH: `https://tailscale.com/docs/features/tailscale-ssh`
- Tailscale tags: `https://tailscale.com/docs/features/tags`
- Tailscale UFW hardening: `https://tailscale.com/docs/how-to/secure-ubuntu-server-with-ufw`

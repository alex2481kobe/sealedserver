# Tailscale

Tailscale is the only way into the server for admins. SSH travels inside the
tailnet, so port 22 is never open to the internet: the provider firewall has no
inbound rules at all, and UFW allows 22 on `tailscale0` only. SSH works in one
of two ways:

| | OpenSSH over Tailscale | Tailscale SSH |
| --- | --- | --- |
| Start with | `tailscale up` | `tailscale up --ssh` |
| Who handles SSH | The server's own `sshd` on port 22 | `tailscaled` |
| Login | Your SSH keys and passphrase | Your tailnet identity, no SSH keys |
| Access rules | `authorized_keys` on the server | The `ssh` block in the tailnet policy |
| Extra check | Key passphrase | Check mode: sign in again before a session |

The setup guide and scripts use OpenSSH over Tailscale, with UFW allowing port
22 on `tailscale0` only.

## Tailnet settings

In the Tailscale admin console:

1. 2FA on the identity provider you sign in with.
2. **Device approval** on, so new devices wait for approval.
3. The policy from `infra/tailscale/tailnet-policy.example.hujson`. It defines
   `tag:server`, `tag:prod` and `tag:dev` and lets admins reach tagged servers on
   port 22 only.
4. Old machines removed when a server is replaced.

## Adding a server

Interactive:

```sh
sudo tailscale up --hostname <server-name>
```

With an auth key and tags, for scripted setup. The key is read from a file so
it never appears in shell history or the process list:

```sh
install -m 600 /dev/null /tmp/ts-key && nano /tmp/ts-key    # paste the key
sudo tailscale up --hostname <server-name> \
  --auth-key file:/tmp/ts-key \
  --advertise-tags=tag:server,tag:prod
shred -u /tmp/ts-key
```

Auth keys are one-off, short-lived and pre-approved only while device approval
is on. Unused keys are revoked.

Tagged servers belong to the tailnet rather than to a person.

## Using Tailscale SSH

```sh
sudo tailscale up --ssh --hostname <server-name>
```

Uncomment the `ssh` block in the tailnet policy. It allows admins to log in as
`deploy` only, and asks them to sign in again before every session on
`tag:prod` servers and once an hour on `tag:dev` servers. Connect with plain
`ssh deploy@<server-name>` or `tailscale ssh deploy@<server-name>`.

To go back to OpenSSH:

```sh
sudo tailscale up --reset --hostname <server-name>
```

## When Tailscale is down

SSH only works through Tailscale, so the way in without it is the VPS
provider's web console. It is a screen and keyboard attached to the server,
not SSH, so the firewall and `PermitRootLogin no` do not apply to it.

1. Open the server's console in the provider's dashboard.
2. Log in as `deploy` with its password (the one `sudo` asks for).
3. Check Tailscale: `sudo systemctl status tailscaled`, `sudo tailscale up --hostname <server-name>`.

If the server's own Tailscale is fine and only your machine's is not, fixing
your machine's Tailscale is enough. The sites keep running either way, because
visitors come in through Cloudflare, not Tailscale.

## Private dashboards

A dashboard bound to `127.0.0.1` on the server is reached through an SSH tunnel:

```sh
ssh -L 9000:127.0.0.1:9000 deploy@<server-name>
```

Then open `http://127.0.0.1:9000` locally.

## Check

```sh
tailscale status
sudo ufw status verbose
```

`ssh deploy@<server-name>` works on the tailnet, and `nc -vz -w 5 <server-ip> 22`
fails from outside it.

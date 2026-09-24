# Tailscale

Tailscale is the only way into the server for admins. The server keeps normal
OpenSSH on port 22, and UFW allows it on the `tailscale0` interface only, so
SSH uses your usual keys and passphrases and is closed to the internet.

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

With an auth key and tags, for scripted setup:

```sh
sudo tailscale up --hostname <server-name> \
  --auth-key <tskey-auth-...> \
  --advertise-tags=tag:server,tag:prod
```

Auth keys are one-off, short-lived and pre-approved only while device approval
is on. Unused keys are revoked.

Tagged servers belong to the tailnet rather than to a person.

## Tailscale SSH

Tailscale SSH replaces OpenSSH keys with tailnet identity and can require a
fresh login before each session (check mode). The template does not use it. A
server that was started with `--ssh` goes back to OpenSSH with:

```sh
sudo tailscale up --reset --hostname <server-name>
```

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

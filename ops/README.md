# Ops Helpers

These helpers are optional. They make a VPS feel closer to a managed platform's logs/shell/status controls while keeping access private through SSH/Tailscale.

Do not expose these helpers through a public web dashboard.

## appctl

`appctl` wraps common per-app operations:

```sh
APP=example SERVICE=example ./ops/appctl status
APP=example SERVICE=example ./ops/appctl logs
APP=example ./ops/appctl nginx-logs
APP=example ./ops/appctl shell
```

Run it from a Tailscale SSH session as a sudo-capable deploy/admin user.

## Why Not A Web Shell?

A web shell is too dangerous for this template. If a dashboard token, proxy rule, or app bug leaks, a web shell becomes server control. Keep shell access on Tailscale/SSH.

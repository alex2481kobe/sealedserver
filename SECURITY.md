# Security Policy

This repository is a reusable backend/server template. Please report security
issues responsibly so they can be fixed without exposing users who copied the
template.

## Reporting a Vulnerability

If GitHub private vulnerability reporting is enabled for this repository, use
that channel first.

If private reporting is not available, open a public issue with a minimal
summary and ask for a private contact path. Do not include exploit payloads,
live credentials, private infrastructure, or sensitive logs in a public issue.

Helpful reports include:

- affected file or documentation page;
- impact and expected risk;
- minimal reproduction steps using placeholder values;
- whether the issue affects only the template or deployed apps created from it;
- suggested fix, if known.

## Scope

In scope:

- insecure template defaults;
- unsafe GitHub Actions or contribution workflows;
- examples that leak secrets or encourage unsafe secret handling;
- deployment docs that expose admin surfaces by default;
- PHP, Go, nginx, systemd, Cloudflare, Tailscale, or Litestream examples with
  security-impacting behavior.

Out of scope:

- attacks against servers, domains, or apps not owned by the reporter;
- denial-of-service testing;
- social engineering;
- vulnerabilities caused only by changing the documented defaults.

## Contribution Safety

Third-party pull requests are treated as untrusted until reviewed. Workflows for
outside PRs should run with read-only repository permissions and without
secrets. Privileged deploy, release, package publishing, and infrastructure jobs
should run only from trusted branches, tags, protected environments, or manual
maintainer dispatch.

Dependency and workflow changes require extra review because supply-chain
attacks often target package install hooks, lockfiles, maintainer tokens, and CI
automation.

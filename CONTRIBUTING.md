# Contributing

Thanks for helping improve this template. The goal is to keep it small,
boring, secure, and easy to adapt for real projects.

## Ground Rules

- Keep examples production-oriented but generic.
- Do not add real credentials, private hostnames, private IPs, server notes, or
  user-specific local paths.
- Prefer small, reviewable pull requests.
- Do not add dependencies speculatively.
- Keep generated files, local databases, logs, and build output out of git.
- Put public documentation in `documentation/`.

## Local Checks

Run the checks that match the files you changed.

```sh
cd apps/go-service
go test ./...
```

```sh
php -l apps/php-sqlite-app/public/index.php
php -l apps/php-sqlite-app/scripts/migrate.php
php -l apps/php-sqlite-app/src/bootstrap.php
php -l apps/php-sqlite-app/src/commerce.php
php -l apps/php-sqlite-app/src/records.php
php -l apps/php-sqlite-app/src/assets.php
```

```sh
sh -n scripts/bootstrap-no-inbound-ubuntu.sh
sh -n scripts/check-server-health.sh
sh -n scripts/create-app-folders.sh
sh -n scripts/lock-no-inbound-firewall.sh
sh -n scripts/verify-no-inbound.sh
sh -n ops/appctl
```

## Pull Requests

Outside contributions are welcome, but this repository treats third-party code
as untrusted until it has been reviewed. First-time and outside contributors may
need maintainer approval before CI jobs run.

CI and security checks are expected to run with least-privilege repository
permissions and without secrets. Do not add privileged workflow behavior without
maintainer review.

Call out any PR that changes:

- `.github/workflows/` or other automation;
- package manifests, lockfiles, install scripts, or dependency behavior;
- shell scripts, Makefiles, Dockerfiles, or deployment examples;
- generated, minified, binary, or vendored files;
- authentication, webhook, download, or admin behavior.

Maintainers may ask for high-risk changes to be split into smaller PRs.

## Maintainer Model

This project may be operated by a single owner. While that is true, the owner
may push directly or merge their own PRs after checks pass. Third-party PRs
still require maintainer review before merge.

If the project gains regular maintainers, add reviewer requirements or
CODEOWNERS rules for sensitive paths.

## Security

Do not open public issues with exploit details, live credentials, private
infrastructure, or proof-of-exploit instructions. Follow `SECURITY.md` instead.

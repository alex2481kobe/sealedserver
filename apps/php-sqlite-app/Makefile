APP_NAME ?= example
REMOTE ?= $(APP_NAME)@host
REMOTE_ROOT ?= /var/www/$(APP_NAME)

.PHONY: dev deploy install-deps migrate

dev:
	php -S 127.0.0.1:8080 -t public

migrate:
	php scripts/migrate.php

deploy:
	rsync -avz --delete public/ $(REMOTE):$(REMOTE_ROOT)/public/
	rsync -avz --delete src/ $(REMOTE):$(REMOTE_ROOT)/src/
	rsync -avz --delete scripts/ $(REMOTE):$(REMOTE_ROOT)/scripts/
	rsync -avz db/schema.sql $(REMOTE):$(REMOTE_ROOT)/db/schema.sql
	ssh $(REMOTE) "sudo systemctl reload nginx && sudo systemctl reload php8.3-fpm"

install-deps:
	@echo "Run on the server:"
	@echo "  sudo apt update"
	@echo "  sudo apt install nginx php8.3-cli php8.3-fpm php8.3-sqlite3 sqlite3 unattended-upgrades logrotate"
	@echo "  curl -fsSL https://litestream.io/install.sh | sudo bash"

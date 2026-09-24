APP ?= example
HOST ?= deploy@server
STAGE ?= /tmp/$(APP)-release
ROOT ?= /var/www/$(APP)

.PHONY: dev deploy

dev:
	APP_ENV_FILE=$(CURDIR)/.env php -S 127.0.0.1:8080 -t public

deploy:
	rsync -az --delete public src db $(HOST):$(STAGE)/
	ssh -t $(HOST) 'for d in public src db; do sudo rsync -a --delete $(STAGE)/$$d/ $(ROOT)/$$d/ || exit 1; done; sudo chown -R $(APP):$(APP) $(ROOT)'

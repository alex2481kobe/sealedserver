APP ?= example
HOST ?= deploy@server
PKG ?= ./cmd/service
OUT ?= bin/$(APP)-server
LINUX_ENV := GOOS=linux GOARCH=amd64 CGO_ENABLED=0
BIN := /opt/$(APP)/$(APP)-server

.PHONY: build build-linux run test deploy rollback clean

build:
	go build -trimpath -o $(OUT) $(PKG)

build-linux:
	$(LINUX_ENV) go build -trimpath -ldflags="-s -w" -o $(OUT)-linux-amd64 $(PKG)

run:
	go run $(PKG)

test:
	go test ./...

# Keeps the running binary as .previous, installs the new one, restarts,
# and fails if the service is not running two seconds later.
deploy: build-linux
	rsync -az $(OUT)-linux-amd64 $(HOST):/tmp/$(APP)-server
	ssh -t $(HOST) 'set -e; \
		if [ -f $(BIN) ]; then sudo cp -p $(BIN) $(BIN).previous; fi; \
		sudo install -o root -g root -m 0755 /tmp/$(APP)-server $(BIN); \
		rm /tmp/$(APP)-server; \
		sudo systemctl restart $(APP); sleep 2; systemctl is-active $(APP)'

rollback:
	ssh -t $(HOST) 'set -e; \
		sudo install -o root -g root -m 0755 $(BIN).previous $(BIN); \
		sudo systemctl restart $(APP); sleep 2; systemctl is-active $(APP)'

clean:
	rm -rf bin/

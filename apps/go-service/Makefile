APP ?= example
HOST ?= deploy@server
PKG ?= ./cmd/service
OUT ?= bin/$(APP)-server
LINUX_ENV := GOOS=linux GOARCH=amd64 CGO_ENABLED=0

.PHONY: build build-linux run test deploy clean

build:
	go build -trimpath -o $(OUT) $(PKG)

build-linux:
	$(LINUX_ENV) go build -trimpath -ldflags="-s -w" -o $(OUT)-linux-amd64 $(PKG)

run:
	go run $(PKG)

test:
	go test ./...

deploy: build-linux
	rsync -az $(OUT)-linux-amd64 $(HOST):/tmp/$(APP)-server
	ssh -t $(HOST) 'sudo install -o root -g root -m 0755 /tmp/$(APP)-server /opt/$(APP)/$(APP)-server && sudo systemctl restart $(APP)'

clean:
	rm -rf bin/

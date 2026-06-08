BINARY ?= go-service
PKG ?= ./cmd/service
OUT ?= bin/$(BINARY)
LINUX_ENV := GOOS=linux GOARCH=amd64 CGO_ENABLED=0

.PHONY: build build-linux run test tidy clean

build:
	go build -trimpath -o $(OUT) $(PKG)

build-linux:
	$(LINUX_ENV) go build -trimpath -ldflags="-s -w" -o $(OUT)-linux-amd64 $(PKG)

run:
	go run $(PKG)

test:
	go test ./...

tidy:
	go mod tidy

clean:
	rm -rf bin/

default: help
help: ## Display this message
	@grep -E '(^[a-zA-Z0-9_.-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

version = $(shell git describe --tags --long)
VERSION ?= $(shell git describe --tags --long 2>/dev/null || echo "v0.0.0")
DIST_DIR := dist

install:
	@npm install -g liquidsoap-prettier@v1.8.3

fmt: ## Format liquidsoap scripts
	@find . -type f -name '*.liq' -exec liquidsoap-prettier -w {} \;

artifact: ## Build binary artifact (zip + md5 in dist/)
	@set -eu; \
	mkdir -p $(DIST_DIR); \
	TMPDIR=$$(mktemp -d /tmp/rf-liquidsoap-XXXX); \
	cp -r scripts/ "$${TMPDIR}/rf-liquidsoap/"; \
	cd "$${TMPDIR}" && zip -qr "$(CURDIR)/$(DIST_DIR)/rf-liquidsoap-$(VERSION).zip" rf-liquidsoap; \
	rm -rf "$${TMPDIR}"; \
	if command -v md5 >/dev/null 2>&1; then \
		md5 -q "$(CURDIR)/$(DIST_DIR)/rf-liquidsoap-$(VERSION).zip" > "$(CURDIR)/$(DIST_DIR)/rf-liquidsoap-$(VERSION).zip.md5"; \
	else \
		md5sum "$(CURDIR)/$(DIST_DIR)/rf-liquidsoap-$(VERSION).zip" | awk '{print $$1}' > "$(CURDIR)/$(DIST_DIR)/rf-liquidsoap-$(VERSION).zip.md5"; \
	fi; \
	ls -la $(CURDIR)/$(DIST_DIR)

test: ## Run test on the liquidsoap configuration
	@docker compose up \
		liquidsoap-test-transcoder-stereo \
		liquidsoap-test-streamer-stereo \
		liquidsoap-test-transcoder-surround \
		liquidsoap-test-streamer-surround

reload: ## Update containers if needed and restart all liquidsoaps
	@docker compose up -d
	@docker compose restart \
		liquidsoap-test-transcoder-stereo \
		liquidsoap-test-streamer-stereo \
		liquidsoap-test-transcoder-surround \
		liquidsoap-test-streamer-surround
	@docker compose restart \
		liquidsoap-myradio \
		liquidsoap-myradiosurround \
		source-mystreamersurround
	@docker compose ps
	@docker compose logs -f

reload-streamers: ## Update containers if needed and restart source-mystreamersurround
	@docker compose up -d
	@docker compose restart \
		source-mystreamersurround
	@docker compose ps
	@docker compose logs -f

start: ## Start everything
	@docker compose up -d
	@docker compose ps
	@docker compose logs -f

stop: ## Stop all containers
	@docker compose down

status: ## Show status of docker containers
	@docker compose ps -a

clean: ## Stop and remove all containers, networks and volumes
	@docker compose down -v

logs: ## Show logs
	@docker compose logs -f

info: ## Show useful default URLs and service ports
	@cat .res/info.txt

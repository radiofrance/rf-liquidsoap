default: help
help: ## Display this message
	@grep -E '(^[a-zA-Z0-9_.-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

version = $(shell git describe --tags --long)

COMPOSE_PROFILES ?= myradio,monitor

artifact: ## Build binary artifact
	@mkdir /tmp/rf-liquidsoap-$(version)
	@cp -r scripts/ /tmp/rf-liquidsoap-$(version)/
	@tar --exclude-vcs --owner=0 --group=0 -C /tmp -cvzf rf-liquidsoap-$(version).tar.gz rf-liquidsoap-$(version)/
	@rm -rf /tmp/rf-liquidsoap-$(version)/
	@md5sum rf-liquidsoap-$(version).tar.gz

test: ## Run test on the liquidsoap configuration
	@docker compose --profile test up

restart: ## Update containers if needed and restart all liquidsoaps
	@docker compose --profile '*' restart
	@docker compose ps
	@docker compose logs -f

start: ## Start everything
	@COMPOSE_PROFILES=$(COMPOSE_PROFILES) docker compose up -d
	@docker compose ps
	@docker compose logs -f

start-surround:
	@COMPOSE_PROFILES=myradiosurround,monitor $(MAKE) start

dev:
	@COMPOSE_PROFILES=dev,monitor $(MAKE) start

stop: ## Stop all containers
	@docker compose --profile '*' down

status: ## Show status of docker containers
	@docker compose ps -a

clean: ## Stop and remove all containers, networks and volumes
	@docker compose --profile '*' down -v

logs: ## Show logs
	@docker compose logs -f

info: ## Show useful default URLs and service ports
	@cat .res/info.txt

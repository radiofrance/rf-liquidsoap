default: help
help: ## Display this message
	@grep -E '(^[a-zA-Z0-9_.-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

version = $(shell git describe --tags --long)

artifact: ## Build binary artifact
	@mkdir /tmp/rf-liquidsoap-$(version)
	@cp -r scripts/ /tmp/rf-liquidsoap-$(version)/
	@tar --exclude-vcs --owner=0 --group=0 -C /tmp -cvzf rf-liquidsoap-$(version).tar.gz rf-liquidsoap-$(version)/
	@rm -rf /tmp/rf-liquidsoap-$(version)/
	@md5sum rf-liquidsoap-$(version).tar.gz

test: ## Run test on the liquidsoap configuration
	@docker compose up liquidsoap-test-transcoder liquidsoap-test-streamer

reload: ## Update containers if needed and restart all liquidsoaps
	@docker compose up -d
	@docker compose restart liquidsoap-test-transcoder liquidsoap-test-streamer
	@docker compose restart liquidsoap-myradio liquidsoap-myradiosurround source-mystreamer
	@docker compose ps
	@docker compose logs -f

reload-streamer: ## Update containers if needed and restart source-mystreamer
	@docker compose up -d
	@docker compose restart source-mystreamer
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

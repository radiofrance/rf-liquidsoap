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
	@docker compose up \
		liquidsoap-test-transcoder-stereo \
		liquidsoap-test-streamer-stereo \
		liquidsoap-test-transcoder-surround \
	  liquidsoap-test-streamer-surround

reload: ## Update containers if needed and restart all liquidsoaps
	@docker compose up -d
	@docker compose restart \
		liquidsoap-test-transcoder-stereo \
		liquidsoap-test-streamer-stereo
	@docker compose restart \
		liquidsoap-myradio
	@docker compose ps
	@docker compose logs -f

reload-streamers: ## Update containers if needed and restart source-mystreamersurround
	@docker compose up -d
	@docker compose restart \
		source-mystreamersurround
	@docker compose ps
	@docker compose logs -f

start: ## Start everything
## Ensure the Docker network exists
	if [ -z "`docker network ls | grep chuntfm-liquidsoap`" ]; then \
		docker network create chuntfm-liquidsoap; \
	else \
		echo "Network chuntfm-liquidsoap already exists"; \
	fi
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

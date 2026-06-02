.PHONY: help

MAKEFLAGS += --silent
.DEFAULT_GOAL := help

COMPOSE := COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker compose

help: ## Show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

include .env

setup-traefik: ## Setup traefik
	@TRAEFIK_NETWORK=traefik-proxy; \
	TRAEFIK_NAME=traefik-local; \
	docker network ls | grep $$TRAEFIK_NETWORK > /dev/null || (echo "Creating traefik network" && docker network create $$TRAEFIK_NETWORK ); \
	if docker ps -a | grep $$TRAEFIK_NAME > /dev/null; then \
		echo "Traefik container already exists"; \
		if docker ps -a | grep $$TRAEFIK_NAME | grep Exited > /dev/null; then echo "Starting traefik container" && docker start $$TRAEFIK_NAME; fi; \
		if ! docker inspect -f '{{json .NetworkSettings.Networks}}' $$TRAEFIK_NAME | grep -q '"'$$TRAEFIK_NETWORK'"'; then \
			echo "Traefik container is not connected to '$$TRAEFIK_NETWORK' network" && exit 1; \
		fi; \
	else \
		echo "Creating traefik container" \
		&& docker pull traefik \
		&& docker run -itd \
			-p 80:80 -p 8080:8080 \
			-v /var/run/docker.sock:/var/run/docker.sock:ro \
			--restart unless-stopped --name $$TRAEFIK_NAME --network=$$TRAEFIK_NETWORK \
			--label "traefik.enable=true" --label "traefik.http.routers.traefik.rule=Host(\`traefik.localhost\`)" --label "traefik.http.routers.traefik.service=api@internal" \
			traefik \
			--api.insecure=true --providers.docker.exposedByDefault=false --providers.docker.network=$$TRAEFIK_NETWORK --accessLog=true; \
	fi

setup: ## Prepare stack to run
	$(MAKE) setup-traefik
	$(MAKE) up
	$(MAKE) npm install

start: ## Start application in dev mode
	$(MAKE) npm "run start -- --port 8080 --host 0.0.0.0 $(filter-out $@,$(MAKECMDGOALS))"

lint: ## Run linters
	$(MAKE) npm "run check -- $(filter-out $@,$(MAKECMDGOALS))"

lint-fix: ## Run linters
	$(MAKE) npm "audit fix" || true
	$(MAKE) npm "run fix"
	$(MAKE) linter-fix

build: ## Build libs and applications
	$(MAKE) npm "run build"

test: ## Run tests
	$(MAKE) npm "run test:ci $(filter-out $@,$(MAKECMDGOALS))"

ci: ## Prepare for CI
	$(MAKE) helm || true
	$(MAKE) lint-fix
	$(MAKE) build
	$(MAKE) test

up: ## Start containers
	@$(call check-env)
	@echo "Starting containers"
	@$(call compose,dev,up --remove-orphans --build -d $(filter-out $@,$(MAKECMDGOALS)))

down: ## Stop containers
	@echo "Stoping containers"
	@$(call compose,dev,down -v --remove-orphans -t 0 $(filter-out $@,$(MAKECMDGOALS)))

restart: ## Restart containers
	@echo "Restarting containers"
	@$(call compose,dev,restart -t 0 $(filter-out $@,$(MAKECMDGOALS)))

logs: ## Show containers logs
	@$(call compose,dev,logs -f $(filter-out $@,$(MAKECMDGOALS)))

ps: ## List containers
	@$(call compose,dev,ps $(filter-out $@,$(MAKECMDGOALS)))

web: ## Open application in browser
	@$(call check-env)
	@$(call open-in-browser,http://landing-page.cigales-cloud.localhost)

shell: ## Exec bash in application container
	@$(call compose,dev,exec application bash $(filter-out $@,$(MAKECMDGOALS)))

npm: ## Exec npm in application container
	@$(call compose,dev,exec application npm $(filter-out $@,$(MAKECMDGOALS)))

#############################
# Remote deploy like commands
#############################

up-deploy: ## Start containers in deploy mode
	@$(call check-env)
	@echo "Starting containers"
	@$(call compose,deploy,up --remove-orphans --build -d $(filter-out $@,$(MAKECMDGOALS)))

down-deploy: ## Stop deploy mode containers
	@echo "Stoping containers"
	@$(call compose,deploy,down -v --remove-orphans -t 0 $(filter-out $@,$(MAKECMDGOALS)))

logs-deploy: ## Show  deploy mode containers logs
	@$(call compose,deploy,logs -f $(filter-out $@,$(MAKECMDGOALS)))

ps-deploy: ## Show  deploy mode containers logs
	@$(call compose,deploy,ps $(filter-out $@,$(MAKECMDGOALS)))

helm: ## Run helm commands
	$(MAKE) helm-build
	$(MAKE) helm-docs
	$(MAKE) helm-tests

helm-build: ## Build helm charts
	@helm dependency build ./charts/application
	@helm package ./charts/application --destination ./charts/dist

helm-docs: ## Generate helm docs
	@helm-docs

helm-tests: ## Run helm tests
	@ct lint
	@helm kubeconform --summary ./charts/application

linter-fix: ## Execute linting and fix
	$(call run_linter, \
		-e FIX_CSS_PRETTIER=true \
		-e FIX_JSON_PRETTIER=true \
		-e FIX_JAVASCRIPT_PRETTIER=true \
		-e FIX_YAML_PRETTIER=true \
		-e FIX_MARKDOWN=true \
		-e FIX_MARKDOWN_PRETTIER=true \
		-e FIX_NATURAL_LANGUAGE=true \
	)

define run_linter
	DEFAULT_WORKSPACE="$(CURDIR)"; \
	LINTER_IMAGE="linter:latest"; \
	VOLUME="$$DEFAULT_WORKSPACE:$$DEFAULT_WORKSPACE"; \
	docker build --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) --tag $$LINTER_IMAGE .; \
	docker run \
		-e DEFAULT_WORKSPACE="$$DEFAULT_WORKSPACE" \
		-e FILTER_REGEX_INCLUDE="$(filter-out $@,$(MAKECMDGOALS))" \
		-e IGNORE_GITIGNORED_FILES=true \
		-e VALIDATE_TYPESCRIPT_ES=false \
        -e VALIDATE_CSS=false \
		$(1) \
		-v $$VOLUME \
		--rm \
		$$LINTER_IMAGE
endef

define compose
	$(COMPOSE) -f compose.yaml -f compose.local.yaml -f compose.$(1).yaml $(2)
endef

define open-in-browser
	@if command -v x-www-browser &> /dev/null ; then x-www-browser $(1); \
	elif command -v xdg-open &> /dev/null ; then xdg-open $(1); \
	elif command -v open &> /dev/null ; then open $(1); \
	elif command -v start &> /dev/null ; then	start $(1);	fi;
endef

#############################
# Argument fix workaround
#############################
%:
	@:

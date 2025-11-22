.PHONY: help docker-start docker-stop docker-restart docker-logs docker-clean docker-build test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

docker-start: ## Start all services with Docker Compose
	@./scripts/docker-start.sh start

docker-stop: ## Stop all services
	@./scripts/docker-start.sh stop

docker-restart: ## Restart all services
	@./scripts/docker-start.sh restart

docker-logs: ## Show logs from all services
	@./scripts/docker-start.sh logs

docker-status: ## Show status of all services
	@./scripts/docker-start.sh status

docker-clean: ## Stop services and remove volumes
	@./scripts/docker-start.sh clean

docker-build: ## Build Docker images without starting
	@docker-compose build

docker-up: ## Start services (alias for docker-start)
	@./scripts/docker-start.sh start

docker-down: ## Stop services (alias for docker-stop)
	@./scripts/docker-start.sh stop

test: ## Run tests (requires services to be running)
	@echo "Running backend tests..."
	@docker exec -it user-registration-backend pytest || echo "Backend container not running"
	@echo "Running frontend tests..."
	@docker exec -it user-registration-frontend yarn test || echo "Frontend container not running"


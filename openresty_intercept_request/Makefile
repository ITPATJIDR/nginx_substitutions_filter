.PHONY: help build up down logs restart test test-fail consume-kafka clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build all Docker images
	docker-compose build

up: ## Start all services
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Services started!"
	@echo "OpenResty: http://localhost:8080"
	@echo "API: http://localhost:3000"
	@echo "Kafka: localhost:29092"

down: ## Stop all services
	docker-compose down

logs: ## Show logs from all services
	docker-compose logs -f

logs-openresty: ## Show OpenResty logs
	docker-compose logs -f openresty

logs-api: ## Show API logs
	docker-compose logs -f api

logs-kafka: ## Show Kafka logs
	docker-compose logs -f kafka

restart: ## Restart all services
	docker-compose restart

restart-api: ## Restart only API service
	docker-compose restart api

stop-api: ## Stop API to simulate backend failure
	docker-compose stop api
	@echo "API stopped - requests will now be intercepted"

start-api: ## Start API service
	docker-compose start api
	@echo "API started - requests will be proxied normally"

test: ## Test normal requests to backend
	@echo "Testing health endpoint..."
	curl -s http://localhost:8080/health
	@echo "\n\nTesting API health..."
	curl -s http://localhost:8080/api/health | jq .
	@echo "\n\nTesting API users..."
	curl -s http://localhost:8080/api/users | jq .
	@echo "\n\nTesting API data..."
	curl -s http://localhost:8080/api/data | jq .

test-fail: ## Test failed request (stop API first with 'make stop-api')
	@echo "Testing failed request interception..."
	curl -X POST http://localhost:8080/api/users \
		-H "Content-Type: application/json" \
		-d '{"name":"John Doe","email":"john@example.com"}' | jq .

consume-kafka: ## Consume messages from Kafka failed-requests topic
	docker-compose exec kafka kafka-console-consumer \
		--bootstrap-server localhost:9092 \
		--topic failed-requests \
		--from-beginning

list-topics: ## List all Kafka topics
	docker-compose exec kafka kafka-topics \
		--bootstrap-server localhost:9092 \
		--list

create-topic: ## Create failed-requests topic (if not auto-created)
	docker-compose exec kafka kafka-topics \
		--bootstrap-server localhost:9092 \
		--create \
		--topic failed-requests \
		--partitions 3 \
		--replication-factor 1

clean: ## Remove all containers, volumes, and images
	docker-compose down -v
	docker-compose rm -f

demo: ## Run a complete demo
	@echo "Starting services..."
	@make up
	@echo "\n=== Testing normal requests ==="
	@sleep 5
	@make test
	@echo "\n\n=== Stopping API to simulate failure ==="
	@make stop-api
	@sleep 2
	@echo "\n=== Testing failed request ==="
	@make test-fail
	@echo "\n\n=== Check Kafka messages (Ctrl+C to exit) ==="
	@sleep 2
	@make consume-kafka


# OpenResty Keycloak Gateway Makefile

.PHONY: build up down logs test clean restart gateway-logs app-logs

# Build and start services
build:
	docker-compose build

up:
	docker-compose up -d

# Build and start services
start: build up

# Stop services
down:
	docker-compose down

# Stop and remove volumes
clean:
	docker-compose down -v --remove-orphans

# View logs
logs:
	docker-compose logs -f

gateway-logs:
	docker-compose logs -f gateway

app-logs:
	docker-compose logs -f app

# Restart services
restart: down up

# Test the setup
test:
	@echo "Testing the setup..."
	@sleep 5
	@bash test.sh

# Health checks
health:
	@echo "Checking service health..."
	@echo "Gateway health:"
	@curl -s http://localhost:8000/gateway-health | jq || curl -s http://localhost:8000/gateway-health
	@echo "\nApp health through gateway:"
	@curl -s http://localhost:8000/health | jq || curl -s http://localhost:8000/health
	@echo "\nDirect app health:"
	@curl -s http://localhost:3000/health | jq || curl -s http://localhost:3000/health

# Development mode (rebuild and start)
dev: clean build
	docker-compose up

# Show status
status:
	docker-compose ps

# Help
help:
	@echo "Available commands:"
	@echo "  build     - Build Docker images"
	@echo "  up        - Start services in background"
	@echo "  start     - Build and start services"
	@echo "  down      - Stop services"
	@echo "  clean     - Stop services and remove volumes"
	@echo "  logs      - Follow all logs"
	@echo "  gateway-logs - Follow gateway logs only"
	@echo "  app-logs  - Follow app logs only"
	@echo "  restart   - Restart services"
	@echo "  test      - Run tests"
	@echo "  health    - Check service health"
	@echo "  dev       - Clean rebuild for development"
	@echo "  status    - Show service status"
	@echo "  help      - Show this help"
# OpenResty Keycloak Gateway Makefile

.PHONY: build up down logs test clean restart gateway-logs app-logs

# Build and start services
build:
	docker-compose build

up:
	docker-compose up -d

# Build and start services
start: 
	build 
	up

# Stop services
down:
	docker-compose down

# Stop and remove volumes
clean:
	docker-compose down -v --remove-orphans
	docker system prune -f

# Force cleanup (for fixing ContainerConfig errors)
force-clean:
	docker-compose down -v --remove-orphans || true
	docker container prune -f
	docker image prune -f
	docker volume prune -f
	docker network prune -f

# View logs
logs:
	docker-compose logs -f

gateway-logs:
	docker-compose logs -f gateway

app-logs:
	docker-compose logs -f app

keycloak-logs:
	docker-compose logs -f keycloak

postgres-logs:
	docker-compose logs -f postgres

# Restart services
restart: down up

# Test the setup
test:
	@echo "Testing the setup..."
	@sleep 5
	@bash test.sh

# Get JWT token from Keycloak
get-token:
	@bash get-jwt-token.sh

# Test with JWT token
test-auth:
	@echo "Testing authentication..."
	@bash get-jwt-token.sh

# Health checks
health:
	@echo "Checking service health..."
	@echo "PostgreSQL health:"
	@docker-compose exec postgres pg_isready -U keycloak || echo "PostgreSQL not ready"
	@echo "\nKeycloak health:"
	@curl -s http://localhost:8080/health/ready | jq || curl -s http://localhost:8080/health/ready || echo "Keycloak not ready"
	@echo "\nGateway health:"
	@curl -s http://localhost:8000/gateway-health | jq || curl -s http://localhost:8000/gateway-health
	@echo "\nApp health through gateway:"
	@curl -s http://localhost:8000/health | jq || curl -s http://localhost:8000/health
	@echo "\nDirect app health:"
	@curl -s http://localhost:3000/health | jq || curl -s http://localhost:3000/health

# Development mode (rebuild and start)
dev: clean build
	docker-compose up

# Fix docker compose issues and restart
fix: force-clean build up

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
	@echo "  keycloak-logs - Follow keycloak logs only"
	@echo "  postgres-logs - Follow postgres logs only"
	@echo "  restart   - Restart services"
	@echo "  test      - Run tests"
	@echo "  get-token - Get JWT token from Keycloak"
	@echo "  test-auth - Test authentication with JWT token"
	@echo "  health    - Check service health"
	@echo "  dev       - Clean rebuild for development"
	@echo "  fix       - Force cleanup and restart (fixes ContainerConfig errors)"
	@echo "  force-clean - Force cleanup all Docker resources"
	@echo "  status    - Show service status"
	@echo "  help      - Show this help"
# Nginx + Keycloak + Express Makefile

.PHONY: build up down logs test clean restart help

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
	docker system prune -f

# Force cleanup (for fixing issues)
force-clean:
	docker-compose down -v --remove-orphans || true
	docker container prune -f
	docker image prune -f
	docker volume prune -f
	docker network prune -f

# View logs
logs:
	docker-compose logs -f

nginx-logs:
	docker-compose logs -f nginx

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

# Get admin token
get-admin-token:
	@bash get-jwt-token.sh admin adminpass

# Test with JWT token
test-auth:
	@echo "Testing authentication..."
	@bash get-jwt-token.sh testuser testpass

# Test admin access
test-admin:
	@echo "Testing admin authentication..."
	@bash get-jwt-token.sh admin adminpass

# Health checks
health:
	@echo "Checking service health..."
	@echo "PostgreSQL health:"
	@docker-compose exec postgres pg_isready -U keycloak || echo "PostgreSQL not ready"
	@echo "\nKeycloak health:"
	@curl -s http://localhost:8080/health/ready | jq || curl -s http://localhost:8080/health/ready || echo "Keycloak not ready"
	@echo "\nNginx health:"
	@curl -s http://localhost:8000/health | jq || curl -s http://localhost:8000/health
	@echo "\nApp health (direct):"
	@docker-compose exec app curl -s http://localhost:3000/health | jq || echo "App not ready"

# Development mode (rebuild and start)
dev: clean build
	docker-compose up

# Fix docker compose issues and restart
fix: force-clean build up

# Show status
status:
	docker-compose ps

# Open Keycloak admin console
keycloak-admin:
	@echo "Keycloak Admin Console: http://localhost:8080"
	@echo "Username: admin"
	@echo "Password: admin"

# Show service URLs
urls:
	@echo "Service URLs:"
	@echo "============="
	@echo "Nginx Gateway: http://localhost:8000"
	@echo "Keycloak Admin: http://localhost:8080 (admin/admin)"
	@echo "Express App (direct): http://localhost:3000"
	@echo ""
	@echo "Test Endpoints:"
	@echo "- Public: http://localhost:8000/"
	@echo "- API (auth required): http://localhost:8000/api/data"
	@echo "- User info: http://localhost:8000/user"
	@echo "- Admin (admin role): http://localhost:8000/admin"
	@echo "- Health: http://localhost:8000/health"

# Help
help:
	@echo "Available commands:"
	@echo "  build     - Build Docker images"
	@echo "  up        - Start services in background"
	@echo "  start     - Build and start services"
	@echo "  down      - Stop services"
	@echo "  clean     - Stop services and remove volumes"
	@echo "  logs      - Follow all logs"
	@echo "  nginx-logs - Follow nginx logs only"
	@echo "  app-logs  - Follow app logs only"
	@echo "  keycloak-logs - Follow keycloak logs only"
	@echo "  postgres-logs - Follow postgres logs only"
	@echo "  restart   - Restart services"
	@echo "  test      - Run tests"
	@echo "  get-token - Get JWT token for testuser"
	@echo "  get-admin-token - Get JWT token for admin"
	@echo "  test-auth - Test authentication with testuser"
	@echo "  test-admin - Test admin authentication"
	@echo "  health    - Check service health"
	@echo "  dev       - Clean rebuild for development"
	@echo "  fix       - Force cleanup and restart"
	@echo "  force-clean - Force cleanup all Docker resources"
	@echo "  status    - Show service status"
	@echo "  keycloak-admin - Show Keycloak admin info"
	@echo "  urls      - Show all service URLs"
	@echo "  help      - Show this help"
